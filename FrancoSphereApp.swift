//
//  FrancoSphereApp.swift
//  FrancoSphere
//
//  Safe version that gradually enables real dashboards as compilation issues are fixed
//

import SwiftUI

@main
struct FrancoSphereApp: App {
    @StateObject private var authManager = NewAuthManager.shared
    
    init() {
        print("🚀 FrancoSphere App Started")
        print("📱 Initial state: isAuthenticated = \(NewAuthManager.shared.isAuthenticated)")
        print("👤 User role: \(NewAuthManager.shared.userRole)")
        print("👷 Worker name: \(NewAuthManager.shared.currentWorkerName)")
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                Group {
                    if authManager.isAuthenticated {
                        // Show dashboard based on role
                        switch authManager.userRole {
                        case "admin":
                            // Admin dashboard has compilation issues, use fallback
                            FallbackDashboard(title: "Admin Dashboard", role: "Administrator")
                        case "client":
                            FallbackDashboard(title: "Client Dashboard", role: "Client")
                        default: // worker
                            // Try to use the real dashboard, fallback if needed
                            WorkerDashboardContainer()
                        }
                    } else {
                        // Show login
                        LoginView()
                            .navigationBarHidden(true)
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(authManager)
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Worker Dashboard Container (with error handling)
struct WorkerDashboardContainer: View {
    @EnvironmentObject var authManager: NewAuthManager
    @State private var showFallback = false
    
    var body: some View {
        Group {
            if showFallback {
                FallbackDashboard(title: "Worker Dashboard", role: "Worker")
            } else {
                // Try to load the real dashboard
                SafeDashboardLoader()
                    .onAppear {
                        // If there are issues loading the real dashboard, show fallback
                        checkDashboardAvailability()
                    }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func checkDashboardAvailability() {
        // For now, let's try the fallback first to ensure login works
        // Once we fix compilation issues, we can enable the real dashboard
        showFallback = true
    }
}

// MARK: - Safe Dashboard Loader
struct SafeDashboardLoader: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Loading Dashboard...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Fallback Dashboard (Enhanced version)
struct FallbackDashboard: View {
    let title: String
    let role: String
    @EnvironmentObject var authManager: NewAuthManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.25),
                        Color(red: 0.15, green: 0.2, blue: 0.35)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: iconForRole(role))
                                .font(.system(size: 60))
                                .foregroundColor(colorForRole(role))
                            
                            Text("FrancoSphere")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(title)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 50)
                        
                        // User info card
                        VStack(spacing: 15) {
                            Text("Welcome")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(authManager.currentWorkerName)
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("ID")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(authManager.workerId)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                
                                Divider()
                                    .frame(height: 30)
                                    .background(Color.white.opacity(0.3))
                                
                                VStack {
                                    Text("Role")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(role)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        
                        // Status card
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("✅ Login Successful")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            
                            Text("Dashboard is currently in fallback mode while compilation issues are resolved")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        
                        Spacer(minLength: 50)
                        
                        // Logout button
                        Button(action: {
                            authManager.logout()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.square")
                                Text("Logout")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func iconForRole(_ role: String) -> String {
        switch role {
        case "Administrator": return "person.3.fill"
        case "Client": return "building.2.fill"
        default: return "hammer.fill"
        }
    }
    
    private func colorForRole(_ role: String) -> Color {
        switch role {
        case "Administrator": return .orange
        case "Client": return .blue
        default: return .green
        }
    }
}
