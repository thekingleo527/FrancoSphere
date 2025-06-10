//
//  DataBootstrapper.swift
//  FrancoSphere
//
//  Seeds SQLite with CSV data the first time the app launches.
//

import Foundation

enum DataBootstrapper {

    /// Run once per fresh install; guarded by UserDefaults.
    static func runIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "SeedComplete") else { return }
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
        let manager = SQLiteManager.shared
        
        try await seedBuildings(manager: manager)
        try await seedWorkers(manager: manager)
        try await seedSchedules(manager: manager)
        // routine_repository_seed.csv will be parsed in a later phase.
    }

    private static func seedBuildings(manager: SQLiteManager) async throws {
        guard let url = Bundle.main.url(forResource: "buildings", withExtension: "csv") else {
            print("⚠️ buildings.csv not found in bundle")
            return
        }
        
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
        print("✅ Seeded \(rows.count - 1) buildings")
    }

    private static func seedWorkers(manager: SQLiteManager) async throws {
        guard let url = Bundle.main.url(forResource: "workers", withExtension: "csv") else {
            print("⚠️ workers.csv not found in bundle")
            return
        }
        
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
        print("✅ Seeded \(rows.count - 1) workers")
    }

    private static func seedSchedules(manager: SQLiteManager) async throws {
        guard let url = Bundle.main.url(forResource: "worker_schedule_seed", withExtension: "csv") else {
            print("⚠️ worker_schedule_seed.csv not found in bundle")
            return
        }
        
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
        print("✅ Seeded \(rows.count - 1) schedules")
    }
}
