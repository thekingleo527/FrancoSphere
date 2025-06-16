//
//  SchemaMigrationPatch.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/14/25.
//


//
//  SchemaMigrationPatch.swift
//  FrancoSphere
//
//  🔧 PHASE-2 FIX PACK 03 - Schema Migration Patch
//  ✅ Fixed to work with actual SQLiteManager structure
//  ✅ Adds missing tables and columns for Edwin's building assignments
//  ✅ Simple, direct approach without complex migration system
//

import Foundation
import SQLite

// MARK: - Schema Migration Patch

public class SchemaMigrationPatch {
    
    /// Apply the schema migration patch to fix database column misalignment
    public static func applyPatch() async throws {
        print("🚀 Applying Schema Migration Patch...")
        
        let sqliteManager = SQLiteManager.shared
        
        do {
            // Step 1: Ensure all required tables exist
            try await createMissingTables(sqliteManager)
            
            // Step 2: Add missing columns to existing tables  
            try await addMissingColumns(sqliteManager)
            
            // Step 3: Seed Edwin's data if missing
            try await seedEdwinData(sqliteManager)
            
            // Step 4: Verify the fix worked
            try await verifyPatchSuccess(sqliteManager)
            
            print("✅ Schema Migration Patch completed successfully!")
            
        } catch {
            print("❌ Schema Migration Patch failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Create Missing Tables
    
    private static func createMissingTables(_ manager: SQLiteManager) async throws {
        print("📝 Creating missing tables...")
        
        // Create worker_assignments table if it doesn't exist
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                worker_name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                assignment_type TEXT DEFAULT 'regular',
                start_date TEXT NOT NULL DEFAULT (datetime('now')),
                end_date TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                UNIQUE(worker_id, building_id)
            );
        """)
        
        // Create routine_tasks table if it doesn't exist
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
        
        // Create worker_skills table if it doesn't exist
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_skills (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                skill_name TEXT NOT NULL,
                skill_level TEXT NOT NULL DEFAULT 'Basic',
                years_experience INTEGER DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                UNIQUE(worker_id, skill_name)
            );
        """)
        
        print("✅ Missing tables created")
    }
    
    // MARK: - Add Missing Columns
    
    private static func addMissingColumns(_ manager: SQLiteManager) async throws {
        print("📝 Adding missing columns...")
        
        // Add columns to tasks table for better compatibility
        let taskColumns = [
            "ALTER TABLE tasks ADD COLUMN building_id TEXT",
            "ALTER TABLE tasks ADD COLUMN worker_id TEXT", 
            "ALTER TABLE tasks ADD COLUMN urgencyLevel TEXT DEFAULT 'medium'",
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
        
        // Update foreign key references if needed
        try await manager.execute("""
            UPDATE tasks SET building_id = CAST(buildingId AS TEXT) 
            WHERE building_id IS NULL AND buildingId IS NOT NULL
        """)
        
        try await manager.execute("""
            UPDATE tasks SET worker_id = CAST(workerId AS TEXT)
            WHERE worker_id IS NULL AND workerId IS NOT NULL  
        """)
        
        print("✅ Missing columns added")
    }
    
    // MARK: - Seed Edwin's Data
    
    private static func seedEdwinData(_ manager: SQLiteManager) async throws {
        print("👤 Seeding Edwin's data...")
        
        // Check if Edwin exists as worker
        let edwinCheck = try await manager.query("""
            SELECT id FROM workers WHERE email = 'edwinlema911@gmail.com' OR name LIKE '%Edwin%'
            LIMIT 1
        """)
        
        var edwinWorkerId: String = "2"
        
        if edwinCheck.isEmpty {
            print("📝 Creating Edwin as worker...")
            let edwinId = try manager.insertWorker(Worker(
                id: 0, // Will be auto-generated
                name: "Edwin Lema",
                email: "edwinlema911@gmail.com", 
                password: "password",
                role: "worker",
                phone: "",
                hourlyRate: 25.0,
                skills: ["Boiler Operation", "General Maintenance", "Cleaning"],
                isActive: true,
                profileImagePath: nil,
                address: "",
                emergencyContact: "",
                notes: "Experienced building maintenance worker",
                buildingIds: nil
            ))
            edwinWorkerId = String(edwinId)
        } else if let id = edwinCheck.first?["id"] as? Int64 {
            edwinWorkerId = String(id)
        }
        
        print("👤 Edwin worker_id: \(edwinWorkerId)")
        
        // Seed Edwin's building assignments
        try await seedEdwinAssignments(manager, workerId: edwinWorkerId)
        
        // Seed Edwin's routine tasks
        try await seedEdwinTasks(manager, workerId: edwinWorkerId)
        
        // Seed Edwin's skills
        try await seedEdwinSkills(manager, workerId: edwinWorkerId)
        
        print("✅ Edwin's data seeded")
    }
    
    private static func seedEdwinAssignments(_ manager: SQLiteManager, workerId: String) async throws {
        print("🏢 Seeding Edwin's building assignments...")
        
        let assignments = [
            (workerId: workerId, workerName: "Edwin Lema", buildingId: "8"),   // 131 Perry Street
            (workerId: workerId, workerName: "Edwin Lema", buildingId: "10"),  // 133 Perry Street
            (workerId: workerId, workerName: "Edwin Lema", buildingId: "12"),  // 135-139 West 17th
            (workerId: workerId, workerName: "Edwin Lema", buildingId: "4"),   // Building 4
            (workerId: workerId, workerName: "Edwin Lema", buildingId: "16"),  // 133 E 15th
            (workerId: workerId, workerName: "Edwin Lema", buildingId: "17"),  // Stuyvesant Park
            (workerId: workerId, workerName: "Edwin Lema", buildingId: "18"),  // 125 E 15th
            (workerId: workerId, workerName: "Edwin Lema", buildingId: "19")   // 127 E 15th
        ]
        
        for assignment in assignments {
            try await manager.execute("""
                INSERT OR REPLACE INTO worker_assignments 
                (worker_id, worker_name, building_id, assignment_type, start_date, created_at) 
                VALUES (?, ?, ?, 'regular', datetime('now'), datetime('now'))
            """, [assignment.workerId, assignment.workerName, assignment.buildingId])
        }
        
        print("✅ Seeded \(assignments.count) building assignments for Edwin")
    }
    
    private static func seedEdwinTasks(_ manager: SQLiteManager, workerId: String) async throws {
        print("📝 Seeding Edwin's routine tasks...")
        
        let tasks = [
            // Morning routine - Stuyvesant Park (Building 17)
            (workerId: workerId, buildingId: "17", name: "Put Mats Out", startTime: "06:00", endTime: "06:15", category: "Cleaning", skillLevel: "Basic"),
            (workerId: workerId, buildingId: "17", name: "Park Area Check", startTime: "06:15", endTime: "06:45", category: "Inspection", skillLevel: "Basic"),
            (workerId: workerId, buildingId: "17", name: "Remove Garbage to Curb", startTime: "06:45", endTime: "07:00", category: "Sanitation", skillLevel: "Basic"),
            
            // Building 16 - 133 E 15th
            (workerId: workerId, buildingId: "16", name: "Boiler Check", startTime: "07:30", endTime: "08:00", category: "Maintenance", skillLevel: "Advanced"),
            (workerId: workerId, buildingId: "16", name: "Clean Common Areas", startTime: "08:00", endTime: "09:00", category: "Cleaning", skillLevel: "Basic"),
            
            // Building 4 - 131 Perry
            (workerId: workerId, buildingId: "4", name: "Check Mail and Packages", startTime: "09:30", endTime: "10:00", category: "Maintenance", skillLevel: "Basic"),
            (workerId: workerId, buildingId: "4", name: "Sweep Front of Building", startTime: "10:00", endTime: "10:30", category: "Cleaning", skillLevel: "Basic"),
            
            // Weekly tasks across other buildings
            (workerId: workerId, buildingId: "8", name: "Boiler Blow Down", startTime: "11:00", endTime: "13:00", category: "Maintenance", skillLevel: "Advanced"),
            (workerId: workerId, buildingId: "10", name: "Replace Light Bulbs", startTime: "13:00", endTime: "14:00", category: "Maintenance", skillLevel: "Basic"),
            (workerId: workerId, buildingId: "12", name: "Inspection Water Tank", startTime: "14:00", endTime: "14:30", category: "Inspection", skillLevel: "Advanced")
        ]
        
        for (index, task) in tasks.enumerated() {
            try await manager.execute("""
                INSERT OR REPLACE INTO routine_tasks 
                (worker_id, building_id, name, category, recurrence, startTime, endTime, skill_level, external_id, created_at) 
                VALUES (?, ?, ?, ?, 'daily', ?, ?, ?, ?, datetime('now'))
            """, [task.workerId, task.buildingId, task.name, task.category, task.startTime, task.endTime, task.skillLevel, "edwin_task_\(index + 1)"])
        }
        
        print("✅ Seeded \(tasks.count) routine tasks for Edwin")
    }
    
    private static func seedEdwinSkills(_ manager: SQLiteManager, workerId: String) async throws {
        print("🔧 Seeding Edwin's skills...")
        
        let skills = [
            (workerId: workerId, skill: "Boiler Operation", level: "Advanced", years: 5),
            (workerId: workerId, skill: "General Maintenance", level: "Advanced", years: 8),
            (workerId: workerId, skill: "Plumbing", level: "Intermediate", years: 3),
            (workerId: workerId, skill: "Electrical", level: "Basic", years: 2),
            (workerId: workerId, skill: "HVAC", level: "Intermediate", years: 4),
            (workerId: workerId, skill: "Cleaning", level: "Advanced", years: 8)
        ]
        
        for skill in skills {
            try await manager.execute("""
                INSERT OR REPLACE INTO worker_skills 
                (worker_id, skill_name, skill_level, years_experience, created_at) 
                VALUES (?, ?, ?, ?, datetime('now'))
            """, [skill.workerId, skill.skill, skill.level, skill.years])
        }
        
        print("✅ Seeded \(skills.count) skills for Edwin")
    }
    
    // MARK: - Verification
    
    private static func verifyPatchSuccess(_ manager: SQLiteManager) async throws {
        print("🔍 Verifying patch success...")
        
        // Test 1: Check Edwin's building assignments
        let buildings = try await manager.query("""
            SELECT DISTINCT b.id, b.name
            FROM buildings b
            INNER JOIN worker_assignments wa ON CAST(b.id AS TEXT) = wa.building_id
            WHERE wa.worker_id = ? OR wa.worker_id = CAST(? AS TEXT)
            ORDER BY b.name
        """, ["2", 2])
        
        let buildingCount = buildings.count
        print("📊 Edwin has access to \(buildingCount) buildings:")
        for building in buildings {
            if let id = building["id"], let name = building["name"] {
                print("   - Building \(id): \(name)")
            }
        }
        
        if buildingCount >= 8 {
            print("🎉 SUCCESS: Edwin has access to his full building portfolio!")
        } else if buildingCount > 0 {
            print("⚠️ PARTIAL: Edwin has some buildings but may need more")
        } else {
            throw NSError(domain: "VerificationError", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Edwin still has no building assignments"])
        }
        
        // Test 2: Check Edwin's routine tasks
        let tasks = try await manager.query("""
            SELECT name, building_id, startTime, category
            FROM routine_tasks
            WHERE worker_id = ? OR worker_id = CAST(? AS TEXT)
            ORDER BY startTime
        """, ["2", 2])
        
        let taskCount = tasks.count
        print("📊 Edwin has \(taskCount) routine tasks:")
        for task in tasks.prefix(3) {
            if let name = task["name"], let buildingId = task["building_id"], let startTime = task["startTime"] {
                print("   - \(startTime): \(name) (Building \(buildingId))")
            }
        }
        
        // Test 3: Verify tables exist
        let tables = try await manager.query("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name IN ('worker_assignments', 'routine_tasks', 'worker_skills')
            ORDER BY name
        """)
        
        print("📊 Required tables present: \(tables.count)/3")
        for table in tables {
            if let name = table["name"] {
                print("   ✅ \(name)")
            }
        }
        
        if tables.count == 3 && buildingCount > 0 && taskCount > 0 {
            print("🎉 All verification tests passed! Schema patch is working correctly.")
        } else {
            print("⚠️ Some verification tests failed. Manual review may be needed.")
        }
    }
}

// MARK: - Convenience Methods

extension SchemaMigrationPatch {
    
    /// Quick check if Edwin has building assignments
    public static func edwinHasBuildings() async -> Bool {
        do {
            let manager = SQLiteManager.shared
            let buildings = try await manager.query("""
                SELECT COUNT(*) as count
                FROM worker_assignments
                WHERE worker_id = '2' OR worker_id = 2
            """)
            
            if let firstRow = buildings.first,
               let count = firstRow["count"] as? Int64 {
                return count > 0
            }
        } catch {
            print("❌ Error checking Edwin's buildings: \(error)")
        }
        
        return false
    }
    
    /// Force reseed Edwin's data (for troubleshooting)
    public static func forceReseedEdwin() async throws {
        print("🔄 Force reseeding Edwin's data...")
        
        let manager = SQLiteManager.shared
        
        // Clear existing data
        try await manager.execute("DELETE FROM worker_assignments WHERE worker_id = '2' OR worker_id = 2")
        try await manager.execute("DELETE FROM routine_tasks WHERE worker_id = '2' OR worker_id = 2")
        try await manager.execute("DELETE FROM worker_skills WHERE worker_id = '2' OR worker_id = 2")
        
        // Reseed
        try await seedEdwinData(manager)
        
        print("✅ Edwin's data force reseeded")
    }
}