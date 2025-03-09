import SwiftUI

@main
struct FrancoSphereApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                AppCoordinator()
                    .environmentObject(authManager)
            }
        }
    }
}

struct AppCoordinator: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Use userRole string value to determine which view to show
                if authManager.userRole == "admin" {
                    AdminDashboardView()
                } else if authManager.userRole == "client" {
                    ClientDashboardView()
                } else {
                    // Use the full WorkerDashboardView instead of the placeholder
                    NavigationView {
                        WorkerDashboardView()
                    }
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Initialize the database structure without test data
            if UserDefaults.standard.bool(forKey: "isFirstLaunch") == false {
                SQLiteManager.shared.ensureDatabaseStructure()
                UserDefaults.standard.set(true, forKey: "isFirstLaunch")
            }
        }
    }
}

struct ClientDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Client Dashboard")
                    .font(.largeTitle)
                    .padding()
                
                Text("Welcome, \(authManager.currentWorkerName)")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Button("Logout") {
                    authManager.logout()
                }
                .padding()
            }
            .navigationTitle("FrancoSphere Client")
        }
    }
}

// This view is no longer needed since we're using the full WorkerDashboardView
// If you need a placeholder for testing, you can keep it with a different name
struct AppWorkerDashboardViewPlaceholder: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Worker Dashboard")
                    .font(.largeTitle)
                    .padding()
                
                Text("Welcome, \(authManager.currentWorkerName)")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Button("Logout") {
                    authManager.logout()
                }
                .padding()
            }
            .navigationTitle("FrancoSphere Worker")
        }
    }
}
