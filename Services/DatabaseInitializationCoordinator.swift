import Foundation

class DatabaseInitializationCoordinator {
    private let grdbManager = GRDBManager.shared
    
    func initializeDatabase() async throws {
        try await grdbManager.createTables()
        try await seedInitialData()
    }
    
    private func seedInitialData() async throws {
        // Check if data already exists
        let workerCount = try await grdbManager.query("SELECT COUNT(*) as count FROM workers")
        
        if let count = workerCount.first?["count"] as? Int64, count == 0 {
            try await seedWorkers()
            try await seedBuildings()
        }
    }
    
    private func seedWorkers() async throws {
        let workers = [
            ("1", "Kevin Dutan", "kevin@example.com", "worker"),
            ("2", "Edwin Lema", "edwin@example.com", "worker")
        ]
        
        for worker in workers {
            try await grdbManager.execute(
                "INSERT INTO workers (id, name, email, role, isActive) VALUES (?, ?, ?, ?, ?)",
                [worker.0, worker.1, worker.2, worker.3, 1]
            )
        }
    }
    
    private func seedBuildings() async throws {
        let buildings = [
            ("14", "Rubin Museum", "150 W 17th St", 40.7401, -73.9978),
            ("1", "12 West 18th Street", "12 W 18th St", 40.7389, -73.9936)
        ]
        
        for building in buildings {
            try await grdbManager.execute(
                "INSERT INTO buildings (id, name, address, latitude, longitude) VALUES (?, ?, ?, ?, ?)",
                [building.0, building.1, building.2, building.3, building.4]
            )
        }
    }
}
