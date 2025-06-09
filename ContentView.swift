import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = NewAuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Direct to appropriate dashboard based on role
                switch authManager.userRole {
                case "admin", "client":
                    AdminDashboardView()
                case "worker":
                    WorkerDashboardView()
                default:
                    // Fallback to worker dashboard
                    WorkerDashboardView()
                }
            } else {
                // Not authenticated, show login
                LoginView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct MainTabView: View {
    @StateObject private var authManager = NewAuthManager.shared
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
            
            BuildingsView()
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
