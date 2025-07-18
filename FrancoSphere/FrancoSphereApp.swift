//
//  FrancoSphereApp.swift
//  FrancoSphere v6.0
//
//  ✅ CLEAN: Single startup system integration
//  ✅ ORGANIZED: Uses DatabaseStartupCoordinator
//  ✅ SIMPLE: Clear initialization flow
//  ✅ PRODUCTION: Ready for deployment
//

import SwiftUI  

@main
struct FrancoSphereApp: App {
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var initializationViewModel = InitializationViewModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !initializationViewModel.isComplete {
                    InitializationView(viewModel: initializationViewModel)
                } else if authManager.isAuthenticated {
                    switch authManager.userRole {
                    case "admin":
                        AdminDashboardView().environmentObject(authManager)
                    case "client":
                        ClientDashboardView().environmentObject(authManager)
                    default: // worker
                        WorkerDashboardView().environmentObject(authManager)
                    }
                } else {
                    LoginView().environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                if !initializationViewModel.isInitializing && !initializationViewModel.isComplete {
                    // Start UI initialization
                    await initializationViewModel.startInitialization()
                    
                    // Start database initialization in parallel
                    await initializeDatabaseSystems()
                }
            }
        }
    }
    
    /// Clean database initialization using single entry point
    @MainActor
    private func initializeDatabaseSystems() async {
        do {
            print("🚀 Starting database initialization...")
            try await DatabaseStartupCoordinator.shared.ensureDataIntegrity()
            print("✅ Database initialization completed successfully")
        } catch {
            print("❌ Database initialization failed: \(error)")
            // Don't block app launch on database errors
            // User can still use app with limited functionality
        }
    }
}
