//
//  SQLiteManager.swift
//  FrancoSphere
//
//  ✅ V6.0: GRDB Migration - Drop-in Replacement
//  ✅ Uses GRDB.swift instead of SQLite.swift
//  ✅ Maintains exact same API for compatibility
//  ✅ All existing services will work without changes
//  ✅ Enhanced with real-time ValueObservation capabilities
//

import Foundation
import GRDB
import Combine

// MARK: - Database Path
private var databasePath: String {
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    return "\(path)/FrancoSphere.db"
}

// MARK: - Binding Type Alias for Compatibility
public typealias Binding = DatabaseValueConvertible

// MARK: - Internal Data Models (Database-specific)

internal struct SQLiteWorker {
    let id: Int64
    let name: String
    let email: String
    let password: String
    let role: String
    let phone: String
    let hourlyRate: Double
    let skills: [String]
    let isActive: Bool
    let profileImagePath: String?
    let address: String
    let emergencyContact: String
    let notes: String
    let buildingIds: [String]?
}

public struct BuildingWorkerAssignment {
    let id: Int64
    let buildingId: Int64
    let workerId: Int64
    let role: String
    let assignedDate: Date
    let isActive: Bool
}

// MARK: - SQLiteManager Class (GRDB-powered)

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
            // Initialize GRDB database
            self.databaseQueue = try DatabaseQueue(path: databasePath)
            createTables()
            print("✅ GRDB Database initialized successfully")
        } catch {
            fatalError("❌ GRDB Database initialization failed: \(error)")
        }
    }
    
    // MARK: - Database Initialization
    
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
                        hourlyRate REAL,
                        skills TEXT,
                        isActive INTEGER DEFAULT 1,
                        profileImagePath TEXT,
                        address TEXT,
                        emergencyContact TEXT,
                        notes TEXT
                    )
                """)
                
                // Buildings table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS buildings (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        address TEXT,
                        latitude REAL,
                        longitude REAL,
                        imageAssetName TEXT,
                        numberOfUnits INTEGER,
                        yearBuilt INTEGER,
                        squareFootage INTEGER,
                        managementCompany TEXT,
                        primaryContact TEXT,
                        contactPhone TEXT,
                        contactEmail TEXT,
                        specialNotes TEXT
                    )
                """)
                
                // Maintenance History table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS maintenance_history (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        buildingId INTEGER NOT NULL,
                        taskName TEXT NOT NULL,
                        description TEXT,
                        completedDate TEXT NOT NULL,
                        completedBy TEXT NOT NULL,
                        category TEXT NOT NULL,
                        urgency TEXT NOT NULL,
                        notes TEXT,
                        photoPaths TEXT,
                        duration INTEGER,
                        cost REAL
                    )
                """)
                
                // Time Clock Entries table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS time_clock_entries (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        workerId INTEGER NOT NULL,
                        buildingId INTEGER NOT NULL,
                        clockInTime TEXT NOT NULL,
                        clockOutTime TEXT,
                        breakDuration INTEGER,
                        totalHours REAL,
                        notes TEXT,
                        isApproved INTEGER,
                        approvedBy TEXT,
                        approvalDate TEXT
                    )
                """)
                
                // Building Worker Assignments table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS building_worker_assignments (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        buildingId INTEGER NOT NULL,
                        workerId INTEGER NOT NULL,
                        role TEXT NOT NULL,
                        assignedDate TEXT NOT NULL,
                        isActive INTEGER DEFAULT 1
                    )
                """)
                
                // Worker Time Logs table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS worker_time_logs (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        workerId INTEGER NOT NULL,
                        buildingId INTEGER NOT NULL,
                        clockInTime TEXT NOT NULL,
                        clockOutTime TEXT
                    )
                """)
                
                // Tasks table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS tasks (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        description TEXT,
                        buildingId INTEGER,
                        workerId INTEGER,
                        isCompleted INTEGER NOT NULL DEFAULT 0,
                        scheduledDate TEXT,
                        recurrence TEXT NOT NULL DEFAULT 'oneTime',
                        urgencyLevel TEXT NOT NULL DEFAULT 'medium',
                        category TEXT NOT NULL DEFAULT 'maintenance',
                        startTime TEXT,
                        endTime TEXT
                    )
                """)
                
                // Inventory table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS inventory (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        buildingId TEXT NOT NULL,
                        name TEXT NOT NULL,
                        quantity INTEGER NOT NULL DEFAULT 0,
                        unit TEXT NOT NULL DEFAULT 'unit',
                        minimumQuantity INTEGER NOT NULL DEFAULT 5,
                        category TEXT NOT NULL DEFAULT 'general',
                        lastRestocked TEXT,
                        location TEXT DEFAULT '',
                        notes TEXT
                    )
                """)
                
                // Worker Schedule table
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS worker_schedule (
                        workerId TEXT NOT NULL,
                        buildingId TEXT NOT NULL,
                        weekdays TEXT NOT NULL,
                        startHour INTEGER NOT NULL,
                        endHour INTEGER NOT NULL,
                        PRIMARY KEY (workerId, buildingId, weekdays, startHour)
                    )
                """)
                
                // Worker Assignments table (for compatibility)
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS worker_assignments (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        worker_id INTEGER NOT NULL,
                        building_id TEXT NOT NULL,
                        worker_name TEXT NOT NULL,
                        is_active INTEGER DEFAULT 1
                    )
                """)
                
                // AllTasks view (for compatibility)
                try db.execute(sql: """
                    CREATE VIEW IF NOT EXISTS AllTasks AS
                    SELECT 
                        id,
                        name,
                        description,
                        buildingId as building_id,
                        workerId as assigned_worker_id,
                        isCompleted as status,
                        scheduledDate as scheduled_date,
                        scheduledDate as due_date,
                        startTime as start_time,
                        endTime as end_time,
                        category,
                        urgencyLevel as urgency
                    FROM tasks
                """)
                
                print("✅ All GRDB tables created successfully")
            }
        } catch {
            print("❌ GRDB table creation failed: \(error)")
        }
    }
    
    // MARK: - Quick Initialize (for app startup)
    
    public func quickInitialize() {
        print("🔧 Quick GRDB Database Initialization...")
        
        if !isDatabaseReady() {
            createTables()
        }
        
        // Check if we need test data
        if (try? countWorkers()) ?? 0 == 0 {
            print("📊 No workers found, loading test data...")
            loadMinimalTestData()
        }
        
        print("✅ GRDB Database ready!")
    }
    
    // MARK: - Helper Methods
    
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
            return false
        }
    }
    
    private func loadMinimalTestData() {
        do {
            try databaseQueue.write { db in
                // Insert test building
                try db.execute(sql: """
                    INSERT INTO buildings (name, address, latitude, longitude, imageAssetName)
                    VALUES (?, ?, ?, ?, ?)
                """, arguments: [
                    "12 West 18th Street",
                    "12 West 18th Street, New York, NY",
                    40.7390,
                    -73.9936,
                    "12West18thStreet"
                ])
                
                let buildingId = db.lastInsertedRowID
                
                // Insert test worker
                try db.execute(sql: """
                    INSERT INTO workers (name, email, passwordHash, role)
                    VALUES (?, ?, ?, ?)
                """, arguments: [
                    "Edwin Lema",
                    "edwinlema911@gmail.com",
                    "password",
                    "worker"
                ])
                
                let workerId = db.lastInsertedRowID
                
                // Create assignment
                try db.execute(sql: """
                    INSERT INTO building_worker_assignments (buildingId, workerId, role, assignedDate, isActive)
                    VALUES (?, ?, ?, ?, ?)
                """, arguments: [
                    buildingId,
                    workerId,
                    "Maintenance",
                    dateFormatter.string(from: Date()),
                    1
                ])
                
                print("✅ GRDB test data loaded successfully")
            }
        } catch {
            print("❌ Failed to load GRDB test data: \(error)")
        }
    }
    
    // MARK: - Query Methods (Compatible API)
    
    public func query(_ sql: String, _ parameters: [Binding] = []) -> [[String: Any]] {
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
    
    public func execute(_ sql: String, _ parameters: [Binding] = []) throws {
        try databaseQueue.write { db in
            try db.execute(sql: sql, arguments: StatementArguments(parameters))
        }
    }
    
    // MARK: - Async Query Methods (Enhanced API)
    
    public func query(_ sql: String, _ parameters: [Binding] = []) async throws -> [[String: Any]] {
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
    
    public func execute(_ sql: String, _ parameters: [Binding] = []) async throws {
        try await databaseQueue.write { db in
            try db.execute(sql: sql, arguments: StatementArguments(parameters))
        }
    }
    
    // MARK: - Worker Methods (Using WorkerProfile compatibility)
    
    public func getWorker(byEmail email: String) throws -> WorkerProfile? {
        return try databaseQueue.read { db in
            guard let row = try Row.fetchOne(db, sql: """
                SELECT * FROM workers WHERE email = ? LIMIT 1
            """, arguments: [email]) else {
                return nil
            }
            
            // Convert database row to WorkerProfile
            let workerId = String(row["id"] as Int64)
            let name: String = row["name"]
            let email: String = row["email"]
            let roleString: String = row["role"]
            
            // Convert role string to UserRole
            let userRole: UserRole
            switch roleString.lowercased() {
            case "admin": userRole = .admin
            case "client": userRole = .client
            default: userRole = .worker
            }
            
            return WorkerProfile(
                id: workerId,
                name: name,
                email: email,
                phoneNumber: row["phone"] ?? "",
                role: userRole,
                skills: [], // Parse skills from database if needed
                hireDate: Date()
            )
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
                "default_password",
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
    
    public func getAllWorkers() throws -> [WorkerProfile] {
        return try databaseQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM workers")
            
            return rows.map { row in
                let workerId = String(row["id"] as Int64)
                let name: String = row["name"]
                let email: String = row["email"]
                let roleString: String = row["role"]
                
                // Convert role string to UserRole
                let userRole: UserRole
                switch roleString.lowercased() {
                case "admin": userRole = .admin
                case "client": userRole = .client
                default: userRole = .worker
                }
                
                return WorkerProfile(
                    id: workerId,
                    name: name,
                    email: email,
                    phoneNumber: row["phone"] ?? "",
                    role: userRole,
                    skills: [], // Parse skills from database if needed
                    hireDate: Date()
                )
            }
        }
    }
    
    public func countWorkers() throws -> Int {
        return try databaseQueue.read { db in
            return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workers") ?? 0
        }
    }
    
    // MARK: - Building Methods
    
    public func insertBuildingDetailed(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        imageAssetName: String,
        numberOfUnits: Int = 0,
        yearBuilt: Int? = nil,
        squareFootage: Int? = nil,
        managementCompany: String? = nil,
        primaryContact: String? = nil,
        contactPhone: String? = nil,
        contactEmail: String? = nil,
        specialNotes: String? = nil
    ) throws -> Int64 {
        return try databaseQueue.write { db in
            try db.execute(sql: """
                INSERT INTO buildings (name, address, latitude, longitude, imageAssetName, numberOfUnits, yearBuilt, squareFootage, managementCompany, primaryContact, contactPhone, contactEmail, specialNotes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, arguments: [
                name, address, latitude, longitude, imageAssetName,
                numberOfUnits, yearBuilt, squareFootage, managementCompany,
                primaryContact, contactPhone, contactEmail, specialNotes
            ])
            
            return db.lastInsertedRowID
        }
    }
    
    public func countBuildings() throws -> Int {
        return try databaseQueue.read { db in
            return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM buildings") ?? 0
        }
    }
    
    // MARK: - Assignment Methods
    
    public func insertBuildingWorkerAssignment(_ assignment: BuildingWorkerAssignment) throws {
        try databaseQueue.write { db in
            try db.execute(sql: """
                INSERT INTO building_worker_assignments (buildingId, workerId, role, assignedDate, isActive)
                VALUES (?, ?, ?, ?, ?)
            """, arguments: [
                assignment.buildingId,
                assignment.workerId,
                assignment.role,
                dateFormatter.string(from: assignment.assignedDate),
                assignment.isActive
            ])
        }
    }
    
    // MARK: - Clock In/Out Methods
    
    public func logClockIn(workerId: Int64, buildingId: Int64, timestamp: Date) {
        do {
            let clockInTimeStr = dateFormatter.string(from: timestamp)
            try databaseQueue.write { db in
                try db.execute(sql: """
                    INSERT INTO worker_time_logs (workerId, buildingId, clockInTime)
                    VALUES (?, ?, ?)
                """, arguments: [workerId, buildingId, clockInTimeStr])
            }
            print("✅ GRDB Clock in recorded")
        } catch {
            print("❌ GRDB Clock in error: \(error)")
        }
    }
    
    public func logClockOut(workerId: Int64, timestamp: Date) {
        do {
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
            print("✅ GRDB Clock out recorded")
        } catch {
            print("❌ GRDB Clock out error: \(error)")
        }
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
            print("❌ GRDB Clock status error: \(error)")
            return (false, nil)
        }
    }
    
    // MARK: - Clear Data
    
    public func clearAllData() throws {
        try databaseQueue.write { db in
            let tables = [
                "workers", "buildings", "maintenance_history",
                "time_clock_entries", "building_worker_assignments",
                "worker_time_logs", "tasks", "inventory", "worker_schedule",
                "worker_assignments"
            ]
            
            for table in tables {
                try db.execute(sql: "DELETE FROM \(table)")
            }
            
            print("✅ All GRDB data cleared from tables")
        }
    }
    
    // MARK: - Real-Time Observation Support (New GRDB Feature)
    
    public func observeWorkers() -> AnyPublisher<[WorkerProfile], Error> {
        let observation = ValueObservation.tracking { db in
            try Row.fetchAll(db, sql: "SELECT * FROM workers WHERE isActive = 1")
        }
        
        return observation
            .publisher(in: databaseQueue)
            .map { rows in
                rows.map { row in
                    let workerId = String(row["id"] as Int64)
                    let name: String = row["name"]
                    let email: String = row["email"]
                    let roleString: String = row["role"]
                    
                    let userRole: UserRole
                    switch roleString.lowercased() {
                    case "admin": userRole = .admin
                    case "client": userRole = .client
                    default: userRole = .worker
                    }
                    
                    return WorkerProfile(
                        id: workerId,
                        name: name,
                        email: email,
                        phoneNumber: row["phone"] ?? "",
                        role: userRole,
                        skills: [],
                        hireDate: Date()
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    public func observeBuildings() -> AnyPublisher<[Row], Error> {
        let observation = ValueObservation.tracking { db in
            try Row.fetchAll(db, sql: "SELECT * FROM buildings ORDER BY name")
        }
        
        return observation
            .publisher(in: databaseQueue)
            .eraseToAnyPublisher()
    }
}

// MARK: - Migration Support Extensions

extension SQLiteManager {
    // Async wrapper for starting SQLiteManager
    public static func start() async throws -> SQLiteManager {
        return SQLiteManager.shared
    }
    
    // Async clock methods
    public func logClockInAsync(workerId: Int64, buildingId: Int64, timestamp: Date) async throws {
        logClockIn(workerId: workerId, buildingId: buildingId, timestamp: timestamp)
    }
    
    public func logClockOutAsync(workerId: Int64, timestamp: Date) async throws {
        logClockOut(workerId: workerId, timestamp: timestamp)
    }
}

// MARK: - Database Value Conversion Helpers

extension DatabaseValueConvertible {
    // Helper for complex parameter conversions if needed
}

// MARK: - Compatibility Type Aliases

public typealias SQLiteBinding = Binding // For backward compatibility
