//
//  V012.swift
//  FrancoSphere
//
//  ✅ GRDB VERSION - Fixed migration for worker assignments
//

import Foundation
import GRDB

/// V012 Migration: Enhanced worker building assignments with GRDB
public struct V012: DatabaseMigration {
    public let version = 12
    public let name = "Enhanced Worker Building Assignments"
    public let checksum = "grdb-worker-assignments-v012"
    
    public init() {}
    
    public func up(_ db: Database) throws {
        print("🔧 V012: Updating worker assignments table with GRDB...")
        
        // Check if worker_assignments table exists
        let tableExists = try db.tableExists("worker_assignments")
        
        if tableExists {
            print("📝 Updating existing worker_assignments table...")
            
            // Get existing columns
            let columns = try db.columns(in: "worker_assignments")
            let existingColumnNames = Set(columns.map { $0.name })
            
            // Add missing columns one by one (GRDB doesn't support multiple ADD COLUMN in one statement)
            if !existingColumnNames.contains("start_date") {
                try db.execute(sql: "ALTER TABLE worker_assignments ADD COLUMN start_date TEXT DEFAULT ?",
                              arguments: [ISO8601DateFormatter().string(from: Date())])
            }
            
            if !existingColumnNames.contains("specialization") {
                try db.execute(sql: "ALTER TABLE worker_assignments ADD COLUMN specialization TEXT DEFAULT 'General'")
            }
            
            if !existingColumnNames.contains("priority_level") {
                try db.execute(sql: "ALTER TABLE worker_assignments ADD COLUMN priority_level INTEGER DEFAULT 1")
            }
            
            if !existingColumnNames.contains("notes") {
                try db.execute(sql: "ALTER TABLE worker_assignments ADD COLUMN notes TEXT")
            }
            
            if !existingColumnNames.contains("building_name") {
                try db.execute(sql: "ALTER TABLE worker_assignments ADD COLUMN building_name TEXT")
            }
            
        } else {
            print("🆕 Creating worker_assignments table with GRDB...")
            
            // Create complete table with GRDB
            try db.create(table: "worker_assignments", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("worker_id", .text).notNull()
                t.column("building_id", .text).notNull()
                t.column("worker_name", .text).notNull()
                t.column("building_name", .text)
                t.column("start_date", .text).defaults(to: ISO8601DateFormatter().string(from: Date()))
                t.column("specialization", .text).defaults(to: "General")
                t.column("priority_level", .integer).defaults(to: 1)
                t.column("is_active", .integer).defaults(to: 1)
                t.column("notes", .text)
            }
            
            // Create index for performance
            try db.create(index: "idx_worker_building", on: "worker_assignments", columns: ["worker_id", "building_id"], unique: true, ifNotExists: true)
        }
        
        print("✅ V012: Worker assignments table updated with GRDB")
    }
    
    public func down(_ db: Database) throws {
        print("🔄 V012: Rolling back worker assignments changes...")
        
        // For rollback, we would need to recreate the table without the new columns
        // This is a simplified rollback - in production, you'd want to preserve data
        try db.execute(sql: "DROP TABLE IF EXISTS worker_assignments")
        
        // Recreate basic table
        try db.create(table: "worker_assignments", ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("worker_id", .text).notNull()
            t.column("building_id", .text).notNull()
            t.column("worker_name", .text).notNull()
            t.column("is_active", .integer).defaults(to: 1)
        }
        
        print("✅ V012: Rollback completed")
    }
}
