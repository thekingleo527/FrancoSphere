//
//  FrancoSphereApp.swift (FIXED PRODUCTION VERSION)
//  FrancoSphere
//
//  ✅ FIXED: SchemaMigrationPatch.applyPatch() instance method error
//  ✅ FIXED: AdminDashboardPlaceholder redeclaration (uses existing AdminDashboardView)
//  ✅ FIXED: Proper async context for schema migration
//  ✅ READY: For immediate compilation without errors
//

import SwiftUI

@main
struct FrancoSphereApp: App {
    @StateObject private var authManager = NewAuthManager.shared
    @State private var hasInitialized = false
    @State private var initializationError: String?
    
    init() {
        print("🚀 FrancoSphere App Started")
        print("📱 Initial state: isAuthenticated = \(NewAuthManager.shared.isAuthenticated)")
        print("👤 User role: \(NewAuthManager.shared.userRole)")
        print("👷 Worker name: \(NewAuthManager.shared.currentWorkerName)")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasInitialized {
                    // Show initialization screen while setting up
                    InitializationView(
                        hasInitialized: $hasInitialized,
                        initializationError: $initializationError
                    )
                } else if authManager.isAuthenticated {
                    // Show dashboard based on role
                    switch authManager.userRole {
                    case "admin":
                        // ✅ FIXED: Use existing AdminDashboardView instead of creating new AdminDashboardPlaceholder
                        AdminDashboardView()
                            .environmentObject(authManager)
                    case "client":
                        FallbackDashboard(title: "Client Dashboard", role: "Client")
                            .environmentObject(authManager)
                    default: // worker
                        // Load the production WorkerDashboardView
                        WorkerDashboardView()
                            .environmentObject(authManager)
                    }
                } else {
                    // Show login
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Initialization View with Fixed Schema Migration
struct InitializationView: View {
    @Binding var hasInitialized: Bool
    @Binding var initializationError: String?
    
    @State private var currentStep = "Starting FrancoSphere..."
    @State private var progress: Double = 0.0
    
    var body: some View {
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
            
            VStack(spacing: 30) {
                // Logo/Brand
                VStack(spacing: 15) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("FrancoSphere")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Property Operations Management")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Initialization progress
                VStack(spacing: 20) {
                    // Progress bar
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 4)
                        
                        Text(currentStep)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Spinner
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                }
                .frame(maxWidth: 300)
                
                if let error = initializationError {
                    // Error state
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Initialization Issue")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        Button("Continue Anyway") {
                            hasInitialized = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .onAppear {
            performInitialization()
        }
    }
    
    private func performInitialization() {
        Task {
            await runInitializationSequence()
        }
    }
    
    private func runInitializationSequence() async {
        let steps = [
            ("Checking database connection...", 0.2),
            ("Applying schema migration...", 0.4),
            ("Loading worker data...", 0.6),
            ("Importing building assignments...", 0.8),
            ("Finalizing setup...", 1.0)
        ]
        
        for (stepName, stepProgress) in steps {
            await MainActor.run {
                currentStep = stepName
                progress = stepProgress
            }
            
            // Perform the actual initialization step
            await performInitializationStep(stepName)
            
            // Small delay for visual feedback
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        // Complete initialization
        await MainActor.run {
            hasInitialized = true
        }
    }
    
    private func performInitializationStep(_ stepName: String) async {
        switch stepName {
        case "Checking database connection...":
            // Ensure SQLiteManager is ready
            let _ = SQLiteManager.shared
            
        case "Applying schema migration...":
            // ✅ FIXED: Use singleton shared instance
            do {
                try await SchemaMigrationPatch.shared.applyPatch()
                print("✅ Schema migration completed successfully")
            } catch {
                print("⚠️ Schema migration warning: \(error)")
                await MainActor.run {
                    initializationError = "Schema migration had issues but continuing..."
                }
            }
            
        case "Loading worker data...":
            // Pre-load WorkerContextEngine if authenticated
            if NewAuthManager.shared.isAuthenticated {
                await WorkerContextEngine.shared.loadWorkerContext()
            }
            
        case "Importing building assignments...":
            // Ensure CSV data is imported if needed
            let importer = OperationalDataManager.shared
            await MainActor.run {
                importer.sqliteManager = SQLiteManager.shared
            }
            
            do {
                let (imported, errors) = try await importer.importRealWorldTasks()
                if imported > 0 {
                    print("✅ Imported \(imported) tasks during initialization")
                }
                if !errors.isEmpty {
                    print("⚠️ Import warnings: \(errors.count) issues")
                }
            } catch {
                print("⚠️ CSV import warning: \(error)")
                // Don't fail initialization for CSV import issues
            }
            
        case "Finalizing setup...":
            // Final validation
            if NewAuthManager.shared.isAuthenticated && NewAuthManager.shared.workerId == "4" {
                // Special validation for Kevin
                let buildingCount = WorkerContextEngine.shared.getAssignedBuildingsCount()
                if buildingCount == 0 {
                    print("⚠️ Kevin has no buildings assigned, but continuing...")
                    await MainActor.run {
                        initializationError = "Building assignments may need refresh"
                    }
                }
            }
            
        default:
            break
        }
    }
}

// MARK: - Enhanced Fallback Dashboard
struct FallbackDashboard: View {
    let title: String
    let role: String
    var error: String?
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
                        if let error = error {
                            VStack(spacing: 15) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("⚠️ Notice")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                                
                                Text(error)
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
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal)
                        }
                        
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
