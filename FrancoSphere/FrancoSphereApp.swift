import SwiftUI

@main
struct FrancoSphereApp: App {
    var body: some Scene {
        WindowGroup {
            AppCoordinator()
        }
    }
}

struct AppCoordinator: View {
    // ✅ Now using NewAuthManager instead of local state
    @StateObject private var authManager = NewAuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Route based on user role from NewAuthManager
                if authManager.userRole == "admin" {
                    NavigationView {
                        // Use the existing AdminDashboardView from elsewhere in the project
                        AdminDashboardView()
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Logout") {
                                        authManager.logout()
                                    }
                                }
                            }
                    }
                } else if authManager.userRole == "client" {
                    ClientDashboardView()
                } else {
                    // Worker dashboard - using the real one
                    WorkerDashboardView()
                }
            } else {
                // ✅ Using LoginView from Views/Auth/LoginView.swift (NOT defined here)
                LoginView()
            }
        }
        .onAppear {
            print("🚀 FrancoSphere App Started")
            print("📱 Initial state: isAuthenticated = \(authManager.isAuthenticated)")
            print("👤 User role: \(authManager.userRole)")
            print("👷 Worker name: \(authManager.currentWorkerName)")
        }
        // FIXED: Updated onChange syntax for iOS 17+
        .onChange(of: authManager.isAuthenticated) {
            print("🔐 Authentication changed to: \(authManager.isAuthenticated)")
        }
        .onChange(of: authManager.userRole) {
            print("👤 User role changed to: \(authManager.userRole)")
        }
    }
}

// MARK: - Client Dashboard View
struct ClientDashboardView: View {
    @StateObject private var authManager = NewAuthManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("FrancoSphere")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Client Portal")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Welcome message
                VStack(spacing: 10) {
                    Text("Welcome, \(authManager.currentWorkerName)")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Client Dashboard")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Client features section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Available Features:")
                        .font(.headline)
                    
                    FeatureRow(icon: "building.columns", title: "Property Overview", description: "View all managed properties")
                    FeatureRow(icon: "chart.bar", title: "Reports & Analytics", description: "Access maintenance reports")
                    FeatureRow(icon: "envelope", title: "Communications", description: "Message with property teams")
                    FeatureRow(icon: "calendar", title: "Scheduled Maintenance", description: "View upcoming work")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                // Logout button
                Button(action: {
                    authManager.logout()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Logout")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Client Portal")
            .navigationBarHidden(true)
        }
    }
}

// Helper view for client features
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}

// REMOVED: AdminDashboardView - using the one defined elsewhere in the project

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 2)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            Text("FrancoSphere")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Initializing...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview
struct FrancoSphereApp_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
            .previewDisplayName("Loading Screen")
        
        AppCoordinator()
            .previewDisplayName("App Coordinator")
        
        ClientDashboardView()
            .previewDisplayName("Client Dashboard")
    }
}
