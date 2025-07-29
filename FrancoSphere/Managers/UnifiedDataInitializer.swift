//
//  UnifiedDataInitializer.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Thin wrapper around DatabaseStartupCoordinator
//  ✅ UI-FOCUSED: Provides progress tracking for SwiftUI
//  ✅ SIMPLIFIED: Delegates all database work to coordinator
//

import Foundation
import SwiftUI

@MainActor
public class UnifiedDataInitializer: ObservableObject {
    public static let shared = UnifiedDataInitializer()
    
    // UI State
    @Published public var isInitialized = false
    @Published public var initializationProgress: Double = 0.0
    @Published public var currentStep = "Preparing..."
    @Published public var error: Error?
    
    // Coordinator
    private let databaseCoordinator = DatabaseStartupCoordinator.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Initialize the app if needed (called from App launch)
    public func initializeIfNeeded() async throws {
        guard !isInitialized else {
            print("✅ App already initialized")
            return
        }
        
        error = nil
        
        do {
            // Step 1: Database Initialization (0-60%)
            currentStep = "Initializing database..."
            initializationProgress = 0.1
            
            // Let DatabaseStartupCoordinator handle ALL database setup
            try await databaseCoordinator.initializeDatabase()
            
            initializationProgress = 0.6
            
            // Step 2: Import Additional Data (60-80%)
            currentStep = "Importing operational data..."
            initializationProgress = 0.7
            
            // Import any additional operational data not in seed
            if await shouldImportOperationalData() {
                let (imported, errors) = try await OperationalDataManager.shared.importRoutinesAndDSNY()
                print("✅ Imported \(imported) additional tasks, \(errors.count) errors")
            }
            
            initializationProgress = 0.8
            
            // Step 3: Verify Health (80-90%)
            currentStep = "Verifying system health..."
            initializationProgress = 0.85
            
            let healthCheck = await databaseCoordinator.performHealthCheck()
            guard healthCheck.isHealthy else {
                throw InitializationError.healthCheckFailed(healthCheck.message)
            }
            
            initializationProgress = 0.9
            
            // Step 4: Start Background Services (90-100%)
            currentStep = "Starting services..."
            initializationProgress = 0.95
            
            await startBackgroundServices()
            
            // Complete
            currentStep = "Ready"
            initializationProgress = 1.0
            isInitialized = true
            
            print("✅ UnifiedDataInitializer: App initialization complete")
            
        } catch {
            self.error = error
            currentStep = "Initialization failed"
            print("❌ UnifiedDataInitializer: \(error)")
            throw error
        }
    }
    
    /// Get current database statistics
    public func getDatabaseStatistics() async throws -> [String: Any] {
        return try await databaseCoordinator.getDatabaseStatistics()
    }
    
    /// Check if the system is healthy
    public func isSystemHealthy() async -> Bool {
        let health = await databaseCoordinator.performHealthCheck()
        return health.isHealthy
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    /// Reset and reinitialize for testing
    public func resetAndReinitialize() async throws {
        print("⚠️ UnifiedDataInitializer: Resetting app...")
        
        isInitialized = false
        initializationProgress = 0.0
        currentStep = "Resetting..."
        error = nil
        
        // Reset database through coordinator
        try await databaseCoordinator.resetAndReinitialize()
        
        // Reset operational data manager
        await OperationalDataManager.shared.reset()
        
        // Reinitialize
        try await initializeIfNeeded()
    }
    
    /// Force reimport operational data
    public func forceReimportOperationalData() async throws {
        currentStep = "Reimporting data..."
        let (imported, errors) = try await OperationalDataManager.shared.importRoutinesAndDSNY()
        print("✅ Force reimported \(imported) tasks, \(errors.count) errors")
    }
    #endif
    
    // MARK: - Private Methods
    
    /// Check if we need to import additional operational data
    private func shouldImportOperationalData() async -> Bool {
        do {
            // Check if we already have DSNY tasks
            let tasks = try await TaskService.shared.getAllTasks()
            let dsnyTasks = tasks.filter { $0.category == "dsny" }
            
            // If we have fewer than expected DSNY tasks, import
            return dsnyTasks.count < 50  // Adjust threshold as needed
        } catch {
            // If we can't check, assume we need to import
            return true
        }
    }
    
    /// Start background services after initialization
    private func startBackgroundServices() async {
        // Start any background services that need initialization
        
        // Example: Start metrics calculation
        Task {
            try? await BuildingMetricsService.shared.updateMetricsCache()
        }
        
        // Example: Start notification scheduling
        Task {
            await NotificationManager.shared.scheduleTaskReminders()
        }
        
        // Example: Start weather updates
        Task {
            try? await WeatherDataAdapter.shared.updateWeatherForAllBuildings()
        }
    }
}

// MARK: - Error Types

public enum InitializationError: LocalizedError {
    case healthCheckFailed(String)
    case dataImportFailed(String)
    case serviceStartupFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .healthCheckFailed(let message):
            return "System health check failed: \(message)"
        case .dataImportFailed(let message):
            return "Data import failed: \(message)"
        case .serviceStartupFailed(let message):
            return "Service startup failed: \(message)"
        }
    }
}

// MARK: - SwiftUI View for Initialization

public struct InitializationView: View {
    @ObservedObject private var initializer = UnifiedDataInitializer.shared
    
    public var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            Image("FrancoSphereLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            
            Text("FrancoSphere")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Progress
            VStack(spacing: 15) {
                Text(initializer.currentStep)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ProgressView(value: initializer.initializationProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 250)
                
                Text("\(Int(initializer.initializationProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            
            // Error display
            if let error = initializer.error {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text("Initialization Failed")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    #if DEBUG
                    Button("Retry") {
                        Task {
                            try? await initializer.resetAndReinitialize()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    #endif
                }
                .padding(.top)
            }
            
            Spacer()
        }
        .padding()
        .task {
            do {
                try await initializer.initializeIfNeeded()
            } catch {
                print("Initialization failed: \(error)")
            }
        }
    }
}

// MARK: - Preview

struct InitializationView_Previews: PreviewProvider {
    static var previews: some View {
        InitializationView()
    }
}
