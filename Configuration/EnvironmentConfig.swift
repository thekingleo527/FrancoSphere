//
//  EnvironmentConfig.swift
//  CyntientOps
//
//  Environment configuration for different deployment targets
//

import Foundation

// Renamed from 'Environment' to 'AppEnvironment' to avoid SwiftUI conflicts
enum AppEnvironment: String {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8080"
        case .staging:
            return "https://staging-api.francosphere.com"
        case .production:
            return "https://api.francosphere.com"
        }
    }
    
    var websocketURL: String {
        switch self {
        case .development:
            return "ws://localhost:8080/sync"
        case .staging:
            return "wss://staging-api.francosphere.com/sync"
        case .production:
            return "wss://api.francosphere.com/sync"
        }
    }
    
    var isDebugEnabled: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
}

final class EnvironmentConfig {
    static let shared = EnvironmentConfig()
    
    let current: AppEnvironment
    
    private init() {
        #if DEBUG
        self.current = .development
        #elseif STAGING
        self.current = .staging
        #else
        self.current = .production
        #endif
    }
    
    var baseURL: String {
        current.baseURL
    }
    
    var websocketURL: String {
        current.websocketURL
    }
    
    var isDebugEnabled: Bool {
        current.isDebugEnabled
    }
    
    /// Check if app is running in demo mode (missing critical credentials)
    var isDemoMode: Bool {
        return DemoMode.isEnabled
    }
    
    /// Get comprehensive credential status for debugging
    var credentialStatus: [String: String] {
        return Credentials.getCredentialStatus()
    }
}

// MARK: - API Configuration Extensions

extension EnvironmentConfig {
    
    // DSNY API configuration
    var dsnyAPIToken: String? {
        let token = Credentials.DSNY_API_TOKEN
        return Credentials.isPlaceholder(token) ? nil : token
    }
    
    var dsnyAPIBaseURL: String {
        "https://data.cityofnewyork.us/resource"
    }
    
    // NYC APIs configuration
    var nycAPIConfiguration: NYCAPIConfig {
        return NYCAPIConfig(
            hpdKey: Credentials.HPD_API_KEY,
            hpdSecret: Credentials.HPD_API_SECRET,
            dobSubscriberKey: Credentials.DOB_SUBSCRIBER_KEY,
            dobAccessToken: Credentials.DOB_ACCESS_TOKEN,
            depAccountNumber: Credentials.DEP_ACCOUNT_NUMBER,
            depPin: Credentials.DEP_API_PIN
        )
    }
    
    // QuickBooks configuration
    var quickBooksConfiguration: QuickBooksConfig {
        // Use sandbox credentials if production credentials are placeholders
        let useProduction = !Credentials.isPlaceholder(Credentials.QUICKBOOKS_CLIENT_ID)
        
        return QuickBooksConfig(
            clientId: useProduction ? Credentials.QUICKBOOKS_CLIENT_ID : Credentials.QB_SANDBOX_CLIENT_ID,
            clientSecret: useProduction ? Credentials.QUICKBOOKS_CLIENT_SECRET : Credentials.QB_SANDBOX_SECRET,
            companyId: useProduction ? Credentials.QUICKBOOKS_COMPANY_ID : Credentials.QB_SANDBOX_COMPANY,
            webhookToken: Credentials.QUICKBOOKS_WEBHOOK_TOKEN,
            isSandbox: !useProduction
        )
    }
    
    // Backend configuration
    var backendConfiguration: BackendConfig {
        return BackendConfig(
            apiBaseURL: Credentials.API_BASE_URL,
            websocketURL: Credentials.WEBSOCKET_URL,
            apiKey: Credentials.API_KEY,
            authToken: Credentials.WEBSOCKET_AUTH_TOKEN
        )
    }
    
    // Monitoring configuration
    var monitoringConfiguration: MonitoringConfig {
        return MonitoringConfig(
            sentryDSN: Credentials.isPlaceholder(Credentials.SENTRY_DSN) ? nil : Credentials.SENTRY_DSN,
            isAnalyticsEnabled: !isDemoMode
        )
    }
}

// MARK: - Configuration Structs

struct NYCAPIConfig {
    let hpdKey: String
    let hpdSecret: String
    let dobSubscriberKey: String
    let dobAccessToken: String
    let depAccountNumber: String
    let depPin: String
    
    var isHPDConfigured: Bool {
        !Credentials.isPlaceholder(hpdKey) && !Credentials.isPlaceholder(hpdSecret)
    }
    
    var isDOBConfigured: Bool {
        !Credentials.isPlaceholder(dobSubscriberKey) && !Credentials.isPlaceholder(dobAccessToken)
    }
    
    var isDEPConfigured: Bool {
        !Credentials.isPlaceholder(depAccountNumber) && !Credentials.isPlaceholder(depPin)
    }
}

struct QuickBooksConfig {
    let clientId: String
    let clientSecret: String
    let companyId: String
    let webhookToken: String
    let isSandbox: Bool
    
    var isConfigured: Bool {
        !Credentials.isPlaceholder(clientId) && !Credentials.isPlaceholder(clientSecret)
    }
}

struct BackendConfig {
    let apiBaseURL: String
    let websocketURL: String
    let apiKey: String
    let authToken: String
    
    var isConfigured: Bool {
        !Credentials.isPlaceholder(apiKey) && !websocketURL.contains("localhost")
    }
}

struct MonitoringConfig {
    let sentryDSN: String?
    let isAnalyticsEnabled: Bool
    
    var isSentryConfigured: Bool {
        guard let dsn = sentryDSN else { return false }
        return !Credentials.isPlaceholder(dsn)
    }
}
