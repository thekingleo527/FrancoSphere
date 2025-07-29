//
//  UnifiedDataInitializer.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Thin wrapper around DatabaseStartupCoordinator
//  ✅ UI-FOCUSED: Provides progress tracking for SwiftUI
//  ✅ SIMPLIFIED: Delegates all database work to coordinator
//  ✅ FIXED: All compilation errors resolved
//

import Foundation
import SwiftUI
import Combine

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
                do {
                    // FIXED: Use the public async wrapper method
                    let result = try await OperationalDataManager.shared.importRoutinesAndDSNYAsync()
                    print("✅ Imported \(result.routines) routines and \(result.dsny) DSNY schedules")
                } catch {
                    print("⚠️ OperationalDataManager import skipped: \(error)")
                    // Not critical - continue with initialization
                }
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
        
        // Reinitialize
        try await initializeIfNeeded()
    }
    
    /// Force reimport operational data
    public func forceReimportOperationalData() async throws {
        currentStep = "Reimporting data..."
        
        do {
            // FIXED: Use the public async wrapper method
            let result = try await OperationalDataManager.shared.importRoutinesAndDSNYAsync()
            print("✅ Force reimported \(result.routines) routines and \(result.dsny) DSNY schedules")
        } catch {
            print("⚠️ Force reimport failed: \(error)")
            throw error
        }
    }
    #endif
    
    // MARK: - Private Methods
    
    /// Check if we need to import additional operational data
    private func shouldImportOperationalData() async -> Bool {
        do {
            // Check if we already have tasks
            let tasks = try await TaskService.shared.getAllTasks()
            
            // If we have fewer than expected tasks, import
            return tasks.count < 50  // Adjust threshold as needed
        } catch {
            // If we can't check, assume we need to import
            return true
        }
    }
    
    /// Start background services after initialization
    private func startBackgroundServices() async {
        // Start any background services that need initialization
        
        // Example: Invalidate metrics cache to trigger fresh calculations
        Task {
            await BuildingMetricsService.shared.invalidateAllCaches()
        }
        
        // Additional background services can be added here
        // For example: weather updates, notification scheduling, etc.
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

// MARK: - Simple Progress View (Optional)

/// A simple progress view that can be used if your app doesn't have a custom InitializationView
public struct SimpleInitializationProgressView: View {
    @ObservedObject private var initializer = UnifiedDataInitializer.shared
    
    public var body: some View {
        VStack(spacing: 20) {
            Text(initializer.currentStep)
                .font(.headline)
                .foregroundColor(.secondary)
            
            ProgressView(value: initializer.initializationProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 250)
            
            Text("\(Int(initializer.initializationProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let error = initializer.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
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

// MARK: - Dependencies
//
// This initializer depends on:
// 1. DatabaseStartupCoordinator - Handles all database setup
// 2. OperationalDataManager.importRoutinesAndDSNYAsync() - For importing additional data
// 3. TaskService.getAllTasks() - For checking existing data
// 4. BuildingMetricsService.invalidateAllCaches() - For refreshing metrics
// 5. BuildingService.getAllBuildings() - Optional, for fetching building data
//
// If any of these are missing, the initializer will still work but may skip some steps.

// MARK: - Usage Example
//
// To use UnifiedDataInitializer in your app:
//
// @main
// struct FrancoSphereApp: App {
//     @StateObject private var initializer = UnifiedDataInitializer.shared
//
//     var body: some Scene {
//         WindowGroup {
//             if initializer.isInitialized {
//                 ContentView()
//             } else {
//                 InitializationView() // Use the existing InitializationView from the app
//                 // Or use SimpleInitializationProgressView() if you don't have a custom view
//             }
//         }
//     }
// }
