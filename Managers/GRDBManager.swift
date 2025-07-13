//
//  GRDBManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/12/25.
import Combine
//


//  GRDBManager.swift
//  FrancoSphere
//
//  Migrated from SQLiteManager to GRDB.swift for better concurrency and real-time observation
//

import Foundation
import GRDB

public final class GRDBManager {
    public static let shared = GRDBManager()
    
    private var dbPool: DatabasePool!
    
    private let dateFormatter: DateFormatter = {
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
    
    private func createTables(_ db: Database) throws {
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
                name TEXT NOT NULL,
                description TEXT,
                buildingId INTEGER NOT NULL,
                workerId INTEGER,
                isCompleted INTEGER NOT NULL DEFAULT 0,
                completedDate TEXT,
                scheduledDate TEXT,
                dueDate TEXT,
                recurrence TEXT NOT NULL DEFAULT 'oneTime',
                urgencyLevel TEXT NOT NULL DEFAULT 'medium',
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
    
    // MARK: - Public API (Compatible with existing SQLiteManager calls)
    
    public func query(_ sql: String, _ parameters: [Any] = []) async throws -> [[String: Any]] {
        return try await dbPool.read { db in
            let statement = try db.makeStatement(sql: sql)
            let rows = try Row.fetchAll(statement, arguments: StatementArguments(parameters ?? []))
            return rows.map { Dictionary($0) }
        }
    }
    
    public func execute(_ sql: String, _ parameters: [Any] = []) async throws {
        try await dbPool.write { db in
            try db.execute(sql: sql, arguments: StatementArguments(parameters ?? []))
        }
    }
    
    public func insertAndReturnID(_ sql: String, _ parameters: [Any] = []) async throws -> Int64 {
        return try await dbPool.write { db in
            try db.execute(sql: sql, arguments: StatementArguments(parameters ?? []))
            return db.lastInsertedRowID
        }
    }
    
    // MARK: - Real-time Observation (NEW - GRDB's killer feature)
    
    public func observeBuildings() -> AnyPublisher<[NamedCoordinate], Error> {
        ValueObservation
            .tracking { db in
                try Row.fetchAll(db, sql: "SELECT * FROM buildings ORDER BY name")
            }
            .map { rows in
                rows.compactMap { row in
                    NamedCoordinate(
                        id: String(row["id"] as? Int64 ?? 0),
                        name: row["name"] as? String ?? "",
                        address: row["address"] as? String,
                        latitude: row["latitude"] as? Double ?? 0,
                        longitude: row["longitude"] as? Double ?? 0
                    )
                }
            }
            .publisher(in: dbPool)
            .eraseToAnyPublisher()
    }
    
    public func observeTasks(for buildingId: String) -> AnyPublisher<[ContextualTask], Error> {
        ValueObservation
            .tracking { db in
                try Row.fetchAll(db, sql: """
                    SELECT t.*, b.name as buildingName, w.name as workerName 
                    FROM routine_tasks t
                    LEFT JOIN buildings b ON t.buildingId = b.id
                    LEFT JOIN workers w ON t.workerId = w.id
                    WHERE t.buildingId = ?
                    ORDER BY t.scheduledDate
                """, arguments: [buildingId])
            }
            .map { rows in
                rows.compactMap { row in
                    ContextualTask(
                        id: String(row["id"] as? Int64 ?? 0),
                        title: row["name"] as? String ?? "",
                        description: row["description"] as? String ?? "",
                        category: TaskCategory(rawValue: row["category"] as? String ?? "maintenance") ?? .maintenance,
                        urgency: TaskUrgency(rawValue: row["urgencyLevel"] as? String ?? "medium") ?? .medium,
                        buildingId: String(row["buildingId"] as? Int64 ?? 0),
                        buildingName: row["buildingName"] as? String ?? "",
                        assignedWorkerId: row["workerId"].flatMap { String(describing: $0) },
                        assignedWorkerName: row["workerName"] as? String,
                        isCompleted: (row["isCompleted"] as? Int64 ?? 0) > 0,
                        completedDate: (row["completedDate"] as? String).flatMap { dateFromString($0) },
                        dueDate: (row["dueDate"] as? String).flatMap { dateFromString($0) },
                        estimatedDuration: TimeInterval((row["estimatedDuration"] as? Int64 ?? 30) * 60),
                        recurrence: TaskRecurrence(rawValue: row["recurrence"] as? String ?? "oneTime") ?? .oneTime,
                        notes: row["notes"] as? String
                    )
                }
            }
            .publisher(in: dbPool)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func dateFromString(_ string: String) -> Date? {
        return dateFormatter.date(from: string)
    }
    
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
            longitude: row["longitude"] ?? 0
        )
    }
    
    public func encode(to container: inout PersistenceContainer) {
        container["name"] = name
        container["address"] = address
        container["latitude"] = latitude
        container["longitude"] = longitude
    }
}