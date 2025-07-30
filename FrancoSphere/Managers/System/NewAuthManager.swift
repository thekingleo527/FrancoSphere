//
//  NewAuthManager.swift
//  FrancoSphere v6.0
//
//  ✅ PHASE 2 COMPLIANT: Secure authentication with Keychain storage
//  ✅ BIOMETRIC: Face ID/Touch ID support
//  ✅ SESSION MANAGEMENT: Token expiration and refresh
//  ✅ ROLE-BASED ACCESS: Proper permission handling
//  ✅ NO HARDCODED CREDENTIALS: All passwords hashed and stored securely
//

import Foundation
import Combine
import SwiftUI
import LocalAuthentication
import Security

// MARK: - Notifications
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let sessionExpired = Notification.Name("sessionExpired")
    static let sessionRefreshed = Notification.Name("sessionRefreshed")
}

// MARK: - NewAuthManager
@MainActor
public class NewAuthManager: ObservableObject {
    public static let shared = NewAuthManager()
    
    // MARK: - Published Properties
    @Published public private(set) var currentUser: CoreTypes.User?
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var authError: AuthError?
    @Published public private(set) var biometricType: LABiometryType = .none
    @Published public private(set) var isBiometricEnabled = false
    @Published public private(set) var sessionStatus: SessionStatus = .none
    
    // MARK: - Public Properties
    public var userRole: CoreTypes.UserRole? {
        guard let roleString = currentUser?.role else { return nil }
        return CoreTypes.UserRole(rawValue: roleString)
    }
    
    public var workerId: CoreTypes.WorkerID? {
        currentUser?.workerId
    }
    
    public var currentWorkerName: String {
        currentUser?.name ?? "Unknown"
    }
    
    public var hasAdminAccess: Bool {
        userRole == .admin || userRole == .manager
    }
    
    public var hasWorkerAccess: Bool {
        userRole == .worker || hasAdminAccess
    }
    
    // MARK: - Private Properties
    private let grdbManager = GRDBManager.shared
    private let laContext = LAContext()
    private var cancellables = Set<AnyCancellable>()
    
    // Session management
    private var sessionToken: String?
    private var refreshToken: String?
    private var sessionExpirationDate: Date?
    private var sessionTimer: Timer?
    
    // Keychain keys
    private let keychainService = "com.francosphere.auth"
    private let sessionTokenKey = "sessionToken"
    private let refreshTokenKey = "refreshToken"
    private let biometricEnabledKey = "biometricEnabled"
    private let lastAuthenticatedUserKey = "lastAuthenticatedUser"
    
    // Security settings
    private let sessionDuration: TimeInterval = 8 * 60 * 60 // 8 hours
    private let sessionRefreshThreshold: TimeInterval = 30 * 60 // 30 minutes before expiry
    private let maxLoginAttempts = 5
    private var loginAttempts = 0
    
    private init() {
        setupBiometrics()
        restoreSession()
        setupSessionMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Authenticate with email and password
    public func authenticate(email: String, password: String) async throws {
        // Check for too many login attempts
        guard loginAttempts < maxLoginAttempts else {
            throw AuthError.tooManyAttempts
        }
        
        isLoading = true
        authError = nil
        defer { isLoading = false }
        
        do {
            // Authenticate with database
            let result = await grdbManager.authenticateWorker(email: email, password: password)
            
            switch result {
            case .success(let authenticatedUser):
                // Create session
                let session = try await createSession(for: (
                    workerId: authenticatedUser.workerId,
                    name: authenticatedUser.name,
                    email: authenticatedUser.email,
                    role: authenticatedUser.role
                ))
                
                // Create CoreTypes.User
                let user = CoreTypes.User(
                    id: authenticatedUser.workerId,
                    workerId: authenticatedUser.workerId,
                    name: authenticatedUser.name,
                    email: authenticatedUser.email,
                    role: authenticatedUser.role
                )
                
                // Store session in keychain
                try await storeSession(session: session, user: user)
                
                // Update state
                self.currentUser = user
                self.isAuthenticated = true
                self.sessionStatus = .active
                self.loginAttempts = 0
                
                // Store last authenticated user for biometric login
                UserDefaults.standard.set(email, forKey: lastAuthenticatedUserKey)
                
                // Start session monitoring
                startSessionTimer()
                
                print("✅ Authentication successful for \(user.name)")
                NotificationCenter.default.post(name: .userDidLogin, object: nil, userInfo: ["user": user])
                
                // Prompt for biometric enrollment if available
                if biometricType != .none && !isBiometricEnabled {
                    Task {
                        try? await promptBiometricEnrollment()
                    }
                }
                
            case .failure(let message):
                loginAttempts += 1
                throw AuthError.authenticationFailed(message)
            }
        } catch {
            authError = error as? AuthError ?? .unknown(error.localizedDescription)
            throw error
        }
    }
    
    /// Authenticate with biometrics
    public func authenticateWithBiometrics() async throws {
        guard isBiometricEnabled else {
            throw AuthError.biometricsNotEnabled
        }
        
        guard let lastEmail = UserDefaults.standard.string(forKey: lastAuthenticatedUserKey) else {
            throw AuthError.noStoredCredentials
        }
        
        isLoading = true
        authError = nil
        defer { isLoading = false }
        
        // Authenticate with biometrics
        let reason = "Authenticate to access FrancoSphere"
        
        do {
            let success = try await laContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                // Retrieve stored session
                if let session = try await retrieveStoredSession() {
                    // Validate session is still active
                    if session.expirationDate > Date() {
                        // Restore user session
                        self.currentUser = session.user
                        self.sessionToken = session.token
                        self.refreshToken = session.refreshToken
                        self.sessionExpirationDate = session.expirationDate
                        self.isAuthenticated = true
                        self.sessionStatus = .active
                        
                        startSessionTimer()
                        
                        print("✅ Biometric authentication successful")
                        NotificationCenter.default.post(name: .userDidLogin, object: nil, userInfo: ["user": session.user])
                    } else {
                        // Session expired, try to refresh
                        try await refreshSession()
                    }
                } else {
                    throw AuthError.noStoredSession
                }
            }
        } catch let error as LAError {
            throw AuthError.biometricAuthenticationFailed(error.localizedDescription)
        }
    }
    
    /// Enable biometric authentication
    public func enableBiometrics() async throws {
        guard isAuthenticated else {
            throw AuthError.notAuthenticated
        }
        
        guard biometricType != .none else {
            throw AuthError.biometricsNotAvailable
        }
        
        let reason = "Enable \(biometricTypeString) for faster authentication"
        
        do {
            let success = try await laContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                UserDefaults.standard.set(true, forKey: biometricEnabledKey)
                isBiometricEnabled = true
                print("✅ Biometrics enabled successfully")
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
    
    /// Logout current user
    public func logout() async {
        // Clear session from database
        if let workerId = currentUser?.workerId {
            try? await grdbManager.logout(workerId: workerId)
        }
        
        // Clear keychain
        clearKeychain()
        
        // Clear state
        let previousUser = currentUser
        currentUser = nil
        sessionToken = nil
        refreshToken = nil
        sessionExpirationDate = nil
        isAuthenticated = false
        sessionStatus = .none
        authError = nil
        
        // Stop session timer
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        if let user = previousUser {
            print("👋 \(user.name) logged out")
        }
        
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    /// Refresh the current session
    public func refreshSession() async throws {
        guard let refreshToken = refreshToken else {
            throw AuthError.noActiveSession
        }
        
        sessionStatus = .refreshing
        
        do {
            // In production, this would call an API endpoint
            // For now, we'll extend the session locally
            let newExpirationDate = Date().addingTimeInterval(sessionDuration)
            self.sessionExpirationDate = newExpirationDate
            self.sessionStatus = .active
            
            // Update stored session
            if let user = currentUser,
               let token = sessionToken {
                let session = Session(
                    token: token,
                    refreshToken: refreshToken,
                    expirationDate: newExpirationDate,
                    user: user
                )
                try await storeSession(session: session, user: user)
            }
            
            NotificationCenter.default.post(name: .sessionRefreshed, object: nil)
            print("✅ Session refreshed successfully")
        } catch {
            sessionStatus = .expired
            throw AuthError.sessionRefreshFailed
        }
    }
    
    /// Check if user has permission for specific action
    public func hasPermission(for permission: Permission) -> Bool {
        guard let role = userRole else { return false }
        return permission.allowedRoles.contains(role)
    }
    
    /// Validate current session
    public func validateSession() async -> Bool {
        guard isAuthenticated,
              let expirationDate = sessionExpirationDate else {
            return false
        }
        
        // Check if session is expired
        if Date() > expirationDate {
            sessionStatus = .expired
            await handleSessionExpired()
            return false
        }
        
        // Check if session needs refresh
        let timeUntilExpiry = expirationDate.timeIntervalSinceNow
        if timeUntilExpiry < sessionRefreshThreshold {
            do {
                try await refreshSession()
            } catch {
                print("⚠️ Failed to refresh session: \(error)")
            }
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func setupBiometrics() {
        var error: NSError?
        let canEvaluate = laContext.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        
        if canEvaluate {
            biometricType = laContext.biometryType
            isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
        } else {
            biometricType = .none
            isBiometricEnabled = false
        }
        
        print("🔐 Biometric setup - Type: \(biometricTypeString), Enabled: \(isBiometricEnabled)")
    }
    
    private func createSession(for authenticatedWorker: (workerId: String, name: String, email: String, role: String)) async throws -> Session {
        // Generate tokens (in production, these would come from the server)
        let sessionToken = UUID().uuidString
        let refreshToken = UUID().uuidString
        let expirationDate = Date().addingTimeInterval(sessionDuration)
        
        // Create session in database
        let sessionId = try await grdbManager.createSession(
            for: authenticatedWorker.workerId,
            deviceInfo: getDeviceInfo()
        )
        
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
        self.sessionExpirationDate = expirationDate
        
        return Session(
            token: sessionToken,
            refreshToken: refreshToken,
            expirationDate: expirationDate,
            user: CoreTypes.User(
                id: authenticatedWorker.workerId,
                workerId: authenticatedWorker.workerId,
                name: authenticatedWorker.name,
                email: authenticatedWorker.email,
                role: authenticatedWorker.role
            )
        )
    }
    
    private func storeSession(session: Session, user: CoreTypes.User) async throws {
        // Store tokens in keychain
        try storeInKeychain(session.token, for: sessionTokenKey)
        try storeInKeychain(session.refreshToken, for: refreshTokenKey)
        
        // Store session data
        let encoder = JSONEncoder()
        let sessionData = try encoder.encode(session)
        try storeInKeychain(sessionData, for: "session")
    }
    
    private func retrieveStoredSession() async throws -> Session? {
        guard let sessionData = try? getFromKeychain(key: "session") as? Data else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(Session.self, from: sessionData)
    }
    
    private func restoreSession() {
        Task {
            do {
                if let session = try await retrieveStoredSession() {
                    // Validate session
                    if session.expirationDate > Date() {
                        self.currentUser = session.user
                        self.sessionToken = session.token
                        self.refreshToken = session.refreshToken
                        self.sessionExpirationDate = session.expirationDate
                        self.isAuthenticated = true
                        self.sessionStatus = .active
                        
                        startSessionTimer()
                        
                        print("✅ Session restored for \(session.user.name)")
                    } else {
                        // Session expired
                        clearKeychain()
                    }
                }
            } catch {
                print("❌ Failed to restore session: \(error)")
            }
        }
    }
    
    private func setupSessionMonitoring() {
        // Monitor app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.validateSession()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.sessionTimer?.invalidate()
            }
            .store(in: &cancellables)
    }
    
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        
        // Check session every minute
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.validateSession()
            }
        }
    }
    
    private func handleSessionExpired() async {
        await logout()
        NotificationCenter.default.post(name: .sessionExpired, object: nil)
    }
    
    private func promptBiometricEnrollment() async throws {
        // In a real app, this would show a proper UI dialog
        // For now, we'll auto-enable if the user agrees
        try await enableBiometrics()
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
    
    // MARK: - Keychain Methods
    
    private func storeInKeychain(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.keychainError("Failed to store in keychain: \(status)")
        }
    }
    
    private func storeInKeychain(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw AuthError.keychainError("Failed to encode string")
        }
        try storeInKeychain(data, for: key)
    }
    
    private func getFromKeychain(key: String) throws -> Any? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
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
        
        return result
    }
    
    private func clearKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Supporting Types

public enum SessionStatus {
    case none
    case active
    case refreshing
    case expired
}

public struct Permission {
    let name: String
    let allowedRoles: Set<CoreTypes.UserRole>
    
    // Common permissions
    static let viewAllBuildings = Permission(
        name: "view_all_buildings",
        allowedRoles: [.admin, .manager, .client]
    )
    
    static let assignTasks = Permission(
        name: "assign_tasks",
        allowedRoles: [.admin, .manager]
    )
    
    static let viewFinancials = Permission(
        name: "view_financials",
        allowedRoles: [.admin, .client]
    )
    
    static let manageWorkers = Permission(
        name: "manage_workers",
        allowedRoles: [.admin, .manager]
    )
    
    static let completeTasks = Permission(
        name: "complete_tasks",
        allowedRoles: [.admin, .manager, .worker]
    )
}

private struct Session: Codable {
    let token: String
    let refreshToken: String
    let expirationDate: Date
    let user: CoreTypes.User
}

// Note: AuthenticatedUser type is defined elsewhere in the project (likely in GRDBManager)
// We use a tuple in createSession to avoid naming conflicts

// MARK: - Auth Errors

public enum AuthError: LocalizedError {
    case authenticationFailed(String)
    case sessionCreationFailed
    case sessionExpired
    case sessionRefreshFailed
    case noActiveSession
    case noStoredSession
    case noStoredCredentials
    case notAuthenticated
    case biometricsNotAvailable
    case biometricsNotEnabled
    case biometricAuthenticationFailed(String)
    case biometricEnrollmentFailed(String)
    case keychainError(String)
    case tooManyAttempts
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .sessionCreationFailed:
            return "Failed to create session"
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .sessionRefreshFailed:
            return "Failed to refresh session"
        case .noActiveSession:
            return "No active session found"
        case .noStoredSession:
            return "No stored session found"
        case .noStoredCredentials:
            return "No stored credentials found. Please log in with your email and password."
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
        case .tooManyAttempts:
            return "Too many failed login attempts. Please try again later."
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}
