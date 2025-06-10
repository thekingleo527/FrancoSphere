// SQLiteManager.swift
// FrancoSphere - Complete Working Version

import Foundation
import SQLite

// MARK: - Table Definitions

// Workers table
let workers = Table("workers")
let workerId = Expression<Int64>("id")
let workerName = Expression<String>("name")
let workerEmail = Expression<String>("email")
let workerPassword = Expression<String>("passwordHash")
let workerRole = Expression<String>("role")
let workerPhone = Expression<String?>("phone")
let hourlyRate = Expression<Double?>("hourlyRate")
let skills = Expression<String?>("skills")
let isActive = Expression<Bool?>("isActive")
let profileImagePath = Expression<String?>("profileImagePath")
let address = Expression<String?>("address")
let emergencyContact = Expression<String?>("emergencyContact")
let notes = Expression<String?>("notes")

// Buildings table
let buildings = Table("buildings")
let buildingId = Expression<Int64>("id")
let buildingName = Expression<String>("name")
let buildingAddress = Expression<String?>("address")
let latitude = Expression<Double?>("latitude")
let longitude = Expression<Double?>("longitude")
let imageAssetName = Expression<String?>("imageAssetName")
let numberOfUnits = Expression<Int?>("numberOfUnits")
let yearBuilt = Expression<Int?>("yearBuilt")
let squareFootage = Expression<Int?>("squareFootage")
let managementCompany = Expression<String?>("managementCompany")
let primaryContact = Expression<String?>("primaryContact")
let contactPhone = Expression<String?>("contactPhone")
let contactEmail = Expression<String?>("contactEmail")
let specialNotes = Expression<String?>("specialNotes")

// Maintenance History table
let maintenanceHistory = Table("maintenance_history")
let historyId = Expression<Int64>("id")
let historyBuildingId = Expression<Int64>("buildingId")
let historyTaskName = Expression<String>("taskName")
let historyDescription = Expression<String?>("description")
let historyCompletedDate = Expression<String>("completedDate")
let historyCompletedBy = Expression<String>("completedBy")
let historyCategory = Expression<String>("category")
let historyUrgency = Expression<String>("urgency")
let historyNotes = Expression<String?>("notes")
let historyPhotoPaths = Expression<String?>("photoPaths")
let historyDuration = Expression<Int?>("duration")
let historyCost = Expression<Double?>("cost")

// Time Clock Entries table
let timeClockEntries = Table("time_clock_entries")
let entryId = Expression<Int64>("id")
let entryWorkerId = Expression<Int64>("workerId")
let entryBuildingId = Expression<Int64>("buildingId")
let clockInTime = Expression<String>("clockInTime")
let clockOutTime = Expression<String?>("clockOutTime")
let breakDuration = Expression<Int?>("breakDuration")
let totalHours = Expression<Double?>("totalHours")
let isApproved = Expression<Bool?>("isApproved")
let approvedBy = Expression<String?>("approvedBy")
let approvalDate = Expression<String?>("approvalDate")

// Building Worker Assignments table
let buildingWorkerAssignments = Table("building_worker_assignments")
let assignmentId = Expression<Int64>("id")
let assignmentBuildingId = Expression<Int64>("buildingId")
let assignmentWorkerId = Expression<Int64>("workerId")
let assignmentRole = Expression<String>("role")
let assignedDate = Expression<String>("assignedDate")

// MARK: - Database Path
private var databasePath: String {
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    return "\(path)/FrancoSphere.sqlite3"
}

// MARK: - Data Models

public struct Worker {
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

// MARK: - SQLiteManager Class

public class SQLiteManager {
    public static let shared = SQLiteManager()
    
    private var db: Connection?
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    private init() {
        // Initialize database on creation
        _ = initializeDatabase()
    }
    
    // MARK: - Database Initialization
    
    private func initializeDatabase() -> Bool {
        do {
            db = try Connection(databasePath)
            createTables()
            print("✅ Database initialized successfully")
            return true
        } catch {
            print("❌ Database initialization failed: \(error)")
            return false
        }
    }
    
    private func createTables() {
        guard let db = db else { return }
        
        do {
            // Workers table
            try db.run(workers.create(ifNotExists: true) { t in
                t.column(workerId, primaryKey: .autoincrement)
                t.column(workerName)
                t.column(workerEmail, unique: true)
                t.column(workerPassword)
                t.column(workerRole)
                t.column(workerPhone)
                t.column(hourlyRate)
                t.column(skills)
                t.column(isActive)
                t.column(profileImagePath)
                t.column(address)
                t.column(emergencyContact)
                t.column(notes)
            })
            
            // Buildings table
            try db.run(buildings.create(ifNotExists: true) { t in
                t.column(buildingId, primaryKey: .autoincrement)
                t.column(buildingName)
                t.column(buildingAddress)
                t.column(latitude)
                t.column(longitude)
                t.column(imageAssetName)
                t.column(numberOfUnits)
                t.column(yearBuilt)
                t.column(squareFootage)
                t.column(managementCompany)
                t.column(primaryContact)
                t.column(contactPhone)
                t.column(contactEmail)
                t.column(specialNotes)
            })
            
            // Maintenance History table
            try db.run(maintenanceHistory.create(ifNotExists: true) { t in
                t.column(historyId, primaryKey: .autoincrement)
                t.column(historyBuildingId)
                t.column(historyTaskName)
                t.column(historyDescription)
                t.column(historyCompletedDate)
                t.column(historyCompletedBy)
                t.column(historyCategory)
                t.column(historyUrgency)
                t.column(historyNotes)
                t.column(historyPhotoPaths)
                t.column(historyDuration)
                t.column(historyCost)
            })
            
            // Time Clock Entries table
            try db.run(timeClockEntries.create(ifNotExists: true) { t in
                t.column(entryId, primaryKey: .autoincrement)
                t.column(entryWorkerId)
                t.column(entryBuildingId)
                t.column(clockInTime)
                t.column(clockOutTime)
                t.column(breakDuration)
                t.column(totalHours)
                t.column(notes)
                t.column(isApproved)
                t.column(approvedBy)
                t.column(approvalDate)
            })
            
            // Building Worker Assignments table
            try db.run(buildingWorkerAssignments.create(ifNotExists: true) { t in
                t.column(assignmentId, primaryKey: .autoincrement)
                t.column(assignmentBuildingId)
                t.column(assignmentWorkerId)
                t.column(assignmentRole)
                t.column(assignedDate)
                t.column(isActive)
            })
            
            // Additional tables
            try db.run("""
                CREATE TABLE IF NOT EXISTS worker_time_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    workerId INTEGER NOT NULL,
                    buildingId INTEGER NOT NULL,
                    clockInTime TEXT NOT NULL,
                    clockOutTime TEXT
                );
                """)
            
            try db.run("""
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
                );
                """)
            
            try db.run("""
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
                );
                """)
            
            try db.run("""
                CREATE TABLE IF NOT EXISTS worker_schedule (
                    workerId TEXT NOT NULL,
                    buildingId TEXT NOT NULL,
                    weekdays TEXT NOT NULL,
                    startHour INTEGER NOT NULL,
                    endHour INTEGER NOT NULL,
                    PRIMARY KEY (workerId, buildingId, weekdays, startHour)
                );
                """)
            
            print("✅ All tables created successfully")
        } catch {
            print("❌ Table creation failed: \(error)")
        }
    }
    
    // MARK: - Quick Initialize (for app startup)
    
    public func quickInitialize() {
        print("🔧 Quick Database Initialization...")
        
        if !isDatabaseReady() {
            _ = initializeDatabase()
        }
        
        // Check if we need test data
        if (try? countWorkers()) ?? 0 == 0 {
            print("📊 No workers found, loading test data...")
            loadMinimalTestData()
        }
        
        print("✅ Database ready!")
    }
    
    // MARK: - Helper Methods
    
    public func isDatabaseReady() -> Bool {
        guard db != nil else { return false }
        
        do {
            let count = try db?.scalar(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='workers'"
            ) as? Int64 ?? 0
            
            return count > 0
        } catch {
            return false
        }
    }
    
    private func loadMinimalTestData() {
        do {
            guard let db = db else { return }
            
            // Insert test building
            let buildingInsert = buildings.insert(
                buildingName <- "12 West 18th Street",
                buildingAddress <- "12 West 18th Street, New York, NY",
                latitude <- 40.7390,
                longitude <- -73.9936,
                imageAssetName <- "12West18thStreet"
            )
            let buildingRowId = try db.run(buildingInsert)
            
            // Insert test worker
            let workerInsert = workers.insert(
                workerName <- "Edwin Lema",
                workerEmail <- "edwinlema911@gmail.com",
                workerPassword <- "password",
                workerRole <- "worker"
            )
            let workerRowId = try db.run(workerInsert)
            
            // Create assignment
            let assignmentInsert = buildingWorkerAssignments.insert(
                assignmentBuildingId <- buildingRowId,
                assignmentWorkerId <- workerRowId,
                assignmentRole <- "Maintenance",
                assignedDate <- dateFormatter.string(from: Date()),
                isActive <- true
            )
            try db.run(assignmentInsert)
            
            print("✅ Test data loaded successfully")
        } catch {
            print("❌ Failed to load test data: \(error)")
        }
    }
    
    // MARK: - Query Methods
    
    public func query(_ sql: String, _ parameters: [Binding] = []) -> [[String: Any]] {
        guard let db = db else { return [] }
        
        var results: [[String: Any]] = []
        
        do {
            let statement = try db.prepare(sql, parameters)
            for row in statement {
                var dict: [String: Any] = [:]
                for (idx, name) in statement.columnNames.enumerated() {
                    dict[name] = row[idx] ?? NSNull()
                }
                results.append(dict)
            }
        } catch {
            print("❌ Query error: \(error)")
        }
        
        return results
    }
    
    public func execute(_ sql: String, _ parameters: [Binding] = []) throws {
        guard let db = db else {
            throw NSError(domain: "SQLiteManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"])
        }
        
        try db.run(sql, parameters)
    }
    
    // MARK: - Worker Methods
    
    public func getWorker(byEmail email: String) throws -> Worker? {
        guard let db = db else { return nil }
        
        let query = workers.filter(workerEmail == email)
        
        if let row = try db.pluck(query) {
            return Worker(
                id: row[workerId],
                name: row[workerName],
                email: row[workerEmail],
                password: row[workerPassword],
                role: row[workerRole],
                phone: row[workerPhone] ?? "",
                hourlyRate: row[hourlyRate] ?? 0.0,
                skills: row[skills]?.components(separatedBy: ",") ?? [],
                isActive: row[isActive] ?? true,
                profileImagePath: row[profileImagePath],
                address: row[address] ?? "",
                emergencyContact: row[emergencyContact] ?? "",
                notes: row[notes] ?? "",
                buildingIds: nil
            )
        }
        
        return nil
    }
    
    public func insertWorker(_ worker: Worker) throws -> Int64 {
        guard let db = db else { throw NSError(domain: "SQLiteManager", code: 0) }
        
        let insert = workers.insert(
            workerName <- worker.name,
            workerEmail <- worker.email,
            workerPassword <- worker.password,
            workerRole <- worker.role,
            workerPhone <- worker.phone,
            hourlyRate <- worker.hourlyRate,
            skills <- worker.skills.joined(separator: ","),
            isActive <- worker.isActive,
            profileImagePath <- worker.profileImagePath,
            address <- worker.address,
            emergencyContact <- worker.emergencyContact,
            notes <- worker.notes
        )
        
        return try db.run(insert)
    }
    
    public func getAllWorkers() throws -> [Worker] {
        guard let db = db else { return [] }
        
        var workersList: [Worker] = []
        
        for row in try db.prepare(workers) {
            let worker = Worker(
                id: row[workerId],
                name: row[workerName],
                email: row[workerEmail],
                password: row[workerPassword],
                role: row[workerRole],
                phone: row[workerPhone] ?? "",
                hourlyRate: row[hourlyRate] ?? 0.0,
                skills: row[skills]?.components(separatedBy: ",") ?? [],
                isActive: row[isActive] ?? true,
                profileImagePath: row[profileImagePath],
                address: row[address] ?? "",
                emergencyContact: row[emergencyContact] ?? "",
                notes: row[notes] ?? "",
                buildingIds: nil
            )
            workersList.append(worker)
        }
        
        return workersList
    }
    
    public func countWorkers() throws -> Int {
        guard let db = db else { return 0 }
        return try db.scalar(workers.count)
    }
    
    // MARK: - Building Methods

    // Method for your NamedCoordinate type
    public func insertBuilding(_ building: Building) throws -> Int64 {
        guard let db = db else { throw NSError(domain: "SQLiteManager", code: 0) }
        
        let insert = buildings.insert(
            buildingName <- building.name,
            buildingAddress <- building.name, // Use name as fallback
            latitude <- building.latitude,
            longitude <- building.longitude,
            imageAssetName <- building.imageAssetName
            // All other fields will use their default values (nil or 0)
        )
        
        return try db.run(insert)
    }

    // Method for manual insertion with all parameters
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
        guard let db = db else { throw NSError(domain: "SQLiteManager", code: 0) }
        
        // Create the insert statement with proper <- operators
        let insert = buildings.insert(
            Expression<String>("name") <- name,
            Expression<String?>("address") <- address,
            Expression<Double?>("latitude") <- latitude,
            Expression<Double?>("longitude") <- longitude,
            Expression<String?>("imageAssetName") <- imageAssetName,
            Expression<Int?>("numberOfUnits") <- numberOfUnits,
            Expression<Int?>("yearBuilt") <- yearBuilt,
            Expression<Int?>("squareFootage") <- squareFootage,
            Expression<String?>("managementCompany") <- managementCompany,
            Expression<String?>("primaryContact") <- primaryContact,
            Expression<String?>("contactPhone") <- contactPhone,
            Expression<String?>("contactEmail") <- contactEmail,
            Expression<String?>("specialNotes") <- specialNotes
        )
        
        return try db.run(insert)
    }
    
    public func countBuildings() throws -> Int {
        guard let db = db else { return 0 }
        return try db.scalar(buildings.count)
    }
    
    // MARK: - Assignment Methods
    
    public func insertBuildingWorkerAssignment(_ assignment: BuildingWorkerAssignment) throws {
        guard let db = db else { throw NSError(domain: "SQLiteManager", code: 0) }
        
        let insert = buildingWorkerAssignments.insert(
            assignmentBuildingId <- assignment.buildingId,
            assignmentWorkerId <- assignment.workerId,
            assignmentRole <- assignment.role,
            assignedDate <- dateFormatter.string(from: assignment.assignedDate),
            isActive <- assignment.isActive
        )
        
        try db.run(insert)
    }
    
    // MARK: - Clock In/Out Methods
    
    public func logClockIn(workerId: Int64, buildingId: Int64, timestamp: Date) {
        do {
            let clockInTimeStr = dateFormatter.string(from: timestamp)
            try execute("""
                INSERT INTO worker_time_logs (workerId, buildingId, clockInTime)
                VALUES (?, ?, ?);
                """, [workerId, buildingId, clockInTimeStr]
            )
            print("✅ Clock in recorded")
        } catch {
            print("❌ Clock in error: \(error)")
        }
    }
    
    public func logClockOut(workerId: Int64, timestamp: Date) {
        do {
            let clockOutTimeStr = dateFormatter.string(from: timestamp)
            try execute("""
                UPDATE worker_time_logs
                SET clockOutTime = ?
                WHERE workerId = ? AND clockOutTime IS NULL
                ORDER BY clockInTime DESC
                LIMIT 1;
                """, [clockOutTimeStr, workerId]
            )
            print("✅ Clock out recorded")
        } catch {
            print("❌ Clock out error: \(error)")
        }
    }
    
    public func isWorkerClockedIn(workerId: Int64) -> (isClockedIn: Bool, buildingId: Int64?) {
        let results = query("""
            SELECT buildingId FROM worker_time_logs
            WHERE workerId = ? AND clockOutTime IS NULL
            ORDER BY clockInTime DESC
            LIMIT 1;
            """, [workerId])
        
        if let firstRow = results.first,
           let buildingId = firstRow["buildingId"] as? Int64 {
            return (true, buildingId)
        }
        
        return (false, nil)
    }
    
    // MARK: - Clear Data
    
    public func clearAllData() throws {
        guard let db = db else { return }
        
        let tables = [
            "workers", "buildings", "maintenance_history",
            "time_clock_entries", "building_worker_assignments",
            "worker_time_logs", "tasks", "inventory", "worker_schedule"
        ]
        
        for table in tables {
            _ = try? db.run("DELETE FROM \(table)")
        }
        
        print("✅ All data cleared from tables")
    }
}

// MARK: - Async Extensions

extension SQLiteManager {
    public func query(_ sql: String, _ parameters: [Binding] = []) async throws -> [[String: Any]] {
        return await withCheckedContinuation { continuation in
            let results = query(sql, parameters)
            continuation.resume(returning: results)
        }
    }
    
    public func execute(_ sql: String, _ parameters: [Binding] = []) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try execute(sql, parameters)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
// MARK: - V012 Migration

struct V012_RoutineTasks: DatabaseMigration {
    let version = 12
    let name = "Routine Tasks and Worker Assignments"
    var checksum: String { "f2a3b4c5d6e7" }
    
    func up(_ db: Connection) throws {
        // Check if worker_assignments table exists from V003
        let tableCheck = try db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='worker_assignments'")
        let tableExists = tableCheck.makeIterator().next() != nil
        
        if tableExists {
            print("📝 Updating existing worker_assignments table...")
            
            // Check which columns already exist
            let columns = try db.prepare("PRAGMA table_info(worker_assignments)")
            var existingColumns = Set<String>()
            for column in columns {
                if let name = column[1] as? String {
                    existingColumns.insert(name)
                }
            }
            
            // Add missing columns WITHOUT default values first
            if !existingColumns.contains("start_date") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN start_date TEXT")
                // Update existing rows with current timestamp
                let currentTimestamp = ISO8601DateFormatter().string(from: Date())
                try db.run("UPDATE worker_assignments SET start_date = ? WHERE start_date IS NULL", [currentTimestamp])
            }
            
            if !existingColumns.contains("end_date") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN end_date TEXT")
            }
            
            if !existingColumns.contains("is_active") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN is_active INTEGER DEFAULT 1")
            }
            
            if !existingColumns.contains("days_of_week") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN days_of_week TEXT")
            }
            
            if !existingColumns.contains("start_hour") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN start_hour INTEGER")
            }
            
            if !existingColumns.contains("end_hour") {
                try db.run("ALTER TABLE worker_assignments ADD COLUMN end_hour INTEGER")
            }
        } else {
            // Create the table fresh with all columns
            print("📝 Creating new worker_assignments table...")
            try db.run("""
                CREATE TABLE IF NOT EXISTS worker_assignments (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    worker_id TEXT NOT NULL,
                    building_id TEXT NOT NULL,
                    start_date TEXT NOT NULL,
                    end_date TEXT,
                    is_active INTEGER NOT NULL DEFAULT 1,
                    days_of_week TEXT,
                    start_hour INTEGER,
                    end_hour INTEGER,
                    created_at TEXT NOT NULL,
                    UNIQUE(worker_id, building_id)
                );
                """)
        }
        
        // Create routine_tasks table
        try db.run("""
            CREATE TABLE IF NOT EXISTS routine_tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                category TEXT NOT NULL,
                recurrence TEXT NOT NULL,
                building_id TEXT NOT NULL,
                start_hour INTEGER NOT NULL,
                end_hour INTEGER NOT NULL,
                days_of_week TEXT,
                required_skill TEXT,
                created_at TEXT NOT NULL
            );
            """)
        
        // Create indexes
        try db.run("CREATE INDEX IF NOT EXISTS idx_worker_assignments_active ON worker_assignments(is_active, worker_id);")
        try db.run("CREATE INDEX IF NOT EXISTS idx_routine_tasks_building ON routine_tasks(building_id);")
    }
    
    func down(_ db: Connection) throws {
        try db.run("DROP INDEX IF EXISTS idx_routine_tasks_building;")
        try db.run("DROP INDEX IF EXISTS idx_worker_assignments_active;")
        try db.run("DROP TABLE IF EXISTS routine_tasks;")
        // Don't drop worker_assignments as it might have been created by V003
    }
}
extension SQLiteManager {
    // Async wrapper for starting SQLiteManager
    public static func start() async throws -> SQLiteManager {
        return SQLiteManager.shared
    }
    
    // These methods should already exist but ensure they're marked correctly:
    public func logClockInAsync(workerId: Int64, buildingId: Int64, timestamp: Date) async throws {
        logClockIn(workerId: workerId, buildingId: buildingId, timestamp: timestamp)
    }
    
    public func logClockOutAsync(workerId: Int64, timestamp: Date) async throws {
        logClockOut(workerId: workerId, timestamp: timestamp)
    }
}
