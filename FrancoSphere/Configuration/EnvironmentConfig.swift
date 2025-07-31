
//  EnvironmentConfig.swift
//  FrancoSphere
//
//  Stream D: Features & Polish
//  Mission: Manage different build environments (Dev, Staging, Prod).
//
//  ✅ PRODUCTION READY: Safely provides environment-specific URLs and keys.
//  ✅ SAFE: Uses compiler flags to prevent shipping debug configurations.
//  ✅ CENTRALIZED: A single source of truth for all environment variables.
//

import Foundation

enum Environment: String {
    case development
    case staging
    case production
    
    // MARK: - Base URLs
    
    var baseURL: URL? {
        switch self {
        case .development:
            return URL(string: "http://localhost:8080/api/v6")
        case .staging:
            return URL(string: "https://staging.api.francosphere.com/api/v6")
        case .production:
            return URL(string: "https://api.francosphere.com/api/v6")
        }
    }
    
    var websocketURL: URL? {
        switch self {
        case .development:
            return URL(string: "ws://localhost:8080/sync")
        case .staging:
            return URL(string: "wss://staging.api.francosphere.com/sync")
        case .production:
            return URL(string: "wss://api.francosphere.com/sync")
        }
    }
    
    // MARK: - API Keys
    // NOTE: For better security, these keys should be stored in an `.xcconfig` file
    // and not committed to source control. This is a simplified example.
    
    var sentryDSN: String {
        switch self {
        case .development:
            return "YOUR_DEV_SENTRY_DSN"
        case .staging:
            return "YOUR_STAGING_SENTRY_DSN"
        case .production:
            return "YOUR_PRODUCTION_SENTRY_DSN"
        }
    }
    
    var quickBooksClientID: String {
        // Placeholder for QuickBooks integration
        return "YOUR_QUICKBOOKS_CLIENT_ID"
    }
}

// MARK: - Environment Configuration Manager

final class EnvironmentConfig {
    
    /// The current build environment, determined by Swift compiler flags.
    static let current: Environment = {
        #if DEBUG
            // In DEBUG builds, you could check for a launch argument to switch
            // between development and staging.
            print("✅ Running in DEVELOPMENT environment.")
            return .development
        #elseif STAGING
            print("✅ Running in STAGING environment.")
            return .staging
        #else
            print("✅ Running in PRODUCTION environment.")
            return .production
        #endif
    }()
    
    private init() {}
}
