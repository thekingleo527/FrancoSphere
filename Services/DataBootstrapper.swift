//
//  DataBootstrapper.swift
//  FrancoSphere
//
//  ✅ UPDATED: Removed all CSV file parsing dependencies
//  ✅ PRESERVED: All hardcoded data and database insertion logic
//  ✅ CHANGED: CSVDataImporter → OperationalDataManager reference
//

import Foundation

// MARK: - DataBootstrapper
enum DataBootstrapper {

    /// Run once per fresh install; guarded by UserDefaults.
    static func runIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "SeedComplete") else {
            print("✅ Seed already completed, skipping")
            return
        }
        
        Task.detached {
            do {
                try await seed()
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "SeedComplete")
                }
                print("✅ Database seed finished.")
            } catch {
                print("🚨 Database seed failed: \(error)")
            }
        }
    }

    // MARK: - Private

    private static func seed() async throws {
        // Wait for SQLiteManager to be ready
        let manager = try await SQLiteManager.start()
        
        // Check if we already have data
        let existingWorkers = try await manager.query("SELECT COUNT(*) as count FROM workers", [])
        if let count = existingWorkers.first?["count"] as? Int64, count > 0 {
            print("✅ Data already exists, skipping seed")
            
            // But make sure we import tasks from OperationalDataManager (on MainActor)
            await MainActor.run {
                Task {
                    await importRealWorldTasks(manager: manager)
                }
            }
            return
        }
        
        // Seed basic data first (using hardcoded data only)
        try await seedBuildings(manager: manager)
        try await seedWorkers(manager: manager)
        try await seedSchedules(manager: manager)
        
        // Import real-world tasks using OperationalDataManager (on MainActor)
        await MainActor.run {
            Task {
                await importRealWorldTasks(manager: manager)
            }
        }
    }
    
    // MARK: - Real-World Task Import (UPDATED: Uses OperationalDataManager)
    
    @MainActor
    private static func importRealWorldTasks(manager: SQLiteManager) async {
        print("📋 Importing real-world tasks using OperationalDataManager...")
        
        let operationalManager = OperationalDataManager.shared  // ✅ CHANGED: from CSVDataImporter
        operationalManager.sqliteManager = manager
        
        do {
            let (imported, errors) = try await operationalManager.importRealWorldTasks()
            print("✅ Imported \(imported) real-world tasks")
            
            if !errors.isEmpty {
                print("⚠️ \(errors.count) errors during task import:")
                for error in errors.prefix(5) { // Show first 5 errors
                    print("  - \(error)")
                }
            }
        } catch {
            print("❌ Failed to import real-world tasks: \(error)")
        }
    }

    // MARK: - Building Seed (UPDATED: Hardcoded data only)
    
    private static func seedBuildings(manager: SQLiteManager) async throws {
        // ✅ ALWAYS use hardcoded buildings (no CSV file checking)
        try await seedBuildingsHardcoded(manager: manager)
    }
    
    // ❌ REMOVED: seedBuildingsFromCSV method entirely
    
    private static func seedBuildingsHardcoded(manager: SQLiteManager) async throws {
        print("📍 Seeding hardcoded buildings...")
        
        let hardcodedBuildings = [
            (id: 1, name: "12 West 18th Street", address: "12 West 18th Street, New York, NY", lat: 40.7390, lon: -73.9936),
            (id: 2, name: "117 West 17th Street", address: "117 West 17th Street, New York, NY", lat: 40.7380, lon: -73.9946),
            (id: 3, name: "112 West 18th Street", address: "112 West 18th Street, New York, NY", lat: 40.7385, lon: -73.9940),
            (id: 4, name: "135-139 West 17th", address: "135-139 West 17th Street, New York, NY", lat: 40.7375, lon: -73.9950),
            (id: 5, name: "136 West 17th", address: "136 West 17th Street, New York, NY", lat: 40.7376, lon: -73.9951),
            (id: 6, name: "138 West 17th Street", address: "138 West 17th Street, New York, NY", lat: 40.7377, lon: -73.9952),
            (id: 7, name: "131 Perry Street", address: "131 Perry Street, New York, NY", lat: 40.7358, lon: -74.0042),
            (id: 8, name: "68 Perry Street", address: "68 Perry Street, New York, NY", lat: 40.7354, lon: -74.0038),
            (id: 9, name: "41 Elizabeth Street", address: "41 Elizabeth Street, New York, NY", lat: 40.7157, lon: -73.9927),
            (id: 10, name: "104 Franklin", address: "104 Franklin Street, New York, NY", lat: 40.7197, lon: -74.0073),
            (id: 11, name: "36 Walker", address: "36 Walker Street, New York, NY", lat: 40.7184, lon: -74.0031),
            (id: 12, name: "123 1st Ave", address: "123 1st Avenue, New York, NY", lat: 40.7282, lon: -73.9857),
            (id: 13, name: "178 Spring", address: "178 Spring Street, New York, NY", lat: 40.7244, lon: -73.9972),
            (id: 14, name: "Rubin Museum (142–148 W 17th)", address: "142-148 West 17th Street, New York, NY", lat: 40.7378, lon: -73.9953),
            (id: 15, name: "133 East 15th Street", address: "133 East 15th Street, New York, NY", lat: 40.7348, lon: -73.9879),
            (id: 16, name: "29–31 East 20th", address: "29-31 East 20th Street, New York, NY", lat: 40.7388, lon: -73.9880),
            (id: 17, name: "115 7th Ave", address: "115 7th Avenue, New York, NY", lat: 40.7413, lon: -73.9991),
            (id: 18, name: "Stuyvesant Cove Park", address: "Stuyvesant Cove Park, New York, NY", lat: 40.7102, lon: -73.9706),
            (id: 99, name: "FrancoSphere HQ", address: "Virtual Office", lat: 40.7589, lon: -73.9851)
        ]
        
        for building in hardcodedBuildings {
            let sql = """
                INSERT OR REPLACE INTO buildings (id, name, address, latitude, longitude, imageAssetName)
                VALUES (?, ?, ?, ?, ?, ?)
            """
            let imageAssetName = building.name.replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "-", with: "_")
                .replacingOccurrences(of: "–", with: "_")
            
            try await manager.execute(sql, [
                building.id, building.name, building.address,
                building.lat, building.lon, imageAssetName
            ])
        }
        
        print("✅ Seeded \(hardcodedBuildings.count) hardcoded buildings")
    }

    // MARK: - Worker Seed (UPDATED: Hardcoded data only)

    private static func seedWorkers(manager: SQLiteManager) async throws {
        // ✅ ALWAYS use hardcoded workers (no CSV file checking)
        try await seedWorkersHardcoded(manager: manager)
    }
    
    // ❌ REMOVED: seedWorkersFromCSV method entirely
    
    private static func seedWorkersHardcoded(manager: SQLiteManager) async throws {
        print("👷 Seeding hardcoded workers...")
        
        let hardcodedWorkers = [
            (id: 1, name: "Admin User", email: "admin@francosphere.com", role: "admin"),
            (id: 2, name: "Greg Foster", email: "greg@francosphere.com", role: "worker"),
            (id: 3, name: "Edwin Paredes", email: "edwin@francosphere.com", role: "worker"),
            (id: 4, name: "Kevin Dutan", email: "kevin@francosphere.com", role: "worker"),
            (id: 5, name: "Richard Mazon", email: "richard@francosphere.com", role: "worker"),
            (id: 6, name: "Daniel Rosales", email: "daniel@francosphere.com", role: "worker"),
            (id: 7, name: "Felix Estrada", email: "felix@francosphere.com", role: "worker"),
            (id: 8, name: "Liam Burke", email: "liam@francosphere.com", role: "worker")
        ]
        
        for worker in hardcodedWorkers {
            let sql = """
                INSERT OR REPLACE INTO workers (id, name, email, role, password)
                VALUES (?, ?, ?, ?, ?)
            """
            try await manager.execute(sql, [
                worker.id, worker.name, worker.email, worker.role, "password"
            ])
            print("📥 Seeded worker: \(worker.name) (\(worker.email))")
        }
        
        print("✅ Seeded \(hardcodedWorkers.count) hardcoded workers")
    }

    // MARK: - Schedule Seed (UPDATED: Hardcoded data only)

    private static func seedSchedules(manager: SQLiteManager) async throws {
        // ✅ ALWAYS use hardcoded schedules (no CSV file checking)
        try await seedSchedulesHardcoded(manager: manager)
    }
    
    // ❌ REMOVED: seedSchedulesFromCSV method entirely
    
    private static func seedSchedulesHardcoded(manager: SQLiteManager) async throws {
        print("⏰ Seeding hardcoded schedules...")
        
        let hardcodedSchedules = [
            (workerId: 2, buildingId: 1, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 9, endHour: 15),  // Greg
            (workerId: 3, buildingId: 2, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 6, endHour: 15),  // Edwin
            (workerId: 4, buildingId: 3, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 6, endHour: 18),  // Kevin
            (workerId: 5, buildingId: 4, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 8, endHour: 16),  // Richard
            (workerId: 6, buildingId: 5, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 8, endHour: 16),  // Daniel
            (workerId: 7, buildingId: 6, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 8, endHour: 16),  // Felix
            (workerId: 8, buildingId: 7, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 8, endHour: 16)   // Liam
        ]
        
        for schedule in hardcodedSchedules {
            let sql = """
                INSERT OR REPLACE INTO worker_schedule (workerId, buildingId, weekdays, startHour, endHour)
                VALUES (?, ?, ?, ?, ?)
            """
            try await manager.execute(sql, [
                schedule.workerId, schedule.buildingId, schedule.weekdays,
                schedule.startHour, schedule.endHour
            ])
        }
        
        print("✅ Seeded \(hardcodedSchedules.count) hardcoded schedules")
    }
}
