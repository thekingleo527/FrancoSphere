//
//  ContentView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed duplicate initialization
//  ✅ CLEAN: Only handles dashboard routing
//  ✅ SIMPLE: No initialization logic here
//  ✅ FIXED: Switch now uses UserRole enum cases instead of strings
//  ✅ FIXED: Uses @ViewBuilder for proper view composition
//  ✅ FIXED: Dashboard views create their own ViewModels internally
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    
    @ViewBuilder
    var body: some View {
        // Route to appropriate dashboard based on role
        switch authManager.userRole {
        case .admin:
            AdminDashboardView()
                .environmentObject(authManager)
        case .client:
            ClientDashboardView()
                .environmentObject(authManager)
        case .worker:
            WorkerDashboardView()
                .environmentObject(authManager)
        case .manager:
            // Managers get admin dashboard with focused features
            AdminDashboardView()
                .environmentObject(authManager)
        case nil:
            // Fallback to worker dashboard when no role is set
            WorkerDashboardView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(NewAuthManager.shared)
}

// MARK: - Preview Note
// To test different dashboard views, you have several options:
//
// 1. Preview each dashboard directly in its own file:
//    - Open AdminDashboardView.swift and use its preview
//    - Open WorkerDashboardView.swift and use its preview
//    - Open ClientDashboardView.swift and use its preview
//
// 2. Log in with different test accounts in the preview:
//    - Use the actual login flow with test credentials
//    - Each test account should have a different role
//
// 3. Temporarily modify NewAuthManager for testing:
//    - Add a debug-only method to set test users
//    - Remember to remove before production
//
// Note: userRole is computed from currentUser and cannot be set directly
