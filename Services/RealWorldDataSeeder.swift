// RealWorldDataSeeder.swift - FINAL SCHEMA FIX
// Handles existing table schema properly

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SQLite
// FrancoSphere Types Import
// (This comment helps identify our import)


@MainActor
class RealWorldDataSeeder {
    static let shared = RealWorldDataSeeder()
    
    private init() {}
    
    // Main seeding function
    static func seedAllRealData(_ manager: SQLiteManager) async throws {
        // Update existing tables first
        try await updateExistingTables(manager)
        
        // Check if already seeded
        let checksum = "edwin_schema_final_v1"
        let existing = try await manager.query("SELECT value FROM app_settings WHERE key = ?", ["data_checksum"])
        if !existing.isEmpty && existing.first?["value"] as? String == checksum {
            print("✅ Real world data already seeded")
            return
        }
        
        print("🌱 Starting real world data seeding with FINAL SCHEMA FIX...")
        
        // Use transaction for speed
        try await manager.execute("BEGIN TRANSACTION")
        
        do {
            // 1. Seed Edwin's 8 buildings with exact coordinates
            try await seedEdwinBuildings(manager)
            
            // 2. Seed all 7 workers with FIXED IDs
            try await seedAllWorkers(manager)
            
            // 3. Seed Edwin's assignments using existing schema
            try await seedEdwinAssignments(manager)
            
            // 4. Seed basic tasks for Edwin
            try await seedEdwinTasks(manager)
            
            // Mark as complete
            try await manager.execute(
                "INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)",
                ["data_checksum", checksum]
            )
            
            try await manager.execute("COMMIT")
            print("✅ Real world data seeding completed successfully with FINAL SCHEMA!")
            
        } catch {
            try await manager.execute("ROLLBACK")
            print("❌ Real world data seeding failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Update Existing Tables
    
    private static func updateExistingTables(_ manager: SQLiteManager) async throws {
        print("🔧 Updating existing database tables...")
        
        // Create app_settings table if it doesn't exist
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS app_settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        // Check if worker_assignments table exists and what columns it has
        let tableInfo = try await manager.query("PRAGMA table_info(worker_assignments)")
        let existingColumns = Set(tableInfo.compactMap { $0["name"] as? String })
        
        print("📋 Existing worker_assignments columns: \(existingColumns)")
        
        // Add missing columns to worker_assignments table
        if !existingColumns.contains("is_primary") {
            try await manager.execute("ALTER TABLE worker_assignments ADD COLUMN is_primary INTEGER DEFAULT 0")
            print("✅ Added is_primary column to worker_assignments")
        }
        
        if !existingColumns.contains("is_active") {
            try await manager.execute("ALTER TABLE worker_assignments ADD COLUMN is_active INTEGER DEFAULT 1")
            print("✅ Added is_active column to worker_assignments")
        }
        
        if !existingColumns.contains("start_date") {
            try await manager.execute("ALTER TABLE worker_assignments ADD COLUMN start_date TEXT DEFAULT CURRENT_TIMESTAMP")
            print("✅ Added start_date column to worker_assignments")
        }
        
        // Create routine_tasks table
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS routine_tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                task_name TEXT NOT NULL,
                recurrence TEXT DEFAULT 'daily',
                start_time TEXT,
                end_time TEXT,
                skill_level TEXT DEFAULT 'Basic',
                category TEXT DEFAULT 'Maintenance',
                is_active INTEGER DEFAULT 1,
                external_id TEXT UNIQUE,
                default_time TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        print("✅ Database schema updated successfully")
    }
    
    // MARK: - Building Seeding (unchanged)
    
    private static func seedEdwinBuildings(_ manager: SQLiteManager) async throws {
        print("🏢 Seeding Edwin's buildings...")
        
        let edwinBuildings = [
            (id: 1, name: "12 West 18th Street", address: "12 W 18th St", lat: 40.738976, lng: -73.992345),
            (id: 4, name: "131 Perry Street", address: "131 Perry St", lat: 40.735678, lng: -74.003456),
            (id: 8, name: "138 West 17th Street", address: "138 W 17th St", lat: 40.739876, lng: -73.996543),
            (id: 10, name: "135-139 West 17th Street", address: "135-139 W 17th St", lat: 40.739654, lng: -73.996789),
            (id: 12, name: "117 West 17th Street", address: "117 W 17th St", lat: 40.739432, lng: -73.995678),
            (id: 15, name: "112 West 18th Street", address: "112 W 18th St", lat: 40.740123, lng: -73.995432),
            (id: 16, name: "133 East 15th Street", address: "133 E 15th St", lat: 40.734567, lng: -73.985432),
            (id: 17, name: "Stuyvesant Cove Park", address: "FDR Drive & E 20th St", lat: 40.731234, lng: -73.971456)
        ]
        
        for building in edwinBuildings {
            try await manager.execute("""
                INSERT OR REPLACE INTO buildings (id, name, address, latitude, longitude, imageAssetName)
                VALUES (?, ?, ?, ?, ?, ?);
            """, [
                building.id,
                building.name,
                building.address,
                building.lat,
                building.lng,
                building.name.replacingOccurrences(of: " ", with: "_")
            ])
        }
        
        print("✅ Seeded \(edwinBuildings.count) buildings for Edwin")
    }
    
    // MARK: - Worker Seeding - FIXED IDs
    
    private static func seedAllWorkers(_ manager: SQLiteManager) async throws {
        print("👷 Seeding all workers with FIXED IDs...")
        
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
                INSERT OR REPLACE INTO workers (id, name, email, role, passwordHash)
                VALUES (?, ?, ?, ?, '');
            """, [worker.id, worker.name, worker.email, worker.role])
        }
        
        print("✅ Seeded \(workers.count) workers with FIXED IDs")
    }
    
    // MARK: - Worker Assignments - Using existing schema
    
    private static func seedEdwinAssignments(_ manager: SQLiteManager) async throws {
        print("📋 Seeding Edwin's building assignments...")
        
        // Edwin's building IDs
        let edwinBuildingIds = ["1", "4", "8", "10", "12", "15", "16", "17"]
        
        // Clear existing assignments for Edwin
        try await manager.execute("DELETE FROM worker_assignments WHERE worker_id = ?", ["2"])
        
        for (index, buildingId) in edwinBuildingIds.enumerated() {
            let isPrimary = index == 0 ? 1 : 0  // First building is primary
            
            // Use the columns that now exist after our schema update
            try await manager.execute("""
                INSERT INTO worker_assignments 
                (worker_id, building_id, is_active, is_primary, start_date) 
                VALUES (?, ?, 1, ?, datetime('now'))
            """, ["2", buildingId, isPrimary])
        }
        
        print("✅ Seeded \(edwinBuildingIds.count) assignments for Edwin (Worker ID: 2)")
    }
    
    // MARK: - Edwin's Tasks - Using correct table structure
    
    private static func seedEdwinTasks(_ manager: SQLiteManager) async throws {
        print("📝 Seeding Edwin's tasks...")
        
        let edwinTasks = [
            (buildingId: "17", taskName: "Put Mats Out", startTime: "06:00", category: "Cleaning"),
            (buildingId: "17", taskName: "Park Area Check", startTime: "06:15", category: "Inspection"),
            (buildingId: "17", taskName: "Remove Garbage to Curb", startTime: "06:45", category: "Sanitation"),
            (buildingId: "16", taskName: "Boiler Check", startTime: "07:30", category: "Maintenance"),
            (buildingId: "16", taskName: "Clean Common Areas", startTime: "08:00", category: "Cleaning"),
            (buildingId: "4", taskName: "Check Mail and Packages", startTime: "09:30", category: "Maintenance"),
            (buildingId: "1", taskName: "Lobby Floor Cleaning", startTime: "10:00", category: "Cleaning")
        ]
        
        // Insert into routine_tasks table
        for (index, task) in edwinTasks.enumerated() {
            let externalId = "edwin_task_\(index + 1)"
            
            try await manager.execute("""
                INSERT OR REPLACE INTO routine_tasks 
                (worker_id, building_id, task_name, recurrence, start_time, category, is_active, external_id, default_time) 
                VALUES (?, ?, ?, 'daily', ?, ?, 1, ?, ?)
            """, ["2", task.buildingId, task.taskName, task.startTime, task.category, externalId, task.startTime])
        }
        
        // Also create today's tasks in main tasks table
        for task in edwinTasks {
            try await manager.execute("""
                INSERT OR IGNORE INTO tasks 
                (name, buildingId, workerId, category, isCompleted, scheduledDate, recurrence, urgencyLevel, startTime) 
                VALUES (?, ?, 2, ?, 0, date('now'), 'daily', 'medium', ?)
            """, [task.taskName, Int(task.buildingId) ?? 0, task.category, task.startTime])
        }
        
        print("✅ Seeded \(edwinTasks.count) tasks for Edwin")
    }
}
