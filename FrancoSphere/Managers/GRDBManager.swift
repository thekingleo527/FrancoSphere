//
//  GRDBManager.swift
//  FrancoSphere
//
//  ✅ COMPLETE: Full authentication + operational database manager
//  ✅ MERGED: All functionality from DatabaseManager + GRDBManager
//  ✅ SINGLE SOURCE: One manager for everything
//

import Foundation
import GRDB
import Combine

// MARK: - Authentication Types

public enum AuthenticationResult {
    case success(AuthenticatedUser)
    case failure(String)
}

public struct AuthenticatedUser: Codable {
    public let id: Int
    public let name: String
    public let email: String
    public let password: String
    public let role: String
    public let workerId: String
    public let displayName: String?
    public let timezone: String
    
    public init(id: Int, name: String, email: String, password: String, role: String, workerId: String, displayName: String? = nil, timezone: String = "America/New_York") {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
        self.role = role
        self.workerId = workerId
        self.displayName = displayName
        self.timezone = timezone
    }
}

// MARK: - Complete GRDBManager Class

public class GRDBManager {
    public static let shared = GRDBManager()
    
    private let dbQueue: DatabaseQueue
    private let dbPath: String
    
    // Configuration
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 0.5
    
    private init() {
        do {
            // Set up database path
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            dbPath = "\(documentsPath)/francosphere.db"
            
            print("📁 Database path: \(dbPath)")
            
            // Create database queue
            dbQueue = try DatabaseQueue(path: dbPath)
            
            // Configure database
            try dbQueue.write { db in
                // Enable foreign keys
                try db.execute(sql: "PRAGMA foreign_keys = ON")
                
                // Create all tables
                try createAllTables(db)
            }
            
            print("✅ GRDBManager initialized successfully")
            
        } catch {
            fatalError("❌ Failed to initialize GRDBManager: \(error)")
        }
    }
    
    // MARK: - Core Database Methods
    
    /// Execute a query and return results
    public func query(_ sql: String, _ arguments: [Any] = []) async throws -> [[String: Any]] {
        return try await withRetry {
            try await self.dbQueue.read { db in
                let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(arguments))
                return rows.map { row in
                    Dictionary(uniqueKeysWithValues: row.columnNames.map { ($0, row[$0] as Any) })
                }
            }
        }
    }
    
    /// Execute a non-query SQL statement
    @discardableResult
    public func execute(_ sql: String, _ arguments: [Any] = []) async throws -> Int64 {
        return try await withRetry {
            try await self.dbQueue.write { db in
                try db.execute(sql: sql, arguments: StatementArguments(arguments))
                return db.lastInsertedRowID
            }
        }
    }
    
    /// Execute multiple statements in a transaction
    public func transaction<T>(_ block: @escaping (Database) throws -> T) async throws -> T {
        return try await withRetry {
            try await self.dbQueue.write { db in
                try db.inTransaction {
                    try block(db)
                    return .commit
                }
            }
        }
    }
    
    // MARK: - Retry Logic
    
    private func withRetry<T>(_ operation: () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                print("⚠️ Database operation failed (attempt \(attempt + 1)/\(maxRetries)): \(error)")
                
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? DatabaseError.unknownError
    }
    
    // MARK: - Database Setup
    
    /// Check if database exists and is accessible
    public func isDatabaseReady() async -> Bool {
        do {
            let result = try await query("SELECT 1")
            return !result.isEmpty
        } catch {
            print("❌ Database not ready: \(error)")
            return false
        }
    }
    
    /// Get database file size
    public func getDatabaseSize() -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: dbPath)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Reset database (dangerous - for testing only)
    public func resetDatabase() async throws {
        try await dbQueue.write { db in
            // Drop all tables
            let tables = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name NOT LIKE 'sqlite_%'
            """)
            
            for table in tables {
                try db.execute(sql: "DROP TABLE IF EXISTS \(table)")
            }
            
            // Recreate all tables
            try createAllTables(db)
        }
        
        print("🔄 Database reset complete")
    }
    
    // MARK: - Table Creation (Core Implementation)
    
    func createAllTables(_ db: Database) throws {
        print("🔧 Creating complete unified schema...")
        
        // 1. Enhanced workers table (merged users + workers)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS workers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                -- Core worker fields
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                phone TEXT,
                hourlyRate REAL DEFAULT 25.0,
                skills TEXT,
                profileImagePath TEXT,
                address TEXT,
                emergencyContact TEXT,
                notes TEXT,
                
                -- Authentication fields (from users table)
                password TEXT NOT NULL,
                role TEXT NOT NULL DEFAULT 'worker',
                isActive INTEGER NOT NULL DEFAULT 1,
                lastLogin TEXT,
                loginAttempts INTEGER DEFAULT 0,
                lockedUntil TEXT,
                
                -- Profile fields (from user_profiles)
                display_name TEXT,
                timezone TEXT DEFAULT 'America/New_York',
                language TEXT DEFAULT 'en',
                notification_preferences TEXT,
                profile_picture_url TEXT,
                emergency_contact_json TEXT,
                
                -- Timestamps
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // 2. Buildings table (unchanged)
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
                specialNotes TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // 3. Routine tasks table (enhanced)
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
                external_id TEXT UNIQUE,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (buildingId) REFERENCES buildings(id),
                FOREIGN KEY (workerId) REFERENCES workers(id)
            )
        """)
        
        // 4. Worker building assignments
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS worker_building_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id INTEGER NOT NULL,
                building_id INTEGER NOT NULL,
                role TEXT NOT NULL DEFAULT 'maintenance',
                assigned_date TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (worker_id) REFERENCES workers(id),
                FOREIGN KEY (building_id) REFERENCES buildings(id),
                UNIQUE(worker_id, building_id)
            )
        """)
        
        // 5. User sessions (for authentication)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS user_sessions (
                session_id TEXT PRIMARY KEY,
                worker_id INTEGER NOT NULL,
                device_info TEXT,
                ip_address TEXT,
                login_time TEXT NOT NULL,
                last_activity TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            )
        """)
        
        // 6. Login history (for security)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS login_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id INTEGER,
                email TEXT NOT NULL,
                login_time TEXT NOT NULL,
                success INTEGER NOT NULL,
                failure_reason TEXT,
                ip_address TEXT,
                device_info TEXT,
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            )
        """)
        
        // 7. Clock sessions (for time tracking)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS clock_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id INTEGER NOT NULL,
                building_id INTEGER NOT NULL,
                clock_in_time TEXT NOT NULL,
                clock_out_time TEXT,
                duration_minutes INTEGER,
                location_lat REAL,
                location_lon REAL,
                notes TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (worker_id) REFERENCES workers(id),
                FOREIGN KEY (building_id) REFERENCES buildings(id)
            )
        """)
        
        // 8. Task completions (evidence tracking)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS task_completions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                task_id INTEGER NOT NULL,
                worker_id INTEGER NOT NULL,
                completion_time TEXT NOT NULL,
                photo_paths TEXT,
                notes TEXT,
                quality_score INTEGER,
                verified_by INTEGER,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (task_id) REFERENCES routine_tasks(id),
                FOREIGN KEY (worker_id) REFERENCES workers(id),
                FOREIGN KEY (verified_by) REFERENCES workers(id)
            )
        """)
        
        // 9. Worker assignments table (compatibility)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS worker_assignments (
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                worker_name TEXT,
                building_name TEXT,
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (worker_id, building_id)
            )
        """)
        
        // 10. Tasks table (legacy compatibility)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                buildingId INTEGER,
                workerId INTEGER,
                isCompleted INTEGER DEFAULT 0,
                scheduledDate TEXT,
                dueDate TEXT,
                category TEXT,
                urgency TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // 11. Worker time logs
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS worker_time_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                workerId INTEGER NOT NULL,
                buildingId INTEGER NOT NULL,
                clockInTime TEXT NOT NULL,
                clockOutTime TEXT,
                duration REAL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (workerId) REFERENCES workers(id),
                FOREIGN KEY (buildingId) REFERENCES buildings(id)
            )
        """)
        
        // Create all necessary indexes
        try createIndexes(db)
        
        print("✅ Complete unified schema created")
    }
    
    private func createIndexes(_ db: Database) throws {
        // Worker indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_workers_email ON workers(email)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_workers_active ON workers(isActive)")
        
        // Task indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_tasks_building ON routine_tasks(buildingId)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_tasks_worker ON routine_tasks(workerId)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_tasks_scheduled ON routine_tasks(scheduledDate)")
        
        // Session indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_sessions_worker_active ON user_sessions(worker_id, is_active)")
        
        // Login history indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_login_history_worker ON login_history(worker_id, login_time)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_login_history_email ON login_history(email)")
        
        // Assignment indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_assignments_worker ON worker_building_assignments(worker_id)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_assignments_building ON worker_building_assignments(building_id)")
    }
    
    // MARK: - Complete Authentication Implementation
    
    /// Authenticate worker with email and password
    public func authenticateWorker(email: String, password: String) async -> AuthenticationResult {
        do {
            // Check if account is locked
            if try await isAccountLocked(email: email) {
                await recordLoginAttempt(email: email, success: false, reason: "Account locked")
                return .failure("Account is temporarily locked due to multiple failed attempts")
            }
            
            // Fetch worker
            let rows = try await query("""
                SELECT * FROM workers 
                WHERE email = ? AND isActive = 1
            """, [email])
            
            guard let row = rows.first else {
                await recordLoginAttempt(email: email, success: false, reason: "User not found")
                return .failure("Invalid credentials")
            }
            
            // Verify password
            let storedPassword = row["password"] as? String ?? ""
            guard storedPassword == password else {
                try await incrementLoginAttempts(email: email)
                await recordLoginAttempt(email: email, success: false, reason: "Invalid password")
                return .failure("Invalid credentials")
            }
            
            // Success - reset attempts and update last login
            try await execute("""
                UPDATE workers 
                SET loginAttempts = 0, 
                    lockedUntil = NULL,
                    lastLogin = datetime('now'),
                    updated_at = datetime('now')
                WHERE email = ?
            """, [email])
            
            await recordLoginAttempt(email: email, success: true, reason: nil)
            
            // Create authenticated user object
            let user = AuthenticatedUser(
                id: Int(row["id"] as? Int64 ?? 0),
                name: row["name"] as? String ?? "",
                email: email,
                password: "", // Don't return password
                role: row["role"] as? String ?? "worker",
                workerId: String(row["id"] as? Int64 ?? 0),
                displayName: row["display_name"] as? String,
                timezone: row["timezone"] as? String ?? "America/New_York"
            )
            
            return .success(user)
            
        } catch {
            print("❌ Authentication error: \(error)")
            return .failure("Authentication failed: \(error.localizedDescription)")
        }
    }
    
    /// Create a new user session
    public func createSession(for workerId: String, deviceInfo: String = "iOS App") async throws -> String {
        let sessionId = UUID().uuidString
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        
        try await execute("""
            INSERT INTO user_sessions 
            (session_id, worker_id, device_info, ip_address, login_time, last_activity, expires_at, is_active)
            VALUES (?, ?, ?, ?, datetime('now'), datetime('now'), ?, 1)
        """, [sessionId, workerId, deviceInfo, "127.0.0.1", ISO8601DateFormatter().string(from: expiresAt)])
        
        return sessionId
    }
    
    /// Validate an existing session
    public func validateSession(_ sessionId: String) async throws -> AuthenticatedUser? {
        let rows = try await query("""
            SELECT 
                w.*, s.expires_at
            FROM user_sessions s
            JOIN workers w ON s.worker_id = w.id
            WHERE s.session_id = ? AND s.is_active = 1 AND w.isActive = 1
        """, [sessionId])
        
        guard let row = rows.first else { return nil }
        
        // Check if session expired
        if let expiresAtString = row["expires_at"] as? String,
           let expiresAt = ISO8601DateFormatter().date(from: expiresAtString),
           Date() > expiresAt {
            // Deactivate expired session
            try await execute("UPDATE user_sessions SET is_active = 0 WHERE session_id = ?", [sessionId])
            return nil
        }
        
        // Update last activity
        try await execute("""
            UPDATE user_sessions 
            SET last_activity = datetime('now') 
            WHERE session_id = ?
        """, [sessionId])
        
        return AuthenticatedUser(
            id: Int(row["id"] as? Int64 ?? 0),
            name: row["name"] as? String ?? "",
            email: row["email"] as? String ?? "",
            password: "", // Don't return password
            role: row["role"] as? String ?? "worker",
            workerId: String(row["id"] as? Int64 ?? 0),
            displayName: row["display_name"] as? String,
            timezone: row["timezone"] as? String ?? "America/New_York"
        )
    }
    
    /// Logout - deactivate all sessions for a worker
    public func logout(workerId: String) async throws {
        try await execute("""
            UPDATE user_sessions 
            SET is_active = 0, last_activity = datetime('now')
            WHERE worker_id = ? AND is_active = 1
        """, [workerId])
    }
    
    // MARK: - Security Features
    
    private func isAccountLocked(email: String) async throws -> Bool {
        let rows = try await query("""
            SELECT loginAttempts, lockedUntil FROM workers WHERE email = ?
        """, [email])
        
        guard let row = rows.first else { return false }
        
        let attempts = row["loginAttempts"] as? Int64 ?? 0
        let lockedUntilString = row["lockedUntil"] as? String
        
        if attempts >= 5 {
            if let lockedUntilString = lockedUntilString,
               let lockedUntil = ISO8601DateFormatter().date(from: lockedUntilString),
               Date() < lockedUntil {
                return true
            } else {
                // Reset if lock period expired
                try await execute("""
                    UPDATE workers SET loginAttempts = 0, lockedUntil = NULL WHERE email = ?
                """, [email])
            }
        }
        
        return false
    }
    
    private func incrementLoginAttempts(email: String) async throws {
        let rows = try await query("SELECT loginAttempts FROM workers WHERE email = ?", [email])
        let currentAttempts = rows.first?["loginAttempts"] as? Int64 ?? 0
        let newAttempts = currentAttempts + 1
        
        var lockedUntil: String? = nil
        if newAttempts >= 5 {
            // Lock for 30 minutes
            let lockTime = Date().addingTimeInterval(30 * 60)
            lockedUntil = ISO8601DateFormatter().string(from: lockTime)
        }
        
        try await execute("""
            UPDATE workers 
            SET loginAttempts = ?, lockedUntil = ?, updated_at = datetime('now')
            WHERE email = ?
        """, [newAttempts, lockedUntil as Any, email])
    }
    
    private func recordLoginAttempt(email: String, success: Bool, reason: String?) async {
        do {
            let workerRows = try await query("SELECT id FROM workers WHERE email = ?", [email])
            let workerId = workerRows.first?["id"] as? Int64
            
            try await execute("""
                INSERT INTO login_history 
                (worker_id, email, login_time, success, failure_reason, ip_address, device_info)
                VALUES (?, ?, datetime('now'), ?, ?, ?, ?)
            """, [workerId as Any, email, success ? 1 : 0, reason as Any, "127.0.0.1", "iOS App"])
        } catch {
            print("⚠️ Failed to record login attempt: \(error)")
        }
    }
    
    // MARK: - Complete Seed Data (All Workers + Test Accounts)
    
    public func seedCompleteWorkerData() async throws {
        print("🌱 Seeding complete worker data with authentication...")
        
        // Real worker data with authentication
        let realWorkers: [(String, String, String, String, String, String?, Double)] = [
            // (id, name, email, password, role, phone, hourlyRate)
            ("1", "Greg Hutson", "g.hutson1989@gmail.com", "password", "worker", "917-555-0001", 28.0),
            ("2", "Edwin Lema", "edwinlema911@gmail.com", "password", "worker", "917-555-0002", 26.0),
            ("3", "Francisco Franco", "francisco@francomanagementgroup.com", "password", "admin", "917-555-0003", 50.0),
            ("4", "Kevin Dutan", "dutankevin1@gmail.com", "password", "worker", "917-555-0004", 25.0),
            ("5", "Mercedes Inamagua", "jneola@gmail.com", "password", "worker", "917-555-0005", 27.0),
            ("6", "Luis Lopez", "luislopez030@yahoo.com", "password", "worker", "917-555-0006", 25.0),
            ("7", "Angel Guirachocha", "lio.angel71@gmail.com", "password", "worker", "917-555-0007", 26.0),
            ("8", "Shawn Magloire", "shawn@francomanagementgroup.com", "password", "admin", "917-555-0008", 45.0)
        ]
        
        // Additional accounts for Shawn (multiple roles)
        let additionalAccounts: [(String, String, String, String)] = [
            // (name, email, password, role)
            ("Shawn Magloire", "francosphere@francomanagementgroup.com", "password", "client"),
            ("Shawn Magloire", "shawn@fme-llc.com", "password", "admin")
        ]
        
        // Test accounts for development
        let testAccounts: [(String, String, String, String)] = [
            ("Test Worker", "test@franco.com", "password", "worker"),
            ("Test Admin", "admin@franco.com", "password", "admin"),
            ("Test Client", "client@franco.com", "password", "client"),
            ("Demo User", "demo@franco.com", "password", "worker")
        ]
        
        // Insert real workers
        for (id, name, email, password, role, phone, rate) in realWorkers {
            try await execute("""
                INSERT OR REPLACE INTO workers 
                (id, name, email, password, role, phone, hourlyRate, isActive, 
                 skills, timezone, notification_preferences, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, 'America/New_York', '{}', datetime('now'), datetime('now'))
            """, [id, name, email, password, role, phone ?? "", rate, getDefaultSkills(for: role)])
        }
        
        // Insert additional accounts (without specific IDs)
        for (name, email, password, role) in additionalAccounts {
            try await execute("""
                INSERT OR IGNORE INTO workers 
                (name, email, password, role, isActive, hourlyRate, 
                 skills, timezone, notification_preferences, created_at, updated_at) 
                VALUES (?, ?, ?, ?, 1, ?, ?, 'America/New_York', '{}', datetime('now'), datetime('now'))
            """, [name, email, password, role, 35.0, getDefaultSkills(for: role)])
        }
        
        // Insert test accounts
        for (name, email, password, role) in testAccounts {
            try await execute("""
                INSERT OR IGNORE INTO workers 
                (name, email, password, role, isActive, hourlyRate, 
                 skills, timezone, notification_preferences, created_at, updated_at) 
                VALUES (?, ?, ?, ?, 1, 25.0, ?, 'America/New_York', '{}', datetime('now'), datetime('now'))
            """, [name, email, password, role, getDefaultSkills(for: role)])
        }
        
        print("✅ Seeded \(realWorkers.count) real workers + \(additionalAccounts.count + testAccounts.count) additional accounts")
    }
    
    private func getDefaultSkills(for role: String) -> String {
        switch role {
        case "admin":
            return "Management,Scheduling,Reporting,Quality Control"
        case "client":
            return "Property Management,Communication"
        default:
            return "General Maintenance,Cleaning,Basic Repairs,Safety Protocols"
        }
    }
    
    // MARK: - User Management Methods
    
    /// Get all users (workers) with optional filtering
    public func getAllUsers(includeInactive: Bool = false) async throws -> [AuthenticatedUser] {
        let condition = includeInactive ? "" : "WHERE isActive = 1"
        
        let rows = try await query("""
            SELECT * FROM workers
            \(condition)
            ORDER BY name
        """)
        
        return rows.map { row in
            AuthenticatedUser(
                id: Int(row["id"] as? Int64 ?? 0),
                name: row["name"] as? String ?? "",
                email: row["email"] as? String ?? "",
                password: "", // Don't return passwords
                role: row["role"] as? String ?? "worker",
                workerId: String(row["id"] as? Int64 ?? 0),
                displayName: row["display_name"] as? String,
                timezone: row["timezone"] as? String ?? "America/New_York"
            )
        }
    }
    
    /// Add a new user
    public func addUser(name: String, email: String, password: String, role: String = "worker") async throws {
        // Check if user already exists
        let existing = try await query("SELECT id FROM workers WHERE email = ?", [email])
        guard existing.isEmpty else {
            throw GRDBError.duplicateUser("User with email \(email) already exists")
        }
        
        try await execute("""
            INSERT INTO workers 
            (name, email, password, role, isActive, created_at, updated_at) 
            VALUES (?, ?, ?, ?, 1, datetime('now'), datetime('now'))
        """, [name, email, password, role])
    }
    
    /// Update user details
    public func updateUser(id: Int, name: String? = nil, email: String? = nil, role: String? = nil, isActive: Bool? = nil) async throws {
        var updates: [String] = []
        var params: [Any] = []
        
        if let name = name {
            updates.append("name = ?")
            params.append(name)
        }
        if let email = email {
            updates.append("email = ?")
            params.append(email)
        }
        if let role = role {
            updates.append("role = ?")
            params.append(role)
        }
        if let isActive = isActive {
            updates.append("isActive = ?")
            params.append(isActive ? 1 : 0)
        }
        
        updates.append("updated_at = datetime('now')")
        params.append(id)
        
        let updateSQL = "UPDATE workers SET \(updates.joined(separator: ", ")) WHERE id = ?"
        try await execute(updateSQL, params)
    }
    
    // MARK: - Statistics and Debugging
    
    /// Get authentication statistics
    public func getAuthenticationStats() async throws -> [String: Any] {
        var stats: [String: Any] = [:]
        
        // Total active users
        let userCount = try await query("SELECT COUNT(*) as count FROM workers WHERE isActive = 1")
        stats["totalActiveUsers"] = userCount.first?["count"] as? Int64 ?? 0
        
        // Users by role
        let roleStats = try await query("""
            SELECT role, COUNT(*) as count FROM workers 
            WHERE isActive = 1 
            GROUP BY role
        """)
        
        var roleBreakdown: [String: Int64] = [:]
        for row in roleStats {
            if let role = row["role"] as? String, let count = row["count"] as? Int64 {
                roleBreakdown[role] = count
            }
        }
        stats["usersByRole"] = roleBreakdown
        
        // Active sessions
        let activeSessions = try await query("""
            SELECT COUNT(*) as count FROM user_sessions 
            WHERE is_active = 1 AND expires_at > datetime('now')
        """)
        stats["activeSessions"] = activeSessions.first?["count"] as? Int64 ?? 0
        
        // Recent login activity
        let recentLogins = try await query("""
            SELECT COUNT(*) as count FROM login_history 
            WHERE login_time >= datetime('now', '-7 days') AND success = 1
        """)
        stats["successfulLoginsLast7Days"] = recentLogins.first?["count"] as? Int64 ?? 0
        
        // Failed login attempts
        let failedLogins = try await query("""
            SELECT COUNT(*) as count FROM login_history 
            WHERE login_time >= datetime('now', '-24 hours') AND success = 0
        """)
        stats["failedLoginsLast24Hours"] = failedLogins.first?["count"] as? Int64 ?? 0
        
        return stats
    }
    
    /// Test authentication for all real workers
    public func testRealWorkerAuthentication() async {
        print("🔐 TESTING REAL WORKER AUTHENTICATION")
        print("═══════════════════════════════════════")
        
        let testWorkers = [
            ("g.hutson1989@gmail.com", "Greg Hutson"),
            ("edwinlema911@gmail.com", "Edwin Lema"),
            ("dutankevin1@gmail.com", "Kevin Dutan"),
            ("jneola@gmail.com", "Mercedes Inamagua"),
            ("luislopez030@yahoo.com", "Luis Lopez"),
            ("lio.angel71@gmail.com", "Angel Guirachocha"),
            ("shawn@francomanagementgroup.com", "Shawn Magloire")
        ]
        
        for (email, expectedName) in testWorkers {
            let result = await authenticateWorker(email: email, password: "password")
            switch result {
            case .success(let user):
                print("   ✅ \(email): Authenticated as \(user.name)")
                if user.name != expectedName {
                    print("      ⚠️ Name mismatch: expected '\(expectedName)', got '\(user.name)'")
                }
            case .failure(let error):
                print("   ❌ \(email): Authentication failed - \(error)")
            }
        }
        
        print("═══════════════════════════════════════")
    }
}

// MARK: - Custom Errors

enum GRDBError: LocalizedError {
    case duplicateUser(String)
    case invalidSession(String)
    case authenticationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .duplicateUser(let msg): return msg
        case .invalidSession(let msg): return msg
        case .authenticationFailed(let msg): return msg
        }
    }
}

enum DatabaseError: LocalizedError {
    case unknownError
    case connectionFailed
    case transactionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unknownError: return "An unknown database error occurred"
        case .connectionFailed: return "Failed to connect to database"
        case .transactionFailed(let msg): return "Transaction failed: \(msg)"
        }
    }
}
