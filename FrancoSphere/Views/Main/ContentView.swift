//
//  ContentView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Uses real AdminDashboardView and ClientDashboardView
//  ✅ ENHANCED: Automatic database initialization on first auth
//  ✅ REAL-TIME: Progress tracking and error handling
//  ✅ ALIGNED: With updated CoreTypes and dashboard models
//  ✅ FIXED: Correct DashboardSyncService method call
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = NewAuthManager.shared
    @State private var isAppReady = false
    @State private var initStatus = "Checking data..."
    @State private var initProgress: Double = 0.0
    
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
                    case "manager":
                        // Managers get admin dashboard with focused features
                        AdminDashboardView()
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
                // Enhanced data loading screen
                VStack(spacing: 24) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    
                    VStack(spacing: 8) {
                        Text("FrancoSphere")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Building Management Excellence")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        ProgressView(value: initProgress)
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                            .tint(.blue)
                        
                        Text(initStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .animation(.easeInOut, value: initStatus)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.black, Color.blue.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .task {
            await initializeApp()
        }
    }
    
    private func initializeApp() async {
        print("🚀 FrancoSphere v6.0 Initializing...")
        
        do {
            // Step 1: Initialize database
            updateProgress(0.2, status: "Initializing database...")
            guard await GRDBManager.shared.isDatabaseReady() else {
                throw AppError.databaseNotReady
            }
            
            // Step 2: Seed initial data if needed
            updateProgress(0.4, status: "Checking worker data...")
            try await GRDBManager.shared.seedCompleteWorkerData()
            
            // Step 3: Check operational data
            updateProgress(0.6, status: "Loading operational data...")
            let hasData = await checkOperationalData()
            
            if !hasData {
                // Import operational data
                updateProgress(0.7, status: "Importing task schedules...")
                try await OperationalDataManager.shared.initializeOperationalData()
            }
            
            // Step 4: Initialize services
            updateProgress(0.8, status: "Starting services...")
            await initializeServices()
            
            // Step 5: Setup complete
            updateProgress(1.0, status: "Ready!")
            try? await Task.sleep(nanoseconds: 500_000_000) // Brief pause
            
            await MainActor.run {
                isAppReady = true
            }
            
        } catch {
            print("❌ Initialization failed: \(error)")
            await MainActor.run {
                initStatus = "Setup failed. Using demo mode."
            }
            await createDemoData()
            await MainActor.run {
                isAppReady = true
            }
        }
    }
    
    private func updateProgress(_ progress: Double, status: String) {
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.3)) {
                self.initProgress = progress
                self.initStatus = status
            }
        }
    }
    
    private func checkOperationalData() async -> Bool {
        do {
            let tasks = try await TaskService.shared.getAllTasks()
            let buildings = try await BuildingService.shared.getAllBuildings()
            let workers = try await WorkerService.shared.getAllActiveWorkers()
            
            print("📊 Data check: \(tasks.count) tasks, \(buildings.count) buildings, \(workers.count) workers")
            
            return !tasks.isEmpty && !buildings.isEmpty && !workers.isEmpty
        } catch {
            print("⚠️ Data check failed: \(error)")
            return false
        }
    }
    
    private func initializeServices() async {
        // Initialize real-time sync for operational data
        await OperationalDataManager.shared.setupRealTimeSync()
        
        // ✅ FIXED: Initialize and enable dashboard sync service
        await MainActor.run {
            DashboardSyncService.shared.initialize()
            DashboardSyncService.shared.enableCrossDashboardSync()
        }
        
        // Initialize intelligence service
        _ = IntelligenceService.shared
        
        print("✅ All services initialized")
    }
    
    private func createDemoData() async {
        // Create demo buildings
        let demoBuilding = NamedCoordinate(
            id: "demo_1",
            name: "Demo Building",
            latitude: 40.7484,
            longitude: -73.9857
        )
        
        // Create demo worker
        let demoWorker = WorkerProfile(
            id: "demo_1",
            name: "Demo Worker",
            email: "demo@franco.com",
            phoneNumber: "555-0123",
            role: .worker,
            skills: ["General Maintenance"],
            certifications: [],
            hireDate: Date(),
            isActive: true
        )
        
        // Create demo tasks with correct initializer
        let demoTasks = [
            ContextualTask(
                id: "demo_task_1",
                title: "Morning Inspection",
                description: "Daily building walkthrough",
                isCompleted: false,
                completedDate: nil,
                dueDate: Date().addingTimeInterval(3600),
                category: .inspection,
                urgency: .medium,
                building: demoBuilding,
                worker: demoWorker,
                buildingId: demoBuilding.id,
                priority: .medium
            ),
            ContextualTask(
                id: "demo_task_2",
                title: "Lobby Cleaning",
                description: "Clean and sanitize lobby area",
                isCompleted: false,
                completedDate: nil,
                dueDate: Date().addingTimeInterval(7200),
                category: .cleaning,
                urgency: .high,
                building: demoBuilding,
                worker: demoWorker,
                buildingId: demoBuilding.id,
                priority: .high
            ),
            ContextualTask(
                id: "demo_task_3",
                title: "HVAC Check",
                description: "Monthly HVAC system inspection",
                isCompleted: true,
                completedDate: Date().addingTimeInterval(-3600),
                dueDate: Date(),
                category: .maintenance,
                urgency: .low,
                building: demoBuilding,
                worker: demoWorker,
                buildingId: demoBuilding.id,
                priority: .low
            )
        ]
        
        // Save demo data
        for task in demoTasks {
            try? await TaskService.shared.createTask(task)
        }
        
        print("✅ Created \(demoTasks.count) demo tasks")
    }
}

// MARK: - App Errors

enum AppError: LocalizedError {
    case databaseNotReady
    case dataImportFailed
    case servicesInitFailed
    
    var errorDescription: String? {
        switch self {
        case .databaseNotReady:
            return "Database initialization failed"
        case .dataImportFailed:
            return "Failed to import operational data"
        case .servicesInitFailed:
            return "Service initialization failed"
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
