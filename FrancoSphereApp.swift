//
//  FrancoSphereApp.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Uses real ClientDashboardView instead of placeholder
//  ✅ REAL: All dashboard implementations now complete
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
                        AdminDashboardView()
                            .environmentObject(authManager)
                    case "client":
                        ClientDashboardView()
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
                if !initializationViewModel.isInitializing && !initializationViewModel.isComplete {
                    await initializationViewModel.startInitialization()
                }
            }
        }
    }
}
