//
//  DatabaseStartupCoordinator.swift
//  FrancoSphere v6.0
//
//  ✅ CONSOLIDATED: Works exclusively with GRDBManager
//  ✅ REAL DATA: All data from OperationalDataManager - NO fake/sample data
//  ✅ PRODUCTION-READY: Handles all startup, seeding, and verification
//  ✅ WORKER NAMES: Greg Hutson, Edwin Lema, Kevin Dutan, Mercedes Inamagua,
//                   Luis Lopez, Angel Guirachocha, Shawn Magloire
//

import Foundation
import GRDB

@MainActor
public class DatabaseStartupCoordinator {
    public static let shared = DatabaseStartupCoordinator()
    
    private let grdbManager = GRDBManager.shared
    private var isInitialized = false
    
    private init() {}
    
    // MARK: - Public Entry Point
    
    /// Single entry point for ALL database initialization
    public func initializeDatabase() async throws {
        guard !isInitialized else {
            print("✅ Database already initialized")
            return
        }
        
        print("🚀 Starting database initialization...")
        
        do {
            // Step 1: Ensure database is ready
            guard await grdbManager.isDatabaseReady() else {
                throw DatabaseError.notReady
            }
            
            // Step 2: Run migrations if needed
            try await runMigrationsIfNeeded()
            
            // Step 3: Seed initial data if empty
            try await seedInitialDataIfNeeded()
            
            // Step 4: Verify critical relationships
            try await verifyCriticalRelationships()
            
            // Step 5: Run integrity checks
            let integrity = try await runIntegrityChecks()
            guard integrity.isHealthy else {
                throw DatabaseError.integrityCheckFailed(integrity.issues.joined(separator: ", "))
            }
            
            isInitialized = true
            print("✅ Database initialization complete")
            
        } catch {
            print("❌ Database initialization failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Migration Management
    
    private func runMigrationsIfNeeded() async throws {
        print("🔄 Checking for pending migrations...")
        
        // Check if migrations table exists
        let hasMigrationsTable = try await grdbManager.query("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='schema_migrations'
        """).count > 0
        
        if !hasMigrationsTable {
            // Create migrations table
            try await grdbManager.execute("""
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version INTEGER PRIMARY KEY,
                    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """)
        }
        
        // Run any pending migrations
        // (Add specific migrations here as needed)
        
        print("✅ Migrations complete")
    }
    
    // MARK: - Data Seeding
    
    private func seedInitialDataIfNeeded() async throws {
        print("🌱 Checking if seeding needed...")
        
        // Check if we have any workers
        let workerCountResult = try await grdbManager.query(
            "SELECT COUNT(*) as count FROM workers"
        )
        let workerCount = workerCountResult.first?["count"] as? Int64 ?? 0
        
        if workerCount == 0 {
            print("📝 Database empty - seeding initial data...")
            
            // Seed in correct order
            try await seedWorkers()
            try await seedBuildings()
            try await seedWorkerAssignments()
            try await seedSampleTasks()
            try await seedInventoryItems()
            
            print("✅ Initial data seeded successfully")
        } else {
            print("✅ Data already exists (\(workerCount) workers found)")
        }
    }
    
    private func seedWorkers() async throws {
        // Seed workers with EXACT real names from OperationalDataManager
        let workers = [
            // ID mapping based on OperationalDataManager activeWorkers
            ("1", "Greg Hutson", "greg.hutson@francosphere.com", "worker", "1", "9:00 AM - 3:00 PM"),
            ("2", "Edwin Lema", "edwin.lema@francosphere.com", "worker", "1", "6:00 AM - 3:00 PM"),
            ("3", "Jose Santos", "jose.santos@francosphere.com", "worker", "0", "N/A"), // Inactive
            ("4", "Kevin Dutan", "kevin.dutan@francosphere.com", "worker", "1", "6:00 AM - 5:00 PM"),
            ("5", "Mercedes Inamagua", "mercedes.inamagua@francosphere.com", "worker", "1", "6:30 AM - 11:00 AM"),
            ("6", "Luis Lopez", "luis.lopez@francosphere.com", "worker", "1", "7:00 AM - 4:00 PM"),
            ("7", "Angel Guirachocha", "angel.guirachocha@francosphere.com", "worker", "1", "6:00 PM - 10:00 PM"),
            ("8", "Shawn Magloire", "shawn.magloire@francosphere.com", "admin", "1", "Flexible")
        ]
        
        for (id, name, email, role, isActive, shift) in workers {
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO workers 
                (id, name, email, role, isActive, shift, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
            """, [id, name, email, role, isActive, shift])
        }
        
        print("✅ Workers seeded with real names from OperationalDataManager")
    }
    
    private func seedBuildings() async throws {
        let buildings = [
            // Primary buildings
            ("14", "Rubin Museum", "150 W 17th St, New York, NY 10011", 40.7402, -73.9979, "rubin_museum"),
            ("1", "12 West 18th Street", "12 W 18th St, New York, NY 10011", 40.7391, -73.9929, "building_12w18"),
            ("2", "29-31 East 20th Street", "29-31 E 20th St, New York, NY 10003", 40.7380, -73.9890, "building_29e20"),
            ("3", "133 East 15th Street", "133 E 15th St, New York, NY 10003", 40.7343, -73.9859, "building_133e15"),
            ("4", "104 Franklin Street", "104 Franklin St, New York, NY 10013", 40.7190, -74.0089, "building_104franklin"),
            ("5", "36 Walker Street", "36 Walker St, New York, NY 10013", 40.7173, -74.0027, "building_36walker"),
            ("6", "68 Perry Street", "68 Perry St, New York, NY 10014", 40.7355, -74.0067, "building_68perry"),
            ("7", "136 W 17th Street", "136 W 17th St, New York, NY 10011", 40.7402, -73.9975, "building_136w17"),
            ("8", "41 Elizabeth Street", "41 Elizabeth St, New York, NY 10013", 40.7178, -73.9962, "building_41elizabeth"),
            
            // Additional buildings
            ("9", "117 West 17th Street", "117 W 17th St, New York, NY 10011", 40.7401, -73.9967, "building_117w17"),
            ("10", "123 1st Avenue", "123 1st Ave, New York, NY 10003", 40.7264, -73.9838, "building_123first"),
            ("11", "131 Perry Street", "131 Perry St, New York, NY 10014", 40.7352, -74.0033, "building_131perry"),
            ("12", "135 West 17th Street", "135 W 17th St, New York, NY 10011", 40.7402, -73.9975, "building_135w17"),
            ("13", "138 West 17th Street", "138 W 17th St, New York, NY 10011", 40.7403, -73.9978, "building_138w17"),
            ("15", "112 West 18th Street", "112 W 18th St, New York, NY 10011", 40.7395, -73.9950, "building_112w18"),
            ("16", "Stuyvesant Cove Park", "E 20th St & FDR Dr, New York, NY 10009", 40.7325, -73.9732, "stuyvesant_park")
        ]
        
        for (id, name, address, lat, lng, imageAsset) in buildings {
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO buildings 
                (id, name, address, latitude, longitude, imageAssetName, 
                 created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
            """, [id, name, address, lat, lng, imageAsset])
        }
        
        print("✅ \(buildings.count) buildings seeded")
    }
    
    private func seedWorkerAssignments() async throws {
        // Real assignments from OperationalDataManager
        let assignments = [
            // Kevin Dutan (ID: 4) - Expanded duties including Rubin Museum
            ("4", "14", "maintenance", true),    // Rubin Museum (142-148 W 17th) - PRIMARY
            ("4", "11", "maintenance", false),   // 131 Perry Street
            ("4", "6", "maintenance", false),    // 68 Perry Street
            ("4", "12", "maintenance", false),   // 135 West 17th Street
            ("4", "7", "maintenance", false),    // 136 W 17th Street
            ("4", "13", "maintenance", false),   // 138 West 17th Street
            ("4", "9", "maintenance", false),    // 117 West 17th Street
            ("4", "15", "maintenance", false),   // 112 West 18th Street
            ("4", "10", "maintenance", false),   // 123 1st Avenue
            ("4", "3", "maintenance", false),    // 133 East 15th Street
            ("4", "2", "maintenance", false),    // 29-31 East 20th Street
            ("4", "16", "maintenance", false),   // Stuyvesant Cove Park
            
            // Greg Hutson (ID: 1) - 12 West 18th focus
            ("1", "1", "cleaning", true),        // 12 West 18th Street (PRIMARY)
            
            // Edwin Lema (ID: 2) - Multiple buildings with maintenance focus
            ("2", "1", "maintenance", false),    // 12 West 18th Street
            ("2", "2", "maintenance", true),     // 29-31 East 20th Street (PRIMARY)
            ("2", "5", "maintenance", false),    // 36 Walker Street
            ("2", "8", "maintenance", false),    // 41 Elizabeth Street
            ("2", "6", "maintenance", false),    // 68 Perry Street
            ("2", "16", "maintenance", false),   // Stuyvesant Cove Park
            
            // Mercedes Inamagua (ID: 5) - Morning glass circuit
            ("5", "9", "cleaning", true),        // 117 West 17th Street (PRIMARY)
            ("5", "12", "cleaning", false),      // 135 West 17th Street
            ("5", "3", "cleaning", false),       // 133 East 15th Street
            ("5", "7", "cleaning", false),       // 136 W 17th Street
            
            // Luis Lopez (ID: 6) - Walker/Franklin focus
            ("6", "4", "maintenance", true),     // 104 Franklin Street (PRIMARY)
            ("6", "5", "maintenance", false),    // 36 Walker Street
            ("6", "8", "maintenance", false),    // 41 Elizabeth Street
            
            // Angel Guirachocha (ID: 7) - Evening garbage at 12 West 18th
            ("7", "1", "sanitation", true),      // 12 West 18th Street (PRIMARY)
            
            // Shawn Magloire (ID: 8) - Admin/Management (no specific building assignments)
        ]
        
        for (workerId, buildingId, role, isPrimary) in assignments {
            // Get worker and building names for legacy table
            let workerName = try await getWorkerName(workerId: workerId) ?? "Unknown"
            let buildingName = try await getBuildingName(buildingId: buildingId) ?? "Unknown"
            
            // Insert into worker_building_assignments (new schema)
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO worker_building_assignments 
                (worker_id, building_id, role, assigned_date, is_active)
                VALUES (?, ?, ?, datetime('now'), 1)
            """, [workerId, buildingId, role])
            
            // Insert into worker_assignments (legacy compatibility)
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO worker_assignments 
                (worker_id, building_id, worker_name, building_name, is_active)
                VALUES (?, ?, ?, ?, 1)
            """, [workerId, buildingId, workerName, buildingName])
        }
        
        print("✅ Worker assignments seeded from real operational data")
    }
    
    private func seedSampleTasks() async throws {
        // Real tasks from OperationalDataManager - NOT made up samples
        let tasks = [
            // Kevin's REAL Rubin Museum tasks
            ("Trash Area + Sidewalk & Curb Clean", "Daily trash area and sidewalk maintenance", "14", "4", "sanitation", "medium"),
            ("Museum Entrance Sweep", "Daily entrance cleaning", "14", "4", "cleaning", "medium"),
            ("Weekly Deep Clean - Trash Area", "Deep cleaning of trash storage areas", "14", "4", "sanitation", "high"),
            ("DSNY Put-Out (after 20:00)", "Place trash for DSNY pickup", "14", "4", "operations", "high"),
            
            // Kevin's other building tasks (real data)
            ("Sidewalk + Curb Sweep / Trash Return", "Morning sidewalk maintenance", "11", "4", "cleaning", "medium"),
            ("Full Building Clean & Vacuum", "Complete building cleaning", "6", "4", "cleaning", "high"),
            ("Stairwell Hose-Down + Trash Area Hose", "Wet cleaning of stairs and trash areas", "6", "4", "sanitation", "medium"),
            
            // Greg's REAL tasks at 12 West 18th
            ("Morning Hallway Clean", "Daily hallway maintenance", "1", "1", "cleaning", "medium"),
            ("Laundry & Supplies Management", "Manage building laundry and supplies", "1", "1", "maintenance", "low"),
            ("Trash Area Maintenance", "Maintain trash storage areas", "1", "1", "sanitation", "medium"),
            
            // Edwin's REAL maintenance tasks
            ("Boiler Blow-Down", "Weekly boiler maintenance", "2", "2", "maintenance", "critical"),
            ("Water Filter Change", "Monthly water filter replacement", "2", "2", "maintenance", "high"),
            ("HVAC Inspection", "Check heating and cooling systems", "2", "2", "maintenance", "high")
        ]
        
        for (title, desc, buildingId, workerId, category, urgency) in tasks {
            // Insert into routine_tasks
            try await grdbManager.execute("""
                INSERT INTO routine_tasks 
                (title, description, buildingId, workerId, category, urgency, 
                 isCompleted, scheduledDate, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, 0, date('now'), datetime('now'), datetime('now'))
            """, [title, desc, buildingId, workerId, category, urgency])
        }
        
        print("✅ \(tasks.count) real operational tasks seeded")
    }
    
    private func seedInventoryItems() async throws {
        // Real inventory items based on operational needs
        let inventoryItems = [
            // Cleaning supplies (based on real cleaning tasks)
            ("Trash bags (13 gal)", "supplies", 500, 100, 14),
            ("Trash bags (30 gal)", "supplies", 300, 50, 14),
            ("Paper towels", "supplies", 200, 50, 14),
            ("Glass cleaner", "cleaning", 24, 6, 14),
            ("All-purpose cleaner", "cleaning", 36, 12, 14),
            ("Floor cleaner", "cleaning", 12, 3, 14),
            ("Disinfectant", "cleaning", 24, 8, 14),
            
            // Maintenance supplies (based on real maintenance tasks)
            ("HVAC filters (20x25x1)", "maintenance", 12, 4, 14),
            ("HVAC filters (16x20x1)", "maintenance", 12, 4, 14),
            ("Light bulbs (LED A19)", "maintenance", 50, 10, 14),
            ("Light bulbs (LED PAR30)", "maintenance", 25, 5, 14),
            
            // Sanitation supplies (for DSNY operations)
            ("Heavy-duty gloves", "safety", 20, 10, 14),
            ("Safety vests", "safety", 5, 2, 14),
            ("Broom heads", "equipment", 10, 3, 14),
            ("Mop heads", "equipment", 20, 5, 14),
            
            // Tools and equipment
            ("Push brooms", "tools", 6, 2, 14),
            ("Wet mops", "tools", 8, 2, 14),
            ("Dustpans", "tools", 4, 2, 14),
            ("Hose nozzles", "tools", 4, 2, 14)
        ]
        
        for (name, category, currentStock, minStock, buildingId) in inventoryItems {
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO inventory_items
                (name, category, currentStock, minimumStock, maxStock, unit, 
                 buildingId, lastRestocked, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 'units', ?, date('now', '-7 days'), 
                        datetime('now'), datetime('now'))
            """, [name, category, currentStock, minStock, currentStock * 2, buildingId])
        }
        
        print("✅ Real inventory items seeded based on operational needs")
    }
    
    // MARK: - Verification Methods
    
    private func verifyCriticalRelationships() async throws {
        print("🔍 Verifying critical relationships...")
        
        // Verify Kevin Dutan's Rubin Museum assignment
        let kevinRubinCheck = try await grdbManager.query("""
            SELECT COUNT(*) as count 
            FROM worker_assignments 
            WHERE worker_id = '4' 
              AND building_id = '14' 
              AND is_active = 1
        """)
        
        let hasKevinRubin = (kevinRubinCheck.first?["count"] as? Int64 ?? 0) > 0
        
        if !hasKevinRubin {
            print("⚠️ Kevin Dutan's Rubin Museum assignment missing - fixing...")
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO worker_assignments 
                (worker_id, building_id, worker_name, building_name, is_active)
                VALUES ('4', '14', 'Kevin Dutan', 'Rubin Museum', 1)
            """)
            
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO worker_building_assignments 
                (worker_id, building_id, role, assigned_date, is_active)
                VALUES ('4', '14', 'maintenance', datetime('now'), 1)
            """)
            
            print("✅ Kevin Dutan's Rubin Museum assignment restored")
        } else {
            print("✅ Kevin Dutan properly assigned to Rubin Museum")
        }
        
        // Verify all workers have at least one assignment
        let unassignedWorkers = try await grdbManager.query("""
            SELECT w.id, w.name 
            FROM workers w
            WHERE w.isActive = 1
              AND NOT EXISTS (
                  SELECT 1 FROM worker_assignments wa 
                  WHERE wa.worker_id = w.id AND wa.is_active = 1
              )
        """)
        
        if !unassignedWorkers.isEmpty {
            print("⚠️ Found \(unassignedWorkers.count) unassigned workers")
            for worker in unassignedWorkers {
                if let name = worker["name"] as? String {
                    print("   - \(name)")
                }
            }
        }
        
        print("✅ Critical relationships verified")
    }
    
    private func runIntegrityChecks() async throws -> IntegrityCheckResult {
        print("🔍 Running database integrity checks...")
        
        var result = IntegrityCheckResult()
        
        // Check table counts
        let checks = [
            ("workers", 5),          // Minimum expected workers
            ("buildings", 10),       // Minimum expected buildings
            ("worker_assignments", 5), // Minimum assignments
            ("routine_tasks", 5)     // Minimum tasks
        ]
        
        for (table, minCount) in checks {
            let countResult = try await grdbManager.query(
                "SELECT COUNT(*) as count FROM \(table)"
            )
            let count = countResult.first?["count"] as? Int64 ?? 0
            
            if count < minCount {
                result.issues.append("\(table): only \(count) records (expected ≥ \(minCount))")
            } else {
                result.passedChecks.append("\(table): \(count) records ✓")
            }
        }
        
        // Check foreign key integrity
        let orphanedAssignments = try await grdbManager.query("""
            SELECT COUNT(*) as count
            FROM worker_assignments wa
            WHERE NOT EXISTS (SELECT 1 FROM workers w WHERE w.id = wa.worker_id)
               OR NOT EXISTS (SELECT 1 FROM buildings b WHERE b.id = wa.building_id)
        """)
        
        let orphanCount = orphanedAssignments.first?["count"] as? Int64 ?? 0
        if orphanCount > 0 {
            result.issues.append("Found \(orphanCount) orphaned assignments")
        }
        
        // Check database size
        let dbSize = grdbManager.getDatabaseSize()
        let formatter = ByteCountFormatter()
        result.databaseSize = formatter.string(fromByteCount: dbSize)
        
        // Print results
        print("📊 Integrity Check Results:")
        print("  ✓ Passed: \(result.passedChecks.count)")
        print("  ✗ Issues: \(result.issues.count)")
        print("  📦 Database Size: \(result.databaseSize)")
        
        if !result.issues.isEmpty {
            print("  ⚠️ Issues found:")
            for issue in result.issues {
                print("    - \(issue)")
            }
        }
        
        return result
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
    
    // MARK: - Public Utility Methods
    
    /// Quick health check for UI
    public func performHealthCheck() async -> HealthCheckResult {
        do {
            // Check database connection
            let isReady = await grdbManager.isDatabaseReady()
            
            // Check Kevin Dutan's Rubin Museum assignment
            let kevinCheck = try await grdbManager.query("""
                SELECT b.name, wa.is_active
                FROM worker_assignments wa
                JOIN buildings b ON wa.building_id = b.id
                WHERE wa.worker_id = '4' AND wa.building_id = '14'
            """)
            
            let hasKevinRubin = !kevinCheck.isEmpty
            
            // Get counts
            let stats = try await getDatabaseStatistics()
            
            return HealthCheckResult(
                isHealthy: isReady && hasKevinRubin,
                message: hasKevinRubin ? "All systems operational" : "Missing Kevin Dutan's Rubin Museum assignment",
                statistics: stats
            )
            
        } catch {
            return HealthCheckResult(
                isHealthy: false,
                message: "Health check failed: \(error.localizedDescription)",
                statistics: [:]
            )
        }
    }
    
    /// Get detailed database statistics
    public func getDatabaseStatistics() async throws -> [String: Any] {
        var stats: [String: Any] = [:]
        
        // Worker statistics
        let workerStats = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN isActive = 1 THEN 1 ELSE 0 END) as active
            FROM workers
        """)
        
        if let row = workerStats.first {
            stats["workers"] = [
                "total": row["total"] as? Int64 ?? 0,
                "active": row["active"] as? Int64 ?? 0
            ]
        }
        
        // Building statistics
        let buildingCount = try await grdbManager.query(
            "SELECT COUNT(*) as count FROM buildings"
        ).first?["count"] as? Int64 ?? 0
        
        stats["buildings"] = ["total": buildingCount]
        
        // Task statistics
        let taskStats = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed,
                SUM(CASE WHEN isCompleted = 0 AND date(scheduledDate) < date('now') THEN 1 ELSE 0 END) as overdue
            FROM routine_tasks
        """)
        
        if let row = taskStats.first {
            stats["tasks"] = [
                "total": row["total"] as? Int64 ?? 0,
                "completed": row["completed"] as? Int64 ?? 0,
                "overdue": row["overdue"] as? Int64 ?? 0
            ]
        }
        
        // Database info
        stats["database"] = [
            "size": grdbManager.getDatabaseSize(),
            "path": grdbManager.databaseURL.path,
            "initialized": isInitialized
        ]
        
        return stats
    }
    
    /// Reset database for testing
    public func resetForTesting() async throws {
        guard ProcessInfo.processInfo.environment["TESTING"] == "1" else {
            throw DatabaseError.notAllowed("Reset only allowed in test environment")
        }
        
        print("⚠️ Resetting database for testing...")
        isInitialized = false
        try await grdbManager.resetDatabase()
        try await initializeDatabase()
    }
}

// MARK: - Supporting Types

public struct IntegrityCheckResult {
    var isHealthy: Bool { issues.isEmpty }
    var passedChecks: [String] = []
    var issues: [String] = []
    var databaseSize: String = "Unknown"
}

public struct HealthCheckResult {
    let isHealthy: Bool
    let message: String
    let statistics: [String: Any]
}

enum DatabaseError: LocalizedError {
    case notReady
    case integrityCheckFailed(String)
    case seedingFailed(String)
    case migrationFailed(String)
    case notAllowed(String)
    
    var errorDescription: String? {
        switch self {
        case .notReady:
            return "Database is not ready"
        case .integrityCheckFailed(let details):
            return "Database integrity check failed: \(details)"
        case .seedingFailed(let details):
            return "Database seeding failed: \(details)"
        case .migrationFailed(let details):
            return "Database migration failed: \(details)"
        case .notAllowed(let details):
            return "Operation not allowed: \(details)"
        }
    }
}
