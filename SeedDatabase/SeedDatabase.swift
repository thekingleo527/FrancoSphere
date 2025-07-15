//
//  SeedDatabase.swift
//  FrancoSphere
//
//  🚀 COMPLETE DATABASE SEEDING - All 7 Workers + Buildings + Assignments
//  ✅ FIXED: GRDB compilation errors resolved
//  ✅ FIXED: Transaction handling using GRDBManager methods
//  ✅ FIXED: Heterogeneous collection literal type annotation
//  ✅ MIGRATED TO GRDB.swift properly
//

import Foundation
import GRDB

public class SeedDatabase {
    
    /// Run all migrations and seeding - call this once before any queries
    public static func runMigrations() async throws {
        print("🔄 Running COMPLETE database migrations with GRDB...")
        
        let manager = GRDBManager.shared
        
        do {
            // Step 1: Apply schema fixes (idempotent)
            try await applySchemaMigration(manager)
            
            // Step 2: Seed ALL workers and buildings
            try await seedCompleteRealWorldData(manager)
            
            print("✅ COMPLETE database migrations completed successfully with GRDB")
            
        } catch {
            print("❌ Database migration failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Schema Migration (Idempotent) - GRDB Version
    
    private static func applySchemaMigration(_ manager: GRDBManager) async throws {
        print("📝 Applying schema migration with GRDB...")
        
        // Create missing tables
        try await createMissingTables(manager)
        
        // Add missing columns (ignore errors if they exist)
        try await addMissingColumns(manager)
        
        print("✅ Schema migration applied with GRDB")
    }
    
    private static func createMissingTables(_ manager: GRDBManager) async throws {
        // Create worker_assignments table
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
        
        // Create worker_building_assignments table (alternative name used in some queries)
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_building_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                role TEXT DEFAULT 'maintenance',
                is_active INTEGER DEFAULT 1,
                assigned_date TEXT DEFAULT (datetime('now')),
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
        
        // Create app_settings table for tracking migrations
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS app_settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        print("✅ All tables created with GRDB")
    }
    
    private static func addMissingColumns(_ manager: GRDBManager) async throws {
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
        
        print("✅ Missing columns added with GRDB")
    }
    
    // MARK: - COMPLETE Real World Data Seeding
    
    private static func seedCompleteRealWorldData(_ manager: GRDBManager) async throws {
        print("🌍 Seeding COMPLETE real-world data with GRDB...")
        
        // Check if already seeded
        let checksum = "complete_francosphere_data_grdb_v1"
        let existing = try await manager.query("SELECT value FROM app_settings WHERE key = ?", ["complete_checksum"])
        if !existing.isEmpty && existing.first?["value"] as? String == checksum {
            print("✅ Complete real-world data already seeded")
            return
        }
        
        // ✅ FIXED: Use GRDBManager methods instead of direct dbPool access
        do {
            // 1. Seed ALL buildings (8 total)
            try await seedAllBuildings(manager)
            
            // 2. Seed ALL workers (7 total)
            try await seedAllWorkers(manager)
            
            // 3. Seed ALL worker building assignments
            try await seedAllWorkerAssignments(manager)
            
            // 4. Seed basic tasks for key workers
            try await seedWorkerTasks(manager)
            
            // 5. Seed worker skills
            try await seedWorkerSkills(manager)
            
            // Mark as complete
            try await manager.execute(
                "INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)",
                ["complete_checksum", checksum]
            )
            
            print("✅ COMPLETE real-world data seeded successfully with GRDB!")
            
        } catch {
            print("❌ Complete data seeding failed: \(error)")
            throw error
        }
    }
    
    // MARK: - All Buildings Seeding
    
    private static func seedAllBuildings(_ manager: GRDBManager) async throws {
        print("🏢 Seeding ALL buildings with GRDB...")
        
        let buildings = [
            (id: 1, name: "12 West 18th Street", address: "12 W 18th St", lat: 40.738976, lng: -73.992345),
            (id: 4, name: "131 Perry Street", address: "131 Perry St", lat: 40.735678, lng: -74.003456),
            (id: 7, name: "104 Franklin Street", address: "104 Franklin St", lat: 40.719234, lng: -74.009876),
            (id: 8, name: "138 West 17th Street", address: "138 W 17th St", lat: 40.739876, lng: -73.996543),
            (id: 10, name: "135-139 West 17th Street", address: "135-139 W 17th St", lat: 40.739654, lng: -73.996789),
            (id: 12, name: "117 West 17th Street", address: "117 W 17th St", lat: 40.739432, lng: -73.995678),
            (id: 13, name: "136 West 17th Street", address: "136 W 17th St", lat: 40.739321, lng: -73.996123),
            (id: 14, name: "Rubin Museum (142-148 West 17th Street)", address: "142-148 W 17th St", lat: 40.740567, lng: -73.997890),
            (id: 15, name: "112 West 18th Street", address: "112 W 18th St", lat: 40.740123, lng: -73.995432),
            (id: 16, name: "133 East 15th Street", address: "133 E 15th St", lat: 40.734567, lng: -73.985432),
            (id: 17, name: "Stuyvesant Cove Park", address: "FDR Drive & E 20th St", lat: 40.731234, lng: -73.971456)
        ]
        
        for building in buildings {
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
        
        print("✅ Seeded \(buildings.count) buildings with GRDB")
    }
    
    // MARK: - All Workers Seeding
    
    private static func seedAllWorkers(_ manager: GRDBManager) async throws {
        print("👷 Seeding ALL 7 workers with GRDB...")
        
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
        
        print("✅ Seeded \(workers.count) workers with GRDB")
    }
    
    // MARK: - All Worker Building Assignments
    
    private static func seedAllWorkerAssignments(_ manager: GRDBManager) async throws {
        print("📋 Seeding ALL worker building assignments with GRDB...")
        
        // Clear existing assignments
        try await manager.execute("DELETE FROM worker_assignments")
        try await manager.execute("DELETE FROM worker_building_assignments")
        
        // Kevin Dutan (ID: 4) - Rubin Museum specialist + other buildings
        let kevinAssignments = [
            (workerId: "4", workerName: "Kevin Dutan", buildingId: "14"), // Rubin Museum (primary)
            (workerId: "4", workerName: "Kevin Dutan", buildingId: "1"),  // 12 West 18th Street
            (workerId: "4", workerName: "Kevin Dutan", buildingId: "8"),  // 138 West 17th Street
            (workerId: "4", workerName: "Kevin Dutan", buildingId: "10"), // 135-139 West 17th Street
            (workerId: "4", workerName: "Kevin Dutan", buildingId: "12"), // 117 West 17th Street
            (workerId: "4", workerName: "Kevin Dutan", buildingId: "13"), // 136 West 17th Street
            (workerId: "4", workerName: "Kevin Dutan", buildingId: "17")  // Stuyvesant Cove Park
        ]
        
        // Mercedes Inamagua (ID: 5) - Mixed residential/commercial
        let mercedesAssignments = [
            (workerId: "5", workerName: "Mercedes Inamagua", buildingId: "7"),  // 104 Franklin Street
            (workerId: "5", workerName: "Mercedes Inamagua", buildingId: "8"),  // 138 West 17th Street
            (workerId: "5", workerName: "Mercedes Inamagua", buildingId: "12"), // 117 West 17th Street
            (workerId: "5", workerName: "Mercedes Inamagua", buildingId: "13"), // 136 West 17th Street
            (workerId: "5", workerName: "Mercedes Inamagua", buildingId: "15")  // 112 West 18th Street
        ]
        
        // Edwin Lema (ID: 2) - Park + high-maintenance buildings
        let edwinAssignments = [
            (workerId: "2", workerName: "Edwin Lema", buildingId: "17"), // Stuyvesant Cove Park (primary)
            (workerId: "2", workerName: "Edwin Lema", buildingId: "16"), // 133 East 15th Street
            (workerId: "2", workerName: "Edwin Lema", buildingId: "4"),  // 131 Perry Street
            (workerId: "2", workerName: "Edwin Lema", buildingId: "1"),  // 12 West 18th Street
            (workerId: "2", workerName: "Edwin Lema", buildingId: "8"),  // 138 West 17th Street
            (workerId: "2", workerName: "Edwin Lema", buildingId: "10"), // 135-139 West 17th Street
            (workerId: "2", workerName: "Edwin Lema", buildingId: "12")  // 117 West 17th Street
        ]
        
        // Luis Lopez (ID: 6) - Smaller buildings
        let luisAssignments = [
            (workerId: "6", workerName: "Luis Lopez", buildingId: "4"),  // 131 Perry Street
            (workerId: "6", workerName: "Luis Lopez", buildingId: "7"),  // 104 Franklin Street
            (workerId: "6", workerName: "Luis Lopez", buildingId: "15")  // 112 West 18th Street
        ]
        
        // Angel Guirachocha (ID: 7) - Mixed portfolio
        let angelAssignments = [
            (workerId: "7", workerName: "Angel Guirachocha", buildingId: "1"),  // 12 West 18th Street
            (workerId: "7", workerName: "Angel Guirachocha", buildingId: "8"),  // 138 West 17th Street
            (workerId: "7", workerName: "Angel Guirachocha", buildingId: "12"), // 117 West 17th Street
            (workerId: "7", workerName: "Angel Guirachocha", buildingId: "16")  // 133 East 15th Street
        ]
        
        // Greg Hutson (ID: 1) - Primary at 12 West 18th + coverage
        let gregAssignments = [
            (workerId: "1", workerName: "Greg Hutson", buildingId: "1"),  // 12 West 18th Street (primary)
            (workerId: "1", workerName: "Greg Hutson", buildingId: "13"), // 136 West 17th Street
            (workerId: "1", workerName: "Greg Hutson", buildingId: "15")  // 112 West 18th Street
        ]
        
        // Shawn Magloire (ID: 8) - Admin oversight of key buildings
        let shawnAssignments = [
            (workerId: "8", workerName: "Shawn Magloire", buildingId: "14"), // Rubin Museum
            (workerId: "8", workerName: "Shawn Magloire", buildingId: "1"),  // 12 West 18th Street
            (workerId: "8", workerName: "Shawn Magloire", buildingId: "7"),  // 104 Franklin Street
            (workerId: "8", workerName: "Shawn Magloire", buildingId: "8")   // 138 West 17th Street
        ]
        
        let allAssignments = kevinAssignments + mercedesAssignments + edwinAssignments + luisAssignments + angelAssignments + gregAssignments + shawnAssignments
        
        for (index, assignment) in allAssignments.enumerated() {
            let isPrimary = (assignment.workerId == "4" && assignment.buildingId == "14") || // Kevin + Rubin
                           (assignment.workerId == "2" && assignment.buildingId == "17") || // Edwin + Park
                           (assignment.workerId == "1" && assignment.buildingId == "1") ? 1 : 0  // Greg + 12 West 18th
            
            // Insert into both tables for compatibility
            try await manager.execute("""
                INSERT INTO worker_assignments 
                (worker_id, worker_name, building_id, assignment_type, is_primary, is_active, start_date, created_at) 
                VALUES (?, ?, ?, 'regular', ?, 1, datetime('now'), datetime('now'))
            """, [assignment.workerId, assignment.workerName, assignment.buildingId, isPrimary])
            
            try await manager.execute("""
                INSERT INTO worker_building_assignments 
                (worker_id, building_id, role, is_active, assigned_date) 
                VALUES (?, ?, 'maintenance', 1, datetime('now'))
            """, [assignment.workerId, assignment.buildingId])
        }
        
        print("✅ Seeded \(allAssignments.count) worker assignments across all 7 workers with GRDB")
    }
    
    // MARK: - Worker Tasks Seeding
    
    private static func seedWorkerTasks(_ manager: GRDBManager) async throws {
        print("📝 Seeding worker tasks with GRDB...")
        
        // Edwin's park tasks (morning routine)
        let edwinTasks = [
            ("2", "17", "Put Mats Out", "06:00", "06:15", "Cleaning", "Basic"),
            ("2", "17", "Park Area Check", "06:15", "06:45", "Inspection", "Basic"),
            ("2", "17", "Remove Garbage to Curb", "06:45", "07:00", "Sanitation", "Basic"),
            ("2", "16", "Boiler Check", "07:30", "08:00", "Maintenance", "Advanced"),
            ("2", "4", "Check Mail and Packages", "09:30", "10:00", "Maintenance", "Basic")
        ]
        
        // Kevin's Rubin Museum tasks
        let kevinTasks = [
            ("4", "14", "Museum Floor Cleaning", "06:00", "08:00", "Cleaning", "Advanced"),
            ("4", "14", "Gallery Temperature Check", "08:00", "08:30", "HVAC", "Intermediate"),
            ("4", "14", "Security System Check", "08:30", "09:00", "Security", "Advanced"),
            ("4", "14", "Visitor Area Preparation", "09:00", "10:00", "Operations", "Basic")
        ]
        
        // Mercedes' residential tasks
        let mercedesTasks = [
            ("5", "7", "Lobby Maintenance", "08:00", "09:00", "Cleaning", "Basic"),
            ("5", "8", "Common Area Cleaning", "09:00", "10:30", "Cleaning", "Basic"),
            ("5", "15", "Package Room Organization", "10:30", "11:00", "Operations", "Basic")
        ]
        
        let allTasks = edwinTasks + kevinTasks + mercedesTasks
        
        for (index, task) in allTasks.enumerated() {
            let externalId = "task_grdb_\(index + 1)"
            
            try await manager.execute("""
                INSERT OR REPLACE INTO routine_tasks 
                (worker_id, building_id, name, category, recurrence, startTime, endTime, skill_level, external_id, created_at) 
                VALUES (?, ?, ?, ?, 'daily', ?, ?, ?, ?, datetime('now'))
            """, [task.0, task.1, task.2, task.5, task.3, task.4, task.6, externalId])
        }
        
        print("✅ Seeded \(allTasks.count) worker tasks with GRDB")
    }
    
    // MARK: - Worker Skills Seeding
    
    private static func seedWorkerSkills(_ manager: GRDBManager) async throws {
        print("🔧 Seeding worker skills with GRDB...")
        
        // Clear existing skills
        try await manager.execute("DELETE FROM worker_skills")
        
        let allSkills = [
            // Kevin (Rubin Museum specialist)
            ("4", "Museum Operations", "Advanced", 8),
            ("4", "Security Systems", "Advanced", 6),
            ("4", "HVAC", "Intermediate", 4),
            ("4", "Cleaning", "Advanced", 10),
            
            // Mercedes (Cleaning specialist)
            ("5", "Cleaning", "Advanced", 8),
            ("5", "Maintenance", "Intermediate", 3),
            ("5", "Operations", "Basic", 2),
            
            // Edwin (Park + Maintenance)
            ("2", "Boiler Operation", "Advanced", 5),
            ("2", "General Maintenance", "Advanced", 8),
            ("2", "Plumbing", "Intermediate", 3),
            ("2", "Park Operations", "Advanced", 6),
            
            // Luis (Multi-building operations)
            ("6", "Cleaning", "Advanced", 6),
            ("6", "Sanitation", "Advanced", 5),
            ("6", "Operations", "Intermediate", 4),
            
            // Angel (Maintenance focus)
            ("7", "Sanitation", "Advanced", 7),
            ("7", "Operations", "Advanced", 5),
            ("7", "Inspection", "Intermediate", 3),
            
            // Greg (Building management)
            ("1", "Cleaning", "Advanced", 9),
            ("1", "Sanitation", "Advanced", 8),
            ("1", "Maintenance", "Advanced", 7),
            ("1", "Operations", "Advanced", 6),
            
            // Shawn (Admin/management)
            ("8", "Maintenance", "Expert", 15),
            ("8", "Management", "Expert", 12),
            ("8", "Inspection", "Expert", 10),
            ("8", "Operations", "Expert", 8)
        ]
        
        for skill in allSkills {
            try await manager.execute("""
                INSERT OR REPLACE INTO worker_skills 
                (worker_id, skill_name, skill_level, years_experience) 
                VALUES (?, ?, ?, ?)
            """, [skill.0, skill.1, skill.2, skill.3])
        }
        
        print("✅ Seeded \(allSkills.count) worker skills with GRDB")
    }
    
    // MARK: - Verification - Complete Database
    
    /// Verify the complete migration worked
    public static func verifyMigration() async throws {
        let manager = GRDBManager.shared
        
        // Test all workers
        let workers = try await manager.query("SELECT COUNT(*) as count FROM workers WHERE isActive = 1")
        let workerCount: Int64 = (workers.first?["count"] as? Int64) ?? 0
        
        // Test all buildings
        let buildings = try await manager.query("SELECT COUNT(*) as count FROM buildings")
        let buildingCount: Int64 = (buildings.first?["count"] as? Int64) ?? 0
        
        // Test all assignments
        let assignments = try await manager.query("SELECT COUNT(*) as count FROM worker_assignments")
        let assignmentCount: Int64 = (assignments.first?["count"] as? Int64) ?? 0
        
        // Test Kevin's Rubin Museum assignment
        let kevinRubin = try await manager.query("""
            SELECT COUNT(*) as count FROM worker_assignments 
            WHERE worker_id = '4' AND building_id = '14'
        """)
        let kevinRubinCount: Int64 = (kevinRubin.first?["count"] as? Int64) ?? 0
        
        // Test skills
        let skills = try await manager.query("SELECT COUNT(*) as count FROM worker_skills")
        let skillCount: Int64 = (skills.first?["count"] as? Int64) ?? 0
        
        print("📊 COMPLETE Database Stats:")
        print("   Workers: \(workerCount)")
        print("   Buildings: \(buildingCount)")
        print("   Assignments: \(assignmentCount)")
        print("   Kevin-Rubin: \(kevinRubinCount)")
        print("   Skills: \(skillCount)")
        
        if workerCount >= 7 && buildingCount >= 8 && assignmentCount >= 20 && kevinRubinCount > 0 && skillCount >= 20 {
            print("🎉 COMPLETE GRDB Migration verification successful!")
        } else {
            throw NSError(domain: "CompleteGRDBMigrationError", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Complete GRDB Migration verification failed"])
        }
    }
    
    /// Quick check if migration is needed
    public static func needsMigration() async -> Bool {
        do {
            let manager = GRDBManager.shared
            
            // Check if we have all workers
            let workers = try await manager.query("SELECT COUNT(*) as count FROM workers WHERE isActive = 1")
            let workerCount: Int64 = (workers.first?["count"] as? Int64) ?? 0
            
            return workerCount < 7
            
        } catch {
            print("⚠️ Could not check migration status with GRDB: \(error)")
            return true
        }
    }
    
    // MARK: - Export Complete Data
    
    /// Export complete migration data for debugging
    public static func exportCompleteData() async -> (success: Bool, data: String?) {
        do {
            let manager = GRDBManager.shared
            
            // Export all data
            let workers = try await manager.query("SELECT * FROM workers WHERE isActive = 1")
            let buildings = try await manager.query("SELECT * FROM buildings")
            let assignments = try await manager.query("SELECT * FROM worker_assignments")
            let skills = try await manager.query("SELECT * FROM worker_skills")
            
            // ✅ FIXED: Explicit type annotation for heterogeneous collection
            let exportData: [String: Any] = [
                "migration_version": "complete_grdb_v1",
                "workers": workers,
                "buildings": buildings,
                "assignments": assignments,
                "skills": skills,
                "export_date": ISO8601DateFormatter().string(from: Date())
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            
            return (true, jsonString)
            
        } catch {
            print("❌ Complete export failed: \(error)")
            return (false, nil)
        }
    }
}

// MARK: - 📝 COMPLETE DATABASE NOTES
/*
 ✅ COMPLETE FRANCOSPHERE DATABASE SEEDING:
 
 👷 WORKERS (7 total):
 - Greg Hutson (ID: 1) - Primary at 12 West 18th St
 - Edwin Lema (ID: 2) - Park specialist + maintenance
 - Kevin Dutan (ID: 4) - Rubin Museum specialist
 - Mercedes Inamagua (ID: 5) - Residential buildings
 - Luis Lopez (ID: 6) - Smaller buildings
 - Angel Guirachocha (ID: 7) - Mixed portfolio
 - Shawn Magloire (ID: 8) - Admin oversight
 
 🏢 BUILDINGS (11 total):
 - 12 West 18th Street
 - 131 Perry Street
 - 104 Franklin Street
 - 138 West 17th Street
 - 135-139 West 17th Street
 - 117 West 17th Street
 - 136 West 17th Street
 - Rubin Museum (142-148 West 17th Street)
 - 112 West 18th Street
 - 133 East 15th Street
 - Stuyvesant Cove Park
 
 📋 ASSIGNMENTS (30+ total):
 - Each worker assigned to 3-7 buildings
 - Kevin specializes in Rubin Museum
 - Edwin handles park operations
 - Complete coverage across all buildings
 
 🎯 STATUS: Complete FrancoSphere database ready for production
 */
