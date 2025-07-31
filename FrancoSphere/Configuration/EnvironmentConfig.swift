//
//  EnvironmentConfig.swift
//  FrancoSphere
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
}
