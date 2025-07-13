//
//  SQLiteManager.swift
//  FrancoSphere
//
//  ✅ V6.0: Clean GRDB Implementation
//  ✅ No global type pollution
//  ✅ Proper GRDB.swift patterns
//  ✅ Database layer isolation
//  ✅ Backward compatibility maintained
//

import Foundation
import GRDB
import Combine

// MARK: - Database Path Configuration
private var databasePath: String {
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    return "\(path)/FrancoSphere.db"
}

// MARK: - Internal Database Parameter Type (No Global Pollution)
internal typealias DBParameter = DatabaseValueConvertible

// MARK: - SQLiteManager Class (Clean GRDB Implementation)
public class SQLiteManager {
    public static let shared = SQLiteManager()
    
    private let databaseQueue: DatabaseQueue
    private var cancellables = Set<AnyCancellable>()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    private init() {
        do {
            // Initialize GRDB database with proper configuration
            var config = Configuration()
            config.prepareDatabase { db in
                db.trace { print("📊 SQL: \($0)") }
            }
            
            self.databaseQueue = try DatabaseQueue(path: databasePath, configuration: config)
            createTables()
            print("✅ GRDB Database initialized at: \(databasePath)")
        } catch {
            fatalError("❌ GRDB Database initialization failed: \(error)")
        }
    }
    
    // MARK: - Database Schema Creation
    private func createTables() {
        do {
            try databaseQueue.write { db in
                // Workers table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS workers (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        email TEXT UNIQUE NOT NULL,
                        passwordHash TEXT NOT NULL,
                        role TEXT NOT NULL,
                        phone TEXT,
                        hourlyRate REAL DEFAULT 0.0,
                        skills TEXT DEFAULT '',
                        isActive INTEGER DEFAULT 1,
                        profileImagePath TEXT,
                        address TEXT DEFAULT '',
                        emergencyContact TEXT DEFAULT '',
                        notes TEXT DEFAULT '',
                        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                // Buildings table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS buildings (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        address TEXT NOT NULL,
                        latitude REAL NOT NULL,
                        longitude REAL NOT NULL,
                        imageAssetName TEXT,
                        numberOfUnits INTEGER DEFAULT 0,
                        yearBuilt INTEGER,
                        squareFootage INTEGER,
                        managementCompany TEXT,
                        primaryContact TEXT,
                        contactPhone TEXT,
                        contactEmail TEXT,
                        specialNotes TEXT,
                        isActive INTEGER DEFAULT 1,
                        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                // Building Worker Assignments table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS building_worker_assignments (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        buildingId INTEGER NOT NULL,
                        workerId INTEGER NOT NULL,
                        role TEXT NOT NULL DEFAULT 'Maintenance',
                        assignedDate TEXT NOT NULL,
                        isActive INTEGER DEFAULT 1,
                        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (buildingId) REFERENCES buildings(id),
                        FOREIGN KEY (workerId) REFERENCES workers(id),
                        UNIQUE(buildingId, workerId, role)
                    )
                """)
                
                // Tasks table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS tasks (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        description TEXT DEFAULT '',
                        buildingId INTEGER,
                        workerId INTEGER,
                        isCompleted INTEGER NOT NULL DEFAULT 0,
                        scheduledDate TEXT,
                        recurrence TEXT NOT NULL DEFAULT 'oneTime',
                        urgencyLevel TEXT NOT NULL DEFAULT 'medium',
                        category TEXT NOT NULL DEFAULT 'maintenance',
                        startTime TEXT,
                        endTime TEXT,
                        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (buildingId) REFERENCES buildings(id),
                        FOREIGN KEY (workerId) REFERENCES workers(id)
                    )
                """)
                
                // Worker Time Logs table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS worker_time_logs (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        workerId INTEGER NOT NULL,
                        buildingId INTEGER NOT NULL,
                        clockInTime TEXT NOT NULL,
                        clockOutTime TEXT,
                        breakDuration INTEGER DEFAULT 0,
                        notes TEXT DEFAULT '',
                        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (workerId) REFERENCES workers(id),
                        FOREIGN KEY (buildingId) REFERENCES buildings(id)
                    )
                """)
                
                // Maintenance History table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS maintenance_history (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        buildingId INTEGER NOT NULL,
                        taskName TEXT NOT NULL,
                        description TEXT DEFAULT '',
                        completedDate TEXT NOT NULL,
                        completedBy TEXT NOT NULL,
                        category TEXT NOT NULL DEFAULT 'maintenance',
                        urgency TEXT NOT NULL DEFAULT 'medium',
                        notes TEXT DEFAULT '',
                        photoPaths TEXT DEFAULT '',
                        duration INTEGER DEFAULT 0,
                        cost REAL DEFAULT 0.0,
                        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (buildingId) REFERENCES buildings(id)
                    )
                """)
                
                // Inventory table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS inventory (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        buildingId INTEGER NOT NULL,
                        name TEXT NOT NULL,
                        quantity INTEGER NOT NULL DEFAULT 0,
                        unit TEXT NOT NULL DEFAULT 'unit',
                        minimumQuantity INTEGER NOT NULL DEFAULT 5,
                        category TEXT NOT NULL DEFAULT 'general',
                        lastRestocked TEXT,
                        location TEXT DEFAULT '',
                        notes TEXT DEFAULT '',
                        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (buildingId) REFERENCES buildings(id)
                    )
                """)
                
                // Worker Schedule table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS worker_schedule (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        workerId INTEGER NOT NULL,
                        buildingId INTEGER NOT NULL,
                        weekdays TEXT NOT NULL,
                        startHour INTEGER NOT NULL,
                        endHour INTEGER NOT NULL,
                        isActive INTEGER DEFAULT 1,
                        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (workerId) REFERENCES workers(id),
                        FOREIGN KEY (buildingId) REFERENCES buildings(id),
                        UNIQUE(workerId, buildingId, weekdays, startHour)
                    )
                """)
                
                // Create indexes for performance
                try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_workers_email ON workers(email)")
                try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_workers_active ON workers(isActive)")
                try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_buildings_active ON buildings(isActive)")
                try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_assignments_active ON building_worker_assignments(isActive)")
                try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_tasks_building ON tasks(buildingId)")
                try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_tasks_worker ON tasks(workerId)")
                try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_time_logs_worker ON worker_time_logs(workerId)")
                
                print("✅ All GRDB tables and indexes created successfully")
            }
        } catch {
            print("❌ GRDB table creation failed: \(error)")
        }
    }
    
    // MARK: - Database Health Check
    public func isDatabaseReady() -> Bool {
        do {
            return try databaseQueue.read { db in
                let count = try Int.fetchOne(db, sql: """
                    SELECT COUNT(*) FROM sqlite_master 
                    WHERE type='table' AND name='workers'
                """) ?? 0
                return count > 0
            }
        } catch {
            print("❌ Database health check failed: \(error)")
            return false
        }
    }
    
    // MARK: - Quick Initialization (App Startup)
    public func quickInitialize() {
        print("🔧 GRDB Quick Database Initialization...")
        
        if !isDatabaseReady() {
            createTables()
        }
        
        // Check if we need to seed initial data
        do {
            let workerCount = try countWorkers()
            if workerCount == 0 {
                print("📊 No workers found, database ready for seeding...")
            } else {
                print("✅ Database has \(workerCount) workers, ready to use")
            }
        } catch {
            print("❌ Error checking worker count: \(error)")
        }
        
        print("✅ GRDB Database initialization complete!")
    }
    
    // MARK: - Safe Query Methods (No Global Type Pollution)
    
    /// Execute a query and return results as dictionaries
    public func query(_ sql: String, parameters: [DBParameter] = []) -> [[String: Any]] {
        do {
            return try databaseQueue.read { db in
                let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(parameters))
                return rows.map { row in
                    var dict: [String: Any] = [:]
                    for (column, dbValue) in row {
                        dict[column] = dbValue.storage.value
                    }
                    return dict
                }
            }
        } catch {
            print("❌ GRDB Query error: \(error)")
            return []
        }
    }
    
    /// Execute a write operation
    public func execute(_ sql: String, parameters: [DBParameter] = []) throws {
        try databaseQueue.write { db in
            try db.execute(sql: sql, arguments: StatementArguments(parameters))
        }
    }
    
    // MARK: - Async Query Methods
    
    public func queryAsync(_ sql: String, parameters: [DBParameter] = []) async throws -> [[String: Any]] {
        return try await databaseQueue.read { db in
            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(parameters))
            return rows.map { row in
                var dict: [String: Any] = [:]
                for (column, dbValue) in row {
                    dict[column] = dbValue.storage.value
                }
                return dict
            }
        }
    }
    
    public func executeAsync(_ sql: String, parameters: [DBParameter] = []) async throws {
        try await databaseQueue.write { db in
            try db.execute(sql: sql, arguments: StatementArguments(parameters))
        }
    }
    
    // MARK: - Worker Management
    
    public func getWorker(byEmail email: String) throws -> WorkerProfile? {
        return try databaseQueue.read { db in
            guard let row = try Row.fetchOne(db, sql: """
                SELECT * FROM workers WHERE email = ? AND isActive = 1 LIMIT 1
            """, arguments: [email]) else {
                return nil
            }
            
            return mapRowToWorkerProfile(row)
        }
    }
    
    public func getWorker(byId id: String) throws -> WorkerProfile? {
        guard let workerId = Int64(id) else { return nil }
        
        return try databaseQueue.read { db in
            guard let row = try Row.fetchOne(db, sql: """
                SELECT * FROM workers WHERE id = ? AND isActive = 1 LIMIT 1
            """, arguments: [workerId]) else {
                return nil
            }
            
            return mapRowToWorkerProfile(row)
        }
    }
    
    public func getAllWorkers() throws -> [WorkerProfile] {
        return try databaseQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT * FROM workers WHERE isActive = 1 ORDER BY name
            """)
            
            return rows.map { mapRowToWorkerProfile($0) }
        }
    }
    
    public func insertWorker(_ worker: WorkerProfile) throws -> Int64 {
        return try databaseQueue.write { db in
            try db.execute(sql: """
                INSERT INTO workers (name, email, passwordHash, role, phone, hourlyRate, skills, isActive, profileImagePath, address, emergencyContact, notes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, arguments: [
                worker.name,
                worker.email,
                "default_password_hash",
                worker.role.rawValue,
                worker.phoneNumber,
                0.0,
                worker.skills.map { $0.rawValue }.joined(separator: ","),
                true,
                nil,
                "",
                "",
                ""
            ])
            
            return db.lastInsertedRowID
        }
    }
    
    public func countWorkers() throws -> Int {
        return try databaseQueue.read { db in
            return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workers WHERE isActive = 1") ?? 0
        }
    }
    
    // MARK: - Building Management
    
    public func getAllBuildings() throws -> [[String: Any]] {
        return query("""
            SELECT * FROM buildings WHERE isActive = 1 ORDER BY name
        """)
    }
    
    public func insertBuilding(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        imageAssetName: String? = nil
    ) throws -> Int64 {
        return try databaseQueue.write { db in
            try db.execute(sql: """
                INSERT INTO buildings (name, address, latitude, longitude, imageAssetName)
                VALUES (?, ?, ?, ?, ?)
            """, arguments: [name, address, latitude, longitude, imageAssetName])
            
            return db.lastInsertedRowID
        }
    }
    
    public func countBuildings() throws -> Int {
        return try databaseQueue.read { db in
            return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM buildings WHERE isActive = 1") ?? 0
        }
    }
    
    // MARK: - Worker-Building Assignments
    
    public func assignWorkerToBuilding(workerId: Int64, buildingId: Int64, role: String = "Maintenance") throws {
        let currentDate = dateFormatter.string(from: Date())
        
        try databaseQueue.write { db in
            try db.execute(sql: """
                INSERT OR REPLACE INTO building_worker_assignments (buildingId, workerId, role, assignedDate, isActive)
                VALUES (?, ?, ?, ?, ?)
            """, arguments: [buildingId, workerId, role, currentDate, true])
        }
    }
    
    public func getWorkerAssignments(workerId: Int64) throws -> [[String: Any]] {
        return query("""
            SELECT 
                b.id as buildingId,
                b.name as buildingName,
                b.address,
                b.latitude,
                b.longitude,
                b.imageAssetName,
                bwa.role,
                bwa.assignedDate
            FROM building_worker_assignments bwa
            JOIN buildings b ON bwa.buildingId = b.id
            WHERE bwa.workerId = ? AND bwa.isActive = 1 AND b.isActive = 1
            ORDER BY b.name
        """, parameters: [workerId])
    }
    
    // MARK: - Time Tracking
    
    public func logClockIn(workerId: Int64, buildingId: Int64, timestamp: Date = Date()) throws {
        let clockInTimeStr = dateFormatter.string(from: timestamp)
        
        try databaseQueue.write { db in
            try db.execute(sql: """
                INSERT INTO worker_time_logs (workerId, buildingId, clockInTime)
                VALUES (?, ?, ?)
            """, arguments: [workerId, buildingId, clockInTimeStr])
        }
        
        print("✅ Clock in recorded for worker \(workerId) at building \(buildingId)")
    }
    
    public func logClockOut(workerId: Int64, timestamp: Date = Date()) throws {
        let clockOutTimeStr = dateFormatter.string(from: timestamp)
        
        try databaseQueue.write { db in
            try db.execute(sql: """
                UPDATE worker_time_logs
                SET clockOutTime = ?
                WHERE workerId = ? AND clockOutTime IS NULL
                ORDER BY clockInTime DESC
                LIMIT 1
            """, arguments: [clockOutTimeStr, workerId])
        }
        
        print("✅ Clock out recorded for worker \(workerId)")
    }
    
    public func isWorkerClockedIn(workerId: Int64) -> (isClockedIn: Bool, buildingId: Int64?) {
        do {
            return try databaseQueue.read { db in
                guard let row = try Row.fetchOne(db, sql: """
                    SELECT buildingId FROM worker_time_logs
                    WHERE workerId = ? AND clockOutTime IS NULL
                    ORDER BY clockInTime DESC
                    LIMIT 1
                """, arguments: [workerId]) else {
                    return (false, nil)
                }
                
                let buildingId: Int64 = row["buildingId"]
                return (true, buildingId)
            }
        } catch {
            print("❌ Clock status check failed: \(error)")
            return (false, nil)
        }
    }
    
    // MARK: - Data Management
    
    public func clearAllData() throws {
        try databaseQueue.write { db in
            let tables = [
                "worker_time_logs", "building_worker_assignments", "tasks",
                "maintenance_history", "inventory", "worker_schedule",
                "workers", "buildings"
            ]
            
            // Disable foreign key constraints temporarily
            try db.execute(sql: "PRAGMA foreign_keys = OFF")
            
            for table in tables {
                try db.execute(sql: "DELETE FROM \(table)")
            }
            
            // Re-enable foreign key constraints
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            
            print("✅ All data cleared from \(tables.count) tables")
        }
    }
    
    // MARK: - Real-Time Observation (GRDB ValueObservation)
    
    public func observeWorkers() -> AnyPublisher<[WorkerProfile], Error> {
        let observation = ValueObservation.tracking { db in
            try Row.fetchAll(db, sql: "SELECT * FROM workers WHERE isActive = 1 ORDER BY name")
        }
        
        return observation
            .publisher(in: databaseQueue)
            .map { rows in
                rows.map { self.mapRowToWorkerProfile($0) }
            }
            .eraseToAnyPublisher()
    }
    
    public func observeBuildings() -> AnyPublisher<[[String: Any]], Error> {
        let observation = ValueObservation.tracking { db in
            try Row.fetchAll(db, sql: "SELECT * FROM buildings WHERE isActive = 1 ORDER BY name")
        }
        
        return observation
            .publisher(in: databaseQueue)
            .map { rows in
                rows.map { row in
                    var dict: [String: Any] = [:]
                    for (column, dbValue) in row {
                        dict[column] = dbValue.storage.value
                    }
                    return dict
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func mapRowToWorkerProfile(_ row: Row) -> WorkerProfile {
        let workerId = String(row["id"] as Int64)
        let name: String = row["name"]
        let email: String = row["email"]
        let roleString: String = row["role"]
        
        // Map role string to UserRole enum
        let userRole: UserRole
        switch roleString.lowercased() {
        case "admin": userRole = .admin
        case "client": userRole = .client
        default: userRole = .worker
        }
        
        // Parse skills from comma-separated string
        let skillsString: String = row["skills"] ?? ""
        let skills: [WorkerSkill] = skillsString
            .split(separator: ",")
            .compactMap { WorkerSkill(rawValue: String($0).trimmingCharacters(in: .whitespaces)) }
        
        return WorkerProfile(
            id: workerId,
            name: name,
            email: email,
            phoneNumber: row["phone"] ?? "",
            role: userRole,
            skills: skills,
            hireDate: Date() // Could parse from createdAt if needed
        )
    }
}

// MARK: - Async Wrapper Extensions (For Compatibility)

extension SQLiteManager {
    /// Async wrapper for starting SQLiteManager
    public static func start() async throws -> SQLiteManager {
        return SQLiteManager.shared
    }
    
    /// Async clock methods
    public func logClockInAsync(workerId: Int64, buildingId: Int64, timestamp: Date = Date()) async throws {
        try logClockIn(workerId: workerId, buildingId: buildingId, timestamp: timestamp)
    }
    
    public func logClockOutAsync(workerId: Int64, timestamp: Date = Date()) async throws {
        try logClockOut(workerId: workerId, timestamp: timestamp)
    }
    
    /// Async worker methods
    public func getAllWorkersAsync() async throws -> [WorkerProfile] {
        return try await databaseQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT * FROM workers WHERE isActive = 1 ORDER BY name
            """)
            
            return rows.map { self.mapRowToWorkerProfile($0) }
        }
    }
}

// MARK: - Database Statistics and Debugging

extension SQLiteManager {
    public func getDatabaseStats() -> [String: Any] {
        do {
            return try databaseQueue.read { db in
                let workerCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workers WHERE isActive = 1") ?? 0
                let buildingCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM buildings WHERE isActive = 1") ?? 0
                let assignmentCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM building_worker_assignments WHERE isActive = 1") ?? 0
                let taskCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM tasks") ?? 0
                
                return [
                    "workers": workerCount,
                    "buildings": buildingCount,
                    "assignments": assignmentCount,
                    "tasks": taskCount,
                    "databasePath": databasePath
                ]
            }
        } catch {
            return ["error": error.localizedDescription]
        }
    }
    
    public func printDatabaseStats() {
        let stats = getDatabaseStats()
        print("📊 Database Statistics:")
        for (key, value) in stats {
            print("   \(key): \(value)")
        }
    }
}
