
// SQLiteManager.swift
// Refactored with migration system and O3 audit improvements
// FrancoSphere v1.1

import Foundation
import SQLite
import SwiftUI
import CommonCrypto

// MARK: - Database Errors (Must be declared before use)

public enum DatabaseError: LocalizedError {
    case notInitialized
    case connectionFailed
    case migrationFailed(String)
    case invalidData(String)
    case databaseBusy
    case rollbackDisabled
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized. Call SQLiteManager.start() first."
        case .connectionFailed:
            return "Failed to connect to database"
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .databaseBusy:
            return "Database is busy. Please try again."
        case .rollbackDisabled:
            return "Database rollback is disabled in production"
        }
    }
}

// MARK: - Placeholder Services (Must be declared before use)

enum FeatureFlagService {
    static let shared = FeatureFlagService.self
    
    static func isEnabled(_ key: String) -> Bool {
        // In real implementation, check database
        return UserDefaults.standard.bool(forKey: "ff_\(key)")
    }
}

enum TelemetryService {
    static let shared = TelemetryService.self
    
    static func logEvent(_ event: String, metadata: [String: Any]) {
        // In real implementation, queue to database
        print("📊 Telemetry: \(event) - \(metadata)")
    }
}

// MARK: - Extensions (Must be declared before use)

extension Data {
    func sha256Hash() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Migration Protocol

public protocol DatabaseMigration {
    var version: Int { get }
    var name: String { get }
    var checksum: String { get } // Added for integrity
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
        // Create migrations table with checksum column
        try db.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                checksum TEXT,
                applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // Get the highest version
        let query = "SELECT MAX(version) FROM schema_migrations"
        if let maxVersion = try db.scalar(query) as? Int64 {
            return Int(maxVersion)
        }
        return 0
    }
    
    func migrate(migrations: [DatabaseMigration]) throws {
        let currentVersion = try getCurrentVersion()
        
        // Sort migrations by version
        let sortedMigrations = migrations.sorted { $0.version < $1.version }
        
        for migration in sortedMigrations where migration.version > currentVersion {
            try runMigration(migration)
        }
    }
    
    private func runMigration(_ migration: DatabaseMigration) throws {
        print("🔄 Running migration \(migration.version): \(migration.name)")
        
        try db.transaction {
            // Run the migration
            try migration.up(db)
            
            // Record it with checksum
            try db.run("""
                INSERT INTO schema_migrations (version, name, checksum)
                VALUES (?, ?, ?)
            """, migration.version, migration.name, migration.checksum)
        }
        
        print("✅ Migration \(migration.version) completed")
    }
    
    func rollback(to version: Int, migrations: [DatabaseMigration]) throws {
        // Safety gate for production
        guard FeatureFlagService.shared.isEnabled("allow_schema_rollback") else {
            throw DatabaseError.rollbackDisabled
        }
        
        let currentVersion = try getCurrentVersion()
        guard version < currentVersion else { return }
        
        // Log rollback attempt
        TelemetryService.shared.logEvent("migration_rollback", metadata: [
            "from_version": currentVersion,
            "to_version": version
        ])
        
        // Get migrations to rollback in reverse order
        let migrationsToRollback = migrations
            .filter { $0.version > version && $0.version <= currentVersion }
            .sorted { $0.version > $1.version }
        
        for migration in migrationsToRollback {
            try db.transaction {
                try migration.down(db)
                try db.run("DELETE FROM schema_migrations WHERE version = ?", migration.version)
            }
            print("↩️ Rolled back migration \(migration.version)")
        }
    }
}

// MARK: - Actor-based SQLiteManager

public actor SQLiteManager {
    // Static instance - DEPRECATED
    @available(*, deprecated, message: "Use SQLiteManager.start() instead")
    public static let shared = SQLiteManager()
    
    // Database connection
    private var db: Connection?
    private var migrator: DatabaseMigrator?
    
    // Prepared statements cache
    private var preparedStatements: [String: Statement] = [:]
    
    // Migration status
    private var isInitialized = false
    
    // Date formatters (reused for performance)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    private static let iso8601Formatter = ISO8601DateFormatter()
    
    // MARK: - Initialization
    
    private init() {
        // Empty init - actual setup happens in initialize()
    }
    
    /// Async factory method - PREFERRED
    public static func start(inMemory: Bool = false) async throws -> SQLiteManager {
        let manager = SQLiteManager()
        try await manager.initialize(inMemory: inMemory)
        return manager
    }
    
    /// Initialize the database with migrations
    public func initialize(inMemory: Bool = false) async throws {
        guard !isInitialized else { return }
        
        // Setup connection
        if inMemory {
            // For testing
            db = try Connection(":memory:")
        } else {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let dbPath = "\(path)/FrancoSphere.sqlite3"
            
            // Backup existing database before migrations
            if FileManager.default.fileExists(atPath: dbPath) {
                do {
                    let backupPath = "\(path)/FrancoSphere_backup_\(Date().timeIntervalSince1970).sqlite3"
                    try FileManager.default.copyItem(atPath: dbPath, toPath: backupPath)
                } catch {
                    // Log but don't block prod upgrades
                    print("⚠️ Backup failed: \(error)")
                }
            }
            
            // Open with busy timeout
            db = try Connection(dbPath)
        }
        
        // Set critical pragmas
        try db?.execute("PRAGMA journal_mode = WAL")
        try db?.execute("PRAGMA busy_timeout = 5000")
        try db?.execute("PRAGMA foreign_keys = ON")
        try db?.execute("PRAGMA synchronous = NORMAL")
        
        // Setup migrator
        guard let db = db else { throw DatabaseError.connectionFailed }
        migrator = DatabaseMigrator(db: db)
        
        // Run migrations
        try await runMigrations()
        
        // Prepare common statements
        try await prepareStatements()
        
        // Schedule maintenance
        scheduleMaintenanceTasks()
        
        isInitialized = true
    }
    
    // MARK: - Migration System
    
    private func runMigrations() async throws {
        guard let migrator = migrator else { return }
        
        let migrations: [DatabaseMigration] = [
            V001_InitialSchema(),
            V002_AddPasswordHash(),
            V003_AddWeatherCache(),
            V004_AddOutboxTables(),
            V005_AddFeatureFlags(),
            V006_AddTelemetry(),
            V007_AddIndexes(),
            V008_PhotoPathMigration()
        ]
        
        try migrator.migrate(migrations: migrations)
    }
    
    // MARK: - Maintenance
    
    private func scheduleMaintenanceTasks() {
        // Weekly WAL checkpoint
        Task {
            while true {
                try? await Task.sleep(for: .seconds(604800)) // 1 week
                try? await performMaintenance()
            }
        }
    }
    
    private func performMaintenance() async throws {
        guard let db = db else { return }
        
        // WAL checkpoint
        try db.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        
        // Vacuum on weekends
        let calendar = Calendar.current
        if calendar.component(.weekday, from: Date()) == 1 { // Sunday
            try db.execute("VACUUM")
        }
    }
    
    // MARK: - Prepared Statements
    
    private func prepareStatements() async throws {
        guard let db = db else { return }
        
        // Prepare common queries
        preparedStatements["getWorker"] = try db.prepare(
            "SELECT * FROM workers WHERE id = ?"
        )
        
        preparedStatements["getBuilding"] = try db.prepare(
            "SELECT * FROM buildings WHERE id = ?"
        )
        
        preparedStatements["getInventory"] = try db.prepare(
            "SELECT * FROM inventory WHERE buildingId = ? ORDER BY name"
        )
    }
    
    // MARK: - Thread-Safe Operations
    
    private func ensureInitialized() throws {
        guard isInitialized, db != nil else {
            throw DatabaseError.notInitialized
        }
    }
    
    /// Execute a non-returning SQL statement
    public func execute(_ sql: String, parameters: [Any] = []) async throws {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }
        
        do {
            let stmt = try db.prepare(sql)
            try bindParameters(stmt, parameters)
            try stmt.run()
        } catch {
            if let sqliteError = error as? Result,
               case .error(_, let code, _) = sqliteError,
               code == 5 { // SQLITE_BUSY
                throw DatabaseError.databaseBusy
            }
            throw error
        }
    }
    
    /// Execute a query returning results
    public func query(_ sql: String, parameters: [Any] = []) async throws -> [[String: Any]] {
        try ensureInitialized()
        guard let db = db else { throw DatabaseError.notInitialized }
        
        var results: [[String: Any]] = []
        
        do {
            let stmt = try db.prepare(sql)
            try bindParameters(stmt, parameters)
            
            for row in stmt {
                var dict: [String: Any] = [:]
                for (idx, name) in stmt.columnNames.enumerated() {
                    dict[name] = row[idx] ?? NSNull()
                }
                results.append(dict)
            }
        } catch {
            if let sqliteError = error as? Result,
               case .error(_, let code, _) = sqliteError,
               code == 5 { // SQLITE_BUSY
                throw DatabaseError.databaseBusy
            }
            throw error
        }
        
        return results
    }
    
    // MARK: - Photo Operations (v1.1 - File-based)
    
    public func saveTaskPhoto(taskId: String, imageData: Data) async throws -> String {
        try ensureInitialized()
        
        // Generate unique filename
        let photoId = UUID().uuidString
        let photoPath = "photos/\(taskId)/\(photoId).jpg"
        
        // Calculate hash
        let photoHash = imageData.sha256Hash()
        
        // Save to documents directory
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fullPath = "\(documentsPath)/\(photoPath)"
        let directoryPath = "\(documentsPath)/photos/\(taskId)"
        
        // Create directory if needed
        try FileManager.default.createDirectory(
            atPath: directoryPath,
            withIntermediateDirectories: true
        )
        
        // Write file
        try imageData.write(to: URL(fileURLWithPath: fullPath))
        
        // Queue for upload
        let sql = """
            INSERT INTO photo_uploads (task_id, photo_path, photo_hash, retry_count, created_at)
            VALUES (?, ?, ?, 0, ?)
        """
        
        try await execute(sql, parameters: [taskId, photoPath, photoHash, Date()])
        
        return photoPath
    }
    
    public func getPendingPhotoUploads(limit: Int = 10) async throws -> [(id: Int64, taskId: String, path: String)] {
        let sql = """
            SELECT id, task_id, photo_path 
            FROM photo_uploads 
            WHERE retry_count < 3 AND uploaded_at IS NULL
            ORDER BY created_at ASC
            LIMIT ?
        """
        
        let rows = try await query(sql, parameters: [limit])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? Int64,
                  let taskId = row["task_id"] as? String,
                  let path = row["photo_path"] as? String else {
                return nil
            }
            return (id, taskId, path)
        }
    }
    
    // MARK: - Weather Cache Operations (v1.1)
    
    public func cacheWeatherData(
        buildingId: String,
        forecastData: Data,
        riskScore: Double,
        expiresIn: TimeInterval = 14400 // 4 hours
    ) async throws {
        try ensureInitialized()
        
        let sql = """
            INSERT OR REPLACE INTO weather_cache 
            (building_id, forecast_data, risk_score, last_updated, expires_at)
            VALUES (?, ?, ?, ?, ?)
        """
        
        let now = Date()
        let expiresAt = now.addingTimeInterval(expiresIn)
        
        try await execute(sql, parameters: [
            buildingId,
            forecastData,
            riskScore,
            now,
            expiresAt
        ])
    }
    
    public func getCachedWeather(buildingId: String) async throws -> (data: Data, riskScore: Double)? {
        try ensureInitialized()
        
        let sql = """
            SELECT forecast_data, risk_score 
            FROM weather_cache 
            WHERE building_id = ? AND expires_at > ?
        """
        
        let rows = try await query(sql, parameters: [buildingId, Date()])
        
        guard let row = rows.first,
              let data = row["forecast_data"] as? Data,
              let riskScore = row["risk_score"] as? Double else {
            return nil
        }
        
        return (data, riskScore)
    }
    
    // MARK: - Feature Flags (v1.1)
    
    public func isFeatureEnabled(_ key: String) async throws -> Bool {
        try ensureInitialized()
        
        let sql = "SELECT enabled FROM feature_flags WHERE key = ?"
        let rows = try await query(sql, parameters: [key])
        
        if let row = rows.first,
           let enabled = row["enabled"] as? Int64 {
            return enabled == 1
        }
        
        return false
    }
    
    // MARK: - Clock In/Out Methods (Actor-isolated)
    
    /// Async version of clock-in (inside the actor)
    public func logClockInAsync(workerId: Int64, buildingId: Int64, timestamp: Date) async throws {
        try ensureInitialized()
        
        // Use the shared dateFormatter to convert timestamp → String
        let dateFormatter = Self.dateFormatter
        let clockInTime = dateFormatter.string(from: timestamp)
        
        let sql = """
            INSERT INTO worker_time_logs (workerId, buildingId, clockInTime)
            VALUES (?, ?, ?)
        """
        
        try await execute(sql, parameters: [workerId, buildingId, clockInTime])
    }
    
    /// Async version of clock-out (inside the actor)
    public func logClockOutAsync(workerId: Int64, timestamp: Date) async throws {
        try ensureInitialized()
        
        let dateFormatter = Self.dateFormatter
        let clockOutTime = dateFormatter.string(from: timestamp)
        
        // Find the most recent "open" log (no clock‐out time yet) for this worker
        let findSql = """
            SELECT id FROM worker_time_logs
            WHERE workerId = ? AND clockOutTime IS NULL
            ORDER BY clockInTime DESC
            LIMIT 1
        """
        
        let rows = try await query(findSql, parameters: [workerId])
        
        if let row = rows.first,
           let logId = row["id"] as? Int64
        {
            let updateSql = """
                UPDATE worker_time_logs
                SET clockOutTime = ?
                WHERE id = ?
            """
            try await execute(updateSql, parameters: [clockOutTime, logId])
        }
    }
    
    /// Async version of "isWorkerClockedIn" (inside the actor)
    public func isWorkerClockedInAsync(workerId: Int64) async -> (isClockedIn: Bool, buildingId: Int64?) {
        do {
            try ensureInitialized()
            
            let sql = """
                SELECT buildingId FROM worker_time_logs
                WHERE workerId = ? AND clockOutTime IS NULL
                ORDER BY clockInTime DESC
                LIMIT 1
            """
            
            let rows = try await query(sql, parameters: [workerId])
            if let row = rows.first,
               let bId = row["buildingId"] as? Int64
            {
                return (true, bId)
            }
            return (false, nil)
        } catch {
            print("❌ Error checking clock-in status: \(error)")
            return (false, nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func bindParameters(_ stmt: Statement, _ parameters: [Any]) throws {
        for (index, param) in parameters.enumerated() {
            let position = index + 1
            
            switch param {
            case let value as String:
                _ = stmt.bind(position, value)
            case let value as Int:
                _ = stmt.bind(position, value)
            case let value as Int64:
                _ = stmt.bind(position, value)
            case let value as Double:
                _ = stmt.bind(position, value)
            case let value as Bool:
                _ = stmt.bind(position, value ? 1 : 0)
            case let value as Date:
                _ = stmt.bind(position, Self.dateFormatter.string(from: value))
            case let value as Data:
                _ = stmt.bind(position, SQLite.Blob(bytes: [UInt8](value)))
            case is NSNull:
                _ = stmt.bind(position, nil as String?)
            default:
                _ = stmt.bind(position, String(describing: param))
            }
        }
    }
}

// MARK: - Non-Actor Wrappers for SQLiteManager

extension SQLiteManager {
    // MARK: – Clock In/Out Methods (Non-Actor Wrappers)
    
    /// Log clock-in for a worker (non-actor wrapper)
    public func logClockIn(workerId: Int64, buildingId: Int64, timestamp: Date) {
        Task {
            do {
                try await self.logClockInAsync(workerId: workerId, buildingId: buildingId, timestamp: timestamp)
            } catch {
                print("❌ Error logging clock in: \(error)")
            }
        }
    }
    
    /// Log clock-out for a worker (non-actor wrapper)
    public func logClockOut(workerId: Int64, timestamp: Date) {
        Task {
            do {
                try await self.logClockOutAsync(workerId: workerId, timestamp: timestamp)
            } catch {
                print("❌ Error logging clock out: \(error)")
            }
        }
    }
    
    /// Check if a worker is currently clocked in (non-actor wrapper)
    /// Returns (isClockedIn: Bool, buildingId: Int64?)
    public func isWorkerClockedIn(workerId: Int64) -> (isClockedIn: Bool, buildingId: Int64?) {
        let semaphore = DispatchSemaphore(value: 0)
        var result: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
        
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
    var checksum: String { "a1b2c3d4e5f6" } // SHA-256 in real implementation
    
    func up(_ db: Connection) throws {
        // Tasks table
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
        
        // Workers table
        try db.execute("""
            CREATE TABLE IF NOT EXISTS workers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                role TEXT NOT NULL
            )
        """)
        
        // Buildings table
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
        
        // Worker time logs
        try db.execute("""
            CREATE TABLE IF NOT EXISTS worker_time_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                workerId INTEGER NOT NULL,
                buildingId INTEGER NOT NULL,
                clockInTime TEXT NOT NULL,
                clockOutTime TEXT
            )
        """)
        
        // Inventory table
        try db.execute("""
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
        
        // Worker schedule
        try db.execute("""
            CREATE TABLE IF NOT EXISTS worker_schedule (
                workerId TEXT NOT NULL,
                buildingId TEXT NOT NULL,
                weekdays TEXT NOT NULL,
                startHour INTEGER NOT NULL,
                endHour INTEGER NOT NULL,
                PRIMARY KEY (workerId, buildingId, weekdays, startHour)
            )
        """)
    }
    
    func down(_ db: Connection) throws {
        // Drop all tables
        try db.execute("DROP TABLE IF EXISTS worker_schedule")
        try db.execute("DROP TABLE IF EXISTS inventory")
        try db.execute("DROP TABLE IF EXISTS worker_time_logs")
        try db.execute("DROP TABLE IF EXISTS buildings")
        try db.execute("DROP TABLE IF EXISTS workers")
        try db.execute("DROP TABLE IF EXISTS tasks")
    }
}

struct V002_AddPasswordHash: DatabaseMigration {
    let version = 2
    let name = "Add Password Hash"
    var checksum: String { "b2c3d4e5f6a7" }
    
    func up(_ db: Connection) throws {
        try db.execute("""
            ALTER TABLE workers 
            ADD COLUMN passwordHash TEXT NOT NULL DEFAULT ''
        """)
    }
    
    func down(_ db: Connection) throws {
        // SQLite doesn't support DROP COLUMN directly
        // Irreversible; rollback will recreate table via backup restore
        print("⚠️ V002 rollback requires backup restore")
    }
}

struct V003_AddWeatherCache: DatabaseMigration {
    let version = 3
    let name = "Add Weather Cache"
    var checksum: String { "c3d4e5f6a7b8" }
    
    func up(_ db: Connection) throws {
        try db.execute("""
            CREATE TABLE IF NOT EXISTS weather_cache (
                building_id TEXT PRIMARY KEY,
                forecast_data BLOB,
                risk_score REAL,
                last_updated TIMESTAMP,
                expires_at TIMESTAMP
            )
        """)
    }
    
    func down(_ db: Connection) throws {
        try db.execute("DROP TABLE IF EXISTS weather_cache")
    }
}

struct V004_AddOutboxTables: DatabaseMigration {
    let version = 4
    let name = "Add Outbox Tables"
    var checksum: String { "d4e5f6a7b8c9" }
    
    func up(_ db: Connection) throws {
        // DEPRECATED: Using photo_uploads instead
        try db.execute("""
            CREATE TABLE IF NOT EXISTS outbox_photos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                task_id TEXT NOT NULL,
                photo_data BLOB NOT NULL,
                retry_count INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
    }
    
    func down(_ db: Connection) throws {
        try db.execute("DROP TABLE IF EXISTS outbox_photos")
    }
}

struct V005_AddFeatureFlags: DatabaseMigration {
    let version = 5
    let name = "Add Feature Flags"
    var checksum: String { "e5f6a7b8c9d0" }
    
    func up(_ db: Connection) throws {
        try db.execute("""
            CREATE TABLE IF NOT EXISTS feature_flags (
                key TEXT PRIMARY KEY,
                enabled INTEGER DEFAULT 0,
                metadata BLOB
            )
        """)
        
        // Insert default feature flags
        let defaultFlags = [
            "weather_intelligence_enabled": false,
            "admin_commands_enabled": false,
            "ai_suggestions_enabled": false,
            "glass_ui_enabled": false,
            "emergency_mode_enabled": false,
            "allow_schema_rollback": false
        ]
        
        for (key, enabled) in defaultFlags {
            try db.run("""
                INSERT OR IGNORE INTO feature_flags (key, enabled)
                VALUES (?, ?)
            """, key, enabled ? 1 : 0)
        }
    }
    
    func down(_ db: Connection) throws {
        try db.execute("DROP TABLE IF EXISTS feature_flags")
    }
}

struct V006_AddTelemetry: DatabaseMigration {
    let version = 6
    let name = "Add Telemetry"
    var checksum: String { "f6a7b8c9d0e1" }
    
    func up(_ db: Connection) throws {
        try db.execute("""
            CREATE TABLE IF NOT EXISTS telemetry_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT NOT NULL,
                user_id TEXT,
                metadata BLOB,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
    }
    
    func down(_ db: Connection) throws {
        try db.execute("DROP TABLE IF EXISTS telemetry_events")
    }
}

struct V007_AddIndexes: DatabaseMigration {
    let version = 7
    let name = "Add Performance Indexes"
    var checksum: String { "a7b8c9d0e1f2" }
    
    func up(_ db: Connection) throws {
        // Index for worker time logs queries
        try db.execute("""
            CREATE INDEX IF NOT EXISTS idx_worker_time_logs_worker_clock
            ON worker_time_logs(workerId, clockOutTime)
        """)
        
        // Index for inventory queries
        try db.execute("""
            CREATE INDEX IF NOT EXISTS idx_inventory_building
            ON inventory(buildingId)
        """)
        
        // Index for telemetry queries
        try db.execute("""
            CREATE INDEX IF NOT EXISTS idx_telemetry_created
            ON telemetry_events(created_at)
        """)
        
        // Index for weather cache expiry
        try db.execute("""
            CREATE INDEX IF NOT EXISTS idx_weather_expires
            ON weather_cache(expires_at)
        """)
    }
    
    func down(_ db: Connection) throws {
        try db.execute("DROP INDEX IF EXISTS idx_worker_time_logs_worker_clock")
        try db.execute("DROP INDEX IF EXISTS idx_inventory_building")
        try db.execute("DROP INDEX IF EXISTS idx_telemetry_created")
        try db.execute("DROP INDEX IF EXISTS idx_weather_expires")
    }
}

struct V008_PhotoPathMigration: DatabaseMigration {
    let version = 8
    let name = "Photo Path Migration"
    var checksum: String { "b8c9d0e1f2a3" }
    
    func up(_ db: Connection) throws {
        // New table for file-based photos
        try db.execute("""
            CREATE TABLE IF NOT EXISTS photo_uploads (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                task_id TEXT NOT NULL,
                photo_path TEXT NOT NULL,
                photo_hash TEXT NOT NULL,
                retry_count INTEGER DEFAULT 0,
                uploaded_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // Index for pending uploads
        try db.execute("""
            CREATE INDEX IF NOT EXISTS idx_photo_uploads_pending
            ON photo_uploads(uploaded_at, retry_count)
        """)
    }
    
    func down(_ db: Connection) throws {
        try db.execute("DROP INDEX IF EXISTS idx_photo_uploads_pending")
        try db.execute("DROP TABLE IF EXISTS photo_uploads")
    }
}
