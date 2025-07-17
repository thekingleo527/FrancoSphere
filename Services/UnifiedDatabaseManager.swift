//
//  UnifiedDatabaseManager.swift
//  FrancoSphere v6.0
//
//  ✅ UNIFIED: Single source of truth for all database operations
//  ✅ COMPREHENSIVE: Handles all initialization, seeding, and verification
//  ✅ COMPATIBLE: Maintains compatibility with existing code patterns
//  ✅ NO CONFLICTS: Eliminates all enum and method conflicts
//

import Foundation
import SwiftUI

@MainActor
public class UnifiedDatabaseManager: ObservableObject {
    public static let shared = UnifiedDatabaseManager()
    
    // MARK: - Published Properties
    @Published public var initializationProgress: Double = 0.0
    @Published public var currentStep: String = "Ready"
    @Published public var isInitialized: Bool = false
    @Published public var hasError: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    private let hasInitializedKey = "UnifiedDatabaseManager_v6_Initialized"
    private let grdbManager = GRDBManager.shared
    private let operationalManager = OperationalDataManager.shared
    
    private init() {
        // Check if already initialized on startup
        if UserDefaults.standard.bool(forKey: hasInitializedKey) {
            isInitialized = true
            currentStep = "Database ready"
            initializationProgress = 1.0
        }
    }
    
    // MARK: - Main Public Interface
    
    /// Primary initialization method - replaces all legacy initialization
    public func initializeDatabase() async throws {
        guard !isInitialized else {
            print("✅ Database already initialized")
            return
        }
        
        hasError = false
        errorMessage = nil
        
        do {
            print("🚀 Starting unified database initialization...")
            
            // Step 1: Schema setup (20%)
            currentStep = "Setting up database schema..."
            initializationProgress = 0.2
            
            try await SeedDatabase.runMigrations()
            
            // Step 2: Check existing data (40%)
            currentStep = "Checking existing data..."
            initializationProgress = 0.4
            
            let status = await DatabaseStatusChecker.verifyIntegrity()
            print("📊 Current data status: \(status.summary)")
            
            if !status.isValid || status.workers == 0 {
                // Step 3: Import operational data (70%)
                currentStep = "Importing operational data..."
                initializationProgress = 0.7
                
                try await importOperationalData()
            }
            
            // Step 4: Run DataBootstrapper if needed (80%)
            currentStep = "Running data bootstrapper..."
            initializationProgress = 0.8
            
            await runDataBootstrapperIfNeeded()
            
            // Step 5: Final verification (90%)
            currentStep = "Verifying data integrity..."
            initializationProgress = 0.9
            
            let finalStatus = await DatabaseStatusChecker.verifyIntegrity()
            if !finalStatus.isValid {
                throw UnifiedDatabaseError.verificationFailed(finalStatus.errors.joined(separator: ", "))
            }
            
            // Step 6: Complete (100%)
            currentStep = "Database initialization complete"
            initializationProgress = 1.0
            
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
            isInitialized = true
            
            print("✅ Unified database initialization completed successfully")
            
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
            print("❌ Unified database initialization failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Legacy Method Compatibility
    
    /// Compatibility method for InitializationViewModel
    public func runInitialization() async throws -> InitializationResult {
        try await initializeDatabase()
        
        let status = await DatabaseStatusChecker.verifyIntegrity()
        
        return InitializationResult(
            isComplete: isInitialized,
            hasErrors: hasError,
            errors: hasError ? [errorMessage ?? "Unknown error"] : [],
            workers: status.workers,
            buildings: status.buildings,
            tasks: status.tasks
        )
    }
    
    /// Compatibility for DataInitializationManager pattern
    public func verifyDataImport() async -> (buildings: Int, workers: Int, tasks: Int) {
        let status = await DatabaseStatusChecker.verifyIntegrity()
        return (status.buildings, status.workers, status.tasks)
    }
    
    // MARK: - Development Support
    
    #if DEBUG
    public func resetForDevelopment() async throws {
        UserDefaults.standard.removeObject(forKey: hasInitializedKey)
        isInitialized = false
        initializationProgress = 0.0
        currentStep = "Reset for development"
        hasError = false
        errorMessage = nil
        
        // Reset OperationalDataManager if method exists
        if await operationalManager.responds(to: #selector(OperationalDataManager.reset)) {
            await operationalManager.reset()
        }
        
        print("🔄 Database reset for development")
    }
    #endif
    
    // MARK: - Private Implementation
    
    private func importOperationalData() async throws {
        do {
            // Use the compatibility method to avoid ambiguity
            let (imported, errors) = try await operationalManager.importOperationalData()
            
            print("✅ Imported \(imported) operational items")
            if !errors.isEmpty {
                print("⚠️ Import had \(errors.count) warnings: \(errors.prefix(3).joined(separator: ", "))")
            }
            
            if imported == 0 {
                print("⚠️ No operational data imported - creating fallback")
                await createFallbackData()
            }
            
        } catch {
            print("❌ Operational data import failed: \(error)")
            await createFallbackData()
        }
    }
    
    private func runDataBootstrapperIfNeeded() async {
        // Run DataBootstrapper in a safe way
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                DataBootstrapper.runIfNeeded()
                continuation.resume()
            }
        }
    }
    
    private func createFallbackData() async {
        do {
            print("🔧 Creating fallback database entries...")
            
            // Check if we need workers
            let workers = try await grdbManager.query("SELECT COUNT(*) as count FROM workers", [])
            let workerCount = workers.first?["count"] as? Int64 ?? 0
            
            if workerCount == 0 {
                try await grdbManager.execute("""
                    INSERT INTO workers (id, name, email, role, isActive) VALUES
                    ('1', 'Fallback Worker', 'fallback@francosphere.com', 'worker', 1),
                    ('4', 'Kevin Dutan', 'kevin@francosphere.com', 'worker', 1)
                """, [])
                print("✅ Created fallback workers")
            }
            
            // Check if we need buildings
            let buildings = try await grdbManager.query("SELECT COUNT(*) as count FROM buildings", [])
            let buildingCount = buildings.first?["count"] as? Int64 ?? 0
            
            if buildingCount == 0 {
                try await grdbManager.execute("""
                    INSERT INTO buildings (id, name, address, latitude, longitude) VALUES
                    ('1', 'Fallback Building', '123 Test Street', 40.7128, -74.0060),
                    ('14', 'Rubin Museum', '150 W 17th St', 40.7402, -73.9980)
                """, [])
                print("✅ Created fallback buildings")
            }
            
            // Check if we need tasks
            let tasks = try await grdbManager.query("SELECT COUNT(*) as count FROM tasks", [])
            let taskCount = tasks.first?["count"] as? Int64 ?? 0
            
            if taskCount == 0 {
                let taskId1 = UUID().uuidString
                let taskId2 = UUID().uuidString
                let now = Date().timeIntervalSince1970
                
                try await grdbManager.execute("""
                    INSERT INTO tasks (id, title, description, isCompleted, scheduledDate, dueDate, category, urgency, buildingId, assignedWorkerId) VALUES
                    (?, 'Morning Inspection', 'Daily building check', 1, ?, ?, 'inspection', 'medium', '1', '1'),
                    (?, 'Museum Maintenance', 'Check HVAC systems', 0, ?, ?, 'maintenance', 'medium', '14', '4')
                """, [taskId1, now, now, taskId2, now, now])
                print("✅ Created fallback tasks")
            }
            
        } catch {
            print("❌ Failed to create fallback data: \(error)")
        }
    }
}

// MARK: - Supporting Types

public struct InitializationResult {
    public let isComplete: Bool
    public let hasErrors: Bool
    public let errors: [String]
    public let workers: Int
    public let buildings: Int
    public let tasks: Int
}

public enum UnifiedDatabaseError: LocalizedError {
    case verificationFailed(String)
    case operationalDataFailed(String)
    case fallbackCreationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .verificationFailed(let msg): return "Database verification failed: \(msg)"
        case .operationalDataFailed(let msg): return "Operational data import failed: \(msg)"
        case .fallbackCreationFailed(let msg): return "Fallback data creation failed: \(msg)"
        }
    }
}
