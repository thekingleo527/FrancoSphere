//
//
//  SeedDatabase.swift
//  FrancoSphere
//
//  🔧 PHASE-2 FINAL - Database Schema Migration
//  ✅ Idempotent column renames to fix "no such column" errors
//  ✅ Seeds Edwin's 8 building assignments
//  ✅ Run once before any database queries
//

import Foundation
import SQLite

public class SeedDatabase {
    
    /// Run all migrations and seeding - call this once before any queries
    public static func runMigrations() async throws {
        print("🔄 Running database migrations...")
        
        let manager = SQLiteManager.shared
        
        do {
            // Step 1: Apply schema fixes (idempotent)
            try await applySchemaMigration(manager)
            
            // Step 2: Seed Edwin's data if missing
            try await seedEdwinData(manager)
            
            print("✅ Database migrations completed successfully")
            
        } catch {
            print("❌ Database migration failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Schema Migration (Idempotent)
    
    private static func applySchemaMigration(_ manager: SQLiteManager) async throws {
        print("📝 Applying schema migration...")
        
        // Create missing tables
        try await createMissingTables(manager)
        
        // Add missing columns (ignore errors if they exist)
        try await addMissingColumns(manager)
        
        // Rename columns (ignore errors if already renamed)
        try await renameColumns(manager)
        
        print("✅ Schema migration applied")
    }
    
    private static func createMissingTables(_ manager: SQLiteManager) async throws {
        // Create worker_assignments table
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                worker_name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                assignment_type TEXT DEFAULT 'regular',
                start_date TEXT NOT NULL DEFAULT (datetime('now')),
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                UNIQUE(worker_id, building_id)
            );
        """)
        
        // Create routine_tasks table with correct column names
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS routine_tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                name TEXT NOT NULL,
                category TEXT NOT NULL DEFAULT 'maintenance',
                recurrence TEXT NOT NULL DEFAULT 'daily',
                startTime TEXT,
                endTime TEXT,
                skill_level TEXT DEFAULT 'Basic',
                external_id TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
        """)
        
        // Create worker_skills table
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_skills (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                skill_name TEXT NOT NULL,
                skill_level TEXT NOT NULL DEFAULT 'Basic',
                years_experience INTEGER DEFAULT 0,
                UNIQUE(worker_id, skill_name)
            );
        """)
    }
    
    private static func addMissingColumns(_ manager: SQLiteManager) async throws {
        // Add missing columns to tasks table
        let taskColumns = [
            "ALTER TABLE tasks ADD COLUMN building_id TEXT",
            "ALTER TABLE tasks ADD COLUMN worker_id TEXT",
            "ALTER TABLE tasks ADD COLUMN isCompleted INTEGER DEFAULT 0",
            "ALTER TABLE tasks ADD COLUMN external_id TEXT"
        ]
        
        for sql in taskColumns {
            do {
                try await manager.execute(sql)
            } catch {
                // Ignore errors if column already exists
                print("⚠️ Column may already exist: \(error)")
            }
        }
        
        // Update foreign key references
        try await manager.execute("""
            UPDATE tasks SET building_id = CAST(buildingId AS TEXT) 
            WHERE building_id IS NULL AND buildingId IS NOT NULL
        """)
        
        try await manager.execute("""
            UPDATE tasks SET worker_id = CAST(workerId AS TEXT)
            WHERE worker_id IS NULL AND workerId IS NOT NULL  
        """)
    }
    
    private static func renameColumns(_ manager: SQLiteManager) async throws {
        // Note: SQLite doesn't support column rename directly in older versions
        // We'll create the tables with correct names instead
        
        // Check if routine_tasks has wrong column names and recreate if needed
        let columns = try await manager.query("PRAGMA table_info(routine_tasks)")
        let columnNames = columns.compactMap { $0["name"] as? String }
        
        if columnNames.contains("task_name") {
            print("🔄 Recreating routine_tasks with correct column names...")
            
            // Backup existing data
            let existingData = try await manager.query("SELECT * FROM routine_tasks")
            
            // Drop and recreate table
            try await manager.execute("DROP TABLE routine_tasks")
            try await createMissingTables(manager)
            
            // Restore data with correct column mapping
            for row in existingData {
                let workerId = row["worker_id"] ?? row["workerId"] ?? "2"
                let buildingId = row["building_id"] ?? row["buildingId"] ?? "1"
                let name = row["name"] ?? row["task_name"] ?? "Maintenance Task"
                let category = row["category"] ?? "maintenance"
                let startTime = row["startTime"] ?? row["start_time"] ?? "09:00"
                let endTime = row["endTime"] ?? row["end_time"] ?? "10:00"
                
                try await manager.execute("""
                    INSERT OR IGNORE INTO routine_tasks 
                    (worker_id, building_id, name, category, startTime, endTime)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, [workerId, buildingId, name, category, startTime, endTime])
            }
            
            print("✅ routine_tasks recreated with correct schema")
        }
    }
    
    // MARK: - Seed Edwin's Data
    
    private static func seedEdwinData(_ manager: SQLiteManager) async throws {
        print("👤 Seeding Edwin's data...")
        
        // Ensure Edwin exists as worker (ID 2)
        let edwinCheck = try await manager.query("SELECT id FROM workers WHERE id = 2")
        
        if edwinCheck.isEmpty {
            print("📝 Creating Edwin as worker...")
            try await manager.execute("""
                INSERT OR REPLACE INTO workers 
                (id, name, email, passwordHash, role, isActive)
                VALUES (2, 'Edwin Lema', 'edwinlema911@gmail.com', 'password', 'worker', 1)
            """)
        }
        
        // Seed Edwin's building assignments
        try await seedEdwinAssignments(manager)
        
        // Seed Edwin's routine tasks
        try await seedEdwinTasks(manager)
        
        // Seed Edwin's skills
        try await seedEdwinSkills(manager)
        
        print("✅ Edwin's data seeded")
    }
    
    private static func seedEdwinAssignments(_ manager: SQLiteManager) async throws {
        print("🏢 Seeding Edwin's 8 building assignments...")
        
        let assignments = [
            ("2", "Edwin Lema", "8"),   // 131 Perry Street
            ("2", "Edwin Lema", "10"),  // 133 Perry Street
            ("2", "Edwin Lema", "12"),  // 135-139 West 17th
            ("2", "Edwin Lema", "4"),   // Building 4
            ("2", "Edwin Lema", "16"),  // 133 E 15th
            ("2", "Edwin Lema", "17"),  // Stuyvesant Park
            ("2", "Edwin Lema", "18"),  // 125 E 15th
            ("2", "Edwin Lema", "19")   // 127 E 15th
        ]
        
        for assignment in assignments {
            try await manager.execute("""
                INSERT OR REPLACE INTO worker_assignments 
                (worker_id, worker_name, building_id, assignment_type, start_date, created_at) 
                VALUES (?, ?, ?, 'regular', datetime('now'), datetime('now'))
            """, [assignment.0, assignment.1, assignment.2])
        }
        
        print("✅ Seeded \(assignments.count) building assignments for Edwin")
    }
    
    private static func seedEdwinTasks(_ manager: SQLiteManager) async throws {
        print("📝 Seeding Edwin's routine tasks...")
        
        let tasks = [
            // Morning routine - Stuyvesant Park (Building 17)
            ("2", "17", "Put Mats Out", "06:00", "06:15", "Cleaning", "Basic"),
            ("2", "17", "Park Area Check", "06:15", "06:45", "Inspection", "Basic"),
            ("2", "17", "Remove Garbage to Curb", "06:45", "07:00", "Sanitation", "Basic"),
            
            // Building 16 - 133 E 15th
            ("2", "16", "Boiler Check", "07:30", "08:00", "Maintenance", "Advanced"),
            ("2", "16", "Clean Common Areas", "08:00", "09:00", "Cleaning", "Basic"),
            
            // Building 4 - 131 Perry
            ("2", "4", "Check Mail and Packages", "09:30", "10:00", "Maintenance", "Basic"),
            ("2", "4", "Sweep Front of Building", "10:00", "10:30", "Cleaning", "Basic"),
            
            // Weekly tasks across other buildings
            ("2", "8", "Boiler Blow Down", "11:00", "13:00", "Maintenance", "Advanced"),
            ("2", "10", "Replace Light Bulbs", "13:00", "14:00", "Maintenance", "Basic"),
            ("2", "12", "Inspection Water Tank", "14:00", "14:30", "Inspection", "Advanced")
        ]
        
        for (index, task) in tasks.enumerated() {
            try await manager.execute("""
                INSERT OR REPLACE INTO routine_tasks 
                (worker_id, building_id, name, category, recurrence, startTime, endTime, skill_level, external_id, created_at) 
                VALUES (?, ?, ?, ?, 'daily', ?, ?, ?, ?, datetime('now'))
            """, [task.0, task.1, task.2, task.5, task.3, task.4, task.6, "edwin_task_\(index + 1)"])
        }
        
        print("✅ Seeded \(tasks.count) routine tasks for Edwin")
    }
    
    private static func seedEdwinSkills(_ manager: SQLiteManager) async throws {
        print("🔧 Seeding Edwin's skills...")
        
        let skills = [
            ("2", "Boiler Operation", "Advanced", 5),
            ("2", "General Maintenance", "Advanced", 8),
            ("2", "Plumbing", "Intermediate", 3),
            ("2", "Electrical", "Basic", 2),
            ("2", "HVAC", "Intermediate", 4),
            ("2", "Cleaning", "Advanced", 8)
        ]
        
        for skill in skills {
            try await manager.execute("""
                INSERT OR REPLACE INTO worker_skills 
                (worker_id, skill_name, skill_level, years_experience) 
                VALUES (?, ?, ?, ?)
            """, [skill.0, skill.1, skill.2, skill.3])
        }
        
        print("✅ Seeded \(skills.count) skills for Edwin")
    }
    
    // MARK: - Verification
    
    /// Verify the migration worked
    public static func verifyMigration() async throws {
        let manager = SQLiteManager.shared
        
        // Test Edwin's building assignments
        let buildings = try await manager.query("""
            SELECT COUNT(*) as count FROM worker_assignments 
            WHERE worker_id = '2'
        """)
        
        let buildingCount = buildings.first?["count"] as? Int64 ?? 0
        print("📊 Edwin has \(buildingCount) building assignments")
        
        // Test routine tasks query
        let tasks = try await manager.query("""
            SELECT name, building_id, startTime FROM routine_tasks 
            WHERE worker_id = '2' LIMIT 3
        """)
        
        print("📊 Edwin has \(tasks.count) routine tasks")
        
        if buildingCount >= 8 && tasks.count > 0 {
            print("🎉 Migration verification successful!")
        } else {
            throw NSError(domain: "MigrationError", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Migration verification failed"])
        }
    }
    
    /// Quick check if migration is needed
    public static func needsMigration() async -> Bool {
        do {
            let manager = SQLiteManager.shared
            
            // Check if Edwin has buildings
            let buildings = try await manager.query("""
                SELECT COUNT(*) as count FROM worker_assignments 
                WHERE worker_id = '2'
            """)
            
            let count = buildings.first?["count"] as? Int64 ?? 0
            return count == 0
            
        } catch {
            print("⚠️ Could not check migration status: \(error)")
            return true // Assume migration needed if we can't check
        }
    }
}
