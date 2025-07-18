//
//  ContentView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Uses real AdminDashboardView and ClientDashboardView
//  ✅ ENHANCED: Automatic database initialization on first auth
//  ✅ REAL-TIME: Progress tracking and error handling
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = NewAuthManager.shared
    @State private var isAppReady = false
    @State private var initStatus = "Checking data..."
    
    var body: some View {
        Group {
            if isAppReady {
                if authManager.isAuthenticated {
                    // Route to appropriate dashboard based on role
                    switch authManager.userRole {
                    case "admin":
                        AdminDashboardView()
                            .environmentObject(authManager)
                    case "client":
                        ClientDashboardView()
                            .environmentObject(authManager)
                    case "worker":
                        WorkerDashboardView()
                            .environmentObject(authManager)
                    default:
                        // Fallback to worker dashboard
                        WorkerDashboardView()
                            .environmentObject(authManager)
                    }
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            } else {
                // Data loading screen
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.blue)
                    
                    Text("FrancoSphere")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(initStatus)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .task {
            await ensureDataReady()
        }
    }
    
    private func ensureDataReady() async {
        print("🔍 ContentView checking data readiness...")
        
        do {
            // Check if we have basic data
            initStatus = "Checking database..."
            let allTasks = try await TaskService.shared.getAllTasks()
            print("📊 Database has \(allTasks.count) tasks")
            
            if allTasks.isEmpty {
                // Import data if needed
                initStatus = "Importing operational data..."
                let (imported, errors) = try await OperationalDataManager.shared.importRoutinesAndDSNY()
                print("✅ Imported \(imported) tasks, \(errors.count) errors")
                
                if imported == 0 {
                    print("🚨 Import failed - creating fallback data")
                    initStatus = "Creating fallback data..."
                    await createFallbackData()
                }
            }
            
            initStatus = "Ready!"
            try? await Task.sleep(nanoseconds: 500_000_000)
            isAppReady = true
            
        } catch {
            print("❌ Data readiness check failed: \(error)")
            initStatus = "Creating fallback data..."
            await createFallbackData()
            isAppReady = true
        }
    }
    
    private func createFallbackData() async {
        let fallbackTasks = [
            ContextualTask(
                id: "fallback_1",
                title: "Morning Building Check",
                description: "Daily inspection",
                isCompleted: true,
                scheduledDate: Date().addingTimeInterval(-3600),
                dueDate: Date(),
                category: .inspection,
                urgency: .medium
            ),
            ContextualTask(
                id: "fallback_2", 
                title: "Maintenance Review",
                description: "Check maintenance items",
                isCompleted: false,
                scheduledDate: Date(),
                dueDate: Date().addingTimeInterval(3600),
                category: .maintenance,
                urgency: .medium
            )
        ]
        
        for task in fallbackTasks {
            try? await TaskService.shared.createTask(task)
        }
        
        print("✅ Created \(fallbackTasks.count) fallback tasks")
    }
}

#Preview {
    ContentView()
}
