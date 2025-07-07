//
//  FrancoSphereApp.swift
//  FrancoSphere
//
//  ✅ V6.0: Cleaned up app entry point.
//  ✅ FIXED: All redeclaration errors resolved by moving views to their own files.
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
                    // Show initialization screen while setting up
                    InitializationView(viewModel: initializationViewModel)
                } else if authManager.isAuthenticated {
                    // Routing logic remains the same
                    switch authManager.userRole {
                    case "admin":
                        AdminDashboardView()
                            .environmentObject(authManager)
                    case "client":
                        // We will build this view later
                        Text("Client Dashboard Placeholder")
                            .environmentObject(authManager)
                    default: // worker
                        WorkerDashboardView()
                            .environmentObject(authManager)
                    }
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                // Trigger initialization on launch if it hasn't already run
                if !initializationViewModel.isInitializing && !initializationViewModel.isComplete {
                    await initializationViewModel.startInitialization()
                }
            }
        }
    }
}
