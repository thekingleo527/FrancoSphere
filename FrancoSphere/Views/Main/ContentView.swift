//
//  ContentView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed duplicate initialization
//  ✅ CLEAN: Only handles dashboard routing
//  ✅ SIMPLE: No initialization logic here
//  ✅ FIXED: Switch now uses UserRole enum cases instead of strings
//  ✅ FIXED: Uses @ViewBuilder for proper view composition
//  ✅ FIXED: Creates and passes required ViewModels to dashboard views
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    
    // ViewModels for each dashboard type
    @StateObject private var adminViewModel = AdminDashboardViewModel()
    @StateObject private var clientViewModel = ClientDashboardViewModel()
    @StateObject private var workerViewModel = WorkerDashboardViewModel()
    
    @ViewBuilder
    var body: some View {
        // Route to appropriate dashboard based on role
        switch authManager.userRole {
        case .admin:
            AdminDashboardView(viewModel: adminViewModel)
                .environmentObject(authManager)
        case .client:
            ClientDashboardView(viewModel: clientViewModel)
                .environmentObject(authManager)
        case .worker:
            WorkerDashboardView(viewModel: workerViewModel)
                .environmentObject(authManager)
        case .manager:
            // Managers get admin dashboard with focused features
            AdminDashboardView(viewModel: adminViewModel)
                .environmentObject(authManager)
        case nil:
            // Fallback to worker dashboard when no role is set
            WorkerDashboardView(viewModel: workerViewModel)
                .environmentObject(authManager)
        }
    }
}

// MARK: - Preview

#Preview("Admin View") {
    ContentView()
        .environmentObject({
            let auth = NewAuthManager.shared
            auth.userRole = .admin
            return auth
        }())
}

#Preview("Worker View") {
    ContentView()
        .environmentObject({
            let auth = NewAuthManager.shared
            auth.userRole = .worker
            return auth
        }())
}

#Preview("Client View") {
    ContentView()
        .environmentObject({
            let auth = NewAuthManager.shared
            auth.userRole = .client
            return auth
        }())
}
