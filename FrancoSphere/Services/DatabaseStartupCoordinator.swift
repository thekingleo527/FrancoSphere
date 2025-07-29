//
//  DatabaseStartupCoordinator.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: Uses only public GRDBManager methods
//  ✅ REFACTORED: Works with existing database architecture
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
        
        print("🚀 Starting consolidated database initialization...")
        
        do {
            // Step 1: Ensure database is ready
            guard await grdbManager.isDatabaseReady() else {
                throw StartupError.databaseNotReady
            }
            
            // Step 2: Create all tables (tables are created in GRDBManager.init)
            // Additional tables that might not be in GRDBManager
            try await createAdditionalTables()
            
            // Step 3: Run migrations if needed
            try await runMigrationsIfNeeded()
            
            // Step 4: Seed authentication data
            try await seedAuthenticationData()
            
            // Step 5: Seed operational data if empty
            try await seedOperationalDataIfNeeded()
            
            // Step 6: Verify critical relationships
            try await verifyCriticalRelationships()
            
            // Step 7: Run integrity checks
            let integrity = try await runIntegrityChecks()
            guard integrity.isHealthy else {
                throw StartupError.integrityCheckFailed(integrity.issues.joined(separator: ", "))
            }
            
            isInitialized = true
            print("✅ Consolidated database initialization complete")
            
        } catch {
            print("❌ Database initialization failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Additional Table Creation
    
    private func createAdditionalTables() async throws {
        print("🔧 Creating additional operational tables...")
        
        // Task templates for recurring tasks
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS task_templates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                category TEXT NOT NULL,
                default_urgency TEXT NOT NULL,
                estimated_duration_minutes INTEGER,
                skill_level TEXT DEFAULT 'Basic',
                recurrence TEXT DEFAULT 'daily',
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(name, category)
            )
        """)
        
        // Worker task assignments
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS worker_task_templates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                task_template_id INTEGER NOT NULL,
                start_time TEXT,
                end_time TEXT,
                days_of_week TEXT DEFAULT 'weekdays',
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (task_template_id) REFERENCES task_templates(id),
                UNIQUE(worker_id, building_id, task_template_id)
            )
        """)
        
        // Building metrics cache
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS building_metrics_cache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                building_id TEXT NOT NULL UNIQUE,
                completion_rate REAL DEFAULT 0.0,
                average_task_time REAL DEFAULT 0.0,
                overdue_tasks INTEGER DEFAULT 0,
                total_tasks INTEGER DEFAULT 0,
                active_workers INTEGER DEFAULT 0,
                last_updated TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        print("✅ Additional operational tables created")
    }
    
    // MARK: - Authentication Data Seeding
    
    private func seedAuthenticationData() async throws {
        print("🔐 Checking authentication data...")
        
        // Check if we already have workers
        let workerCountResult = try await grdbManager.query(
            "SELECT COUNT(*) as count FROM workers"
        )
        let workerCount = workerCountResult.first?["count"] as? Int64 ?? 0
        
        if workerCount == 0 {
            print("📝 Seeding authentication data...")
            
            // Real worker authentication data
            let realWorkers: [(String, String, String, String, String, String?, Double)] = [
                // (id, name, email, password, role, phone, hourlyRate)
                ("1", "Greg Hutson", "g.hutson1989@gmail.com", "password", "worker", "917-555-0001", 28.0),
                ("2", "Edwin Lema", "edwinlema911@gmail.com", "password", "worker", "917-555-0002", 26.0),
                ("4", "Kevin Dutan", "dutankevin1@gmail.com", "password", "worker", "917-555-0004", 25.0),
                ("5", "Mercedes Inamagua", "jneola@gmail.com", "password", "worker", "917-555-0005", 27.0),
                ("6", "Luis Lopez", "luislopez030@yahoo.com", "password", "worker", "917-555-0006", 25.0),
                ("7", "Angel Guirachocha", "lio.angel71@gmail.com", "password", "worker", "917-555-0007", 26.0),
                ("8", "Shawn Magloire", "shawn@francomanagementgroup.com", "password", "admin", "917-555-0008", 45.0),
                
                // Additional accounts for multiple roles
                ("9", "Shawn Magloire", "francosphere@francomanagementgroup.com", "password", "client", "917-555-0008", 45.0),
                ("10", "Shawn Magloire", "shawn@fme-llc.com", "password", "admin", "917-555-0008", 45.0),
                
                // Test accounts
                ("100", "Test Worker", "test@franco.com", "password", "worker", "917-555-0100", 25.0),
                ("101", "Test Admin", "admin@franco.com", "password", "admin", "917-555-0101", 35.0),
                ("102", "Test Client", "client@franco.com", "password", "client", "917-555-0102", 30.0)
            ]
            
            for (id, name, email, password, role, phone, rate) in realWorkers {
                try await grdbManager.execute("""
                    INSERT OR REPLACE INTO workers 
                    (id, name, email, password, role, phone, hourlyRate, isActive, 
                     skills, timezone, notification_preferences, created_at, updated_at) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, 'America/New_York', '{}', datetime('now'), datetime('now'))
                """, [id, name, email, password, role, phone ?? "", rate, getDefaultSkills(for: role)])
            }
            
            print("✅ Seeded \(realWorkers.count) workers with authentication")
        } else {
            print("✅ Workers already exist (\(workerCount) workers)")
        }
    }
    
    // MARK: - Operational Data Seeding
    
    private func seedOperationalDataIfNeeded() async throws {
        print("🌱 Checking operational data...")
        
        // Check if we have buildings
        let buildingCountResult = try await grdbManager.query(
            "SELECT COUNT(*) as count FROM buildings"
        )
        let buildingCount = buildingCountResult.first?["count"] as? Int64 ?? 0
        
        if buildingCount == 0 {
            print("📝 Seeding operational data...")
            
            try await seedBuildings()
            try await seedWorkerAssignments()
            try await seedSampleTasks()
            try await seedInventoryItems()
            
            print("✅ Operational data seeded")
        } else {
            print("✅ Operational data exists (\(buildingCount) buildings)")
        }
    }
    
    private func seedBuildings() async throws {
        let buildings = [
            // Primary buildings from OperationalDataManager
            ("14", "Rubin Museum", "150 W 17th St, New York, NY 10011", 40.7402, -73.9979, "rubin_museum"),
            ("1", "12 West 18th Street", "12 W 18th St, New York, NY 10011", 40.7391, -73.9929, "building_12w18"),
            ("2", "29-31 East 20th Street", "29-31 E 20th St, New York, NY 10003", 40.7380, -73.9890, "building_29e20"),
            ("3", "133 East 15th Street", "133 E 15th St, New York, NY 10003", 40.7343, -73.9859, "building_133e15"),
            ("4", "104 Franklin Street", "104 Franklin St, New York, NY 10013", 40.7190, -74.0089, "building_104franklin"),
            ("5", "36 Walker Street", "36 Walker St, New York, NY 10013", 40.7173, -74.0027, "building_36walker"),
            ("6", "68 Perry Street", "68 Perry St, New York, NY 10014", 40.7355, -74.0067, "building_68perry"),
            ("7", "136 W 17th Street", "136 W 17th St, New York, NY 10011", 40.7402, -73.9975, "building_136w17"),
            ("8", "41 Elizabeth Street", "41 Elizabeth St, New York, NY 10013", 40.7178, -73.9962, "building_41elizabeth"),
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
                (id, name, address, latitude, longitude, imageAssetName, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
            """, [id, name, address, lat, lng, imageAsset])
        }
        
        print("✅ \(buildings.count) buildings seeded")
    }
    
    private func seedWorkerAssignments() async throws {
        // Real assignments from OperationalDataManager
        let assignments = [
            // Kevin Dutan (ID: 4) - Primary at Rubin Museum
            ("4", "14", "maintenance"),    // Rubin Museum - PRIMARY
            ("4", "11", "maintenance"),    // 131 Perry Street
            ("4", "6", "maintenance"),     // 68 Perry Street
            
            // Greg Hutson (ID: 1)
            ("1", "1", "cleaning"),        // 12 West 18th Street - PRIMARY
            
            // Edwin Lema (ID: 2)
            ("2", "2", "maintenance"),     // 29-31 East 20th Street - PRIMARY
            ("2", "5", "maintenance"),     // 36 Walker Street
            
            // Mercedes Inamagua (ID: 5)
            ("5", "9", "cleaning"),        // 117 West 17th Street - PRIMARY
            
            // Luis Lopez (ID: 6)
            ("6", "4", "maintenance"),     // 104 Franklin Street - PRIMARY
            
            // Angel Guirachocha (ID: 7)
            ("7", "1", "sanitation"),      // 12 West 18th Street - PRIMARY
        ]
        
        for (workerId, buildingId, role) in assignments {
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO worker_building_assignments 
                (worker_id, building_id, role, assigned_date, is_active)
                VALUES (?, ?, ?, datetime('now'), 1)
            """, [workerId, buildingId, role])
        }
        
        print("✅ Worker assignments seeded")
    }
    
    private func seedSampleTasks() async throws {
        // Real tasks from operational data
        let tasks = [
            // Kevin's Rubin Museum tasks
            ("Trash Area + Sidewalk & Curb Clean", "Daily trash area and sidewalk maintenance", "14", "4", "sanitation", "medium"),
            ("Museum Entrance Sweep", "Daily entrance cleaning", "14", "4", "cleaning", "medium"),
            
            // Greg's 12 West 18th tasks
            ("Morning Hallway Clean", "Daily hallway maintenance", "1", "1", "cleaning", "medium"),
            ("Laundry & Supplies Management", "Manage building laundry and supplies", "1", "1", "maintenance", "low"),
            
            // Edwin's maintenance tasks
            ("Boiler Blow-Down", "Weekly boiler maintenance", "2", "2", "maintenance", "critical"),
            ("HVAC Inspection", "Check heating and cooling systems", "2", "2", "maintenance", "high")
        ]
        
        for (title, desc, buildingId, workerId, category, urgency) in tasks {
            try await grdbManager.execute("""
                INSERT INTO routine_tasks 
                (title, description, buildingId, workerId, category, urgency, 
                 isCompleted, scheduledDate, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, 0, date('now'), datetime('now'), datetime('now'))
            """, [title, desc, buildingId, workerId, category, urgency])
        }
        
        print("✅ Sample tasks seeded")
    }
    
    private func seedInventoryItems() async throws {
        let inventoryItems = [
            ("Trash bags (13 gal)", "supplies", 500, 100, 14),
            ("Paper towels", "supplies", 200, 50, 14),
            ("Glass cleaner", "cleaning", 24, 6, 14),
            ("HVAC filters (20x25x1)", "maintenance", 12, 4, 14)
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
        
        print("✅ Inventory items seeded")
    }
    
    // MARK: - Migration Management
    
    private func runMigrationsIfNeeded() async throws {
        print("🔄 Checking for pending migrations...")
        
        // Create migrations table if needed
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // For now, we don't have any migrations to run
        // This is where future schema updates would go
        
        print("✅ Migrations complete")
    }
    
    // MARK: - Verification Methods
    
    private func verifyCriticalRelationships() async throws {
        print("🔍 Verifying critical relationships...")
        
        // Verify Kevin Dutan's Rubin Museum assignment
        let kevinRubinCheck = try await grdbManager.query("""
            SELECT COUNT(*) as count 
            FROM worker_building_assignments 
            WHERE worker_id = '4' AND building_id = '14' AND is_active = 1
        """)
        
        let hasKevinRubin = (kevinRubinCheck.first?["count"] as? Int64 ?? 0) > 0
        
        if !hasKevinRubin {
            print("⚠️ Creating Kevin Dutan's Rubin Museum assignment...")
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO worker_building_assignments 
                (worker_id, building_id, role, assigned_date, is_active)
                VALUES ('4', '14', 'maintenance', datetime('now'), 1)
            """)
            
            print("✅ Kevin Dutan's Rubin Museum assignment created")
        }
        
        print("✅ Critical relationships verified")
    }
    
    private func runIntegrityChecks() async throws -> IntegrityCheckResult {
        print("🔍 Running integrity checks...")
        
        var result = IntegrityCheckResult()
        
        // Check table counts
        let checks = [
            ("workers", 7),          // Minimum real workers
            ("buildings", 10),       // Minimum buildings
            ("worker_building_assignments", 5), // Minimum assignments
            ("routine_tasks", 0)     // Tasks can be empty
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
        
        print("📊 Integrity check: \(result.passedChecks.count) passed, \(result.issues.count) issues")
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func tableExists(_ tableName: String) async throws -> Bool {
        let result = try await grdbManager.query("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name=?
        """, [tableName])
        return !result.isEmpty
    }
    
    private func getDefaultSkills(for role: String) -> String {
        switch role {
        case "admin":
            return "Management,Scheduling,Reporting,Quality Control"
        case "client":
            return "Property Management,Communication"
        default:
            return "General Maintenance,Cleaning,Basic Repairs,Safety Protocols"
        }
    }
    
    // MARK: - Public Utility Methods
    
    public func performHealthCheck() async -> HealthCheckResult {
        do {
            let isReady = await grdbManager.isDatabaseReady()
            let stats = try await getDatabaseStatistics()
            
            return HealthCheckResult(
                isHealthy: isReady && isInitialized,
                message: isInitialized ? "All systems operational" : "Database not initialized",
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
        
        // Authentication statistics
        let authStats = try await grdbManager.getAuthenticationStats()
        stats["authentication"] = authStats
        
        // Building statistics
        let buildingStats = try await grdbManager.query("""
            SELECT COUNT(*) as total FROM buildings
        """)
        
        if let row = buildingStats.first {
            stats["buildings"] = [
                "total": row["total"] as? Int64 ?? 0
            ]
        }
        
        // Task statistics
        let taskStats = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed
            FROM routine_tasks
        """)
        
        if let row = taskStats.first {
            stats["tasks"] = [
                "total": row["total"] as? Int64 ?? 0,
                "completed": row["completed"] as? Int64 ?? 0
            ]
        }
        
        // Database info
        let isDatabaseReady = await grdbManager.isDatabaseReady()
        stats["database"] = [
            "initialized": isInitialized,
            "ready": isDatabaseReady,
            "size": grdbManager.getDatabaseSize()
        ]
        
        return stats
    }
    
    /// Reset and reinitialize the database (for testing)
    public func resetAndReinitialize() async throws {
        print("⚠️ Resetting database...")
        
        // Reset the database
        try await grdbManager.resetDatabase()
        
        // Reset initialization flag
        isInitialized = false
        
        // Reinitialize
        try await initializeDatabase()
        
        print("✅ Database reset and reinitialized")
    }
}

// MARK: - Supporting Types

public struct IntegrityCheckResult {
    var isHealthy: Bool { issues.isEmpty }
    var passedChecks: [String] = []
    var issues: [String] = []
}

public struct HealthCheckResult {
    let isHealthy: Bool
    let message: String
    let statistics: [String: Any]
}

// Use specific error type to avoid conflicts
enum StartupError: LocalizedError {
    case databaseNotReady
    case integrityCheckFailed(String)
    case seedingFailed(String)
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .databaseNotReady:
            return "Database is not ready"
        case .integrityCheckFailed(let details):
            return "Database integrity check failed: \(details)"
        case .seedingFailed(let details):
            return "Database seeding failed: \(details)"
        case .migrationFailed(let details):
            return "Database migration failed: \(details)"
        }
    }
}
