//
//  ContentView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Now delegates ViewModel creation to role-specific container views.
//  ✅ CLEAN: Only handles top-level routing based on user role.
//  ✅ ROBUST: Aligned with a consistent ViewModel injection pattern.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    
    @ViewBuilder
    var body: some View {
        // Route to the appropriate role-specific container view.
        // Each container is responsible for creating its own ViewModel.
        switch authManager.userRole {
        case .admin, .manager:
            // Admin and Manager share the same dashboard experience.
            AdminDashboardContainerView()
        case .client:
            ClientDashboardContainerView()
        case .worker:
            WorkerDashboardContainerView()
        case nil:
            // Fallback for an undefined role, defaults to the worker experience.
            // This is a safe default for a partially configured user.
            WorkerDashboardContainerView()
        }
        // Pass the authManager down so the container views can use it.
        .environmentObject(authManager)
    }
}
