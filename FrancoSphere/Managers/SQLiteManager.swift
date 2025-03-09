// SQLiteManager.swift
// SQLite database manager for the FrancoSphere application

import Foundation
import SQLite
import SwiftUI

class SQLiteManager {
    static let shared = SQLiteManager()
    var db: Connection!

    private init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/FrancoSphere.sqlite3")
            createTables()
        } catch {
            print("SQLite connection error: \(error)")
        }
    }

    private func createTables() {
        createTasksTable()
        createWorkersTable()
        createBuildingsTable()
        createTimeLogsTable()
        createInventoryTable()
    }

    private func createTasksTable() {
        do {
            try db.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                buildingId INTEGER,
                workerId INTEGER,
                isCompleted INTEGER DEFAULT 0,
                scheduledDate TEXT,
                recurrence TEXT DEFAULT 'oneTime',
                urgencyLevel TEXT DEFAULT 'medium',
                category TEXT DEFAULT 'maintenance',
                startTime TEXT,
                endTime TEXT
            )
            """)
            print("Tasks table created successfully")
        } catch {
            print("Tasks table creation error: \(error)")
        }
    }

    private func createWorkersTable() {
        do {
            try db.execute("""
            CREATE TABLE IF NOT EXISTS workers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                role TEXT NOT NULL
            )
            """)
            print("Workers table created successfully")
            insertRealWorkers()
        } catch {
            print("Workers table creation error: \(error)")
        }
    }

    private func createBuildingsTable() {
        do {
            try db.execute("""
            CREATE TABLE IF NOT EXISTS buildings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                address TEXT,
                latitude REAL,
                longitude REAL,
                imageAssetName TEXT
            )
            """)
            print("Buildings table created successfully")
            insertRealBuildings()
        } catch {
            print("Buildings table creation error: \(error)")
        }
    }
    
    private func createTimeLogsTable() {
        do {
            try db.execute("""
            CREATE TABLE IF NOT EXISTS worker_time_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                workerId INTEGER NOT NULL,
                buildingId INTEGER NOT NULL,
                clockInTime TEXT NOT NULL,
                clockOutTime TEXT
            )
            """)
            print("Worker time logs table created successfully")
        } catch {
            print("Worker time logs table creation error: \(error)")
        }
    }
    
    // MARK: - Inventory Table and Methods
    
    private func createInventoryTable() {
        do {
            try db.execute("""
            CREATE TABLE IF NOT EXISTS inventory (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                building_id TEXT NOT NULL,
                name TEXT NOT NULL,
                quantity INTEGER NOT NULL DEFAULT 0,
                unit TEXT NOT NULL DEFAULT 'unit',
                minimum_quantity INTEGER NOT NULL DEFAULT 5,
                category TEXT NOT NULL DEFAULT 'general',
                last_restocked TEXT,
                location TEXT DEFAULT '',
                notes TEXT
            )
            """)
            print("Inventory table created successfully")
            insertSampleInventoryItems()
        } catch {
            print("Inventory table creation error: \(error)")
        }
    }
    
    private func insertSampleInventoryItems() {
        do {
            let count = try db.scalar("SELECT COUNT(*) FROM inventory") as? Int64 ?? 0
            
            if count == 0 {
                try db.transaction {
                    let buildings = getAllBuildings()
                    
                    for building in buildings {
                        let buildingId = building["id"] as! Int64
                        let buildingIdString = String(buildingId)
                        
                        let currentDate = Date()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let dateString = dateFormatter.string(from: currentDate)
                        
                        try db.run("INSERT INTO inventory (building_id, name, quantity, unit, minimum_quantity, category, last_restocked, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                  buildingIdString, "Light Bulbs", Int.random(in: 5...20), "pcs", 10, "electrical", dateString, "Storage Room 1")
                        
                        try db.run("INSERT INTO inventory (building_id, name, quantity, unit, minimum_quantity, category, last_restocked, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                  buildingIdString, "Air Filters", Int.random(in: 2...8), "pcs", 4, "hvac", dateString, "Storage Room 2")
                        
                        try db.run("INSERT INTO inventory (building_id, name, quantity, unit, minimum_quantity, category, last_restocked, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                  buildingIdString, "Cleaning Solution", Int.random(in: 1...5), "bottles", 2, "cleaning", dateString, "Janitor Closet")
                        
                        try db.run("INSERT INTO inventory (building_id, name, quantity, unit, minimum_quantity, category, last_restocked, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                  buildingIdString, "Toilet Paper", Int.random(in: 10...50), "rolls", 20, "other", dateString, "Bathroom Supply Closet")
                        
                        try db.run("INSERT INTO inventory (building_id, name, quantity, unit, minimum_quantity, category, last_restocked, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                  buildingIdString, "Plumbing Tape", Int.random(in: 1...5), "rolls", 2, "plumbing", dateString, "Tool Room")
                    }
                }
                print("Sample inventory items inserted successfully")
            }
        } catch {
            print("Error checking/inserting inventory: \(error)")
        }
    }
    
    func isInventoryReady(forBuilding id: String) -> Bool {
        do {
            let tableExists = try db.scalar("SELECT name FROM sqlite_master WHERE type='table' AND name='inventory'") as? String != nil
            if !tableExists {
                return false
            }
            let _ = try db.scalar("SELECT COUNT(*) FROM inventory WHERE building_id = ?", id) as? Int64
            return true
        } catch {
            print("Inventory not ready: \(error.localizedDescription)")
            return false
        }
    }
    
    func getInventoryItemsSafe(forBuilding id: String) -> [FrancoSphere.InventoryItem] {
        if !isInventoryReady(forBuilding: id) {
            return []
        }
        do {
            return getInventoryItems(forBuilding: id)
        } catch {
            print("Error fetching inventory: \(error.localizedDescription)")
            return []
        }
    }
    
    func getInventoryItems(forBuilding id: String) -> [FrancoSphere.InventoryItem] {
        var inventoryItems: [FrancoSphere.InventoryItem] = []
        do {
            let query = """
            SELECT id, building_id, name, quantity, unit, minimum_quantity, category, last_restocked, location, notes
            FROM inventory
            WHERE building_id = ?
            ORDER BY name
            """
            for row in try db.prepare(query, id) {
                guard let rowId = row[0] as? Int64,
                      let buildingId = row[1] as? String,
                      let name = row[2] as? String,
                      let quantity = row[3] as? Int64,
                      let unit = row[4] as? String,
                      let minimumQuantity = row[5] as? Int64,
                      let categoryString = row[6] as? String,
                      let lastRestockedString = row[7] as? String,
                      let location = row[8] as? String else {
                    continue
                }
                let notes = row[9] as? String
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let lastRestockedDate = dateFormatter.date(from: lastRestockedString) ?? Date()
                let category = FrancoSphere.InventoryCategory(rawValue: categoryString) ?? .other
                let item = FrancoSphere.InventoryItem(
                    id: String(rowId),
                    name: name,
                    buildingID: buildingId,
                    category: category,
                    quantity: Int(quantity),
                    unit: unit,
                    minimumQuantity: Int(minimumQuantity),
                    needsReorder: Int(quantity) <= Int(minimumQuantity),
                    lastRestockDate: lastRestockedDate,
                    location: location,
                    notes: notes
                )
                inventoryItems.append(item)
            }
        } catch {
            print("Error fetching inventory items: \(error)")
        }
        return inventoryItems
    }
    
    func updateInventoryItemQuantity(itemId: String, newQuantity: Int) -> Bool {
        do {
            let query = """
            UPDATE inventory
            SET quantity = ?, last_restocked = ?
            WHERE id = ?
            """
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let currentDateString = dateFormatter.string(from: Date())
            try db.run(query, newQuantity, currentDateString, itemId)
            return true
        } catch {
            print("Error updating inventory item: \(error)")
            return false
        }
    }
    
    func addInventoryItem(buildingId: String, name: String, quantity: Int, unit: String,
                         minimumQuantity: Int, category: FrancoSphere.InventoryCategory) -> Bool {
        do {
            let query = """
            INSERT INTO inventory (building_id, name, quantity, unit, minimum_quantity, category, last_restocked, location)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let currentDateString = dateFormatter.string(from: Date())
            try db.run(query, buildingId, name, quantity, unit, minimumQuantity,
                     category.rawValue, currentDateString, "Storage Room")
            return true
        } catch {
            print("Error adding inventory item: \(error)")
            return false
        }
    }
    
    func deleteInventoryItem(itemId: String) -> Bool {
        do {
            let query = "DELETE FROM inventory WHERE id = ?"
            try db.run(query, itemId)
            return true
        } catch {
            print("Error deleting inventory item: \(error)")
            return false
        }
    }
    
    // MARK: - Insert Real Data Methods
    
    private func insertRealWorkers() {
        do {
            try db.execute("""
            INSERT OR IGNORE INTO workers (id, name, email, role)
            VALUES 
            (1, 'Greg Hutson', 'g.hutson1989@gmail.com', 'worker'),
            (2, 'Edwin Lema', 'edwinlema911@gmail.com', 'worker'),
            (3, 'Jose Santos', 'josesantos14891989@gmail.com', 'worker'),
            (4, 'Kevin Dutan', 'dutankevin1@gmail.com', 'worker'),
            (5, 'Mercedes Inamagua', 'Jneola@gmail.com', 'worker'),
            (6, 'Luis Lopez', 'luislopez030@yahoo.com', 'worker'),
            (7, 'Angel Guirachocha', 'lio.angel71@gmail.com', 'worker'),
            (8, 'Shawn Magloire', 'shawn@francomanagementgroup.com', 'worker'),
            (9, 'Shawn Magloire', 'FrancoSphere@francomanagementgroup.com', 'client'),
            (10, 'Shawn Magloire', 'Shawn@fme-llc.com', 'admin')
            """)
            print("Real workers inserted successfully")
        } catch {
            print("Error inserting real workers: \(error)")
        }
    }
    
    private func insertRealBuildings() {
        do {
            try db.execute("""
            INSERT OR IGNORE INTO buildings (id, name, address, latitude, longitude, imageAssetName)
            VALUES 
            (1, '12 West 18th Street', '12 W 18th St, New York, NY', 40.7390, -73.9930, '12_West_18th_Street'),
            (2, '29-31 East 20th Street', '29-31 E 20th St, New York, NY', 40.7380, -73.9880, '29_31_East_20th_Street'),
            (3, '36 Walker Street', '36 Walker St, New York, NY', 40.7190, -74.0050, '36_Walker_Street'),
            (4, '41 Elizabeth Street', '41 Elizabeth St, New York, NY', 40.7170, -73.9970, '41_Elizabeth_Street'),
            (5, '68 Perry Street', '68 Perry St, New York, NY', 40.7350, -74.0050, '68_Perry_Street'),
            (6, '104 Franklin Street', '104 Franklin St, New York, NY', 40.7180, -74.0060, '104_Franklin_Street'),
            (7, '112 West 18th Street', '112 W 18th St, New York, NY', 40.7400, -73.9940, '112_West_18th_Street'),
            (8, '117 West 17th Street', '117 W 17th St, New York, NY', 40.7395, -73.9950, '117_West_17th_Street'),
            (9, '123 1st Avenue', '123 1st Ave, New York, NY', 40.7270, -73.9850, '123_1st_Avenue'),
            (10, '131 Perry Street', '131 Perry St, New York, NY', 40.7340, -74.0060, '131_Perry_Street'),
            (11, '133 East 15th Street', '133 E 15th St, New York, NY', 40.7345, -73.9875, '133_East_15th_Street'),
            (12, '135-139 West 17th Street', '135-139 W 17th St, New York, NY', 40.7400, -73.9960, '135-139_West_17th_Street'),
            (13, '136 West 17th Street', '136 W 17th St, New York, NY', 40.7402, -73.9970, '136_West_17th_Street'),
            (14, 'Rubin Museum (142-148 W 17th)', '142-148 W 17th St, New York, NY', 40.7405, -73.9980, 'Rubin_Museum_142_148_West_17th')
            """)
            print("Real buildings inserted successfully")
        } catch {
            print("Error inserting real buildings: \(error)")
        }
    }
    
    // MARK: - Helper Functions
    
    func getAllBuildings() -> [[String: Any]] {
        var buildings: [[String: Any]] = []
        do {
            let query = "SELECT * FROM buildings"
            for row in try db.prepare(query) {
                let building: [String: Any] = [
                    "id": row[0] as! Int64,
                    "name": row[1] as! String,
                    "address": row[2] as? String ?? "",
                    "latitude": row[3] as! Double,
                    "longitude": row[4] as! Double,
                    "imageAssetName": row[5] as? String ?? ""
                ]
                buildings.append(building)
            }
        } catch {
            print("Error fetching buildings: \(error)")
        }
        return buildings
    }
    
    func authenticateUser(email: String, password: String, completion: @escaping (Bool, [String: Any]?, String?) -> Void) {
        do {
            let query = "SELECT id, name, email, role FROM workers WHERE email = ? COLLATE NOCASE"
            var userData: [String: Any]? = nil
            for row in try db.prepare(query, [email]) {
                userData = [
                    "id": row[0] as! Int64,
                    "name": row[1] as! String,
                    "email": row[2] as! String,
                    "role": row[3] as! String
                ]
                break
            }
            if let userData = userData {
                if password == "password" {
                    completion(true, userData, nil)
                } else {
                    completion(false, nil, "Incorrect password")
                }
            } else {
                completion(false, nil, "User not found")
            }
        } catch {
            print("Error authenticating user: \(error)")
            completion(false, nil, "Database error")
        }
    }
    
    func getTasksForBuilding(buildingId: Int64) -> [[String: Any]] {
        var tasks: [[String: Any]] = []
        do {
            let query = "SELECT * FROM tasks WHERE buildingId = ?"
            for row in try db.prepare(query, [buildingId]) {
                let task: [String: Any] = [
                    "id": row[0] as! Int64,
                    "name": row[1] as! String,
                    "description": row[2] as? String ?? "",
                    "buildingId": row[3] as! Int64,
                    "workerId": row[4] as! Int64,
                    "isCompleted": ((row[5] as? Int64) ?? 0) == 1,
                    "scheduledDate": row[6] as? String ?? ""
                ]
                tasks.append(task)
            }
        } catch {
            print("Error fetching tasks: \(error)")
        }
        return tasks
    }
    
    // MARK: - Worker Time Tracking
    
    func logClockIn(workerId: Int64, buildingId: Int64, timestamp: Date) {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timeString = dateFormatter.string(from: timestamp)
            
            let checkQuery = "SELECT id FROM worker_time_logs WHERE workerId = ? AND clockOutTime IS NULL"
            var activeLogId: Int64? = nil
            
            for row in try db.prepare(checkQuery, [workerId]) {
                activeLogId = row[0] as? Int64
                break
            }
            
            if let id = activeLogId {
                let updateQuery = "UPDATE worker_time_logs SET clockOutTime = ? WHERE id = ?"
                try db.run(updateQuery, timeString, id)
                print("Worker \(workerId) was already clocked in, automatically clocked out")
            }
            
            let insertQuery = "INSERT INTO worker_time_logs (workerId, buildingId, clockInTime) VALUES (?, ?, ?)"
            try db.run(insertQuery, workerId, buildingId, timeString)
            
            print("Successfully logged clock-in for worker \(workerId) at building \(buildingId)")
        } catch {
            print("Error logging clock-in: \(error)")
        }
    }
    
    func logClockOut(workerId: Int64, timestamp: Date) {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timeString = dateFormatter.string(from: timestamp)
            
            let updateQuery = "UPDATE worker_time_logs SET clockOutTime = ? WHERE workerId = ? AND clockOutTime IS NULL ORDER BY id DESC LIMIT 1"
            try db.run(updateQuery, timeString, workerId)
            
            print("Successfully logged clock-out for worker \(workerId)")
        } catch {
            print("Error logging clock-out: \(error)")
        }
    }
    
    func isWorkerClockedIn(workerId: Int64) -> (isClockedIn: Bool, buildingId: Int64?) {
        do {
            let query = "SELECT buildingId FROM worker_time_logs WHERE workerId = ? AND clockOutTime IS NULL ORDER BY id DESC LIMIT 1"
            var buildingId: Int64? = nil
            
            for row in try db.prepare(query, [workerId]) {
                buildingId = row[0] as? Int64
                break
            }
            
            if let buildingId = buildingId {
                return (true, buildingId)
            }
        } catch {
            print("Error checking worker clock-in status: \(error)")
        }
        
        return (false, nil)
    }
    
    func getWorkerClockInHistory(workerId: Int64, limit: Int = 10) -> [[String: Any]] {
        var history: [[String: Any]] = []
        do {
            let query = """
            SELECT w.id, w.buildingId, b.name, w.clockInTime, w.clockOutTime
            FROM worker_time_logs w
            LEFT JOIN buildings b ON w.buildingId = b.id
            WHERE w.workerId = ?
            ORDER BY w.id DESC
            LIMIT ?
            """
            for row in try db.prepare(query, [workerId, limit]) {
                let entry: [String: Any] = [
                    "id": row[0] as! Int64,
                    "buildingId": row[1] as! Int64,
                    "buildingName": (row[2] as? String) ?? "Unknown Building",
                    "clockInTime": row[3] as! String,
                    "clockOutTime": row[4] as? String ?? ""
                ]
                history.append(entry)
            }
        } catch {
            print("Error fetching worker clock-in history: \(error)")
        }
        return history
    }
    
    func getWorkerName(for workerId: Int64) -> String {
        do {
            let query = "SELECT name FROM workers WHERE id = ?"
            for row in try db.prepare(query, [workerId]) {
                return row[0] as! String
            }
        } catch {
            print("Error getting worker name: \(error)")
        }
        return "Unknown Worker"
    }
    
    func getBuildingName(for buildingId: Int64) -> String {
        do {
            let query = "SELECT name FROM buildings WHERE id = ?"
            for row in try db.prepare(query, [buildingId]) {
                return row[0] as! String
            }
        } catch {
            print("Error getting building name: \(error)")
        }
        return "Unknown Building"
    }
    
    // MARK: - App Initialization
    
    func ensureDatabaseStructure() {
        createTables()
        print("Database structure ensured")
    }
    
    // MARK: - New Parameterized SQL Methods
    
    func execute(_ sql: String, parameters: [Any] = []) throws {
        do {
            if parameters.isEmpty {
                try db.execute(sql)
            } else {
                let stmt = try db.prepare(sql)
                for (index, param) in parameters.enumerated() {
                    switch param {
                    case let value as String:
                        try stmt.bind(index + 1, value)
                    case let value as Int:
                        try stmt.bind(index + 1, value)
                    case let value as Int64:
                        try stmt.bind(index + 1, value)
                    case let value as Double:
                        try stmt.bind(index + 1, value)
                    case let value as Bool:
                        try stmt.bind(index + 1, value ? 1 : 0)
                    case let value as Date:
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        try stmt.bind(index + 1, formatter.string(from: value))
                    case is NSNull:
                        try stmt.bind(index + 1, nil)
                    default:
                        try stmt.bind(index + 1, String(describing: param))
                    }
                }
                try stmt.run()
            }
        } catch {
            print("SQL execute error: \(error)")
            throw error
        }
    }
    
    func query(_ sql: String, parameters: [Any] = []) throws -> [[String: Any]] {
        var results: [[String: Any]] = []
        do {
            let stmt = try db.prepare(sql)
            for (index, param) in parameters.enumerated() {
                switch param {
                case let value as String:
                    try stmt.bind(index + 1, value)
                case let value as Int:
                    try stmt.bind(index + 1, value)
                case let value as Int64:
                    try stmt.bind(index + 1, value)
                case let value as Double:
                    try stmt.bind(index + 1, value)
                case let value as Bool:
                    try stmt.bind(index + 1, value ? 1 : 0)
                case let value as Date:
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    try stmt.bind(index + 1, formatter.string(from: value))
                case is NSNull:
                    try stmt.bind(index + 1, nil)
                default:
                    try stmt.bind(index + 1, String(describing: param))
                }
            }
            for row in stmt {
                var dict: [String: Any] = [:]
                for (idx, name) in stmt.columnNames.enumerated() {
                    if let value = row[idx] {
                        dict[name] = value
                    } else {
                        dict[name] = NSNull()
                    }
                }
                results.append(dict)
            }
            return results
        } catch {
            print("SQL query error: \(error)")
            throw error
        }
    }
}
