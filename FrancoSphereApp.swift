//
//  FrancoSphereApp.swift
//  FrancoSphere
//
//  ✅ V6.0: Cleaned up app entry point.
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
                        Text("Client Dashboard Placeholder").environmentObject(authManager)
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
                    await initializationViewModel.startInitialization()
                }
            }
        }
    }
}
