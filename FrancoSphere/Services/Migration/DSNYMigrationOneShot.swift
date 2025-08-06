//
//  DSNYMigrationOneShot.swift
//  CyntientOps
//
//  One-time DSNY terminology migration
//  DELETE THIS FILE AFTER RUNNING
//
//  Usage: Add to your app initialization:
//  Task {
//      try await DSNYMigrationOneShot.migrate()
//  }
//

import Foundation

public struct DSNYMigrationOneShot {
    
    public static func migrate() async throws {
        print("🚀 Starting DSNY terminology migration...")
        
        let updateCount = try await GRDBManager.shared.execute("""
            UPDATE routine_tasks 
            SET 
                title = CASE 
                    WHEN title = 'Trash Management - Evening' THEN 'DSNY: Set Out Trash'
                    WHEN title = 'Trash Removal' THEN 'DSNY: Set Out Trash'
                    WHEN title = 'Trash removal' THEN 'DSNY: Set Out Trash'
                    WHEN title = 'Put Out Trash' THEN 'DSNY: Set Out Trash'
                    WHEN title = 'DSNY Put-Out (after 20:00)' THEN 'DSNY: Set Out Trash'
                    WHEN title = 'Bring in trash bins' THEN 'DSNY: Bring In Trash Bins'
                    WHEN title = 'DSNY Prep / Move Bins' THEN 'DSNY: Bring In Trash Bins'
                    WHEN title = 'Recycling Management' THEN 'DSNY: Set Out Recycling'
                    WHEN title = 'DSNY Compliance' THEN 'DSNY: Compliance Check'
                    WHEN title = 'Rubin Museum DSNY' THEN 'DSNY: Compliance Check'
                    WHEN title = 'Rubin DSNY Operations' THEN 'DSNY: Compliance Check'
                    ELSE title
                END,
                category = CASE
                    WHEN (title LIKE '%Trash%' OR title LIKE '%DSNY%' OR title LIKE '%Recycling%') 
                         AND category = 'maintenance'
                    THEN 'sanitation'
                    ELSE category
                END,
                updated_at = datetime('now')
            WHERE 
                title LIKE '%Trash%' OR 
                title LIKE '%DSNY%' OR 
                title LIKE '%Recycling%';
        """)
        
        print("✅ Updated \(updateCount) DSNY tasks")
        
        // Verify Kevin's tasks
        let kevinTasks = try await GRDBManager.shared.query("""
            SELECT title, building_id 
            FROM routine_tasks 
            WHERE worker_id = '4' AND title LIKE 'DSNY:%'
            ORDER BY title
        """)
        
        print("\n📋 Kevin's DSNY tasks:")
        for task in kevinTasks {
            if let title = task["title"] as? String {
                print("  • \(title)")
            }
        }
        
        print("\n✅ DSNY migration completed!")
        print("⚠️  DELETE DSNYMigrationOneShot.swift now!")
    }
}
