//
//  SeedDatabase.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//

import Foundation
// Remove the direct SQLite import - it's included via your app module

@main
struct SeedDatabase {
    static func main() async {
        print("🌱 Starting database seed...")
        
        do {
            // Use the updated approach with RealWorldDataSeeder
            let db = try await SQLiteManager.start(inMemory: false)
            
            // Use RealWorldDataSeeder instead of CSVDataImporter
            try await RealWorldDataSeeder.seedAllRealData(db)
            
            print("✅ Database seeded successfully!")
            
            // Verify the data
            let workerCount = try await db.query("SELECT COUNT(*) as count FROM workers")
            let buildingCount = try await db.query("SELECT COUNT(*) as count FROM buildings")
            let taskCount = try await db.query("SELECT COUNT(*) as count FROM routine_tasks")
            
            print("📊 Database stats:")
            print("   Workers: \(workerCount.first?["count"] as? Int64 ?? 0)")
            print("   Buildings: \(buildingCount.first?["count"] as? Int64 ?? 0)")
            print("   Tasks: \(taskCount.first?["count"] as? Int64 ?? 0)")
            
            exit(0)
        } catch {
            print("❌ Seed failed: \(error)")
            exit(1)
        }
    }
}
