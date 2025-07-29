//
//  FrancoSphereApp.swift
//  FrancoSphere v6.0
//
//  ✅ CLEAN: Single startup system integration
//  ✅ ORGANIZED: Uses existing InitializationViewModel
//  ✅ SIMPLE: Clear initialization flow
//  ✅ PRODUCTION: Ready for deployment
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
                    InitializationView(viewModel: initializationViewModel)
                } else if authManager.isAuthenticated {
                    authenticatedView
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
            .environmentObject(authManager)
            .environmentObject(dataSyncService)
            .task {
                if !initializationViewModel.isInitializing && !initializationViewModel.isComplete {
                    await initializationViewModel.startInitialization()
                }
            }
        }
    }
    
    @ViewBuilder
    private var authenticatedView: some View {
        switch authManager.userRole {
        case "admin":
            AdminDashboardView()
        case "client":
            ClientDashboardView()
        default: // worker
            WorkerDashboardView()
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
