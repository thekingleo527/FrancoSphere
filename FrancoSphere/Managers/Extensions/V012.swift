//
//  V012.swift
//  FrancoSphere
//
//  Fixed SQLite migration for worker assignments
//

import Foundation
import SQLite

struct V012_RoutineTasks: DatabaseMigration {
    let version = 12
    let name = "Routine Tasks and Worker Assignments"
    var checksum: String { "f2a3b4c5d6e7" }
    
    func up(_ db: Connection) throws {
        // Check if worker_assignments table exists from V003
        let tableCheck = try db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='worker_assignments'")
        let tableExists = tableCheck.makeIterator().next() != nil
        
        if tableExists {
            print("📝 Updating existing worker_assignments table...")
            
            // Check which columns already exist
            let columns = try db.prepare("PRAGMA table_info(worker_assignments)")
            var existingColumns = Set<String>()
            for column in columns {
                if let name = column[1] as? String {
                    existingColumns.insert(name)
                }
            }
            
            // Add missing columns WITHOUT default values first
            if !existingColumns.contains("start_date") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN start_date TEXT")
                // Update existing rows with current timestamp
                let currentTimestamp = Date().iso8601String
                try db.run("UPDATE worker_assignments SET start_date = ? WHERE start_date IS NULL", [currentTimestamp])
            }
            
            if !existingColumns.contains("end_date") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN end_date TEXT")
            }
            
            if !existingColumns.contains("is_active") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN is_active INTEGER DEFAULT 1")
            }
            
            if !existingColumns.contains("days_of_week") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN days_of_week TEXT")
            }
            
            if !existingColumns.contains("start_hour") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN start_hour INTEGER")
            }
            
            if !existingColumns.contains("end_hour") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN end_hour INTEGER")
            }
        } else {
            // Create the table fresh with all columns
            print("📝 Creating new worker_assignments table...")
            try db.run("""
                CREATE TABLE IF NOT EXISTS worker_assignments (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    worker_id TEXT NOT NULL,
                    building_id TEXT NOT NULL,
                    start_date TEXT NOT NULL,
                    end_date TEXT,
                    is_active INTEGER NOT NULL DEFAULT 1,
                    days_of_week TEXT,
                    start_hour INTEGER,
                    end_hour INTEGER,
                    created_at TEXT NOT NULL,
                    UNIQUE(worker_id, building_id)
                );
                """)
        }
        
        // Create routine_tasks table
        try db.run("""
            CREATE TABLE IF NOT EXISTS routine_tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                category TEXT NOT NULL,
                recurrence TEXT NOT NULL,
                building_id TEXT NOT NULL,
                start_hour INTEGER NOT NULL,
                end_hour INTEGER NOT NULL,
                days_of_week TEXT,
                required_skill TEXT,
                created_at TEXT NOT NULL
            );
            """)
        
        // Create indexes
        try db.run("CREATE INDEX IF NOT EXISTS idx_worker_assignments_active ON worker_assignments(is_active, worker_id);")
        try db.run("CREATE INDEX IF NOT EXISTS idx_routine_tasks_building ON routine_tasks(building_id);")
    }
    
    func down(_ db: Connection) throws {
        try db.run("DROP INDEX IF EXISTS idx_routine_tasks_building;")
        try db.run("DROP INDEX IF EXISTS idx_worker_assignments_active;")
        try db.run("DROP TABLE IF EXISTS routine_tasks;")
        // Don't drop worker_assignments as it might have been created by V003
    }
}
