//
//  NewAuthManager.swift
//  FrancoSphere v6.0
//
//  ✅ SECURE: Uses Keychain for session storage
//  ✅ INTEGRATED: Uses GRDBManager's authentication
//  ✅ BIOMETRIC: Face ID/Touch ID support
//  ✅ SESSION MANAGEMENT: Proper expiration and refresh
//

import Foundation
import Combine
import SwiftUI
import LocalAuthentication
import Security

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let sessionExpired = Notification.Name("sessionExpired")
}

@MainActor
public class NewAuthManager: ObservableObject {
    public static let shared = NewAuthManager()
    
    // MARK: - Published Properties
    @Published public private(set) var currentUser: CoreTypes.User?
    @Published public private(set) var isLoading = false
    @Published public private(set) var biometricType: LABiometryType = .none
    @Published public private(set) var isBiometricEnabled = false
    
    // MARK: - Public Properties
    public var isAuthenticated: Bool { currentUser != nil && isSessionValid }
    public var userRole: String { currentUser?.role ?? "worker" }
    public var workerId: String? { currentUser?.workerId }
    public var currentWorkerName: String { currentUser?.name ?? "Unknown" }
    
    // MARK: - Private Properties
    private let securityManager = SecurityManager.shared
    private let grdbManager = GRDBManager.shared
    private let laContext = LAContext()
    
    private var sessionId: String?
    private var sessionExpirationTimer: Timer?
    private var isSessionValid = false
    
    // Keychain keys
    private let sessionKey = "francosphere_session"
    private let biometricEnabledKey = "francosphere_biometric_enabled"
    
    private init() {
        setupBiometrics()
        restoreSession()
        startSessionMonitoring()
    }
    
    // MARK: - Biometric Setup
    
    private func setupBiometrics() {
        var error: NSError?
        let canEvaluate = laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if canEvaluate {
            biometricType = laContext.biometryType
            isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
        } else {
            biometricType = .none
            isBiometricEnabled = false
        }
        
        print("🔐 Biometric setup: type=\(biometricType.rawValue), enabled=\(isBiometricEnabled)")
    }
    
    // MARK: - Public Methods
    
    public func getCurrentUser() async -> CoreTypes.User? {
        return currentUser
    }
    
    /// Login with email and password
    public func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Use GRDBManager's secure authentication
        let result = await grdbManager.authenticateWorker(email: email, password: password)
        
        switch result {
        case .success(let authenticatedUser):
            // Create session
            do {
                let sessionId = try await grdbManager.createSession(
                    for: authenticatedUser.workerId,
                    deviceInfo: getDeviceInfo()
                )
                
                // Create CoreTypes.User
                let user = CoreTypes.User(
                    id: authenticatedUser.workerId,
                    workerId: authenticatedUser.workerId,
                    name: authenticatedUser.name,
                    email: authenticatedUser.email,
                    role: authenticatedUser.role
                )
                
                // Store session securely
                try await storeSession(user: user, sessionId: sessionId)
                
                // Update state
                self.currentUser = user
                self.sessionId = sessionId
                self.isSessionValid = true
                
                print("✅ Login successful for: \(user.name)")
                NotificationCenter.default.post(name: .userDidLogin, object: nil, userInfo: ["user": user])
                
                // Ask about biometric enrollment
                if biometricType != .none && !isBiometricEnabled {
                    await promptBiometricEnrollment()
                }
                
            } catch {
                throw AuthError.sessionCreationFailed
            }
            
        case .failure(let message):
            throw AuthError.authenticationFailed(message)
        }
    }
    
    /// Login with biometrics
    public func loginWithBiometrics() async throws {
        guard isBiometricEnabled else {
            throw AuthError.biometricsNotEnabled
        }
        
        // Retrieve stored session
        guard let sessionData = try await retrieveSessionFromKeychain() else {
            throw AuthError.noStoredSession
        }
        
        // Authenticate with biometrics
        let reason = "Authenticate to access FrancoSphere"
        
        do {
            let success = try await laContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                // Validate session is still active
                if let validatedUser = try await grdbManager.validateSession(sessionData.sessionId) {
                    // Create CoreTypes.User
                    let user = CoreTypes.User(
                        id: validatedUser.workerId,
                        workerId: validatedUser.workerId,
                        name: validatedUser.name,
                        email: validatedUser.email,
                        role: validatedUser.role
                    )
                    
                    // Update state
                    self.currentUser = user
                    self.sessionId = sessionData.sessionId
                    self.isSessionValid = true
                    
                    print("✅ Biometric login successful for: \(user.name)")
                    NotificationCenter.default.post(name: .userDidLogin, object: nil, userInfo: ["user": user])
                } else {
                    // Session expired
                    try await clearSession()
                    throw AuthError.sessionExpired
                }
            }
        } catch {
            throw AuthError.biometricAuthenticationFailed(error.localizedDescription)
        }
    }
    
    /// Enable biometric authentication
    public func enableBiometrics() async throws {
        guard currentUser != nil, sessionId != nil else {
            throw AuthError.notAuthenticated
        }
        
        guard biometricType != .none else {
            throw AuthError.biometricsNotAvailable
        }
        
        let reason = "Enable biometric authentication for FrancoSphere"
        
        do {
            let success = try await laContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                UserDefaults.standard.set(true, forKey: biometricEnabledKey)
                isBiometricEnabled = true
                print("✅ Biometrics enabled")
            }
        } catch {
            throw AuthError.biometricEnrollmentFailed(error.localizedDescription)
        }
    }
    
    /// Disable biometric authentication
    public func disableBiometrics() {
        UserDefaults.standard.set(false, forKey: biometricEnabledKey)
        isBiometricEnabled = false
        print("🔐 Biometrics disabled")
    }
    
    /// Logout
    public func logout() async {
        guard let user = currentUser else { return }
        
        // Logout from database
        if let workerId = user.workerId {
            try? await grdbManager.logout(workerId: workerId)
        }
        
        // Clear session
        try? await clearSession()
        
        // Update state
        currentUser = nil
        sessionId = nil
        isSessionValid = false
        
        print("👋 \(user.name) logged out.")
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    /// Refresh session
    public func refreshSession() async throws {
        guard let sessionId = sessionId else {
            throw AuthError.noActiveSession
        }
        
        if let validatedUser = try await grdbManager.validateSession(sessionId) {
            // Session still valid, update last activity
            isSessionValid = true
        } else {
            // Session expired
            isSessionValid = false
            try await clearSession()
            throw AuthError.sessionExpired
        }
    }
    
    // MARK: - Private Methods
    
    private func storeSession(user: CoreTypes.User, sessionId: String) async throws {
        let sessionData = SessionData(
            user: user,
            sessionId: sessionId,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(sessionData)
        
        // Store in Keychain using SecurityManager
        Task {
            try await securityManager.storeInKeychain(
                data,
                key: sessionKey,
                expiration: sessionData.expiresAt
            )
        }
    }
    
    private func retrieveSessionFromKeychain() async throws -> SessionData? {
        let data = try await Task {
            try await securityManager.getFromKeychain(key: sessionKey)
        }.value
        
        guard let data = data else { return nil }
        
        let decoder = JSONDecoder()
        return try decoder.decode(SessionData.self, from: data)
    }
    
    private func clearSession() async throws {
        Task {
            try await securityManager.deleteFromKeychain(key: sessionKey)
        }
        sessionExpirationTimer?.invalidate()
        sessionExpirationTimer = nil
    }
    
    private func restoreSession() {
        Task {
            do {
                if let sessionData = try await retrieveSessionFromKeychain() {
                    // Check if session is still valid
                    if Date() < sessionData.expiresAt {
                        // Validate with database
                        if let validatedUser = try await grdbManager.validateSession(sessionData.sessionId) {
                            self.currentUser = sessionData.user
                            self.sessionId = sessionData.sessionId
                            self.isSessionValid = true
                            print("✅ Restored session for \(sessionData.user.name)")
                        } else {
                            // Session invalid in database
                            try await clearSession()
                        }
                    } else {
                        // Session expired
                        try await clearSession()
                    }
                }
            } catch {
                print("❌ Failed to restore session: \(error)")
            }
        }
    }
    
    private func startSessionMonitoring() {
        // Check session validity every 5 minutes
        sessionExpirationTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task { [weak self] in
                do {
                    try await self?.refreshSession()
                } catch {
                    print("⚠️ Session refresh failed: \(error)")
                    if case AuthError.sessionExpired = error {
                        await self?.handleSessionExpired()
                    }
                }
            }
        }
    }
    
    private func handleSessionExpired() async {
        await logout()
        await MainActor.run {
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
    }
    
    private func promptBiometricEnrollment() async {
        // This would show a UI prompt asking if user wants to enable biometrics
        // For now, we'll just print
        print("🔐 Would you like to enable \(biometricTypeString) for faster login?")
    }
    
    private var biometricTypeString: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometric Authentication"
        }
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) - iOS \(device.systemVersion)"
    }
}

// MARK: - Supporting Types

private struct SessionData: Codable {
    let user: CoreTypes.User
    let sessionId: String
    let createdAt: Date
    let expiresAt: Date
}

// MARK: - Enhanced Auth Errors

public enum AuthError: LocalizedError {
    case authenticationFailed(String)
    case sessionCreationFailed
    case sessionExpired
    case noActiveSession
    case noStoredSession
    case notAuthenticated
    case biometricsNotAvailable
    case biometricsNotEnabled
    case biometricAuthenticationFailed(String)
    case biometricEnrollmentFailed(String)
    case keychainError(String)
    
    public var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return message
        case .sessionCreationFailed:
            return "Failed to create session"
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .noActiveSession:
            return "No active session found"
        case .noStoredSession:
            return "No stored session found. Please log in with your credentials."
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricsNotEnabled:
            return "Biometric authentication is not enabled"
        case .biometricAuthenticationFailed(let message):
            return "Biometric authentication failed: \(message)"
        case .biometricEnrollmentFailed(let message):
            return "Failed to enable biometrics: \(message)"
        case .keychainError(let message):
            return "Secure storage error: \(message)"
        }
    }
}

// MARK: - SecurityManager Extension

extension SecurityManager {
    /// Store data in keychain (made available for NewAuthManager)
    func storeInKeychain(_ data: Data, key: String, expiration: Date? = nil) async throws {
        // This is a wrapper to expose the private method
        // In production, you'd modify SecurityManager to make this public
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        if let expiration = expiration {
            let expirationData = try JSONEncoder().encode(expiration)
            query[kSecAttrComment as String] = expirationData.base64EncodedString()
        }
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.keychainError("Failed to store in keychain: \(status)")
        }
    }
    
    /// Retrieve data from keychain
    func getFromKeychain(key: String) async throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw AuthError.keychainError("Failed to retrieve from keychain: \(status)")
        }
        
        guard let resultDict = result as? [String: Any],
              let data = resultDict[kSecValueData as String] as? Data else {
            throw AuthError.keychainError("Invalid keychain data")
        }
        
        // Check expiration
        if let expirationString = resultDict[kSecAttrComment as String] as? String,
           let expirationData = Data(base64Encoded: expirationString),
           let expiration = try? JSONDecoder().decode(Date.self, from: expirationData),
           expiration < Date() {
            
            try await deleteFromKeychain(key: key)
            throw AuthError.sessionExpired
        }
        
        return data
    }
    
    /// Delete from keychain
    func deleteFromKeychain(key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AuthError.keychainError("Failed to delete from keychain: \(status)")
        }
    }
}
