//
//  ContentView.swift
//  FrancoSphere
//
//  Fixed: Generic parameter inference and missing view imports
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
                    WorkerDashboardViewWrapper()
                default:
                    // Fallback to worker dashboard
                    WorkerDashboardViewWrapper()
                }
            } else {
                // Not authenticated, show login
                LoginView()
            }
        }
        .onAppear {
            // Ensure authentication state is current
            authManager.checkAuthenticationStatus()
        }
    }
}

// MARK: - Wrapper for WorkerDashboardView
struct WorkerDashboardViewWrapper: View {
    var body: some View {
        // Use the main WorkerDashboardView from Views/Main/
        WorkerDashboardView()
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
                
                Text("Admin features coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Switch to Worker View") {
                    // Force switch to worker view for testing
                    authManager.userRole = "worker"
                }
                .buttonStyle(.borderedProminent)
                
                Button("Logout") {
                    authManager.logout()
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
            .navigationTitle("FrancoSphere Admin")
        }
    }
}

// MARK: - Main Tab View (Alternative Navigation)
struct MainTabView: View {
    @StateObject private var authManager = NewAuthManager.shared
    
    var body: some View {
        TabView {
            WorkerDashboardViewWrapper()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
            
            BuildingsListPlaceholder()
                .tabItem {
                    Label("Buildings", systemImage: "building.2")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .accentColor(Color(red: 0.34, green: 0.34, blue: 0.8))
    }
}

// MARK: - Placeholder for BuildingsView
struct BuildingsListPlaceholder: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Buildings List")
                    .font(.largeTitle)
                Text("Coming Soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Buildings")
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
