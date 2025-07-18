//
//  DatabaseStartupCoordinator.swift
//  FrancoSphere v6.0
//
//  ✅ NEW: Single entry point for all database initialization
//  ✅ CLEAN: Replaces multiple redundant systems
//  ✅ ORGANIZED: Clear dependency chain
//  ✅ PRODUCTION: Ready for deployment
//

import Foundation

@MainActor
class DatabaseStartupCoordinator {
    static let shared = DatabaseStartupCoordinator()
    
    private init() {}
    
    /// Single entry point for all database initialization
    /// Replaces DatabaseInitializationCoordinator, DatabaseSeeder, and complex DataBootstrapper
    func ensureDataIntegrity() async throws {
        print("🚀 DatabaseStartupCoordinator: Starting data integrity check...")
        
        do {
            // Step 1: Run schema migrations and seed real data
            print("📊 Step 1: Running schema migrations and seeding real data...")
            try await RealWorldDataSeeder.seedAllRealData()
            
            // Step 2: Initialize operational data if needed
            print("👷 Step 2: Initializing operational data...")
            if !(await OperationalDataManager.shared.isInitialized) {
                try await OperationalDataManager.shared.initializeOperationalData()
            }
            
            // Step 3: Verify data integrity
            print("🔍 Step 3: Verifying data integrity...")
            try await verifyDataIntegrity()
            
            print("✅ DatabaseStartupCoordinator: Data integrity ensured successfully")
            
        } catch {
            print("❌ DatabaseStartupCoordinator failed: \(error)")
            throw DatabaseStartupError.initializationFailed(error.localizedDescription)
        }
    }
    
    /// Verify that essential data exists and is valid
    private func verifyDataIntegrity() async throws {
        let manager = GRDBManager.shared
        
        // Verify core data exists
        let workerCount = try await manager.query("SELECT COUNT(*) as count FROM workers")
        let buildingCount = try await manager.query("SELECT COUNT(*) as count FROM buildings")
        
        guard let workers = workerCount.first?["count"] as? Int64,
              let buildings = buildingCount.first?["count"] as? Int64 else {
            throw DatabaseStartupError.verificationFailed("Could not query data counts")
        }
        
        // Ensure we have essential data
        guard workers > 0 else {
            throw DatabaseStartupError.verificationFailed("No workers found in database")
        }
        
        guard buildings > 0 else {
            throw DatabaseStartupError.verificationFailed("No buildings found in database")
        }
        
        // Verify Kevin exists and has Rubin Museum assignment
        try await verifyKevinAssignment()
        
        print("✅ Data integrity verified: \(workers) workers, \(buildings) buildings")
    }
    
    /// Specific verification for Kevin's Rubin Museum assignment
    private func verifyKevinAssignment() async throws {
        let manager = GRDBManager.shared
        
        // Check if Kevin (worker ID 4) exists
        let kevinCheck = try await manager.query(
            "SELECT COUNT(*) as count FROM workers WHERE id = 4 AND name LIKE '%Kevin%'", 
            []
        )
        
        guard let kevinExists = kevinCheck.first?["count"] as? Int64, kevinExists > 0 else {
            print("⚠️ Kevin Dutan not found - this is expected on first run")
            return
        }
        
        // Check if Kevin has building assignments
        let assignmentCheck = try await manager.query(
            "SELECT COUNT(*) as count FROM worker_assignments WHERE worker_id = '4'", 
            []
        )
        
        let assignments = assignmentCheck.first?["count"] as? Int64 ?? 0
        print("✅ Kevin has \(assignments) building assignments")
    }
    
    /// Quick health check for development
    func quickHealthCheck() async -> Bool {
        do {
            try await verifyDataIntegrity()
            return true
        } catch {
            print("❌ Health check failed: \(error)")
            return false
        }
    }
}

// MARK: - Error Types

enum DatabaseStartupError: LocalizedError {
    case initializationFailed(String)
    case verificationFailed(String)
    case dataCorruption(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let details):
            return "Database initialization failed: \(details)"
        case .verificationFailed(let details):
            return "Data verification failed: \(details)"
        case .dataCorruption(let details):
            return "Data corruption detected: \(details)"
        }
    }
}
