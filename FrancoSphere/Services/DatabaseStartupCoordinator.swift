//
//  DatabaseStartupCoordinator.swift
//  FrancoSphere v6.0 - SINGLE SOURCE OF TRUTH
//
//  ✅ Updated to work with new GRDBManager
//  ✅ Uses raw SQL queries instead of GRDB ORM
//  ✅ Handles all seeding and initialization
//

import Foundation

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
        
        // Step 1: Check if database is ready
        guard await grdbManager.isDatabaseReady() else {
            throw DatabaseError.integrityCheckFailed("Database not ready")
        }
        
        // Step 2: Seed initial data if needed
        try await seedInitialDataIfNeeded()
        
        // Step 3: Verify Kevin's assignment
        try await verifyKevinAssignment()
        
        // Step 4: Run integrity checks
        try await runIntegrityChecks()
        
        isInitialized = true
        print("✅ Database initialization complete")
    }
    
    private func seedInitialDataIfNeeded() async throws {
        print("🌱 Checking if seeding needed...")
        
        // Check if workers exist
        let workerCountResult = try await grdbManager.query("SELECT COUNT(*) as count FROM workers")
        let workerCount = workerCountResult.first?["count"] as? Int64 ?? 0
        
        if workerCount == 0 {
            print("📝 Seeding initial data...")
            
            // Use GRDBManager's built-in seeding
            try await grdbManager.seedCompleteWorkerData()
            
            // Seed buildings
            try await seedBuildings()
            
            // Seed worker assignments
            try await seedWorkerAssignments()
            
            // Seed sample tasks
            try await seedSampleTasks()
            
            print("✅ Initial data seeded")
        } else {
            print("✅ Data already exists, skipping seed")
        }
    }
    
    private func seedBuildings() async throws {
        let buildings = [
            // Kevin's buildings (including Rubin Museum)
            ("14", "Rubin Museum", "150 W 17th St, New York, NY 10011", 40.7402, -73.9979, "rubin_museum"),
            ("1", "12 West 18th Street", "12 W 18th St, New York, NY 10011", 40.7391, -73.9929, "building_12w18"),
            ("2", "133 East 15th Street", "133 E 15th St, New York, NY 10003", 40.7343, -73.9859, "building_133e15"),
            ("3", "41 Elizabeth Street", "41 Elizabeth St, New York, NY 10013", 40.7178, -73.9962, "building_41elizabeth"),
            ("4", "104 Franklin Street", "104 Franklin St, New York, NY 10013", 40.7190, -74.0089, "building_104franklin"),
            ("5", "131 Perry Street", "131 Perry St, New York, NY 10014", 40.7355, -74.0067, "building_131perry"),
            ("6", "36 Walker Street", "36 Walker St, New York, NY 10013", 40.7173, -74.0027, "building_36walker"),
            ("7", "123 1st Avenue", "123 1st Ave, New York, NY 10003", 40.7264, -73.9838, "building_123first"),
            
            // Other buildings
            ("8", "117 West 17th Street", "117 W 17th St, New York, NY 10011", 40.7401, -73.9967, "building_117w17"),
            ("9", "142-148 West 17th Street", "142-148 W 17th St, New York, NY 10011", 40.7403, -73.9981, "building_142w17"),
            ("10", "135 West 17th Street", "135 W 17th St, New York, NY 10011", 40.7402, -73.9975, "building_135w17"),
            ("11", "138 West 17th Street", "138 W 17th St, New York, NY 10011", 40.7403, -73.9978, "building_138w17"),
            ("12", "67 Perry Street", "67 Perry St, New York, NY 10014", 40.7352, -74.0033, "building_67perry"),
            ("13", "Stuyvesant Cove Park", "E 20th St & FDR Dr, New York, NY 10009", 40.7325, -73.9732, "stuyvesant_park")
        ]
        
        for (id, name, address, lat, lng, imageAsset) in buildings {
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO buildings 
                (id, name, address, latitude, longitude, imageAssetName, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
            """, [id, name, address, lat, lng, imageAsset])
        }
        
        print("✅ Seeded \(buildings.count) buildings")
    }
    
    private func seedWorkerAssignments() async throws {
        // First, seed into worker_building_assignments table
        let assignments = [
            // Kevin's assignments (Worker ID 4 based on seed data)
            ("4", "14", "maintenance", true),   // Rubin Museum PRIMARY
            ("4", "1", "maintenance", false),
            ("4", "2", "maintenance", false),
            ("4", "3", "maintenance", false),
            ("4", "4", "maintenance", false),
            ("4", "5", "maintenance", false),
            ("4", "6", "maintenance", false),
            ("4", "7", "maintenance", false),
            
            // Edwin's park assignment (Worker ID 2)
            ("2", "13", "maintenance", true),
            
            // Other assignments
            ("5", "8", "maintenance", true),    // Mercedes
            ("5", "9", "maintenance", false),
            ("6", "10", "maintenance", true),   // Luis
            ("6", "11", "maintenance", false),
            ("7", "12", "maintenance", true)    // Angel
        ]
        
        for (workerId, buildingId, role, isPrimary) in assignments {
            // Insert into worker_building_assignments
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO worker_building_assignments 
                (worker_id, building_id, role, assigned_date, is_active)
                VALUES (?, ?, ?, datetime('now'), 1)
            """, [workerId, buildingId, role])
            
            // Also insert into legacy worker_assignments table for compatibility
            let workerName = try await getWorkerName(workerId: workerId)
            let buildingName = try await getBuildingName(buildingId: buildingId)
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO worker_assignments 
                (worker_id, building_id, worker_name, building_name, is_active)
                VALUES (?, ?, ?, ?, 1)
            """, [workerId, buildingId, workerName ?? "", buildingName ?? ""])
        }
        
        print("✅ Seeded worker assignments")
    }
    
    private func seedSampleTasks() async throws {
        let kevinId = "4" // Kevin's worker ID from seed data
        
        let tasks = [
            ("Clean lobby windows", "Regular window cleaning", "14", kevinId, "cleaning", "medium"),
            ("Check HVAC filters", "Monthly HVAC maintenance", "14", kevinId, "maintenance", "high"),
            ("Empty trash bins", "Daily trash collection", "14", kevinId, "cleaning", "low"),
            ("Inspect fire extinguishers", "Safety equipment check", "14", kevinId, "inspection", "high"),
            ("Polish brass fixtures", "Weekly brass maintenance", "14", kevinId, "cleaning", "medium")
        ]
        
        for (title, desc, buildingId, workerId, category, urgency) in tasks {
            // Insert into routine_tasks table
            try await grdbManager.execute("""
                INSERT INTO routine_tasks 
                (title, description, buildingId, workerId, category, urgency, 
                 isCompleted, scheduledDate, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, 0, date('now'), datetime('now'), datetime('now'))
            """, [title, desc, buildingId, workerId, category, urgency])
            
            // Also insert into tasks table for compatibility
            try await grdbManager.execute("""
                INSERT INTO tasks 
                (name, description, buildingId, workerId, category, urgency, 
                 isCompleted, scheduledDate, created_at)
                VALUES (?, ?, ?, ?, ?, ?, 0, date('now'), datetime('now'))
            """, [title, desc, Int(buildingId) ?? 0, Int(workerId) ?? 0, category, urgency])
        }
        
        print("✅ Seeded sample tasks")
    }
    
    private func verifyKevinAssignment() async throws {
        print("🔍 Verifying Kevin's Rubin Museum assignment...")
        
        // Kevin is worker ID 4 in our seed data
        let kevinAssignments = try await grdbManager.query("""
            SELECT wa.*, b.name as building_name
            FROM worker_assignments wa
            JOIN buildings b ON wa.building_id = b.id
            WHERE wa.worker_id = '4' AND wa.is_active = 1
        """)
        
        let hasRubinMuseum = kevinAssignments.contains { assignment in
            (assignment["building_id"] as? String) == "14"
        }
        
        if hasRubinMuseum {
            print("✅ Kevin properly assigned to Rubin Museum")
            print("   Total assignments: \(kevinAssignments.count)")
            for assignment in kevinAssignments {
                if let buildingName = assignment["building_name"] as? String {
                    print("   - \(buildingName)")
                }
            }
        } else {
            print("❌ Kevin's Rubin Museum assignment missing - fixing...")
            
            // Add the assignment
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO worker_assignments 
                (worker_id, building_id, worker_name, building_name, is_active)
                VALUES ('4', '14', 'Kevin Dutan', 'Rubin Museum', 1)
            """, [])
            
            // Also add to worker_building_assignments
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO worker_building_assignments 
                (worker_id, building_id, role, assigned_date, is_active)
                VALUES ('4', '14', 'maintenance', datetime('now'), 1)
            """, [])
            
            print("✅ Kevin's assignment fixed")
        }
    }
    
    private func runIntegrityChecks() async throws {
        print("🔍 Running database integrity checks...")
        
        // Check workers
        let workerResult = try await grdbManager.query("SELECT COUNT(*) as count FROM workers")
        let workerCount = workerResult.first?["count"] as? Int64 ?? 0
        
        // Check buildings
        let buildingResult = try await grdbManager.query("SELECT COUNT(*) as count FROM buildings")
        let buildingCount = buildingResult.first?["count"] as? Int64 ?? 0
        
        // Check assignments
        let assignmentResult = try await grdbManager.query("SELECT COUNT(*) as count FROM worker_assignments WHERE is_active = 1")
        let assignmentCount = assignmentResult.first?["count"] as? Int64 ?? 0
        
        // Check tasks
        let taskResult = try await grdbManager.query("SELECT COUNT(*) as count FROM routine_tasks")
        let taskCount = taskResult.first?["count"] as? Int64 ?? 0
        
        print("📊 Database Statistics:")
        print("  - Workers: \(workerCount)")
        print("  - Buildings: \(buildingCount)")
        print("  - Active Assignments: \(assignmentCount)")
        print("  - Tasks: \(taskCount)")
        
        // Database size
        let dbSize = grdbManager.getDatabaseSize()
        let formatter = ByteCountFormatter()
        print("  - Database Size: \(formatter.string(fromByteCount: dbSize))")
        
        guard workerCount > 0 && buildingCount > 0 else {
            throw DatabaseError.integrityCheckFailed("Missing critical data")
        }
        
        print("✅ Integrity checks passed")
    }
    
    // MARK: - Helper Methods
    
    private func getWorkerName(workerId: String) async throws -> String? {
        let result = try await grdbManager.query(
            "SELECT name FROM workers WHERE id = ?",
            [workerId]
        )
        return result.first?["name"] as? String
    }
    
    private func getBuildingName(buildingId: String) async throws -> String? {
        let result = try await grdbManager.query(
            "SELECT name FROM buildings WHERE id = ?",
            [buildingId]
        )
        return result.first?["name"] as? String
    }
    
    // MARK: - Public Methods for Testing
    
    /// Reset the database (for testing only)
    public func resetAndReinitialize() async throws {
        print("🔄 Resetting database...")
        isInitialized = false
        try await grdbManager.resetDatabase()
        try await initializeDatabase()
    }
    
    /// Quick health check
    public func quickHealthCheck() async throws -> Bool {
        print("💓 Performing quick health check...")
        
        // Check if Kevin (worker ID 4) has Rubin Museum assignment
        let kevinCheck = try await grdbManager.query("""
            SELECT COUNT(*) as count 
            FROM worker_assignments 
            WHERE worker_id = '4' AND building_id = '14' AND is_active = 1
        """)
        
        let hasRubinAssignment = (kevinCheck.first?["count"] as? Int64 ?? 0) > 0
        
        if hasRubinAssignment {
            print("✅ Health check passed - Kevin has Rubin Museum")
        } else {
            print("❌ Health check failed - Kevin missing Rubin Museum")
        }
        
        return hasRubinAssignment
    }
    
    /// Get detailed statistics
    public func getDatabaseStatistics() async throws -> [String: Any] {
        var stats: [String: Any] = [:]
        
        // Get authentication stats from GRDBManager
        stats["authentication"] = try await grdbManager.getAuthenticationStats()
        
        // Get operational stats
        let workerStats = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN isActive = 1 THEN 1 ELSE 0 END) as active,
                COUNT(DISTINCT role) as roles
            FROM workers
        """)
        
        if let row = workerStats.first {
            stats["workers"] = [
                "total": row["total"] as? Int64 ?? 0,
                "active": row["active"] as? Int64 ?? 0,
                "roles": row["roles"] as? Int64 ?? 0
            ]
        }
        
        // Get building stats
        let buildingStats = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total,
                COUNT(DISTINCT SUBSTR(address, -5)) as zipcodes
            FROM buildings
        """)
        
        if let row = buildingStats.first {
            stats["buildings"] = [
                "total": row["total"] as? Int64 ?? 0,
                "zipcodes": row["zipcodes"] as? Int64 ?? 0
            ]
        }
        
        // Get task stats
        let taskStats = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed,
                COUNT(DISTINCT category) as categories
            FROM routine_tasks
        """)
        
        if let row = taskStats.first {
            stats["tasks"] = [
                "total": row["total"] as? Int64 ?? 0,
                "completed": row["completed"] as? Int64 ?? 0,
                "categories": row["categories"] as? Int64 ?? 0
            ]
        }
        
        return stats
    }
}

// MARK: - Error Types

enum DatabaseError: LocalizedError {
    case integrityCheckFailed(String)
    case seedingFailed(String)
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .integrityCheckFailed(let msg):
            return "Database integrity check failed: \(msg)"
        case .seedingFailed(let msg):
            return "Database seeding failed: \(msg)"
        case .migrationFailed(let msg):
            return "Database migration failed: \(msg)"
        }
    }
}
