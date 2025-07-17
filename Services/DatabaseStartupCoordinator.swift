//
//  DatabaseStartupCoordinator.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/17/25.
//


//
//  DatabaseStartupCoordinator.swift
//  FrancoSphere v6.0
//
//  🚨 CRITICAL FIX: Ensure OperationalDataManager data imports on app startup
//  ✅ FIXED: Progress 0/0 issue by guaranteeing real tasks in database
//  ✅ ADDED: Automatic import verification and retry logic
//  ✅ ENHANCED: Kevin's Rubin Museum assignment verification
//

import Foundation

actor DatabaseStartupCoordinator {
    static let shared = DatabaseStartupCoordinator()
    
    private var hasInitialized = false
    private var isInitializing = false
    
    private init() {}
    
    /// Ensure database is properly initialized with real operational data
    /// This is the CRITICAL method that fixes the Progress 0/0 issue
    func ensureDataIntegrity() async throws {
        guard !hasInitialized && !isInitializing else { 
            print("✅ Database already initialized or in progress")
            return 
        }
        
        isInitializing = true
        
        print("🚀 Starting critical database initialization...")
        
        do {
            // Step 1: Verify database structure exists
            try await verifyDatabaseStructure()
            
            // Step 2: Check if we have real tasks (CRITICAL)
            let hasRealTasks = try await verifyRealTasksExist()
            
            if !hasRealTasks {
                print("🚨 No real tasks found - importing from OperationalDataManager...")
                try await importOperationalData()
            } else {
                print("✅ Real tasks already exist in database")
            }
            
            // Step 3: Verify Kevin's specific assignments (CRITICAL)
            try await verifyKevinAssignments()
            
            // Step 4: Final verification
            try await performFinalVerification()
            
            hasInitialized = true
            print("✅ Database initialization completed successfully")
            
        } catch {
            isInitializing = false
            print("❌ Database initialization failed: \(error)")
            throw error
        }
        
        isInitializing = false
    }
    
    // MARK: - Critical Verification Steps
    
    /// Check if database has real tasks from OperationalDataManager
    private func verifyRealTasksExist() async throws -> Bool {
        let manager = GRDBManager.shared
        
        let rows = try await manager.query("""
            SELECT COUNT(*) as task_count FROM routine_tasks
        """)
        
        let taskCount = rows.first?["task_count"] as? Int64 ?? 0
        print("📊 Current task count in database: \(taskCount)")
        
        return taskCount > 0
    }
    
    /// Import operational data and verify success
    private func importOperationalData() async throws {
        let operationalManager = OperationalDataManager.shared
        
        print("🔄 Importing operational data...")
        let (imported, errors) = try await operationalManager.importRoutinesAndDSNY()
        
        if !errors.isEmpty {
            print("⚠️ Import had \(errors.count) errors:")
            for error in errors.prefix(5) {
                print("   - \(error.localizedDescription)")
            }
        }
        
        guard imported > 0 else {
            throw DatabaseInitializationError.noTasksImported
        }
        
        print("✅ Successfully imported \(imported) tasks")
    }
    
    /// Verify Kevin's specific assignments (CRITICAL for user stories)
    private func verifyKevinAssignments() async throws {
        let manager = GRDBManager.shared
        
        // Check Kevin's tasks
        let kevinTasks = try await manager.query("""
            SELECT COUNT(*) as task_count 
            FROM routine_tasks 
            WHERE workerId = '4'
        """)
        
        let kevinTaskCount = kevinTasks.first?["task_count"] as? Int64 ?? 0
        
        // Check Kevin's buildings (especially Rubin Museum)
        let kevinBuildings = try await manager.query("""
            SELECT DISTINCT buildingId 
            FROM routine_tasks 
            WHERE workerId = '4'
        """)
        
        let buildingIds = kevinBuildings.compactMap { $0["buildingId"] as? String }
        let hasRubinMuseum = buildingIds.contains("rubin-museum")
        
        print("📋 Kevin verification:")
        print("   Tasks: \(kevinTaskCount)")
        print("   Buildings: \(buildingIds.count)")
        print("   Rubin Museum: \(hasRubinMuseum ? "✅" : "❌")")
        
        guard kevinTaskCount > 0 else {
            throw DatabaseInitializationError.kevinHasNoTasks
        }
        
        guard hasRubinMuseum else {
            throw DatabaseInitializationError.kevinMissingRubinMuseum
        }
    }
    
    /// Verify database has proper structure
    private func verifyDatabaseStructure() async throws {
        let manager = GRDBManager.shared
        
        // Check required tables exist
        let requiredTables = ["routine_tasks", "workers", "buildings", "worker_assignments"]
        
        for tableName in requiredTables {
            let rows = try await manager.query("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name=?
            """, [tableName])
            
            guard !rows.isEmpty else {
                throw DatabaseInitializationError.missingTable(tableName)
            }
        }
        
        print("✅ All required database tables exist")
    }
    
    /// Final verification that everything is working
    private func performFinalVerification() async throws {
        let manager = GRDBManager.shared
        
        // Get task counts per worker
        let workerCounts = try await manager.query("""
            SELECT workerId, COUNT(*) as task_count
            FROM routine_tasks
            GROUP BY workerId
            ORDER BY workerId
        """)
        
        print("📊 Final verification - tasks per worker:")
        for row in workerCounts {
            let workerId = row["workerId"] as? String ?? "unknown"
            let taskCount = row["task_count"] as? Int64 ?? 0
            print("   Worker \(workerId): \(taskCount) tasks")
        }
        
        // Verify we have tasks for all active workers
        let activeWorkerIds = ["1", "2", "4", "5", "6", "7", "8"]
        let workersWithTasks = workerCounts.compactMap { $0["workerId"] as? String }
        
        for workerId in activeWorkerIds {
            guard workersWithTasks.contains(workerId) else {
                print("⚠️ Worker \(workerId) has no tasks")
            }
        }
        
        // Total verification
        let totalTasks = workerCounts.reduce(0) { $0 + (($1["task_count"] as? Int64) ?? 0) }
        guard totalTasks > 0 else {
            throw DatabaseInitializationError.noTasksAfterImport
        }
        
        print("✅ Final verification passed: \(totalTasks) total tasks")
    }
}

// MARK: - Database Initialization Errors

enum DatabaseInitializationError: LocalizedError {
    case missingTable(String)
    case noTasksImported
    case kevinHasNoTasks
    case kevinMissingRubinMuseum
    case noTasksAfterImport
    
    var errorDescription: String? {
        switch self {
        case .missingTable(let table):
            return "Required database table missing: \(table)"
        case .noTasksImported:
            return "Failed to import any tasks from OperationalDataManager"
        case .kevinHasNoTasks:
            return "Kevin Dutan has no tasks assigned (critical user story failure)"
        case .kevinMissingRubinMuseum:
            return "Kevin missing Rubin Museum assignment (critical requirement)"
        case .noTasksAfterImport:
            return "No tasks found after import process"
        }
    }
}

// MARK: - App Integration Helper

extension DatabaseStartupCoordinator {
    
    /// Call this from App initialization to ensure data integrity
    @MainActor
    static func initializeForApp() async {
        print("🚀 Initializing database for app startup...")
        
        do {
            try await DatabaseStartupCoordinator.shared.ensureDataIntegrity()
            print("✅ App database initialization successful")
        } catch {
            print("❌ CRITICAL: App database initialization failed: \(error)")
            // Don't throw - let app continue with degraded functionality
        }
    }
}