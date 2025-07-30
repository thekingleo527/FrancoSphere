//
//  ContentView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed duplicate initialization
//  ✅ CLEAN: Only handles dashboard routing
//  ✅ SIMPLE: No initialization logic here
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    
    var body: some View {
        Group {
            // Route to appropriate dashboard based on role
            switch authManager.userRole {
            case "admin":
                AdminDashboardView()
            case "client":
                ClientDashboardView()
            case "worker":
                WorkerDashboardView()
            case "manager":
                // Managers get admin dashboard with focused features
                AdminDashboardView()
            default:
                // Fallback to worker dashboard
                WorkerDashboardView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(NewAuthManager.shared)
}
