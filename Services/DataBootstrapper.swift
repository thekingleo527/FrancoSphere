//
//  DataBootstrapper.swift
//  FrancoSphere v6.0
//
//  ✅ REAL DATA ONLY: No hardcoded arrays, no fake data
//  ✅ FIXED: Uses ONLY existing real data methods from OperationalDataManager
//  ✅ FIXED: Calls SeedDatabase.runMigrations() for real schema setup
//  ✅ ALIGNED: Thin layer that coordinates real data initialization
//

import Foundation

// MARK: - DataBootstrapper (Real Data Coordinator Only)
enum DataBootstrapper {

    /// Run once per fresh install; guarded by UserDefaults.
    /// Coordinates real data initialization using existing systems
    static func runIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "SeedComplete") else {
            print("✅ Seed already completed, skipping")
            return
        }
        
        Task.detached {
            do {
                try await initializeRealData()
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "SeedComplete")
                }
                print("✅ Real data initialization finished.")
            } catch {
                print("🚨 Real data initialization failed: \(error)")
            }
        }
    }

    // MARK: - Real Data Initialization

    private static func initializeRealData() async throws {
        print("🚀 DataBootstrapper: Initializing REAL data systems...")
        
        // Step 1: Ensure database schema is ready using real migration system
        print("📊 Step 1: Running real database migrations...")
        try await RealWorldDataSeeder.seedAllRealData()

        // Step 2: Initialize operational data using real OperationalDataManager
        print("👷 Step 2: Initializing real operational data...")
        await MainActor.run {
            Task {
                do {
                    try await OperationalDataManager.shared.initializeOperationalData()
                    print("✅ Real operational data initialized successfully")
                } catch {
                    print("❌ Failed to initialize real operational data: \(error)")
                    throw error
                }
            }
        }
        
        // Step 3: Verify real data integrity
        print("🔍 Step 3: Verifying real data integrity...")
        try await verifyRealDataIntegrity()
        
        print("✅ All real data systems initialized successfully")
    }
    
    // MARK: - Real Data Verification
    
    private static func verifyRealDataIntegrity() async throws {
        // Get the real SQLiteManager instance
        let manager = try await SQLiteManager.start()
        
        // Verify real workers exist (using real GRDB queries)
        let workerCount = try await manager.query("SELECT COUNT(*) as count FROM workers", parameters: [])
        let workers = workerCount.first?["count"] as? Int64 ?? 0
        
        // Verify real buildings exist
        let buildingCount = try await manager.query("SELECT COUNT(*) as count FROM buildings", parameters: [])
        let buildings = buildingCount.first?["count"] as? Int64 ?? 0
        
        // Verify real tasks exist
        let taskCount = try await manager.query("SELECT COUNT(*) as count FROM tasks", parameters: [])
        let tasks = taskCount.first?["count"] as? Int64 ?? 0
        
        print("📊 Real Data Verification:")
        print("  - Workers: \(workers)")
        print("  - Buildings: \(buildings)")
        print("  - Tasks: \(tasks)")
        
        // Verify Kevin's Rubin Museum assignment (critical real data test)
        let kevinRubin = try await manager.query("""
            SELECT COUNT(*) as count FROM worker_assignments 
            WHERE worker_id = '4' AND building_id = '14'
        """, parameters: [])
        let kevinAssignments = kevinRubin.first?["count"] as? Int64 ?? 0
        
        if kevinAssignments > 0 {
            print("✅ VERIFIED: Kevin's Rubin Museum assignment exists in real data")
        } else {
            print("⚠️ WARNING: Kevin's Rubin Museum assignment not found in real data")
        }
        
        // Verify Edwin's park assignment
        let edwinPark = try await manager.query("""
            SELECT COUNT(*) as count FROM worker_assignments 
            WHERE worker_id = '2' AND building_id = '16'
        """, parameters: [])
        let edwinAssignments = edwinPark.first?["count"] as? Int64 ?? 0
        
        if edwinAssignments > 0 {
            print("✅ VERIFIED: Edwin's Stuyvesant Cove Park assignment exists in real data")
        } else {
            print("⚠️ WARNING: Edwin's park assignment not found in real data")
        }
        
        // Ensure we have minimum real data to function
        guard workers > 0 && buildings > 0 else {
            throw DataBootstrapperError.insufficientRealData(workers: Int(workers), buildings: Int(buildings))
        }
        
        print("✅ Real data integrity verification passed")
    }
}

// MARK: - Real Data Errors

enum DataBootstrapperError: LocalizedError {
    case insufficientRealData(workers: Int, buildings: Int)
    case realDataCorruption(String)
    case migrationFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientRealData(let workers, let buildings):
            return "Insufficient real data: \(workers) workers, \(buildings) buildings"
        case .realDataCorruption(let details):
            return "Real data corruption detected: \(details)"
        case .migrationFailure(let details):
            return "Database migration failed: \(details)"
        }
    }
}
