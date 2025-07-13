//
//  DatabaseSeeder.swift
//  FrancoSphere
//
//  🚀 MIGRATED TO GRDB.swift - Utility class for seeding database
//  ✅ Maintains all existing functionality
//  ✅ Uses GRDB.swift for better performance and real-time observation
//  ✅ Compatible with existing RealWorldDataSeeder calls
//

import Foundation
import GRDB

/// Utility class for seeding the database with test data
class DatabaseSeeder {
    
    static let shared = DatabaseSeeder()
    
    private init() {}
    
    /// Seeds the database with real-world data
    /// - Returns: A tuple with (success: Bool, message: String)
    func seedDatabase() async -> (success: Bool, message: String) {
        do {
            print("🌱 Starting database seed...")
            
            // Get database instance (now GRDB)
            let db = GRDBManager.shared
            
            // Ensure database is initialized
            if !db.isDatabaseReady() {
                db.quickInitialize()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Use RealWorldDataSeeder to populate data (adapted for GRDB)
            try await RealWorldDataSeeder.seedAllRealData(db)
            
            // Get stats to verify
            let stats = try await getDatabaseStats(db)
            
            let message = """
            ✅ Database seeded successfully with GRDB!
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
            let db = GRDBManager.shared
            
            // Ensure database is initialized
            if !db.isDatabaseReady() {
                db.quickInitialize()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Basic worker data using GRDB
            try await db.execute("""
                INSERT OR REPLACE INTO workers (id, name, email, role, passwordHash)
                VALUES (3, 'Edwin Lema', 'edwinlema911@gmail.com', 'worker', '');
            """)
            
            // Basic building data
            try await db.execute("""
                INSERT OR REPLACE INTO buildings (id, name, address, latitude, longitude)
                VALUES (17, 'Stuyvesant Cove Park', 'FDR Drive & E 20th St', 40.731234, -73.971456);
            """)
            
            return (true, "✅ Basic data seeded with GRDB")
            
        } catch {
            return (false, "❌ Basic seed failed: \(error.localizedDescription)")
        }
    }
    
    /// Imports tasks from CSV (if you still need this)
    func importCSVTasks() async -> (success: Bool, message: String) {
        do {
            // Note: OperationalDataManager will need to be updated for GRDB too
            let (count, errors) = try await OperationalDataManager.shared.importRealWorldTasks()
            
            let message = """
            ✅ Imported \(count) tasks with GRDB
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
            let db = GRDBManager.shared
            
            // Ensure database is initialized
            if !db.isDatabaseReady() {
                db.quickInitialize()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Clear tables in reverse dependency order using GRDB
            try await db.execute("DELETE FROM routine_tasks")
            try await db.execute("DELETE FROM tasks")
            try await db.execute("DELETE FROM worker_assignments")
            try await db.execute("DELETE FROM worker_skills")
            try await db.execute("DELETE FROM buildings")
            try await db.execute("DELETE FROM workers")
            try await db.execute("DELETE FROM app_settings")
            
            return (true, "✅ Database cleared successfully with GRDB")
            
        } catch {
            return (false, "❌ Clear failed: \(error.localizedDescription)")
        }
    }
    
    /// Gets current database statistics
    private func getDatabaseStats(_ db: GRDBManager) async throws -> (workers: Int, buildings: Int, tasks: Int) {
        let workerCount = try await db.query("SELECT COUNT(*) as count FROM workers")
        let buildingCount = try await db.query("SELECT COUNT(*) as count FROM buildings")
        let taskCount = try await db.query("SELECT COUNT(*) as count FROM routine_tasks")
        
        return (
            workers: Int(workerCount.first?["count"] as? Int64 ?? 0),
            buildings: Int(buildingCount.first?["count"] as? Int64 ?? 0),
            tasks: Int(taskCount.first?["count"] as? Int64 ?? 0)
        )
    }
    
    // MARK: - GRDB-Specific Methods (New capabilities)
    
    /// Seeds database with real-time observation setup
    func seedWithObservation() async -> (success: Bool, message: String) {
        let result = await seedDatabase()
        
        if result.success {
            // Set up real-time observations for live data
            setupDatabaseObservations()
            return (true, result.message + "\n🔄 Real-time observations enabled")
        }
        
        return result
    }
    
    /// Sets up real-time database observations (GRDB's killer feature)
    private func setupDatabaseObservations() {
        print("🔄 Setting up GRDB real-time observations...")
        
        // Example: Observe building changes
        // This will be used by your services for real-time updates
        let buildingObservation = GRDBManager.shared.observeBuildings()
        
        // Example: Observe task changes for a specific building
        // let taskObservation = GRDBManager.shared.observeTasks(for: "17")
        
        print("✅ Real-time observations configured")
    }
    
    /// Validates database integrity (GRDB version)
    func validateDatabase() async -> (success: Bool, message: String) {
        do {
            let db = GRDBManager.shared
            
            // Check foreign key constraints
            let fkCheck = try await db.query("PRAGMA foreign_key_check")
            if !fkCheck.isEmpty {
                return (false, "❌ Foreign key constraint violations found")
            }
            
            // Check table integrity
            let integrityCheck = try await db.query("PRAGMA integrity_check")
            let result = integrityCheck.first?["integrity_check"] as? String ?? "corrupt"
            
            if result != "ok" {
                return (false, "❌ Database integrity check failed: \(result)")
            }
            
            // Check worker assignments
            let assignments = try await db.query("""
                SELECT COUNT(*) as count FROM worker_assignments 
                WHERE worker_id = '2'
            """)
            
            let edwinAssignments = assignments.first?["count"] as? Int64 ?? 0
            
            let message = """
            ✅ Database validation passed
            📊 Edwin has \(edwinAssignments) building assignments
            🔧 Foreign keys: Valid
            🗃️ Integrity: OK
            """
            
            return (true, message)
            
        } catch {
            return (false, "❌ Validation failed: \(error.localizedDescription)")
        }
    }
    
    /// Exports database to JSON (useful for debugging)
    func exportToJSON() async -> (success: Bool, data: String?) {
        do {
            let db = GRDBManager.shared
            
            // Export all tables to JSON
            let workers = try await db.query("SELECT * FROM workers")
            let buildings = try await db.query("SELECT * FROM buildings")
            let assignments = try await db.query("SELECT * FROM worker_assignments")
            let tasks = try await db.query("SELECT * FROM routine_tasks LIMIT 10") // Limit for readability
            
            let exportData = [
                "workers": workers,
                "buildings": buildings,
                "assignments": assignments,
                "tasks": tasks,
                "export_date": ISO8601DateFormatter().string(from: Date())
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            
            return (true, jsonString)
            
        } catch {
            print("❌ Export failed: \(error)")
            return (false, nil)
        }
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
    
    /// Quick debug info
    static func debugInfo() async {
        let validation = await shared.validateDatabase()
        print("🐛 Debug validation: \(validation.message)")
        
        if let (_, jsonData) = await shared.exportToJSON(), let data = jsonData {
            print("📄 Database export sample:")
            print(String(data.prefix(500)) + "...")
        }
    }
}
#endif

// MARK: - Migration Compatibility

extension DatabaseSeeder {
    /// Maintains compatibility with existing code that calls seedDatabase
    @available(*, deprecated, message: "Use seedDatabase() instead")
    func legacySeed() async -> Bool {
        let result = await seedDatabase()
        return result.success
    }
    
    /// Helper for code that expects synchronous seeding
    func seedDatabaseSync() -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            let seedResult = await seedDatabase()
            result = seedResult.success
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
}
