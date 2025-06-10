//
//  ContentView.swift
//  FrancoSphere
//
//  Main entry point - routes to appropriate dashboard based on auth
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = NewAuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Direct to appropriate dashboard based on role
                switch authManager.userRole {
                case "admin", "client":
                    AdminDashboardPlaceholder()
                case "worker":
                    // Use the actual WorkerDashboardView_V2 from your project
                    WorkerDashboardView_V2()
                default:
                    // Fallback to worker dashboard
                    WorkerDashboardView_V2()
                }
            } else {
                // Not authenticated, show login
                LoginView()
            }
        }
        .onAppear {
            // Check authentication status synchronously (already handled in init)
            print("ContentView appeared - Auth status: \(authManager.isAuthenticated)")
        }
    }
}

// MARK: - Placeholder for AdminDashboardView
struct AdminDashboardPlaceholder: View {
    @StateObject private var authManager = NewAuthManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Admin Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Welcome, \(authManager.displayName)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Admin features coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.vertical)
                
                // Quick stats
                VStack(alignment: .leading, spacing: 12) {
                    Label("18 Buildings", systemImage: "building.2.fill")
                    Label("7 Active Workers", systemImage: "person.3.fill")
                    Label("120+ Tasks", systemImage: "checklist")
                }
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button("Switch to Worker View") {
                        // Temporarily switch role for testing
                        authManager.userRole = "worker"
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Logout") {
                        authManager.logout()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
            .navigationTitle("FrancoSphere Admin")
        }
    }
}

// MARK: - Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
