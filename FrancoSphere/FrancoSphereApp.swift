//
//  FrancoSphereApp.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Single initialization path
//  ✅ CLEAN: Clear flow - Initialize → Authenticate → Route
//  ✅ SIMPLE: No duplicate logic
//

import SwiftUI

@main
struct FrancoSphereApp: App {
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var initializationViewModel = InitializationViewModel()
    @StateObject private var dataSyncService = DataSynchronizationService.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !initializationViewModel.isComplete {
                    // Step 1: Initialize the app
                    InitializationView(viewModel: initializationViewModel)
                } else if authManager.isAuthenticated {
                    // Step 2: Show authenticated content
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(dataSyncService)
                } else {
                    // Step 3: Show login if not authenticated
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                // Start initialization if needed
                if !initializationViewModel.isInitializing && !initializationViewModel.isComplete {
                    await initializationViewModel.startInitialization()
                }
            }
        }
    }
}

// MARK: - App Environment
struct AppEnvironment {
    static let isDebug = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
}
