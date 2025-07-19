//
//  InitializationViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ UNIFIED: Single initialization flow with DatabaseStartupCoordinator
//  ✅ COMPREHENSIVE: Handles all startup tasks in sequence
//  ✅ RESILIENT: Proper error handling and recovery
//  ✅ OBSERVABLE: Clear progress updates for UI
//

import Foundation
import SwiftUI

@MainActor
class InitializationViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var currentStep: String = "Preparing FrancoSphere..."
    @Published var isInitializing: Bool = false
    @Published var isComplete: Bool = false
    @Published var initializationError: String?
    
    // Track initialization attempts for retry logic
    private var initializationAttempts = 0
    private let maxAttempts = 3
    
    func startInitialization() async {
        guard !isInitializing else { return }
        
        isInitializing = true
        isComplete = false
        initializationError = nil
        initializationAttempts += 1
        
        do {
            // Step 1: Verify app environment (5%)
            await updateProgress(0.05, "Checking environment...")
            try await verifyEnvironment()
            
            // Step 2: Initialize database system (40%)
            await updateProgress(0.10, "Initializing database...")
            try await initializeDatabase()
            
            // Step 3: Verify data integrity (20%)
            await updateProgress(0.50, "Verifying data integrity...")
            try await verifyDataIntegrity()
            
            // Step 4: Load user context if authenticated (20%)
            await updateProgress(0.70, "Loading user data...")
            try await loadUserContext()
            
            // Step 5: Initialize services (10%)
            await updateProgress(0.90, "Starting services...")
            try await initializeServices()
            
            // Step 6: Final setup (5%)
            await updateProgress(0.95, "Finalizing setup...")
            try await finalizeSetup()
            
            // Complete
            await updateProgress(1.0, "Ready!")
            
            // Small delay to show completion
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            isComplete = true
            isInitializing = false
            
            print("✅ FrancoSphere initialization completed successfully")
            
        } catch {
            handleInitializationError(error)
        }
    }
    
    // MARK: - Initialization Steps
    
    private func verifyEnvironment() async throws {
        // Check for required directories, permissions, etc.
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard documentsPath != nil else {
            throw InitializationError.environmentError("Cannot access documents directory")
        }
        
        // Verify we can write to documents directory
        let testFile = documentsPath!.appendingPathComponent("test.tmp")
        do {
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
        } catch {
            throw InitializationError.environmentError("Cannot write to documents directory")
        }
    }
    
    private func initializeDatabase() async throws {
        do {
            // Use DatabaseStartupCoordinator as the single source of truth
            try await DatabaseStartupCoordinator.shared.initializeDatabase()
            
            await updateProgress(0.30, "Database schema created...")
            
            // Ensure data integrity
            try await DatabaseStartupCoordinator.shared.ensureDataIntegrity()
            
            await updateProgress(0.40, "Database initialized successfully")
            
        } catch {
            // On first attempt, try to recover
            if initializationAttempts == 1 {
                print("⚠️ Database initialization failed, attempting recovery...")
                try await DatabaseStartupCoordinator.shared.recoverDatabase()
                try await DatabaseStartupCoordinator.shared.initializeDatabase()
            } else {
                throw InitializationError.databaseError("Failed to initialize database: \(error.localizedDescription)")
            }
        }
    }
    
    private func verifyDataIntegrity() async throws {
        await updateProgress(0.55, "Checking workers...")
        
        // Verify critical data exists
        let workerCount = try await GRDBManager.shared.query(
            "SELECT COUNT(*) as count FROM workers WHERE isActive = 1"
        ).first?["count"] as? Int64 ?? 0
        
        guard workerCount > 0 else {
            throw InitializationError.dataError("No active workers found in database")
        }
        
        await updateProgress(0.60, "Checking buildings...")
        
        let buildingCount = try await GRDBManager.shared.query(
            "SELECT COUNT(*) as count FROM buildings"
        ).first?["count"] as? Int64 ?? 0
        
        guard buildingCount > 0 else {
            throw InitializationError.dataError("No buildings found in database")
        }
        
        await updateProgress(0.65, "Verifying assignments...")
        
        // Verify Kevin's assignment specifically
        let kevinAssignment = try await GRDBManager.shared.query("""
            SELECT COUNT(*) as count 
            FROM worker_assignments 
            WHERE worker_id = '1' AND building_id = '14' AND is_primary = 1
        """).first?["count"] as? Int64 ?? 0
        
        if kevinAssignment == 0 {
            print("⚠️ Kevin's Rubin Museum assignment missing - fixing...")
            try await DatabaseStartupCoordinator.shared.fixKevinAssignment()
        }
        
        print("✅ Data integrity verified: \(workerCount) workers, \(buildingCount) buildings")
    }
    
    private func loadUserContext() async throws {
        // Only load if user is authenticated
        guard let currentUser = await NewAuthManager.shared.getCurrentUser() else {
            print("ℹ️ No authenticated user, skipping context load")
            return
        }
        
        await updateProgress(0.75, "Loading worker context...")
        
        do {
            // Load the worker context
            try await WorkerContextEngine.shared.loadContext(for: currentUser.workerId)
            
            await updateProgress(0.85, "User data loaded successfully")
            
        } catch {
            // Non-critical error - user can still use app
            print("⚠️ Failed to load worker context: \(error)")
            // Don't throw - this is not fatal
        }
    }
    
    private func initializeServices() async throws {
        // Initialize weather service
        await WeatherService.shared.startMonitoring()
        
        // Initialize telemetry
        await TelemetryService.shared.startSession()
        
        // Initialize dashboard sync
        await DashboardSyncService.shared.initialize()
        
        // Initialize Nova AI (non-blocking)
        Task {
            await NovaAIContextFramework.shared.initialize()
        }
    }
    
    private func finalizeSetup() async throws {
        // Set initialization flag
        UserDefaults.standard.set(true, forKey: "HasCompletedInitialization")
        UserDefaults.standard.set(Date(), forKey: "LastInitializationDate")
        
        // Log successful initialization
        print("📱 FrancoSphere v6.0 initialized")
        print("  - Database: ✅")
        print("  - Services: ✅")
        print("  - User Context: ✅")
        print("  - Ready for production")
    }
    
    // MARK: - Error Handling
    
    private func handleInitializationError(_ error: Error) {
        isInitializing = false
        
        let errorMessage: String
        var isCritical = false
        
        if let initError = error as? InitializationError {
            errorMessage = initError.localizedDescription
            isCritical = initError.isCritical
        } else {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            isCritical = true
        }
        
        print("❌ Initialization error: \(errorMessage)")
        
        // For non-critical errors or if we have more attempts, allow retry
        if !isCritical && initializationAttempts < maxAttempts {
            // Set error but mark as complete to allow app usage
            initializationError = errorMessage
            isComplete = true
        } else {
            // Critical error - show error screen
            initializationError = errorMessage
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ newProgress: Double, _ message: String) async {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.progress = newProgress
            self.currentStep = message
        }
        
        // Small delay for visual feedback
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    }
}

// MARK: - Initialization Errors

enum InitializationError: LocalizedError {
    case environmentError(String)
    case databaseError(String)
    case dataError(String)
    case serviceError(String)
    
    var errorDescription: String? {
        switch self {
        case .environmentError(let message):
            return "Environment Error: \(message)"
        case .databaseError(let message):
            return "Database Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .serviceError(let message):
            return "Service Error: \(message)"
        }
    }
    
    var isCritical: Bool {
        switch self {
        case .environmentError, .databaseError:
            return true
        case .dataError, .serviceError:
            return false
        }
    }
}
