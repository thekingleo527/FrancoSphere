//
//  QuickBooksOAuthManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/4/25.
//


//
//  QuickBooksOAuthManager.swift
//  FrancoSphere
//
//  💼 COMPLETE QUICKBOOKS OAUTH 2.0 IMPLEMENTATION
//  ✅ OAuth 2.0 authentication flow with PKCE
//  ✅ Automatic token refresh handling
//  ✅ Secure token storage via SecurityManager
//  ✅ Connection status monitoring
//  ✅ Error handling and retry logic
//

import Foundation
import SwiftUI
import AuthenticationServices
import Combine

// MARK: - QuickBooks OAuth Manager

@MainActor
class QuickBooksOAuthManager: NSObject, ObservableObject {
    
    static let shared = QuickBooksOAuthManager()
    
    // MARK: - Published Properties for UI
    @Published var isAuthenticated = false
    @Published var connectionStatus: QBConnectionStatus = .disconnected
    @Published var lastSyncDate: Date?
    @Published var companyInfo: QBCompanyInfo?
    @Published var authError: QBAuthError?
    @Published var isRefreshingToken = false
    
    // MARK: - Configuration (IMPORTANT: Replace with your actual values)
    private let clientId = "YOUR_QUICKBOOKS_CLIENT_ID" // Replace with actual
    private let clientSecret = "YOUR_QUICKBOOKS_CLIENT_SECRET" // Replace with actual
    private let redirectURI = "francosphere://oauth/callback"
    private let scope = "com.intuit.quickbooks.accounting"
    private let baseURL = "https://sandbox-quickbooks.api.intuit.com" // Use https://quickbooks.api.intuit.com for production
    
    // MARK: - Private Properties
    private let securityManager = SecurityManager.shared
    private var authSession: ASWebAuthenticationSession?
    private var tokenRefreshTimer: Timer?
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupTokenRefreshTimer()
        
        Task {
            await checkExistingAuthentication()
        }
    }
    
    // MARK: - Public OAuth Methods
    
    /// Initiate OAuth 2.0 authentication flow
    func initiateOAuth() async throws {
        print("🚀 Starting QuickBooks OAuth flow...")
        
        // Generate PKCE parameters for enhanced security
        generatePKCEParameters()
        
        // Build authorization URL
        let authURL = buildAuthorizationURL()
        
        // Start authentication session
        try await performAuthenticationSession(url: authURL)
    }
    
    /// Handle OAuth callback from redirect URI
    func handleOAuthCallback(url: URL) async throws {
        print("📲 Processing OAuth callback...")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw QBAuthError.invalidCallback
        }
        
        // Extract authorization code and realmId
        guard let code = queryItems.first(where: { $0.name == "code" })?.value,
              let realmId = queryItems.first(where: { $0.name == "realmId" })?.value else {
            
            // Check for error in callback
            if let error = queryItems.first(where: { $0.name == "error" })?.value {
                throw QBAuthError.authorizationDenied(error)
            }
            
            throw QBAuthError.missingAuthorizationCode
        }
        
        // Exchange authorization code for tokens
        try await exchangeCodeForTokens(code: code, realmId: realmId)
    }
    
    /// Refresh access token using refresh token
    func refreshAccessToken() async throws {
        print("🔄 Refreshing QuickBooks access token...")
        
        isRefreshingToken = true
        defer { isRefreshingToken = false }
        
        // Get existing refresh token
        guard let refreshToken = try await securityManager.getQuickBooksRefreshToken() else {
            throw QBAuthError.noRefreshToken
        }
        
        // Prepare refresh request
        let tokenURL = URL(string: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(basicAuthHeader)", forHTTPHeaderField: "Authorization")
        
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QBAuthError.networkError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw QBAuthError.tokenRefreshFailed(errorMessage)
        }
        
        // Parse token response
        let tokenResponse = try JSONDecoder().decode(QBTokenResponse.self, from: data)
        
        // Get existing credentials for company info
        let existingCredentials = try await securityManager.getQuickBooksCredentials()
        
        // Create new credentials
        let newCredentials = QuickBooksCredentials(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken ?? refreshToken, // Use new or keep existing
            companyId: existingCredentials?.companyId ?? "",
            realmId: existingCredentials?.realmId ?? "",
            expiresIn: tokenResponse.expiresIn
        )
        
        // Store new credentials
        try await securityManager.storeQuickBooksCredentials(newCredentials)
        
        // Update UI state
        connectionStatus = .connected
        isAuthenticated = true
        authError = nil
        
        print("✅ Token refreshed successfully")
    }
    
    /// Disconnect from QuickBooks
    func disconnect() async throws {
        print("🔌 Disconnecting from QuickBooks...")
        
        // Clear stored credentials
        try await securityManager.clearQuickBooksCredentials()
        
        // Update UI state
        isAuthenticated = false
        connectionStatus = .disconnected
        companyInfo = nil
        lastSyncDate = nil
        authError = nil
        
        // Stop token refresh timer
        tokenRefreshTimer?.invalidate()
        tokenRefreshTimer = nil
        
        print("✅ Disconnected successfully")
    }
    
    /// Get current authentication status
    func getAuthenticationStatus() async -> QBConnectionStatus {
        do {
            let credentials = try await securityManager.getQuickBooksCredentials()
            
            if let credentials = credentials {
                if credentials.isExpired {
                    return .expired
                } else {
                    return .connected
                }
            } else {
                return .disconnected
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }
    
    /// Test API connection with current credentials
    func testConnection() async throws -> QBCompanyInfo {
        print("🧪 Testing QuickBooks connection...")
        
        guard let credentials = try await securityManager.getQuickBooksCredentials() else {
            throw QBAuthError.notAuthenticated
        }
        
        // Call Company Info API
        let url = URL(string: "\(baseURL)/v3/company/\(credentials.realmId)/companyinfo/\(credentials.realmId)")!
        var request = URLRequest(url: url)
        request.setValue(credentials.authorizationHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QBAuthError.networkError("Invalid response")
        }
        
        if httpResponse.statusCode == 401 {
            // Token expired, try to refresh
            try await refreshAccessToken()
            throw QBAuthError.tokenExpired
        } else if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw QBAuthError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        // Parse company info response
        let companyResponse = try JSONDecoder().decode(QBCompanyInfoResponse.self, from: data)
        let company = companyResponse.QueryResponse.CompanyInfo.first!
        
        let companyInfo = QBCompanyInfo(
            id: company.Id,
            name: company.CompanyName,
            email: company.Email,
            address: company.CompanyAddr?.Line1,
            city: company.CompanyAddr?.City,
            state: company.CompanyAddr?.CountrySubDivisionCode,
            zipCode: company.CompanyAddr?.PostalCode,
            country: company.Country
        )
        
        // Update stored company info
        self.companyInfo = companyInfo
        connectionStatus = .connected
        
        print("✅ Connection test successful: \(companyInfo.name)")
        
        return companyInfo
    }
    
    // MARK: - Private Implementation
    
    /// Check for existing authentication on app startup
    private func checkExistingAuthentication() async {
        do {
            let credentials = try await securityManager.getQuickBooksCredentials()
            
            if let credentials = credentials {
                if credentials.isExpired {
                    print("⚠️ Stored token expired, attempting refresh...")
                    try await refreshAccessToken()
                } else {
                    // Test existing connection
                    let companyInfo = try await testConnection()
                    self.companyInfo = companyInfo
                    isAuthenticated = true
                    connectionStatus = .connected
                    print("✅ Existing QuickBooks connection restored")
                }
            }
        } catch {
            print("❌ Failed to restore existing connection: \(error)")
            connectionStatus = .error(error.localizedDescription)
        }
    }
    
    /// Generate PKCE parameters for OAuth security
    private func generatePKCEParameters() {
        // Generate code verifier (random string)
        let verifier = generateRandomString(length: 128)
        codeVerifier = verifier
        
        // Generate code challenge (SHA256 hash of verifier, base64url encoded)
        let challengeData = Data(verifier.utf8)
        let hashed = SHA256.hash(data: challengeData)
        codeChallenge = Data(hashed).base64URLEncodedString()
    }
    
    /// Build OAuth authorization URL
    private func buildAuthorizationURL() -> URL {
        var components = URLComponents(string: "https://appcenter.intuit.com/connect/oauth2")!
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        
        return components.url!
    }
    
    /// Perform authentication session with ASWebAuthenticationSession
    private func performAuthenticationSession(url: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            authSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "francosphere"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: QBAuthError.authenticationFailed(error.localizedDescription))
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: QBAuthError.invalidCallback)
                    return
                }
                
                Task {
                    do {
                        try await self.handleOAuthCallback(url: callbackURL)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = false
            authSession?.start()
        }
    }
    
    /// Exchange authorization code for access and refresh tokens
    private func exchangeCodeForTokens(code: String, realmId: String) async throws {
        let tokenURL = URL(string: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(basicAuthHeader)", forHTTPHeaderField: "Authorization")
        
        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ]
        
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QBAuthError.networkError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw QBAuthError.tokenExchangeFailed(errorMessage)
        }
        
        // Parse token response
        let tokenResponse = try JSONDecoder().decode(QBTokenResponse.self, from: data)
        
        // Create credentials
        let credentials = QuickBooksCredentials(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken ?? "",
            companyId: realmId, // Use realmId as company identifier
            realmId: realmId,
            expiresIn: tokenResponse.expiresIn
        )
        
        // Store credentials securely
        try await securityManager.storeQuickBooksCredentials(credentials)
        
        // Store refresh token separately
        if let refreshToken = tokenResponse.refreshToken {
            try await securityManager.storeQuickBooksRefreshToken(refreshToken)
        }
        
        // Update UI state
        isAuthenticated = true
        connectionStatus = .connected
        authError = nil
        
        // Test connection and get company info
        do {
            let companyInfo = try await testConnection()
            self.companyInfo = companyInfo
        } catch {
            print("⚠️ Failed to get company info: \(error)")
        }
        
        print("✅ QuickBooks authentication successful")
    }
    
    /// Setup automatic token refresh timer
    private func setupTokenRefreshTimer() {
        tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: 3300, repeats: true) { _ in
            Task {
                do {
                    try await self.refreshAccessToken()
                } catch {
                    print("⚠️ Automatic token refresh failed: \(error)")
                }
            }
        }
    }
    
    /// Generate basic auth header for client credentials
    private var basicAuthHeader: String {
        let credentials = "\(clientId):\(clientSecret)"
        let credentialsData = credentials.data(using: .utf8)!
        return credentialsData.base64EncodedString()
    }
    
    /// Generate random string for PKCE
    private func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension QuickBooksOAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? UIWindow()
    }
}

// MARK: - Supporting Types

enum QBConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case expired
    case error(String)
    
    var displayText: String {
        switch self {
        case .disconnected: return "Not Connected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .expired: return "Token Expired"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .blue
        case .connected: return .green
        case .expired: return .orange
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .disconnected: return "link.circle"
        case .connecting: return "arrow.clockwise.circle"
        case .connected: return "checkmark.circle.fill"
        case .expired: return "clock.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

enum QBAuthError: LocalizedError {
    case invalidCallback
    case missingAuthorizationCode
    case authorizationDenied(String)
    case tokenExchangeFailed(String)
    case tokenRefreshFailed(String)
    case networkError(String)
    case notAuthenticated
    case tokenExpired
    case noRefreshToken
    case authenticationFailed(String)
    case apiError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "Invalid OAuth callback received"
        case .missingAuthorizationCode:
            return "Authorization code not received"
        case .authorizationDenied(let reason):
            return "Authorization denied: \(reason)"
        case .tokenExchangeFailed(let message):
            return "Token exchange failed: \(message)"
        case .tokenRefreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .notAuthenticated:
            return "Not authenticated with QuickBooks"
        case .tokenExpired:
            return "Access token has expired"
        case .noRefreshToken:
            return "No refresh token available"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        }
    }
}

struct QBCompanyInfo {
    let id: String
    let name: String
    let email: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    
    var formattedAddress: String {
        let components = [address, city, state, zipCode].compactMap { $0 }
        return components.joined(separator: ", ")
    }
}

// MARK: - API Response Types

private struct QBTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

private struct QBCompanyInfoResponse: Codable {
    let QueryResponse: QueryResponse
    
    struct QueryResponse: Codable {
        let CompanyInfo: [CompanyInfo]
    }
    
    struct CompanyInfo: Codable {
        let Id: String
        let CompanyName: String
        let Email: String?
        let CompanyAddr: Address?
        let Country: String?
    }
    
    struct Address: Codable {
        let Line1: String?
        let City: String?
        let CountrySubDivisionCode: String?
        let PostalCode: String?
    }
}

// MARK: - Data Extension for Base64URL

extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}