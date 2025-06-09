// SQLiteManager.swift
// Refactored to use SQLite.swift (no GRDB)
// FrancoSphere v1.1 - FIXED VERSION

import Foundation
import SQLite
import SwiftUI
import CommonCrypto

// MARK: - Database Errors

public enum DatabaseError: LocalizedError {
    case notInitialized
    case connectionFailed
    case migrationFailed(String)
    case invalidData(String)

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized. Call SQLiteManager.start() first."
        case .connectionFailed:
            return "Failed to connect to database."
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        }
    }
}

// MARK: - Placeholder Services

enum FeatureFlagService {
    static let shared = FeatureFlagService.self
    static func isEnabled(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: "ff_\(key)")
    }
}

enum TelemetryService {
    static let shared = TelemetryService.self
    static func logEvent(_ event: String, metadata: [String: Any]) {
        print("📊 Telemetry: \(event) - \(metadata)")
    }
}

// MARK: - Extensions

extension Data {
    func sha256Hash() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// REMOVED: Duplicate Date extension for iso8601String
// This is already defined elsewhere in your project

// MARK: - Migration Protocol

public protocol DatabaseMigration {
    var version: Int { get }
    var name: String { get }
    var checksum: String { get }
    func up(_ db: Connection) throws
    func down(_ db: Connection) throws
}

// MARK: - Migration Runner

public final class DatabaseMigrator {
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func getCurrentVersion() throws -> Int {
        try db.run("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                checksum TEXT NOT NULL,
                applied_at TEXT NOT NULL
            );
            """)
        let stmt = try db.prepare("SELECT MAX(version) AS maxv FROM schema_migrations;")
        if let row = try stmt.run().makeIterator().next(),
           let maxv = row[0] as? Int64 {
            return Int(maxv)
        }
        return 0
    }

    func migrate(migrations: [DatabaseMigration]) throws {
        let currentVersion = try getCurrentVersion()
        let sorted = migrations.sorted { $0.version < $1.version }
        for migration in sorted where migration.version > currentVersion {
            try runMigration(migration)
        }
    }

    private func runMigration(_ migration: DatabaseMigration) throws {
        print("🔄 Running migration \(migration.version): \(migration.name)")
        do {
            try db.transaction {
                try migration.up(db)
                let timestamp = Date().iso8601String
                try db.run(
                    "INSERT INTO schema_migrations (version, name, checksum, applied_at) VALUES (?, ?, ?, ?);",
                    [migration.version, migration.name, migration.checksum, timestamp]
                )
            }
            print("✅ Migration \(migration.version) completed")
        } catch {
            throw DatabaseError.migrationFailed(error.localizedDescription)
        }
    }

    func rollback(to version: Int, migrations: [DatabaseMigration]) throws {
        guard FeatureFlagService.shared.isEnabled("allow_schema_rollback") else {
            throw DatabaseError.migrationFailed("Rollback disabled")
        }
        let currentVersion = try getCurrentVersion()
        guard version < currentVersion else { return }

        TelemetryService.shared.logEvent("migration_rollback", metadata: [
            "from_version": currentVersion,
            "to_version": version
        ])

        let toRollback = migrations
            .filter { $0.version > version && $0.version <= currentVersion }
            .sorted { $0.version > $1.version }

        for migration in toRollback {
            try db.transaction {
                try migration.down(db)
                try db.run("DELETE FROM schema_migrations WHERE version = ?;", [migration.version])
            }
            print("↩️ Rolled back migration \(migration.version)")
        }
    }
}

// MARK: - SQLiteManager

public actor SQLiteManager {
    @available(*, deprecated, message: "Use SQLiteManager.start() instead")
    public static let shared = SQLiteManager()

    private var db: Connection?
    private var migrator: DatabaseMigrator?
    private var preparedStatements: [String: Statement] = [:]
    private var isInitialized = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
    private static let iso8601Formatter = ISO8601DateFormatter()

    private init() {}

    /// Async factory
    public static func start(inMemory: Bool = false) async throws -> SQLiteManager {
        let manager = SQLiteManager()
        try await manager.initialize(inMemory: inMemory)
        return manager
    }

    /// Initialize the database
    public func initialize(inMemory: Bool = false) async throws {
        guard !isInitialized else { return }

        let connection: Connection
        if inMemory {
            connection = try Connection(.inMemory)
        } else {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let dbPath = "\(path)/FrancoSphere.sqlite3"
            if FileManager.default.fileExists(atPath: dbPath) {
                let backupPath = "\(path)/FrancoSphere_backup_\(Date().timeIntervalSince1970).sqlite3"
                do {
                    try FileManager.default.copyItem(atPath: dbPath, toPath: backupPath)
                } catch {
                    print("⚠️ Backup failed: \(error)")
                }
            }
            connection = try Connection(dbPath)
        }

        // Pragmas
        try connection.run("PRAGMA journal_mode = WAL;")
        try connection.run("PRAGMA busy_timeout = 5000;")
        try connection.run("PRAGMA foreign_keys = ON;")
        try connection.run("PRAGMA synchronous = NORMAL;")

        self.db = connection
        self.migrator = DatabaseMigrator(db: connection)

        try await runMigrations()
        try await prepareStatements()
        scheduleMaintenanceTasks()

        isInitialized = true
    }

    // MARK: - Migration System

    private func runMigrations() async throws {
            guard let db = db, let migrator = migrator else { return }

            let migrations: [DatabaseMigration] = [
                V001_InitialSchema(),
                V002_AddPasswordHash(),
                V003_AddWeatherCache(),
                V004_AddOutboxTables(),
                V005_AddFeatureFlags(),
                V006_AddTelemetry(),
                V007_AddIndexes(),
                V008_PhotoPathMigration(),
                V009_BuildingNameMapping(),
                V010_TaskTemplateData(),
                V011_BuildingInventory(),
                V012_RoutineTasks()  // Adds worker_assignments, routine_tasks, worker_skills tables
            ]

            try migrator.migrate(migrations: migrations)
        }
    // MARK: - Maintenance

    private func scheduleMaintenanceTasks() {
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 604_800_000_000_000) // 1 week
                try? await performMaintenance()
            }
        }
    }

    private func performMaintenance() async throws {
        guard let db = db else { return }
        try db.run("PRAGMA wal_checkpoint(TRUNCATE);")
        let calendar = Calendar.current
        if calendar.component(.weekday, from: Date()) == 1 {
            try db.run("VACUUM;")
        }
    }

    // MARK: - Prepared Statements

    private func prepareStatements() async throws {
        guard let db = db else { return }
        preparedStatements["getWorker"] = try db.prepare("SELECT * FROM workers WHERE id = ?;")
        preparedStatements["getBuilding"] = try db.prepare("SELECT * FROM buildings WHERE id = ?;")
        preparedStatements["getInventory"] = try db.prepare("SELECT * FROM inventory WHERE buildingId = ? ORDER BY name;")
    }

    private func ensureInitialized() throws {
        guard isInitialized, db != nil else {
            throw DatabaseError.notInitialized
        }
    }

    /// Execute a non-returning SQL statement
    public func execute(_ sql: String, _ parameters: [SQLite.Binding] = []) async throws {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }
        do {
            try db.run(sql, parameters)
        } catch {
            throw error
        }
    }

    /// Execute a query returning results
    public func query(_ sql: String, _ parameters: [SQLite.Binding] = []) async throws -> [[String: Any]] {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }

        var rowsArray: [[String: Any]] = []
        let statement = try db.prepare(sql, parameters)
        for row in try statement.run() {
            var dict: [String: Any] = [:]
            for (idx, name) in statement.columnNames.enumerated() {
                dict[name] = row[idx] ?? NSNull()
            }
            rowsArray.append(dict)
        }
        return rowsArray
    }

    // MARK: - Photo Operations

    public func saveTaskPhoto(taskId: String, imageData: Data) async throws -> String {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }

        let photoId = UUID().uuidString
        let photoPath = "photos/\(taskId)/\(photoId).jpg"
        let photoHash = imageData.sha256Hash()

        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fullPath = "\(documentsPath)/\(photoPath)"
        let directoryPath = "\(documentsPath)/photos/\(taskId)"

        try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        try imageData.write(to: URL(fileURLWithPath: fullPath))

        let createdAt = Date().iso8601String
        try db.run("""
            INSERT INTO photo_uploads (task_id, photo_path, photo_hash, retry_count, created_at)
            VALUES (?, ?, ?, 0, ?);
            """, [taskId, photoPath, photoHash, createdAt]
        )

        return photoPath
    }

    public func getPendingPhotoUploads(limit: Int = 10) async throws -> [(id: Int64, taskId: String, path: String)] {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }

        var uploads: [(Int64, String, String)] = []
        let statement = try db.prepare("""
            SELECT id, task_id, photo_path
            FROM photo_uploads
            WHERE retry_count < 3 AND uploaded_at IS NULL
            ORDER BY created_at ASC
            LIMIT ?;
            """, [limit]
        )
        for row in try statement.run() {
            if let id = row[0] as? Int64,
               let taskId = row[1] as? String,
               let path = row[2] as? String
            {
                uploads.append((id, taskId, path))
            }
        }
        return uploads
    }

    // MARK: - Weather Cache Operations

    public func cacheWeatherData(
        buildingId: String,
        forecastData: Data,
        riskScore: Double,
        expiresIn: TimeInterval = 14_400
    ) async throws {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }

        let nowStr = Date().iso8601String
        let expiresAtStr = Date().addingTimeInterval(expiresIn).iso8601String
        // FIXED: Use Blob(_:) instead of deprecated Blob(bytes:)
        try db.run("""
            INSERT OR REPLACE INTO weather_cache
            (building_id, forecast_data, risk_score, last_updated, expires_at)
            VALUES (?, ?, ?, ?, ?);
            """, [buildingId, Blob(bytes: [UInt8](forecastData)), riskScore, nowStr, expiresAtStr]
        )
    }

    public func getCachedWeather(buildingId: String) async throws -> (data: Data, riskScore: Double)? {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }

        let nowStr = Date().iso8601String
        let stmt = try db.prepare("""
            SELECT forecast_data, risk_score
            FROM weather_cache
            WHERE building_id = ? AND expires_at > ?;
            """, [buildingId, nowStr])
        
        if let row = try stmt.run().makeIterator().next() {
            if let blob = row[0] as? Blob,
               let riskScore = row[1] as? Double
            {
                return (Data(bytes: blob.bytes), riskScore)
            }
        }
        return nil
    }

    // MARK: - Feature Flags

    public func isFeatureEnabled(_ key: String) async throws -> Bool {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }

        let stmt = try db.prepare("SELECT enabled FROM feature_flags WHERE key = ?;", [key])
        if let row = try stmt.run().makeIterator().next(),
           let enabled = row[0] as? Int64
        {
            return enabled == 1
        }
        return false
    }

    // MARK: - Clock In/Out Methods

    public func logClockInAsync(workerId: Int64, buildingId: Int64, timestamp: Date) async throws {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }

        let clockInTime = Self.dateFormatter.string(from: timestamp)
        try db.run("""
            INSERT INTO worker_time_logs (workerId, buildingId, clockInTime)
            VALUES (?, ?, ?);
            """, [workerId, buildingId, clockInTime]
        )
    }

    public func logClockOutAsync(workerId: Int64, timestamp: Date) async throws {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }

        let clockOutTime = Self.dateFormatter.string(from: timestamp)
        let stmt = try db.prepare("""
            SELECT id FROM worker_time_logs
            WHERE workerId = ? AND clockOutTime IS NULL
            ORDER BY clockInTime DESC
            LIMIT 1;
            """, [workerId])
        
        if let row = try stmt.run().makeIterator().next() {
            if let logId = row[0] as? Int64 {
                try db.run("""
                    UPDATE worker_time_logs
                    SET clockOutTime = ?
                    WHERE id = ?;
                    """, [clockOutTime, logId]
                )
            }
        }
    }

    public func isWorkerClockedInAsync(workerId: Int64) async -> (isClockedIn: Bool, buildingId: Int64?) {
        do {
            try ensureInitialized()
            guard let db = db else { return (false, nil) }

            let stmt = try db.prepare("""
                SELECT buildingId FROM worker_time_logs
                WHERE workerId = ? AND clockOutTime IS NULL
                ORDER BY clockInTime DESC
                LIMIT 1;
                """, [workerId])
            
            if let row = try stmt.run().makeIterator().next() {
                if let bId = row[0] as? Int64 {
                    return (true, bId)
                }
            }
            return (false, nil)
        } catch {
            print("❌ Error checking clock-in status: \(error)")
            return (false, nil)
        }
    }
}

// MARK: - Non-Actor Wrappers

extension SQLiteManager {
    public func logClockIn(workerId: Int64, buildingId: Int64, timestamp: Date) {
        Task {
            do {
                try await self.logClockInAsync(workerId: workerId, buildingId: buildingId, timestamp: timestamp)
            } catch {
                print("❌ Error logging clock in: \(error)")
            }
        }
    }

    public func logClockOut(workerId: Int64, timestamp: Date) {
        Task {
            do {
                try await self.logClockOutAsync(workerId: workerId, timestamp: timestamp)
            } catch {
                print("❌ Error logging clock out: \(error)")
            }
        }
    }

    public func isWorkerClockedIn(workerId: Int64) -> (isClockedIn: Bool, buildingId: Int64?) {
        let semaphore = DispatchSemaphore(value: 0)
        var result: (Bool, Int64?) = (false, nil)
        Task {
            result = await self.isWorkerClockedInAsync(workerId: workerId)
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
}

// MARK: - Migration Implementations

struct V001_InitialSchema: DatabaseMigration {
    let version = 1
    let name = "Initial Schema"
    var checksum: String { "a1b2c3d4e5f6" }

    func up(_ db: Connection) throws {
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
            CREATE TABLE IF NOT EXISTS workers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                role TEXT NOT NULL
            );
            """)
        try db.run("""
            CREATE TABLE IF NOT EXISTS buildings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                address TEXT,
                latitude REAL,
                longitude REAL,
                imageAssetName TEXT
            );
            """)
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
    }

    func down(_ db: Connection) throws {
        try db.run("DROP TABLE IF EXISTS worker_schedule;")
        try db.run("DROP TABLE IF EXISTS inventory;")
        try db.run("DROP TABLE IF EXISTS worker_time_logs;")
        try db.run("DROP TABLE IF EXISTS buildings;")
        try db.run("DROP TABLE IF EXISTS workers;")
        try db.run("DROP TABLE IF EXISTS tasks;")
    }
}

struct V002_AddPasswordHash: DatabaseMigration {
    let version = 2
    let name = "Add Password Hash"
    var checksum: String { "b2c3d4e5f6a7" }

    func up(_ db: Connection) throws {
        try db.run("ALTER TABLE workers ADD COLUMN passwordHash TEXT NOT NULL DEFAULT '';")
    }

    func down(_ db: Connection) throws {
        print("⚠️ V002 rollback requires backup restore")
    }
}

struct V003_AddWeatherCache: DatabaseMigration {
    let version = 3
    let name = "Add Weather Cache"
    var checksum: String { "c3d4e5f6a7b8" }

    func up(_ db: Connection) throws {
        try db.run("""
            CREATE TABLE IF NOT EXISTS weather_cache (
                building_id TEXT PRIMARY KEY,
                forecast_data BLOB,
                risk_score REAL,
                last_updated TEXT,
                expires_at TEXT
            );
            """)
    }

    func down(_ db: Connection) throws {
        try db.run("DROP TABLE IF EXISTS weather_cache;")
    }
}

struct V004_AddOutboxTables: DatabaseMigration {
    let version = 4
    let name = "Add Outbox Tables"
    var checksum: String { "d4e5f6a7b8c9" }

    func up(_ db: Connection) throws {
        try db.run("""
            CREATE TABLE IF NOT EXISTS outbox_photos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                task_id TEXT NOT NULL,
                photo_data BLOB NOT NULL,
                retry_count INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT '\(Date().iso8601String)'
            );
            """)
    }

    func down(_ db: Connection) throws {
        try db.run("DROP TABLE IF EXISTS outbox_photos;")
    }
}

struct V005_AddFeatureFlags: DatabaseMigration {
    let version = 5
    let name = "Add Feature Flags"
    var checksum: String { "e5f6a7b8c9d0" }

    func up(_ db: Connection) throws {
        try db.run("""
            CREATE TABLE IF NOT EXISTS feature_flags (
                key TEXT PRIMARY KEY,
                enabled INTEGER NOT NULL DEFAULT 0,
                metadata BLOB
            );
            """)
        let defaultFlags: [(String, Bool)] = [
            ("weather_intelligence_enabled", false),
            ("admin_commands_enabled", false),
            ("ai_suggestions_enabled", false),
            ("glass_ui_enabled", false),
            ("emergency_mode_enabled", false),
            ("allow_schema_rollback", false)
        ]
        for (key, enabled) in defaultFlags {
            try db.run(
                "INSERT OR IGNORE INTO feature_flags (key, enabled) VALUES (?, ?);",
                [key, enabled ? 1 : 0]
            )
        }
    }

    func down(_ db: Connection) throws {
        try db.run("DROP TABLE IF EXISTS feature_flags;")
    }
}

struct V006_AddTelemetry: DatabaseMigration {
    let version = 6
    let name = "Add Telemetry"
    var checksum: String { "f6a7b8c9d0e1" }

    func up(_ db: Connection) throws {
        try db.run("""
            CREATE TABLE IF NOT EXISTS telemetry_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT NOT NULL,
                user_id TEXT,
                metadata BLOB,
                created_at TEXT NOT NULL DEFAULT '\(Date().iso8601String)'
            );
            """)
    }

    func down(_ db: Connection) throws {
        try db.run("DROP TABLE IF EXISTS telemetry_events;")
    }
}

struct V007_AddIndexes: DatabaseMigration {
    let version = 7
    let name = "Add Performance Indexes"
    var checksum: String { "a7b8c9d0e1f2" }

    func up(_ db: Connection) throws {
        try db.run("CREATE INDEX IF NOT EXISTS idx_worker_time_logs_worker_clock ON worker_time_logs(workerId, clockOutTime);")
        try db.run("CREATE INDEX IF NOT EXISTS idx_inventory_building ON inventory(buildingId);")
        try db.run("CREATE INDEX IF NOT EXISTS idx_telemetry_created ON telemetry_events(created_at);")
        try db.run("CREATE INDEX IF NOT EXISTS idx_weather_expires ON weather_cache(expires_at);")
    }

    func down(_ db: Connection) throws {
        try db.run("DROP INDEX IF EXISTS idx_worker_time_logs_worker_clock;")
        try db.run("DROP INDEX IF EXISTS idx_inventory_building;")
        try db.run("DROP INDEX IF EXISTS idx_telemetry_created;")
        try db.run("DROP INDEX IF EXISTS idx_weather_expires;")
    }
}

struct V008_PhotoPathMigration: DatabaseMigration {
    let version = 8
    let name = "Photo Path Migration"
    var checksum: String { "b8c9d0e1f2a3" }

    func up(_ db: Connection) throws {
        try db.run("""
            CREATE TABLE IF NOT EXISTS photo_uploads (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                task_id TEXT NOT NULL,
                photo_path TEXT NOT NULL,
                photo_hash TEXT NOT NULL,
                retry_count INTEGER NOT NULL DEFAULT 0,
                uploaded_at TEXT,
                created_at TEXT NOT NULL DEFAULT '\(Date().iso8601String)'
            );
            """)
        try db.run("CREATE INDEX IF NOT EXISTS idx_photo_uploads_pending ON photo_uploads(uploaded_at, retry_count);")
    }

    func down(_ db: Connection) throws {
        try db.run("DROP INDEX IF EXISTS idx_photo_uploads_pending;")
        try db.run("DROP TABLE IF EXISTS photo_uploads;")
    }
}

// ────────────────────────────────────────────────────────────────────────────────
// ─── NEW MIGRATIONS BEGIN HERE ─────────────────────────────────────────────────
// ────────────────────────────────────────────────────────────────────────────────

struct V009_BuildingNameMapping: DatabaseMigration {
    let version = 9
    let name = "Building Name Mapping"
    var checksum: String { "c9d0e1f2a3b4" }

    func up(_ db: Connection) throws {
        try db.run("""
            CREATE TABLE IF NOT EXISTS building_name_mappings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                csv_name TEXT NOT NULL UNIQUE,
                canonical_name TEXT NOT NULL,
                building_id TEXT NOT NULL
            );
            """)
        let mappings: [(String, String, String)] = [
            ("135–139 West 17th",    "135-139 West 17th Street",          "12"),
            ("135_139 West 17th",    "135-139 West 17th Street",          "12"),
            ("29–31 East 20th",      "29-31 East 20th Street",            "2"),
            ("29_31 East 20th",      "29-31 East 20th Street",            "2"),
            ("36 Walker",            "36 Walker Street",                  "3"),
            ("104 Franklin",         "104 Franklin Street",               "6"),
            ("123 1st Ave",          "123 1st Avenue",                    "9"),
            ("Stuyvesant Cove",      "Stuyvesant Cove Park",              "16"),
            ("Rubin Museum",         "Rubin Museum (142-148 W 17th)",     "15"),
            ("142-148 W 17th",       "Rubin Museum (142-148 W 17th)",     "15"),
            ("117 W 17th",           "117 West 17th Street",              "8"),
            ("112 W 18th",           "112 West 18th Street",              "7"),
            ("138 W 17th",           "138 West 17th Street",              "14"),
            ("12 W 18th",            "12 West 18th Street",               "1"),
            ("68 Perry",             "68 Perry Street",                   "5"),
            ("131 Perry",            "131 Perry Street",                  "10"),
            ("41 Elizabeth",         "41 Elizabeth Street",               "4"),
            ("133 E 15th",           "133 East 15th Street",              "11"),
            ("136 W 17th",           "136 West 17th Street",              "13"),
            ("178 Spring",           "178 Spring Street",                 "17"),
            ("115 7th Ave",          "115 7th Avenue",                    "18"),
            ("Rubin Museum (142–148 W 17th)", "Rubin Museum (142-148 W 17th)", "15")
        ]
        for (csvName, canonicalName, buildingId) in mappings {
            try db.run(
                "INSERT OR IGNORE INTO building_name_mappings (csv_name, canonical_name, building_id) VALUES (?, ?, ?);",
                [csvName, canonicalName, buildingId]
            )
        }

        try db.run("ALTER TABLE buildings ADD COLUMN timezone TEXT NOT NULL DEFAULT 'America/New_York';")
        try db.run("ALTER TABLE buildings ADD COLUMN has_outdoor_access INTEGER NOT NULL DEFAULT 1;")
        try db.run("ALTER TABLE tasks ADD COLUMN external_id TEXT;")
        try db.run("CREATE INDEX IF NOT EXISTS idx_tasks_external_id ON tasks(external_id);")
        try db.run("""
            UPDATE tasks
            SET buildingId = (
                SELECT building_id
                FROM building_name_mappings
                WHERE tasks.buildingId = building_name_mappings.csv_name
            )
            WHERE EXISTS (
                SELECT 1
                FROM building_name_mappings
                WHERE tasks.buildingId = building_name_mappings.csv_name
            );
            """)
    }

    func down(_ db: Connection) throws {
        try db.run("DROP INDEX IF EXISTS idx_tasks_external_id;")
        try db.run("DROP TABLE IF EXISTS building_name_mappings;")
    }
}

struct V010_TaskTemplateData: DatabaseMigration {
    let version = 10
    let name = "Task Template Data"
    var checksum: String { "d0e1f2a3b4c5" }

    func up(_ db: Connection) throws {
        try db.run("""
            CREATE TABLE IF NOT EXISTS task_templates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                category TEXT NOT NULL,
                description TEXT NOT NULL,
                required_skill_level TEXT NOT NULL,
                recurrence TEXT NOT NULL,
                urgency TEXT NOT NULL,
                estimated_duration INTEGER NOT NULL DEFAULT 3600
            );
            """)
        let templates: [(String, String, String, String, String, String, Int)] = [
            ("Put Mats Out", "Cleaning", "Place entrance mats outside building entrances", "Basic", "Daily", "Low", 900),
            ("Remove Garbage to Curb", "Sanitation", "Move garbage bins to curb for collection", "Basic", "Daily", "Medium", 1800),
            ("Check Mail and Packages", "Maintenance", "Collect and distribute mail and packages", "Basic", "Daily", "Low", 1200),
            ("Sweep Front of Building", "Cleaning", "Sweep sidewalk and entrance areas", "Basic", "Weekly", "Low", 1800),
            ("Clean Outside", "Cleaning", "Clean exterior surfaces and common areas", "Basic", "Weekly", "Low", 3600),
            ("Mop and Clean Common Areas", "Cleaning", "Mop floors and clean all common areas", "Basic", "Weekly", "Medium", 5400),
            ("Clean Garbage", "Sanitation", "Clean and sanitize garbage collection areas", "Basic", "Weekly", "Medium", 3600),
            ("Mop and Vacuum Floors", "Cleaning", "Vacuum carpets and mop hard floors", "Basic", "Weekly", "Medium", 5400),
            ("Dust All Common Areas", "Cleaning", "Dust all surfaces in common areas", "Basic", "Weekly", "Low", 3600),
            ("Mop and Vacuum Floors (Lobby)", "Cleaning", "Deep clean lobby floors", "Basic", "Weekly", "Medium", 3600),
            ("Clean Garbage and Common Areas", "Sanitation", "Comprehensive cleaning of garbage areas and common spaces", "Basic", "Weekly", "Medium", 5400),
            ("Remove Old Boxes", "Sanitation", "Remove and dispose of old cardboard boxes", "Basic", "Weekly", "Low", 1800),
            ("Clean Courtyard", "Cleaning", "Clean and maintain courtyard areas", "Basic", "Weekly", "Low", 3600),
            ("Wipe Down Boiler", "Maintenance", "Clean and inspect boiler exterior", "Intermediate", "Weekly", "Medium", 1800),
            ("Boiler Blow Down", "Maintenance", "Perform boiler blowdown maintenance", "Advanced", "Weekly", "High", 7200),
            ("Replace All Light Bulbs", "Maintenance", "Check and replace all burned out light bulbs", "Basic", "Monthly", "Medium", 7200),
            ("Sweep and Mop Stairwell", "Cleaning", "Deep clean all stairwells", "Basic", "Monthly", "Low", 5400),
            ("Inspection Water Tank", "Inspection", "Inspect water tank for leaks and proper operation", "Advanced", "Monthly", "High", 3600),
            ("Power Wash", "Cleaning", "Power wash exterior surfaces", "Intermediate", "Monthly", "Medium", 10800),
            ("Check Plumbing and Drainage", "Inspection", "Inspect all plumbing fixtures and drainage systems", "Intermediate", "Monthly", "Medium", 7200)
        ]
        for (name, category, desc, skillLevel, recurrence, urgency, duration) in templates {
            try db.run(
                "INSERT OR IGNORE INTO task_templates (name, category, description, required_skill_level, recurrence, urgency, estimated_duration) VALUES (?, ?, ?, ?, ?, ?, ?);",
                [name, category, desc, skillLevel, recurrence, urgency, duration]
            )
        }
    }

    func down(_ db: Connection) throws {
        try db.run("DROP TABLE IF EXISTS task_templates;")
    }
}

struct V011_BuildingInventory: DatabaseMigration {
    let version = 11
    let name = "Building Inventory"
    var checksum: String { "e1f2a3b4c5d6" }

    func up(_ db: Connection) throws {
        try db.run("""
            CREATE TABLE IF NOT EXISTS building_inventory_defaults (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                building_id TEXT NOT NULL,
                item_name TEXT NOT NULL,
                category TEXT NOT NULL,
                default_quantity INTEGER NOT NULL DEFAULT 0,
                unit TEXT NOT NULL,
                minimum_quantity INTEGER NOT NULL DEFAULT 5,
                location TEXT DEFAULT '',
                UNIQUE(building_id, item_name)
            );
            """)
        try db.run("""
            CREATE TABLE IF NOT EXISTS inventory_audit_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                building_id TEXT NOT NULL,
                item_id TEXT NOT NULL,
                action TEXT NOT NULL,
                quantity_change INTEGER NOT NULL,
                performed_by TEXT NOT NULL,
                timestamp TEXT NOT NULL DEFAULT '\(Date().iso8601String)',
                notes TEXT
            );
            """)
        try db.run("""
            CREATE TABLE IF NOT EXISTS building_weather_settings (
                building_id TEXT PRIMARY KEY,
                temp_low_threshold REAL NOT NULL DEFAULT 32,
                temp_high_threshold REAL NOT NULL DEFAULT 90,
                wind_threshold REAL NOT NULL DEFAULT 25,
                precipitation_threshold REAL NOT NULL DEFAULT 0.5,
                auto_create_weather_tasks INTEGER NOT NULL DEFAULT 1
            );
            """)
        try db.run("""
            CREATE TABLE IF NOT EXISTS schedule_conflicts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                date TEXT NOT NULL,
                conflict_type TEXT NOT NULL,
                building_ids TEXT NOT NULL,
                resolved INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT '\(Date().iso8601String)'
            );
            """)
        try db.run("CREATE INDEX IF NOT EXISTS idx_inventory_defaults_building ON building_inventory_defaults(building_id);")
        try db.run("CREATE INDEX IF NOT EXISTS idx_audit_log_building_timestamp ON inventory_audit_log(building_id, timestamp);")
        try db.run("CREATE INDEX IF NOT EXISTS idx_conflicts_worker_date ON schedule_conflicts(worker_id, date, resolved);")
    }

    func down(_ db: Connection) throws {
        try db.run("DROP INDEX IF EXISTS idx_conflicts_worker_date;")
        try db.run("DROP INDEX IF EXISTS idx_audit_log_building_timestamp;")
        try db.run("DROP INDEX IF EXISTS idx_inventory_defaults_building;")
        try db.run("DROP TABLE IF EXISTS schedule_conflicts;")
        try db.run("DROP TABLE IF EXISTS building_weather_settings;")
        try db.run("DROP TABLE IF EXISTS inventory_audit_log;")
        try db.run("DROP TABLE IF EXISTS building_inventory_defaults;")
    }
}
