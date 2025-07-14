//
//  DatabaseInitializationCoordinator.swift
//  FrancoSphere
//
//  ✅ V6.0 FIXED: Uses existing SchemaMigrationPatch instead of direct createTables call
//  ✅ INTEGRATION: Follows established initialization patterns
//  ✅ GRDB: Uses proper GRDB methods and patterns
//

import Foundation

class DatabaseInitializationCoordinator {
    private let grdbManager = GRDBManager.shared
    
    func initializeDatabase() async throws {
        // Use existing SchemaMigrationPatch which handles table creation and data seeding
        try await SchemaMigrationPatch.shared.applyPatch()
        
        // Verify initialization was successful
        try await verifyInitialization()
    }
    
    private func verifyInitialization() async throws {
        // Check if core tables have data
        let workerCount = try await grdbManager.query("SELECT COUNT(*) as count FROM workers")
        let buildingCount = try await grdbManager.query("SELECT COUNT(*) as count FROM buildings")
        
        guard let workers = workerCount.first?["count"] as? Int64,
              let buildings = buildingCount.first?["count"] as? Int64 else {
            throw DatabaseInitializationError.verificationFailed("Could not verify table counts")
        }
        
        if workers == 0 || buildings == 0 {
            throw DatabaseInitializationError.verificationFailed("Database tables appear to be empty")
        }
        
        print("✅ Database initialization verified: \(workers) workers, \(buildings) buildings")
    }
    
    private func seedInitialData() async throws {
        // Check if data already exists
        let workerCount = try await grdbManager.query("SELECT COUNT(*) as count FROM workers")
        
        if let count = workerCount.first?["count"] as? Int64, count == 0 {
            try await seedWorkers()
            try await seedBuildings()
            try await seedWorkerAssignments()
        }
    }
    
    private func seedWorkers() async throws {
        let workers = [
            ("Kevin Dutan", "kevin.dutan@francosphere.com", "worker"),
            ("Edwin Lema", "edwin.lema@francosphere.com", "worker"),
            ("Mercedes Inamagua", "mercedes.inamagua@francosphere.com", "worker"),
            ("Luis Lopez", "luis.lopez@francosphere.com", "worker"),
            ("Angel Guirachocha", "angel.guirachocha@francosphere.com", "worker"),
            ("Greg Hutson", "greg.hutson@francosphere.com", "worker"),
            ("Shawn Magloire", "shawn.magloire@francosphere.com", "admin")
        ]
        
        for worker in workers {
            try await grdbManager.execute("""
                INSERT INTO workers (name, email, password, role, isActive) 
                VALUES (?, ?, ?, ?, ?)
            """, [worker.0, worker.1, "password", worker.2, 1])
        }
        
        print("✅ Seeded \(workers.count) workers")
    }
    
    private func seedBuildings() async throws {
        let buildings = [
            ("Rubin Museum", "150 W 17th St", 40.7401, -73.9978, "rubin_museum"),
            ("12 West 18th Street", "12 W 18th St", 40.7389, -73.9936, "12West18thStreet"),
            ("Franklin Square", "1 Franklin Sq", 40.7580, -73.9855, "franklin_square"),
            ("East River Park", "East River Dr", 40.7194, -73.9744, "east_river_park"),
            ("178 Spring Street", "178 Spring St", 40.7248, -73.9964, "178_spring_street")
        ]
        
        for building in buildings {
            try await grdbManager.execute("""
                INSERT INTO buildings (name, address, latitude, longitude, imageAssetName) 
                VALUES (?, ?, ?, ?, ?)
            """, [building.0, building.1, building.2, building.3, building.4])
        }
        
        print("✅ Seeded \(buildings.count) buildings")
    }
    
    private func seedWorkerAssignments() async throws {
        // Get worker and building IDs for assignments
        let workers = try await grdbManager.query("SELECT id, name FROM workers ORDER BY id")
        let buildings = try await grdbManager.query("SELECT id, name FROM buildings ORDER BY id")
        
        // Kevin's assignments (Rubin Museum specialist)
        if let kevin = workers.first(where: { ($0["name"] as? String)?.contains("Kevin") == true }),
           let kevinId = kevin["id"] as? Int64,
           let rubin = buildings.first(where: { ($0["name"] as? String)?.contains("Rubin") == true }),
           let rubinId = rubin["id"] as? Int64 {
            
            try await grdbManager.execute("""
                INSERT INTO worker_building_assignments (worker_id, building_id, role, assigned_date, is_active)
                VALUES (?, ?, ?, ?, ?)
            """, [kevinId, rubinId, "Museum Specialist", Date().timeIntervalSince1970, 1])
        }
        
        // Edwin's assignments (Parks and maintenance)
        if let edwin = workers.first(where: { ($0["name"] as? String)?.contains("Edwin") == true }),
           let edwinId = edwin["id"] as? Int64,
           let park = buildings.first(where: { ($0["name"] as? String)?.contains("Park") == true }),
           let parkId = park["id"] as? Int64 {
            
            try await grdbManager.execute("""
                INSERT INTO worker_building_assignments (worker_id, building_id, role, assigned_date, is_active)
                VALUES (?, ?, ?, ?, ?)
            """, [edwinId, parkId, "Park Operations", Date().timeIntervalSince1970, 1])
        }
        
        print("✅ Seeded worker assignments")
    }
}

// MARK: - Error Types

enum DatabaseInitializationError: LocalizedError {
    case verificationFailed(String)
    case seedingFailed(String)
    case schemaCreationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed(let message):
            return "Database verification failed: \(message)"
        case .seedingFailed(let message):
            return "Database seeding failed: \(message)"
        case .schemaCreationFailed(let message):
            return "Schema creation failed: \(message)"
        }
    }
}
