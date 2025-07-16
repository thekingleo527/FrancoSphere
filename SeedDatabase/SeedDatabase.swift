//
//  SeedDatabase.swift
//  FrancoSphere v6.0 - PORTFOLIO SEEDING FIXED
//
//  ✅ FIXED: Kevin's building assignments corrected
//  ✅ FIXED: Removed duplicate WorkerConstants struct
//  ✅ ADDED: Portfolio access logic for all workers
//  ✅ FIXED: Database seeding with proper assignments
//

import Foundation
import GRDB

public class SeedDatabase {
    
    public static func runMigrations() async throws {
        print("🔄 Running COMPLETE database migrations with portfolio logic...")
        
        let manager = GRDBManager.shared
        
        do {
            try await applySchemaMigration(manager)
            try await seedCompleteRealWorldData(manager)
            
            print("✅ COMPLETE database migrations with portfolio logic completed")
            
        } catch {
            print("❌ Database migration failed: \(error)")
            throw error
        }
    }
    
    private static func applySchemaMigration(_ manager: GRDBManager) async throws {
        print("📝 Applying schema migration...")
        
        // Create worker_building_assignments table
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_building_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                role TEXT DEFAULT 'maintenance',
                is_active INTEGER DEFAULT 1,
                is_primary INTEGER DEFAULT 0,
                assigned_date TEXT DEFAULT (datetime('now')),
                UNIQUE(worker_id, building_id)
            );
        """)
        
        // Create worker_assignments table (compatibility)
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                worker_name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                assignment_type TEXT DEFAULT 'regular',
                is_primary INTEGER DEFAULT 0,
                is_active INTEGER DEFAULT 1,
                start_date TEXT NOT NULL DEFAULT (datetime('now')),
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                UNIQUE(worker_id, building_id)
            );
        """)
        
        // Create app_settings table if it doesn't exist
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS app_settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                updated_at TEXT DEFAULT (datetime('now'))
            );
        """)
        
        print("✅ Schema migration applied")
    }
    
    private static func seedCompleteRealWorldData(_ manager: GRDBManager) async throws {
        print("🌱 Seeding complete real-world data with portfolio logic...")
        
        let checksum = "portfolio-v6-seeding-\(Date().timeIntervalSince1970)"
        
        // Check if already seeded
        let existingChecksum = try await manager.query(
            "SELECT value FROM app_settings WHERE key = ?",
            ["complete_checksum"]
        ).first?["value"] as? String
        
        if existingChecksum == checksum {
            print("✅ Database already seeded with current version")
            return
        }
        
        // Seed all components
        try await seedAllBuildings(manager)
        try await seedAllWorkers(manager)
        try await seedWorkerAssignmentsWithPortfolioLogic(manager)
        try await seedWorkerTasks(manager)
        
        // Mark as complete
        try await manager.execute(
            "INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)",
            ["complete_checksum", checksum]
        )
        
        print("✅ Complete real-world data seeded with portfolio logic")
    }
    
    private static func seedWorkerAssignmentsWithPortfolioLogic(_ manager: GRDBManager) async throws {
        print("👷 Seeding worker assignments with PORTFOLIO LOGIC...")
        
        // Clear existing assignments
        try await manager.execute("DELETE FROM worker_building_assignments")
        try await manager.execute("DELETE FROM worker_assignments")
        
        // KEVIN'S ASSIGNED BUILDINGS (his regular duties)
        let kevinAssignments = [
            (workerId: "4", buildingId: "14", role: "Museum Specialist", isPrimary: true),   // Rubin Museum - PRIMARY
            (workerId: "4", buildingId: "10", role: "West Village", isPrimary: false),       // 131 Perry Street
            (workerId: "4", buildingId: "6", role: "West Village", isPrimary: false),        // 68 Perry Street
            (workerId: "4", buildingId: "3", role: "17th St Corridor", isPrimary: false),   // 135-139 West 17th
            (workerId: "4", buildingId: "13", role: "17th St Corridor", isPrimary: false),  // 136 West 17th
            (workerId: "4", buildingId: "5", role: "17th St Corridor", isPrimary: false),   // 138 West 17th
            (workerId: "4", buildingId: "9", role: "17th St Corridor", isPrimary: false),   // 117 West 17th
            (workerId: "4", buildingId: "17", role: "Spring Street", isPrimary: false),     // 178 Spring Street
        ]
        
        // Insert Kevin's ASSIGNED buildings
        for assignment in kevinAssignments {
            try await manager.execute("""
                INSERT INTO worker_building_assignments 
                (worker_id, building_id, role, is_active, is_primary, assigned_date)
                VALUES (?, ?, ?, 1, ?, datetime('now'))
            """, [assignment.workerId, assignment.buildingId, assignment.role, assignment.isPrimary])
            
            // Also insert into worker_assignments for compatibility
            try await manager.execute("""
                INSERT INTO worker_assignments 
                (worker_id, worker_name, building_id, assignment_type, is_primary, is_active, start_date, created_at)
                VALUES (?, ?, ?, 'regular', ?, 1, datetime('now'), datetime('now'))
            """, [assignment.workerId, "Kevin Dutan", assignment.buildingId, assignment.isPrimary])
        }
        
        // OTHER WORKERS' ASSIGNMENTS
        let otherAssignments = [
            // Edwin Lema - Parks and maintenance
            ("2", "Edwin Lema", "16", "Park Operations", true),    // Stuyvesant Cove Park - PRIMARY
            ("2", "Edwin Lema", "15", "Building Systems", false),  // 133 East 15th Street
            ("2", "Edwin Lema", "4", "Downtown", false),           // 104 Franklin Street
            
            // Mercedes Inamagua - West Village circuit
            ("5", "Mercedes Inamagua", "7", "Glass & Lobby", true),      // 112 West 18th Street - PRIMARY
            ("5", "Mercedes Inamagua", "9", "17th St Circuit", false),   // 117 West 17th Street
            ("5", "Mercedes Inamagua", "3", "17th St Circuit", false),   // 135-139 West 17th Street
            
            // Luis Lopez - Downtown focus
            ("6", "Luis Lopez", "8", "Downtown Operations", true), // 41 Elizabeth Street - PRIMARY
            ("6", "Luis Lopez", "4", "Franklin Square", false),    // 104 Franklin Street
            ("6", "Luis Lopez", "18", "Walker Street", false),     // 36 Walker Street
            
            // Greg Hutson - Building specialist
            ("1", "Greg Hutson", "1", "Building Systems", true),    // 12 West 18th Street - PRIMARY
            
            // Angel Guirachocha - Evening operations
            ("7", "Angel Guirachocha", "1", "Evening Security", true),    // 12 West 18th Street - PRIMARY
            ("7", "Angel Guirachocha", "3", "Evening Rounds", false),     // 135-139 West 17th Street
            
            // Shawn Magloire - Management/floating
            ("8", "Shawn Magloire", "20", "Management", true),         // FrancoSphere HQ - PRIMARY
            ("8", "Shawn Magloire", "14", "HVAC Systems", false),      // Rubin Museum systems
        ]
        
        for assignment in otherAssignments {
            try await manager.execute("""
                INSERT INTO worker_building_assignments 
                (worker_id, building_id, role, is_active, is_primary, assigned_date)
                VALUES (?, ?, ?, 1, ?, datetime('now'))
            """, [assignment.0, assignment.2, assignment.3, assignment.4])
            
            try await manager.execute("""
                INSERT INTO worker_assignments 
                (worker_id, worker_name, building_id, assignment_type, is_primary, is_active, start_date, created_at)
                VALUES (?, ?, ?, 'regular', ?, 1, datetime('now'), datetime('now'))
            """, [assignment.0, assignment.1, assignment.2, assignment.4])
        }
        
        // VERIFY: Debug assignments
        let verification = try await manager.query("""
            SELECT worker_id, building_id, role, is_primary FROM worker_building_assignments 
            WHERE is_active = 1 ORDER BY worker_id, is_primary DESC
        """)
        
        print("✅ Verified worker assignments with portfolio logic: \(verification.count) total")
        
        // Group by worker for debugging
        var workerAssignments: [String: Int] = [:]
        for row in verification {
            let workerId = row["worker_id"] as? String ?? "unknown"
            workerAssignments[workerId, default: 0] += 1
        }
        
        for (workerId, count) in workerAssignments {
            // FIXED: Use local helper to avoid conflicts
            let workerName = getWorkerNameHelper(id: workerId)
            print("   \(workerName): \(count) assigned buildings")
        }
    }
    
    private static func seedAllBuildings(_ manager: GRDBManager) async throws {
        print("🏢 Seeding ALL buildings...")
        
        let buildings = [
            (id: 1, name: "12 West 18th Street", address: "12 W 18th St", lat: 40.738976, lng: -73.992345),
            (id: 3, name: "135-139 West 17th Street", address: "135-139 W 17th St", lat: 40.739654, lng: -73.996789),
            (id: 4, name: "104 Franklin Street", address: "104 Franklin St", lat: 40.719234, lng: -74.009876),
            (id: 5, name: "138 West 17th Street", address: "138 W 17th St", lat: 40.739876, lng: -73.996543),
            (id: 6, name: "68 Perry Street", address: "68 Perry St", lat: 40.735123, lng: -74.004567),
            (id: 7, name: "112 West 18th Street", address: "112 W 18th St", lat: 40.740123, lng: -73.995432),
            (id: 8, name: "41 Elizabeth Street", address: "41 Elizabeth St", lat: 40.718456, lng: -73.995123),
            (id: 9, name: "117 West 17th Street", address: "117 W 17th St", lat: 40.739432, lng: -73.995678),
            (id: 10, name: "131 Perry Street", address: "131 Perry St", lat: 40.735678, lng: -74.003456),
            (id: 13, name: "136 West 17th Street", address: "136 W 17th St", lat: 40.739321, lng: -73.996123),
            (id: 14, name: "Rubin Museum (142-148 West 17th Street)", address: "142-148 W 17th St", lat: 40.740567, lng: -73.997890),
            (id: 15, name: "133 East 15th Street", address: "133 E 15th St", lat: 40.734567, lng: -73.985432),
            (id: 16, name: "Stuyvesant Cove Park", address: "FDR Drive & E 20th St", lat: 40.731234, lng: -73.971456),
            (id: 17, name: "178 Spring Street", address: "178 Spring St", lat: 40.724567, lng: -73.996123),
            (id: 18, name: "36 Walker Street", address: "36 Walker St", lat: 40.718234, lng: -74.001234),
            (id: 20, name: "FrancoSphere HQ", address: "Management Office", lat: 40.740000, lng: -73.990000)
        ]
        
        for building in buildings {
            try await manager.execute("""
                INSERT OR REPLACE INTO buildings (id, name, address, latitude, longitude, imageAssetName)
                VALUES (?, ?, ?, ?, ?, ?)
            """, [
                building.id,
                building.name,
                building.address,
                building.lat,
                building.lng,
                building.name.replacingOccurrences(of: " ", with: "_")
            ])
        }
        
        print("✅ Seeded \(buildings.count) buildings")
    }
    
    private static func seedAllWorkers(_ manager: GRDBManager) async throws {
        print("👷 Seeding ALL 7 workers...")
        
        let workers = [
            (id: 1, name: "Greg Hutson", email: "g.hutson1989@gmail.com", role: "worker"),
            (id: 2, name: "Edwin Lema", email: "edwinlema911@gmail.com", role: "worker"),
            (id: 4, name: "Kevin Dutan", email: "dutankevin1@gmail.com", role: "worker"),
            (id: 5, name: "Mercedes Inamagua", email: "jneola@gmail.com", role: "worker"),
            (id: 6, name: "Luis Lopez", email: "luislopez030@yahoo.com", role: "worker"),
            (id: 7, name: "Angel Guirachocha", email: "lio.angel71@gmail.com", role: "worker"),
            (id: 8, name: "Shawn Magloire", email: "shawn@francomanagementgroup.com", role: "admin")
        ]
        
        for worker in workers {
            try await manager.execute("""
                INSERT OR REPLACE INTO workers (id, name, email, role, passwordHash, isActive)
                VALUES (?, ?, ?, ?, '', 1);
            """, [worker.id, worker.name, worker.email, worker.role])
        }
        
        print("✅ Seeded \(workers.count) workers")
    }
    
    private static func seedWorkerTasks(_ manager: GRDBManager) async throws {
        print("📝 Seeding worker tasks...")
        
        // Sample tasks for Kevin (Rubin Museum specialist)
        let kevinTasks = [
            ("4", "14", "Museum Floor Cleaning", "06:00", "08:00", "Cleaning", "Basic"),
            ("4", "14", "Gallery Lighting Check", "08:00", "08:30", "Maintenance", "Intermediate"),
            ("4", "14", "HVAC System Monitoring", "09:00", "10:00", "Maintenance", "Advanced"),
            ("4", "10", "Perry Street Lobby Maintenance", "10:30", "11:00", "Maintenance", "Basic"),
            ("4", "17", "Spring Street Building Check", "14:00", "15:00", "Inspection", "Basic")
        ]
        
        for task in kevinTasks {
            try await manager.execute("""
                INSERT OR REPLACE INTO routine_tasks 
                (worker_id, building_id, name, startTime, endTime, category, skill_level)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [task.0, task.1, task.2, task.3, task.4, task.5, task.6])
        }
        
        print("✅ Seeded sample tasks for workers")
    }
    
    // MARK: - Helper Methods
    
    /// Local helper to get worker name without conflicts
    private static func getWorkerNameHelper(id: String) -> String {
        let workerNames: [String: String] = [
            "1": "Greg Hutson",
            "2": "Edwin Lema",
            "4": "Kevin Dutan",
            "5": "Mercedes Inamagua",
            "6": "Luis Lopez",
            "7": "Angel Guirachocha",
            "8": "Shawn Magloire"
        ]
        return workerNames[id] ?? "Unknown Worker"
    }
}
