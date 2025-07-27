//
//  GRDBManager.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ SWIFT 6: Sendable compliance for Row operations
//  ✅ GRDB syntax corrected for proper GRDB.swift usage
//  ✅ ContextualTask initializer aligned with actual signature
//  ✅ Maintains compatibility with existing project structure
//  ✅ Preserves real-time observation capabilities
//

import Foundation
import GRDB
import Combine

public final class GRDBManager {
    public static let shared = GRDBManager()
    
    private var dbPool: DatabasePool!
    
    // ✅ FIXED: Make dateFormatter public for extension access
    public let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    private init() {
        initializeDatabase()
    }
    
    // MARK: - Database Initialization
    
    private func initializeDatabase() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let databasePath = documentsPath.appendingPathComponent("FrancoSphere.sqlite").path
            
            var config = Configuration()
            config.prepareDatabase { db in
                // Enable foreign keys
                try db.execute(sql: "PRAGMA foreign_keys = ON")
            }
            
            dbPool = try DatabasePool(path: databasePath, configuration: config)
            
            // Create tables
            try dbPool.write { db in
                try createTables(db)
            }
            
            print("✅ GRDB Database initialized successfully")
        } catch {
            print("❌ GRDB Database initialization failed: \(error)")
        }
    }
    
    public func createTables(_ db: Database) throws {
        // Workers table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS workers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                role TEXT NOT NULL DEFAULT 'worker',
                phone TEXT,
                hourlyRate REAL DEFAULT 25.0,
                skills TEXT,
                isActive INTEGER NOT NULL DEFAULT 1,
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
                address TEXT NOT NULL,
                latitude REAL,
                longitude REAL,
                imageAssetName TEXT,
                numberOfUnits INTEGER,
                yearBuilt INTEGER,
                squareFootage REAL,
                managementCompany TEXT,
                primaryContact TEXT,
                contactPhone TEXT,
                contactEmail TEXT,
                specialNotes TEXT
            )
        """)
        
        // Tasks table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS routine_tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                buildingId INTEGER NOT NULL,
                workerId INTEGER,
                isCompleted INTEGER NOT NULL DEFAULT 0,
                completedDate TEXT,
                scheduledDate TEXT,
                dueDate TEXT,
                recurrence TEXT NOT NULL DEFAULT 'oneTime',
                urgency TEXT NOT NULL DEFAULT 'medium',
                category TEXT NOT NULL DEFAULT 'maintenance',
                estimatedDuration INTEGER DEFAULT 30,
                notes TEXT,
                photoPaths TEXT,
                FOREIGN KEY (buildingId) REFERENCES buildings(id),
                FOREIGN KEY (workerId) REFERENCES workers(id)
            )
        """)
        
        // Worker assignments
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS worker_building_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id INTEGER NOT NULL,
                building_id INTEGER NOT NULL,
                role TEXT NOT NULL DEFAULT 'maintenance',
                assigned_date TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1,
                FOREIGN KEY (worker_id) REFERENCES workers(id),
                FOREIGN KEY (building_id) REFERENCES buildings(id),
                UNIQUE(worker_id, building_id)
            )
        """)
        
        print("✅ GRDB Tables created successfully")
    }
    
    // MARK: - Public API (Compatible with existing GRDBManager calls)
    
    public func query(_ sql: String, _ parameters: [Any] = []) async throws -> [[String: Any]] {
        return try await dbPool.read { db in
            // ✅ FIXED: Convert [Any] to proper GRDB arguments
            let rows: [Row]
            if parameters.isEmpty {
                rows = try Row.fetchAll(db, sql: sql)
            } else {
                // Convert [Any] to [DatabaseValueConvertible]
                let grdbParams = parameters.map { param -> DatabaseValueConvertible in
                    if let convertible = param as? DatabaseValueConvertible {
                        return convertible
                    } else {
                        return String(describing: param)
                    }
                }
                rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(grdbParams))
            }
            
            // ✅ FIXED: Process rows within the closure to avoid Sendable issues
            return rows.map { row in
                var dict: [String: Any] = [:]
                for (column, value) in row {
                    dict[column] = value.storage.value
                }
                return dict
            }
        }
    }
    
    public func execute(_ sql: String, _ parameters: [Any] = []) async throws {
        try await dbPool.write { db in
            // ✅ FIXED: Convert [Any] to proper GRDB arguments
            if parameters.isEmpty {
                try db.execute(sql: sql)
            } else {
                // Convert [Any] to [DatabaseValueConvertible]
                let grdbParams = parameters.map { param -> DatabaseValueConvertible in
                    if let convertible = param as? DatabaseValueConvertible {
                        return convertible
                    } else {
                        return String(describing: param)
                    }
                }
                try db.execute(sql: sql, arguments: StatementArguments(grdbParams))
            }
        }
    }
    
    public func insertAndReturnID(_ sql: String, _ parameters: [Any] = []) async throws -> Int64 {
        return try await dbPool.write { db in
            // ✅ FIXED: Convert [Any] to proper GRDB arguments
            if parameters.isEmpty {
                try db.execute(sql: sql)
            } else {
                // Convert [Any] to [DatabaseValueConvertible]
                let grdbParams = parameters.map { param -> DatabaseValueConvertible in
                    if let convertible = param as? DatabaseValueConvertible {
                        return convertible
                    } else {
                        return String(describing: param)
                    }
                }
                try db.execute(sql: sql, arguments: StatementArguments(grdbParams))
            }
            return db.lastInsertedRowID
        }
    }
    
    // MARK: - Real-time Observation (FIXED for Swift 6)
    
    public func observeBuildings() -> AnyPublisher<[NamedCoordinate], Error> {
        // ✅ FIXED: Process rows within ValueObservation to avoid Sendable issues
        let observation = ValueObservation.tracking { db in
            try Row.fetchAll(db, sql: "SELECT * FROM buildings ORDER BY name")
                .map { row in
                    NamedCoordinate(
                        id: String(row["id"] as? Int64 ?? 0),
                        name: row["name"] as? String ?? "",
                        address: row["address"] as? String,
                        latitude: row["latitude"] as? Double ?? 0,
                        longitude: row["longitude"] as? Double ?? 0,
                        imageAssetName: row["imageAssetName"] as? String
                    )
                }
        }
        
        return observation.publisher(in: dbPool).eraseToAnyPublisher()
    }
    
    public func observeTasks(for buildingId: String) -> AnyPublisher<[ContextualTask], Error> {
        // ✅ FIXED: Process rows within ValueObservation to avoid Sendable issues
        let observation = ValueObservation.tracking { db in
            // ✅ FIXED: Multi-line string literal indentation
            try Row.fetchAll(db, sql: """
                SELECT t.*, b.name as buildingName, w.name as workerName 
                FROM routine_tasks t
                LEFT JOIN buildings b ON t.buildingId = b.id
                LEFT JOIN workers w ON t.workerId = w.id
                WHERE t.buildingId = ?
                ORDER BY t.scheduledDate
                """, arguments: StatementArguments([buildingId]))
                .map { row in
                    self.contextualTaskFromRow(row)
                }
                .compactMap { $0 }
        }
        
        return observation.publisher(in: dbPool).eraseToAnyPublisher()
    }
    
    // ✅ FIXED: Helper method aligned with actual ContextualTask initializer
    public func contextualTaskFromRow(_ row: Row) -> ContextualTask? {
        guard let title = row["title"] as? String else { return nil }
        
        // Convert category string to enum with safe fallback
        let categoryString = row["category"] as? String ?? "maintenance"
        let category: TaskCategory? = {
            switch categoryString.lowercased() {
            case "maintenance": return .maintenance
            case "cleaning": return .cleaning
            case "repair": return .repair
            case "sanitation": return .sanitation
            case "inspection": return .inspection
            case "landscaping": return .landscaping
            case "security": return .security
            case "emergency": return .emergency
            case "installation": return .installation
            case "utilities": return .utilities
            case "renovation": return .renovation
            case "administrative": return .administrative
            default: return .maintenance
            }
        }()
        
        // Convert urgency string to enum with safe fallback
        let urgencyString = row["urgency"] as? String ?? "medium"
        let urgency: TaskUrgency? = {
            switch urgencyString.lowercased() {
            case "low": return .low
            case "medium": return .medium
            case "high": return .high
            case "critical": return .critical
            case "urgent": return .urgent
            case "emergency": return .emergency
            default: return .medium
            }
        }()
        
        // Convert dates
        let completedDate = (row["completedDate"] as? String).flatMap { dateFormatter.date(from: $0) }
        let dueDate = (row["dueDate"] as? String).flatMap { dateFormatter.date(from: $0) }
        
        // ✅ FIXED: Create NamedCoordinate for building (if we have building data)
        let building: NamedCoordinate? = {
            if let buildingName = row["buildingName"] as? String,
               let buildingId = row["buildingId"] as? Int64 {
                return NamedCoordinate(
                    id: String(buildingId),
                    name: buildingName,
                    latitude: 0,
                    longitude: 0
                )
            }
            return nil
        }()
        
        // ✅ FIXED: Removed scheduledDate from ContextualTask initializer (not in actual signature)
        return ContextualTask(
            id: String(row["id"] as? Int64 ?? 0),
            title: title,
            description: row["description"] as? String,
            isCompleted: (row["isCompleted"] as? Int64 ?? 0) > 0,
            completedDate: completedDate,
            dueDate: dueDate,
            category: category,
            urgency: urgency,
            building: building,
            worker: nil,
            buildingId: String(row["buildingId"] as? Int64 ?? 0),
            priority: urgency
        )
    }
    
    // MARK: - Helper Methods
    
    // NOTE: isDatabaseReady() is also declared in DatabaseMigrationFix.swift extension
    // Keep this public version as it's being used by other services
    public func isDatabaseReady() -> Bool {
        return dbPool != nil
    }
    
    public func quickInitialize() {
        if !isDatabaseReady() {
            initializeDatabase()
        }
        print("✅ GRDB Database ready!")
    }
}

// MARK: - GRDB Record Protocols (for type safety)

extension NamedCoordinate: FetchableRecord, PersistableRecord {
    public init(row: Row) {
        self.init(
            id: String(row["id"] as? Int64 ?? 0),
            name: row["name"] ?? "",
            address: row["address"],
            latitude: row["latitude"] ?? 0,
            longitude: row["longitude"] ?? 0,
            imageAssetName: row["imageAssetName"]
        )
    }
    
    public func encode(to container: inout PersistenceContainer) {
        container["name"] = name
        if let address = address {
            container["address"] = address
        }
        container["latitude"] = latitude
        container["longitude"] = longitude
        if let imageAssetName = imageAssetName {
            container["imageAssetName"] = imageAssetName
        }
    }
}

// MARK: - ContextualTask GRDB Support

extension ContextualTask: FetchableRecord, PersistableRecord {
    public init(row: Row) {
        // ✅ FIXED: Use the actual ContextualTask initializer signature
        let title = row["title"] as? String ?? "Unknown Task"
        let description = row["description"] as? String
        let isCompleted = (row["isCompleted"] as? Int64 ?? 0) > 0
        let buildingId = String(row["buildingId"] as? Int64 ?? 0)
        
        // Convert category string to enum with safe fallback
        let categoryString = row["category"] as? String ?? "maintenance"
        let category: TaskCategory? = {
            switch categoryString.lowercased() {
            case "maintenance": return .maintenance
            case "cleaning": return .cleaning
            case "repair": return .repair
            case "sanitation": return .sanitation
            case "inspection": return .inspection
            case "landscaping": return .landscaping
            case "security": return .security
            case "emergency": return .emergency
            case "installation": return .installation
            case "utilities": return .utilities
            case "renovation": return .renovation
            case "administrative": return .administrative
            default: return .maintenance
            }
        }()
        
        // Convert urgency string to enum with safe fallback
        let urgencyString = row["urgency"] as? String ?? "medium"
        let urgency: TaskUrgency? = {
            switch urgencyString.lowercased() {
            case "low": return .low
            case "medium": return .medium
            case "high": return .high
            case "critical": return .critical
            case "urgent": return .urgent
            case "emergency": return .emergency
            default: return .medium
            }
        }()
        
        // Convert dates
        let dateFormatter = GRDBManager.shared.dateFormatter
        let completedDate = (row["completedDate"] as? String).flatMap { dateFormatter.date(from: $0) }
        let dueDate = (row["dueDate"] as? String).flatMap { dateFormatter.date(from: $0) }
        
        // Create building object if we have building data
        let building: NamedCoordinate? = {
            if let buildingName = row["buildingName"] as? String {
                return NamedCoordinate(
                    id: buildingId,
                    name: buildingName,
                    latitude: 0,
                    longitude: 0
                )
            }
            return nil
        }()
        
        // ✅ FIXED: Removed scheduledDate from ContextualTask initializer
        self.init(
            id: String(row["id"] as? Int64 ?? 0),
            title: title,
            description: description,
            isCompleted: isCompleted,
            completedDate: completedDate,
            dueDate: dueDate,
            category: category,
            urgency: urgency,
            building: building,
            worker: nil,
            buildingId: buildingId,
            priority: urgency
        )
    }
    
    public func encode(to container: inout PersistenceContainer) {
        // ✅ FIXED: Use correct ContextualTask properties
        container["title"] = title
        container["description"] = description
        container["buildingId"] = buildingId.flatMap { Int64($0) } ?? 0
        container["isCompleted"] = isCompleted ? 1 : 0
        
        // ✅ FIXED: Convert enums to strings for database storage with safe fallback
        if let category = category {
            let categoryString: String = {
                switch category {
                case .maintenance: return "maintenance"
                case .cleaning: return "cleaning"
                case .repair: return "repair"
                case .sanitation: return "sanitation"
                case .inspection: return "inspection"
                case .landscaping: return "landscaping"
                case .security: return "security"
                case .emergency: return "emergency"
                case .installation: return "installation"
                case .utilities: return "utilities"
                case .renovation: return "renovation"
                case .administrative: return "administrative"
                }
            }()
            container["category"] = categoryString
        }
        
        if let urgency = urgency {
            let urgencyString: String = {
                switch urgency {
                case .low: return "low"
                case .medium: return "medium"
                case .high: return "high"
                case .critical: return "critical"
                case .urgent: return "urgent"
                case .emergency: return "emergency"
                }
            }()
            container["urgency"] = urgencyString
        }
        
        // ✅ FIXED: Handle date formatting with accessible dateFormatter
        if let completedDate = completedDate {
            container["completedDate"] = GRDBManager.shared.dateFormatter.string(from: completedDate)
        }
        
        // Note: scheduledDate is stored in the database but not part of ContextualTask
        // It can be retrieved from the row if needed for other purposes
        
        if let dueDate = dueDate {
            container["dueDate"] = GRDBManager.shared.dateFormatter.string(from: dueDate)
        }
    }
}
