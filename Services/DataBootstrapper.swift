//
//  DataBootstrapper.swift
//  FrancoSphere
//
//  Seeds SQLite with real-world data the first time the app launches.
//  Updated to work with hardcoded task data instead of CSV files.
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
                print("✅ CSV seed finished.")
            } catch {
                print("🚨 CSV seed failed: \(error)")
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
            
            // But make sure we import tasks from CSVDataImporter (on MainActor)
            await MainActor.run {
                Task {
                    await importRealWorldTasks(manager: manager)
                }
            }
            return
        }
        
        // Seed basic data first
        try await seedBuildings(manager: manager)
        try await seedWorkers(manager: manager)
        try await seedSchedules(manager: manager)
        
        // Import real-world tasks using CSVDataImporter (on MainActor)
        await MainActor.run {
            Task {
                await importRealWorldTasks(manager: manager)
            }
        }
    }
    
    // MARK: - Real-World Task Import
    
    @MainActor
    private static func importRealWorldTasks(manager: SQLiteManager) async {
        print("📋 Importing real-world tasks using CSVDataImporter...")
        
        let importer = CSVDataImporter.shared
        importer.sqliteManager = manager
        
        do {
            let (imported, errors) = try await importer.importRealWorldTasks()
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

    private static func seedBuildings(manager: SQLiteManager) async throws {
        // First check if we have CSV file
        if let url = Bundle.main.url(forResource: "buildings", withExtension: "csv") {
            try await seedBuildingsFromCSV(manager: manager, url: url)
        } else {
            // Fallback to hardcoded buildings
            try await seedBuildingsHardcoded(manager: manager)
        }
    }
    
    private static func seedBuildingsFromCSV(manager: SQLiteManager, url: URL) async throws {
        let rows = try CSVLoader.rows(from: url)
        guard let header = rows.first else { return }
        let map = CSVLoader.headerMap(header)

        for r in rows.dropFirst() {
            // Note: headerMap converts to lowercase, so use lowercase keys
            guard let idIndex = map["id"],
                  let nameIndex = map["name"],
                  let addressIndex = map["address"],
                  let latIndex = map["latitude"],
                  let lonIndex = map["longitude"],
                  r.count > max(idIndex, nameIndex, addressIndex, latIndex, lonIndex),
                  let id = Int64(r[idIndex]) else {
                continue
            }
            
            let name = r[nameIndex]
            let address = r[addressIndex]
            let lat = Double(r[latIndex]) ?? 0
            let lon = Double(r[lonIndex]) ?? 0
            
            // Insert building using SQLiteManager's execute method
            let sql = """
                INSERT OR REPLACE INTO buildings (id, name, address, latitude, longitude, imageAssetName)
                VALUES (?, ?, ?, ?, ?, ?)
            """
            // Generate a default image asset name from the building name
            let imageAssetName = name.replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "-", with: "_")
            
            try await manager.execute(sql, [id, name, address, lat, lon, imageAssetName])
        }
        print("✅ Seeded \(rows.count - 1) buildings from CSV")
    }
    
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
            (id: 14, name: "133 East 15th Street", address: "133 East 15th Street, New York, NY", lat: 40.7348, lon: -73.9879),
            (id: 15, name: "29–31 East 20th", address: "29-31 East 20th Street, New York, NY", lat: 40.7388, lon: -73.9880),
            (id: 16, name: "115 7th Ave", address: "115 7th Avenue, New York, NY", lat: 40.7413, lon: -73.9991),
            (id: 17, name: "Stuyvesant Cove Park", address: "Stuyvesant Cove Park, New York, NY", lat: 40.7102, lon: -73.9706),
            (id: 18, name: "Rubin Museum (142–148 W 17th)", address: "142-148 West 17th Street, New York, NY", lat: 40.7378, lon: -73.9953),
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

    private static func seedWorkers(manager: SQLiteManager) async throws {
        // First check if we have CSV file
        if let url = Bundle.main.url(forResource: "workers", withExtension: "csv") {
            try await seedWorkersFromCSV(manager: manager, url: url)
        } else {
            // Fallback to hardcoded workers
            try await seedWorkersHardcoded(manager: manager)
        }
    }
    
    private static func seedWorkersFromCSV(manager: SQLiteManager, url: URL) async throws {
        let rows = try CSVLoader.rows(from: url)
        guard let header = rows.first else { return }
        let map = CSVLoader.headerMap(header)

        for r in rows.dropFirst() {
            // Note: headerMap converts to lowercase, so use lowercase keys
            guard let idIndex = map["id"],
                  let nameIndex = map["full_name"] ?? map["name"], // Try both column names
                  let emailIndex = map["email"],
                  r.count > max(idIndex, nameIndex, emailIndex),
                  let id = Int64(r[idIndex]) else {
                continue
            }
            
            let name = r[nameIndex]
            let email = r[emailIndex]
            let uid = map["uid"].flatMap { r.count > $0 ? r[$0] : nil } ?? ""
            let role = map["role"].flatMap { r.count > $0 ? r[$0] : nil } ?? "worker"
            let rateStr = map["base_rate"].flatMap { r.count > $0 ? r[$0] : nil } ?? "0"
            let rate = Double(rateStr) ?? 0
            let skillsStr = map["skills"].flatMap { r.count > $0 ? r[$0] : nil } ?? ""
            
            // Insert worker using SQLiteManager's execute method
            let sql = """
                INSERT OR REPLACE INTO workers (id, name, email, role, passwordHash)
                VALUES (?, ?, ?, ?, ?)
            """
            // Use default password for seeded workers
            try await manager.execute(sql, [id, name, email, role, "password"])
            
            print("📥 Seeded worker: \(name) (\(email))")
        }
        print("✅ Seeded \(rows.count - 1) workers from CSV")
    }
    
    private static func seedWorkersHardcoded(manager: SQLiteManager) async throws {
        print("👷 Seeding hardcoded workers...")
        
        let hardcodedWorkers = [
            (id: 1, name: "Kevin Dutan", email: "kevin.dutan@francosphere.com", role: "worker"),
            (id: 2, name: "Mercedes Inamagua", email: "mercedes.inamagua@francosphere.com", role: "worker"),
            (id: 3, name: "Edwin Lema", email: "edwinlema911@gmail.com", role: "worker"),
            (id: 4, name: "Luis Lopez", email: "luis.lopez@francosphere.com", role: "worker"),
            (id: 5, name: "Angel Guirachocha", email: "angel.guirachocha@francosphere.com", role: "worker"),
            (id: 6, name: "Greg Hutson", email: "greg.hutson@francosphere.com", role: "worker"),
            (id: 7, name: "Shawn Magloire", email: "shawn@francosphere.com", role: "admin")
        ]
        
        for worker in hardcodedWorkers {
            let sql = """
                INSERT OR REPLACE INTO workers (id, name, email, role, passwordHash)
                VALUES (?, ?, ?, ?, ?)
            """
            try await manager.execute(sql, [
                worker.id, worker.name, worker.email, worker.role, "password"
            ])
            print("📥 Seeded worker: \(worker.name) (\(worker.email))")
        }
        
        print("✅ Seeded \(hardcodedWorkers.count) hardcoded workers")
    }

    private static func seedSchedules(manager: SQLiteManager) async throws {
        // First check if we have CSV file
        if let url = Bundle.main.url(forResource: "worker_schedule_seed", withExtension: "csv") {
            try await seedSchedulesFromCSV(manager: manager, url: url)
        } else {
            // Fallback to hardcoded schedules
            try await seedSchedulesHardcoded(manager: manager)
        }
    }
    
    private static func seedSchedulesFromCSV(manager: SQLiteManager, url: URL) async throws {
        let rows = try CSVLoader.rows(from: url)
        guard let header = rows.first else { return }
        let map = CSVLoader.headerMap(header)

        for r in rows.dropFirst() {
            // Note: headerMap converts to lowercase, so use lowercase keys
            guard let widIndex = map["worker_id"],
                  let bidIndex = map["building_id"],
                  r.count > max(widIndex, bidIndex),
                  let wid = Int64(r[widIndex]),
                  let bid = Int64(r[bidIndex]) else {
                continue
            }

            let weekdaysStr = map["weekdays"].flatMap { r.count > $0 ? r[$0] : nil } ?? ""
            let startHrStr = map["start_hour"].flatMap { r.count > $0 ? r[$0] : nil } ?? "8"
            let endHrStr = map["end_hour"].flatMap { r.count > $0 ? r[$0] : nil } ?? "16"
            let startHr = Int(startHrStr) ?? 8
            let endHr = Int(endHrStr) ?? 16

            // Insert schedule using SQLiteManager's execute method
            let sql = """
                INSERT OR REPLACE INTO worker_schedule (workerId, buildingId, weekdays, startHour, endHour)
                VALUES (?, ?, ?, ?, ?)
            """
            try await manager.execute(sql, [wid, bid, weekdaysStr, startHr, endHr])
        }
        print("✅ Seeded \(rows.count - 1) schedules from CSV")
    }
    
    private static func seedSchedulesHardcoded(manager: SQLiteManager) async throws {
        print("📅 Seeding hardcoded schedules...")
        
        // Based on the real-world task assignments from CSVDataImporter
        let hardcodedSchedules = [
            // Kevin Dutan - Mon-Fri 06:00-17:00
            (workerId: 1, buildingId: 7, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 6, endHour: 17), // 131 Perry
            (workerId: 1, buildingId: 8, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 6, endHour: 17), // 68 Perry
            (workerId: 1, buildingId: 4, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 6, endHour: 17), // 135-139 W 17th
            
            // Mercedes Inamagua - 06:30-11:00
            (workerId: 2, buildingId: 3, weekdays: "Mon,Tue,Wed,Thu,Fri,Sat", startHour: 6, endHour: 11), // 112 W 18th
            (workerId: 2, buildingId: 2, weekdays: "Mon,Tue,Wed,Thu,Fri,Sat", startHour: 6, endHour: 11), // 117 W 17th
            (workerId: 2, buildingId: 10, weekdays: "Mon,Thu", startHour: 14, endHour: 16), // 104 Franklin
            
            // Edwin Lema - 06:00-15:00
            (workerId: 3, buildingId: 17, weekdays: "Mon,Tue,Wed,Thu,Fri,Sat,Sun", startHour: 6, endHour: 15), // Stuyvesant Park
            (workerId: 3, buildingId: 14, weekdays: "Mon,Wed,Fri", startHour: 6, endHour: 15), // 133 E 15th
            (workerId: 3, buildingId: 99, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 13, endHour: 15), // HQ
            
            // Luis Lopez - 07:00-16:00
            (workerId: 4, buildingId: 9, weekdays: "Mon,Tue,Wed,Thu,Fri,Sat", startHour: 7, endHour: 16), // 41 Elizabeth
            (workerId: 4, buildingId: 10, weekdays: "Mon,Wed,Fri", startHour: 7, endHour: 16), // 104 Franklin
            (workerId: 4, buildingId: 11, weekdays: "Mon,Wed,Fri", startHour: 7, endHour: 16), // 36 Walker
            
            // Angel Guirachocha - 18:00-22:00
            (workerId: 5, buildingId: 1, weekdays: "Mon,Wed,Fri", startHour: 18, endHour: 22), // 12 W 18th
            (workerId: 5, buildingId: 8, weekdays: "Mon,Wed,Fri", startHour: 18, endHour: 22), // 68 Perry
            (workerId: 5, buildingId: 12, weekdays: "Tue,Thu", startHour: 18, endHour: 22), // 123 1st Ave
            
            // Greg Hutson - 09:00-15:00
            (workerId: 6, buildingId: 1, weekdays: "Mon,Tue,Wed,Thu,Fri", startHour: 9, endHour: 15), // 12 W 18th
            
            // Shawn Magloire - Floating specialist
            (workerId: 7, buildingId: 2, weekdays: "Mon", startHour: 9, endHour: 11), // 117 W 17th
            (workerId: 7, buildingId: 14, weekdays: "Tue", startHour: 11, endHour: 13), // 133 E 15th
            (workerId: 7, buildingId: 5, weekdays: "Wed", startHour: 13, endHour: 15), // 136 W 17th
            (workerId: 7, buildingId: 6, weekdays: "Thu", startHour: 15, endHour: 17), // 138 W 17th
            (workerId: 7, buildingId: 16, weekdays: "Fri", startHour: 9, endHour: 11), // 115 7th Ave
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
