//
//  DatabaseStartupCoordinator.swift
//  FrancoSphere v6.0 - SINGLE SOURCE OF TRUTH
//
//  ✅ This is the ONLY database initialization service
//  ✅ Uses GRDB exclusively (no SQLite)
//  ✅ Handles all seeding and migration
//

import Foundation
import GRDB

@MainActor
public class DatabaseStartupCoordinator {
    public static let shared = DatabaseStartupCoordinator()
    
    private let grdbManager = GRDBManager.shared
    private var isInitialized = false
    
    private init() {}
    
    /// Single entry point for ALL database initialization
    public func initializeDatabase() async throws {
        guard !isInitialized else {
            print("✅ Database already initialized")
            return
        }
        
        print("🚀 Starting database initialization...")
        
        // Step 1: Run migrations
        try await runMigrations()
        
        // Step 2: Seed initial data if needed
        try await seedInitialDataIfNeeded()
        
        // Step 3: Verify Kevin's assignment
        try await verifyKevinAssignment()
        
        // Step 4: Run integrity checks
        try await runIntegrityChecks()
        
        isInitialized = true
        print("✅ Database initialization complete")
    }
    
    private func runMigrations() async throws {
        print("📊 Running database migrations...")
        
        try await grdbManager.migrate { migrator in
            // V1: Initial schema
            migrator.registerMigration("v1_initial") { db in
                try db.create(table: "workers", ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("name", .text).notNull()
                    t.column("email", .text).notNull().unique()
                    t.column("role", .text).notNull()
                    t.column("isActive", .boolean).notNull().defaults(to: true)
                }
                
                try db.create(table: "buildings", ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("name", .text).notNull()
                    t.column("address", .text).notNull()
                    t.column("latitude", .double).notNull()
                    t.column("longitude", .double).notNull()
                    t.column("type", .text)
                    t.column("imageUrl", .text)
                }
                
                try db.create(table: "worker_assignments", ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("workerId", .text).notNull().references("workers")
                    t.column("buildingId", .text).notNull().references("buildings")
                    t.column("isPrimary", .boolean).notNull().defaults(to: false)
                    t.column("createdAt", .datetime).notNull()
                }
                
                try db.create(table: "tasks", ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("title", .text).notNull()
                    t.column("description", .text)
                    t.column("buildingId", .text).notNull().references("buildings")
                    t.column("assignedWorkerId", .text).references("workers")
                    t.column("category", .text).notNull()
                    t.column("urgency", .text).notNull()
                    t.column("status", .text).notNull()
                    t.column("dueDate", .datetime)
                    t.column("completedAt", .datetime)
                    t.column("createdAt", .datetime).notNull()
                }
            }
        }
        
        print("✅ Migrations completed")
    }
    
    private func seedInitialDataIfNeeded() async throws {
        print("🌱 Checking if seeding needed...")
        
        let workerCount = try await grdbManager.read { db in
            try Worker.fetchCount(db)
        }
        
        if workerCount == 0 {
            print("📝 Seeding initial data...")
            try await seedWorkers()
            try await seedBuildings()
            try await seedWorkerAssignments()
            try await seedSampleTasks()
            print("✅ Initial data seeded")
        } else {
            print("✅ Data already exists, skipping seed")
        }
    }
    
    private func seedWorkers() async throws {
        let workers = [
            Worker(id: "1", name: "Kevin Dutan", email: "kevin@francosphere.com", role: "worker"),
            Worker(id: "2", name: "Edwin Lema", email: "edwin@francosphere.com", role: "worker"),
            Worker(id: "3", name: "Mercedes Inamagua", email: "mercedes@francosphere.com", role: "worker"),
            Worker(id: "4", name: "Luis Lopez", email: "luis@francosphere.com", role: "worker"),
            Worker(id: "5", name: "Angel Guiracocha", email: "angel@francosphere.com", role: "worker"),
            Worker(id: "6", name: "Greg Hutson", email: "greg@francosphere.com", role: "worker"),
            Worker(id: "7", name: "Shawn Magloire", email: "shawn@francosphere.com", role: "admin")
        ]
        
        try await grdbManager.write { db in
            for worker in workers {
                try worker.insert(db)
            }
        }
    }
    
    private func seedBuildings() async throws {
        let buildings = [
            // Kevin's buildings (including Rubin Museum)
            Building(id: "14", name: "Rubin Museum", address: "150 W 17th St", latitude: 40.7402, longitude: -73.9979),
            Building(id: "1", name: "12 West 18th Street", address: "12 W 18th St", latitude: 40.7391, longitude: -73.9929),
            Building(id: "2", name: "133 East 15th Street", address: "133 E 15th St", latitude: 40.7343, longitude: -73.9859),
            Building(id: "3", name: "41 Elizabeth Street", address: "41 Elizabeth St", latitude: 40.7178, longitude: -73.9962),
            Building(id: "4", name: "104 Franklin Street", address: "104 Franklin St", latitude: 40.7190, longitude: -74.0089),
            Building(id: "5", name: "131 Perry Street", address: "131 Perry St", latitude: 40.7355, longitude: -74.0067),
            Building(id: "6", name: "36 Walker Street", address: "36 Walker St", latitude: 40.7173, longitude: -74.0027),
            Building(id: "7", name: "123 1st Avenue", address: "123 1st Ave", latitude: 40.7264, longitude: -73.9838),
            
            // Other buildings
            Building(id: "8", name: "117 West 17th Street", address: "117 W 17th St", latitude: 40.7401, longitude: -73.9967),
            Building(id: "9", name: "142-148 West 17th Street", address: "142-148 W 17th St", latitude: 40.7403, longitude: -73.9981),
            Building(id: "10", name: "135 West 17th Street", address: "135 W 17th St", latitude: 40.7402, longitude: -73.9975),
            Building(id: "11", name: "138 West 17th Street", address: "138 W 17th St", latitude: 40.7403, longitude: -73.9978),
            Building(id: "12", name: "67 Perry Street", address: "67 Perry St", latitude: 40.7352, longitude: -74.0033),
            Building(id: "13", name: "Stuyvesant Cove Park", address: "E 20th St & FDR Dr", latitude: 40.7325, longitude: -73.9732)
        ]
        
        try await grdbManager.write { db in
            for building in buildings {
                try building.insert(db)
            }
        }
    }
    
    private func seedWorkerAssignments() async throws {
        let assignments = [
            // Kevin's assignments (Worker ID 1)
            WorkerAssignment(workerId: "1", buildingId: "14", isPrimary: true),  // Rubin Museum PRIMARY
            WorkerAssignment(workerId: "1", buildingId: "1", isPrimary: false),
            WorkerAssignment(workerId: "1", buildingId: "2", isPrimary: false),
            WorkerAssignment(workerId: "1", buildingId: "3", isPrimary: false),
            WorkerAssignment(workerId: "1", buildingId: "4", isPrimary: false),
            WorkerAssignment(workerId: "1", buildingId: "5", isPrimary: false),
            WorkerAssignment(workerId: "1", buildingId: "6", isPrimary: false),
            WorkerAssignment(workerId: "1", buildingId: "7", isPrimary: false),
            
            // Edwin's park assignment
            WorkerAssignment(workerId: "2", buildingId: "13", isPrimary: true),
            
            // Other assignments
            WorkerAssignment(workerId: "3", buildingId: "8", isPrimary: true),
            WorkerAssignment(workerId: "3", buildingId: "9", isPrimary: false),
            WorkerAssignment(workerId: "4", buildingId: "10", isPrimary: true),
            WorkerAssignment(workerId: "4", buildingId: "11", isPrimary: false),
            WorkerAssignment(workerId: "5", buildingId: "12", isPrimary: true)
        ]
        
        try await grdbManager.write { db in
            for assignment in assignments {
                try assignment.insert(db)
            }
        }
    }
    
    private func seedSampleTasks() async throws {
        let tasks = [
            Task(
                id: UUID().uuidString,
                title: "Clean lobby windows",
                buildingId: "14",
                assignedWorkerId: "1",
                category: "cleaning",
                urgency: "medium",
                status: "pending"
            ),
            Task(
                id: UUID().uuidString,
                title: "Check HVAC filters",
                buildingId: "14",
                assignedWorkerId: "1",
                category: "maintenance",
                urgency: "high",
                status: "pending"
            )
        ]
        
        try await grdbManager.write { db in
            for task in tasks {
                try task.insert(db)
            }
        }
    }
    
    private func verifyKevinAssignment() async throws {
        print("🔍 Verifying Kevin's Rubin Museum assignment...")
        
        let kevinAssignments = try await grdbManager.read { db in
            try WorkerAssignment
                .filter(Column("workerId") == "1")
                .fetchAll(db)
        }
        
        let hasRubinMuseum = kevinAssignments.contains { $0.buildingId == "14" && $0.isPrimary }
        
        if hasRubinMuseum {
            print("✅ Kevin properly assigned to Rubin Museum as PRIMARY")
        } else {
            print("❌ Kevin's Rubin Museum assignment missing - fixing...")
            try await grdbManager.write { db in
                try WorkerAssignment(workerId: "1", buildingId: "14", isPrimary: true).insert(db)
            }
            print("✅ Kevin's assignment fixed")
        }
    }
    
    private func runIntegrityChecks() async throws {
        print("🔍 Running database integrity checks...")
        
        let stats = try await grdbManager.read { db -> (workers: Int, buildings: Int, assignments: Int, tasks: Int) in
            let workers = try Worker.fetchCount(db)
            let buildings = try Building.fetchCount(db)
            let assignments = try WorkerAssignment.fetchCount(db)
            let tasks = try Task.fetchCount(db)
            return (workers, buildings, assignments, tasks)
        }
        
        print("📊 Database Statistics:")
        print("  - Workers: \(stats.workers)")
        print("  - Buildings: \(stats.buildings)")
        print("  - Assignments: \(stats.assignments)")
        print("  - Tasks: \(stats.tasks)")
        
        guard stats.workers > 0 && stats.buildings > 0 else {
            throw DatabaseError.integrityCheckFailed("Missing critical data")
        }
        
        print("✅ Integrity checks passed")
    }
}

// MARK: - Database Models

struct Worker: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "workers"
    
    let id: String
    let name: String
    let email: String
    let role: String
    var isActive: Bool = true
}

struct Building: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "buildings"
    
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    var type: String?
    var imageUrl: String?
}

struct WorkerAssignment: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "worker_assignments"
    
    var id: String = UUID().uuidString
    let workerId: String
    let buildingId: String
    let isPrimary: Bool
    var createdAt: Date = Date()
}

struct Task: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "tasks"
    
    let id: String
    let title: String
    var description: String?
    let buildingId: String
    let assignedWorkerId: String?
    let category: String
    let urgency: String
    let status: String
    var dueDate: Date?
    var completedAt: Date?
    var createdAt: Date = Date()
}

enum DatabaseError: Error {
    case integrityCheckFailed(String)
}
