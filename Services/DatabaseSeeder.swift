//
//  DatabaseSeeder.swift
//  FrancoSphere
//
//  Utility class for seeding database (no @main attribute)
//

import Foundation

/// Utility class for seeding the database with test data
class DatabaseSeeder {
    
    static let shared = DatabaseSeeder()
    
    private init() {}
    
    /// Seeds the database with real-world data
    /// - Returns: A tuple with (success: Bool, message: String)
    func seedDatabase() async -> (success: Bool, message: String) {
        do {
            print("🌱 Starting database seed...")
            
            // Get database instance
            let db = SQLiteManager.shared
            
            // Ensure database is initialized
            if !db.isDatabaseReady() {
                db.quickInitialize()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Use RealWorldDataSeeder to populate data
            try await RealWorldDataSeeder.seedAllRealData(db)
            
            // Get stats to verify
            let stats = try await getDatabaseStats(db)
            
            let message = """
            ✅ Database seeded successfully!
            📊 Database stats:
               Workers: \(stats.workers)
               Buildings: \(stats.buildings)
               Tasks: \(stats.tasks)
            """
            
            print(message)
            return (true, message)
            
        } catch {
            let errorMessage = "❌ Seed failed: \(error.localizedDescription)"
            print(errorMessage)
            return (false, errorMessage)
        }
    }
    
    /// Alternative seeding without RealWorldDataSeeder (if file is missing)
    func seedBasicData() async -> (success: Bool, message: String) {
        do {
            let db = SQLiteManager.shared
            
            // Ensure database is initialized
            if !db.isDatabaseReady() {
                db.quickInitialize()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Basic worker data
            let workers = [
                (id: 3, name: "Edwin Lema", email: "edwinlema911@gmail.com", role: "worker")
            ]
            
            for worker in workers {
                try await db.execute("""
                    INSERT OR REPLACE INTO workers (id, name, email, role, passwordHash)
                    VALUES (?, ?, ?, ?, '');
                """, [worker.id, worker.name, worker.email, worker.role])
            }
            
            // Basic building data
            try await db.execute("""
                INSERT OR REPLACE INTO buildings (id, name, address, latitude, longitude)
                VALUES (17, 'Stuyvesant Cove Park', 'FDR Drive & E 20th St', 40.731234, -73.971456);
            """)
            
            return (true, "✅ Basic data seeded")
            
        } catch {
            return (false, "❌ Basic seed failed: \(error.localizedDescription)")
        }
    }
    
    /// Imports tasks from CSV (if you still need this)
    func importCSVTasks() async -> (success: Bool, message: String) {
        do {
            let (count, errors) = try await CSVDataImporter.shared.importRealWorldTasks()
            
            let message = """
            ✅ Imported \(count) tasks
            ⚠️ Errors: \(errors.count)
            """
            
            print(message)
            return (true, message)
            
        } catch {
            let errorMessage = "❌ CSV import failed: \(error.localizedDescription)"
            print(errorMessage)
            return (false, errorMessage)
        }
    }
    
    /// Clears all data from the database
    func clearDatabase() async -> (success: Bool, message: String) {
        do {
            let db = SQLiteManager.shared
            
            // Ensure database is initialized
            if !db.isDatabaseReady() {
                db.quickInitialize()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Clear tables in reverse dependency order
            try await db.execute("DELETE FROM routine_tasks")
            try await db.execute("DELETE FROM tasks")
            try await db.execute("DELETE FROM worker_assignments")
            try await db.execute("DELETE FROM worker_skills")
            try await db.execute("DELETE FROM buildings")
            try await db.execute("DELETE FROM workers")
            try await db.execute("DELETE FROM app_settings")
            
            return (true, "✅ Database cleared successfully")
            
        } catch {
            return (false, "❌ Clear failed: \(error.localizedDescription)")
        }
    }
    
    /// Gets current database statistics
    private func getDatabaseStats(_ db: SQLiteManager) async throws -> (workers: Int, buildings: Int, tasks: Int) {
        let workerCount = try await db.query("SELECT COUNT(*) as count FROM workers")
        let buildingCount = try await db.query("SELECT COUNT(*) as count FROM buildings")
        let taskCount = try await db.query("SELECT COUNT(*) as count FROM routine_tasks")
        
        return (
            workers: Int(workerCount.first?["count"] as? Int64 ?? 0),
            buildings: Int(buildingCount.first?["count"] as? Int64 ?? 0),
            tasks: Int(taskCount.first?["count"] as? Int64 ?? 0)
        )
    }
}

// MARK: - Debug Menu Extension

#if DEBUG
extension DatabaseSeeder {
    /// Convenience method for debug builds
    static func seedIfNeeded() async {
        let result = await shared.seedDatabase()
        if !result.success {
            print("⚠️ Database seeding failed in debug build")
        }
    }
}
#endif
