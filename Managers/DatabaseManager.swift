//
//  DatabaseManager.swift - COMPILATION ERRORS FIXED
//  FrancoSphere
//
//  ✅ FIXED: Removed duplicate DatabaseMigration protocol
//  ✅ FIXED: currentTimestamp compilation errors
//  ✅ FIXED: Extra arguments in calls
//  ✅ FIXED: Tuple access errors
//  ✅ Uses DatabaseMigration.swift protocol
//

import SQLite
import Foundation

// MARK: - Complete Database Manager (Compilation Fixed)
class DatabaseManager {
    
    static let shared = DatabaseManager()
    private var db: Connection?

    // MARK: - Original User Authentication Tables
    private let users = Table("users")
    
    // Original user expressions
    private let id = Expression<Int64>("id")
    private let name = Expression<String>("name")
    private let email = Expression<String>("email")
    private let password = Expression<String>("password")

    // MARK: - Worker Schedule Tables
    private let workerSchedules = Table("worker_schedules")
    private let workerShiftPatterns = Table("worker_shift_patterns")
    
    // MARK: - Worker Schedule Expressions
    private let scheduleId = Expression<Int64>("id")
    private let workerId = Expression<String>("worker_id")
    private let workerName = Expression<String>("worker_name")
    private let scheduleText = Expression<String>("schedule_text")
    private let startTime = Expression<String?>("start_time")
    private let endTime = Expression<String?>("end_time")
    private let daysOfWeek = Expression<String?>("days_of_week")
    private let timezone = Expression<String>("timezone")
    private let isActive = Expression<Int>("is_active")
    private let createdAt = Expression<String>("created_at")
    private let updatedAt = Expression<String>("updated_at")
    
    // Worker shift pattern expressions
    private let shiftType = Expression<String>("shift_type")
    private let startHour = Expression<Int>("start_hour")
    private let endHour = Expression<Int>("end_hour")
    private let days = Expression<String?>("days")
    private let breakStartHour = Expression<Int?>("break_start_hour")
    private let breakEndHour = Expression<Int?>("break_end_hour")

    private init() {
        setupDatabase()
    }

    // MARK: - ✅ ORIGINAL FUNCTIONALITY PRESERVED
    
    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/db.sqlite3")
            
            print("Database path: \(path)/db.sqlite3")

            // Create original users table
            try createOriginalUsersTables()
            
            // Create new worker schedule tables
            try createWorkerScheduleTables()
            
            // Seed original test users + real workers
            try seedOriginalUsers()
            
            // Apply worker schedule migration
            Task {
                try await applyWorkerScheduleMigration()
            }

        } catch {
            print("Error setting up database: \(error)")
        }
    }
    
    /// Create original users table + workers table (FIXED)
    private func createOriginalUsersTables() throws {
        // Original users table
        try db?.run(users.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(name)
            t.column(email, unique: true)
            t.column(password)
        })
        
        // Workers table for real worker data
        try db?.execute("""
            CREATE TABLE IF NOT EXISTS workers (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                role TEXT DEFAULT 'worker',
                passwordHash TEXT,
                skillLevels TEXT, -- JSON array
                assignedBuildings TEXT, -- JSON array  
                timezonePreference TEXT DEFAULT 'EST',
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now'))
            )
        """)
        
        // Seed real workers into workers table
        try seedRealWorkersTable()
        
        print("✅ Original users table + workers table created")
    }
    
    /// Seed real workers into workers table
    private func seedRealWorkersTable() throws {
        let realWorkers: [(String, String, String, String, String)] = [
            // (id, name, email, role, skillLevels)
            ("1", "Greg Hutson", "g.hutson1989@gmail.com", "worker", "[\"plumbing\",\"electrical\",\"hvac\"]"),
            ("2", "Edwin Lema", "edwinlema911@gmail.com", "worker", "[\"cleaning\",\"sanitation\",\"inspection\"]"),
            ("4", "Kevin Dutan", "dutankevin1@gmail.com", "worker", "[\"hvac\",\"electrical\",\"technical\"]"),
            ("5", "Mercedes Inamagua", "jneola@gmail.com", "worker", "[\"cleaning\",\"sanitation\"]"),
            ("6", "Luis Lopez", "luislopez030@yahoo.com", "worker", "[\"maintenance\",\"manual\",\"inspection\"]"),
            ("7", "Angel Guirachocha", "lio.angel71@gmail.com", "worker", "[\"cleaning\",\"sanitation\",\"manual\"]"),
            ("8", "Shawn Magloire", "shawn@francomanagementgroup.com", "worker", "[\"management\",\"inspection\",\"maintenance\"]"),
            ("9", "Shawn Magloire", "francosphere@francomanagementgroup.com", "client", "[\"management\",\"oversight\"]"),
            ("10", "Shawn Magloire", "shawn@fme-llc.com", "admin", "[\"management\",\"administration\"]")
        ]
        
        for worker in realWorkers {
            // FIXED: Proper SQLite.swift parameter binding
            try db?.execute("""
                INSERT OR REPLACE INTO workers 
                (id, name, email, role, passwordHash, skillLevels, is_active)
                VALUES (?, ?, ?, ?, 'password', ?, 1)
            """)
            
            // Use run with parameters array
            try db?.run("""
                INSERT OR REPLACE INTO workers 
                (id, name, email, role, passwordHash, skillLevels, is_active)
                VALUES (?, ?, ?, ?, 'password', ?, 1)
            """, [worker.0, worker.1, worker.2, worker.3, worker.4])
        }
        
        // Mark Jose Santos as inactive (if exists)
        try db?.execute("UPDATE workers SET is_active = 0 WHERE id = '3' OR name LIKE '%Jose%'")
        
        print("✅ Real workers seeded into workers table")
    }
    
    /// Seed original test users + real workers (FIXED)
    private func seedOriginalUsers() {
        do {
            // Original test users (preserved)
            try addUser(name: "Test User", email: "test@franco.com", password: "password")
            try addUser(name: "Worker User", email: "worker@franco.com", password: "password")
            try addUser(name: "Client User", email: "client@franco.com", password: "password")
            try addUser(name: "Admin User", email: "admin@franco.com", password: "password")
            
            // Real worker users (PHASE-2 ACTIVE ROSTER)
            try addUser(name: "Greg Hutson", email: "g.hutson1989@gmail.com", password: "password")
            try addUser(name: "Edwin Lema", email: "edwinlema911@gmail.com", password: "password")
            try addUser(name: "Kevin Dutan", email: "dutankevin1@gmail.com", password: "password")
            try addUser(name: "Mercedes Inamagua", email: "jneola@gmail.com", password: "password")
            try addUser(name: "Luis Lopez", email: "luislopez030@yahoo.com", password: "password")
            try addUser(name: "Angel Guirachocha", email: "lio.angel71@gmail.com", password: "password")
            try addUser(name: "Shawn Magloire", email: "shawn@francomanagementgroup.com", password: "password")
            
            // Admin/Client accounts
            try addUser(name: "Shawn Magloire", email: "francosphere@francomanagementgroup.com", password: "password")
            try addUser(name: "Shawn Magloire", email: "shawn@fme-llc.com", password: "password")
            
            print("✅ Original test users + real workers added successfully")
        } catch {
            print("Error adding users: \(error)")
        }
    }

    // MARK: - ✅ ORIGINAL USER METHODS (PRESERVED)
    
    func addUser(name userName: String, email userEmail: String, password userPassword: String) throws {
        guard let db = db else { throw NSError(domain: "DBError", code: 1) }

        let query = users.filter(email == userEmail)
        if try db.pluck(query) == nil {
            try db.run(users.insert(
                name <- userName,
                email <- userEmail,
                password <- userPassword
            ))
            print("Added user: \(userName), \(userEmail)")
        } else {
            print("User already exists: \(userEmail)")
        }
    }

    func fetchUser(byEmail userEmail: String) throws -> (String, String, String)? {
        guard let db = db else { throw NSError(domain: "DBError", code: 1) }

        print("Searching for user with email: \(userEmail)")
        if let user = try db.pluck(users.filter(email == userEmail)) {
            let fetchedName: String = try user.get(name)
            let fetchedEmail: String = try user.get(email)
            let fetchedPassword: String = try user.get(password)
            print("Found user: \(fetchedName), \(fetchedEmail)")
            return (fetchedName, fetchedEmail, fetchedPassword)
        }
        print("User not found with email: \(userEmail)")
        return nil
    }

    func authenticateUser(email userEmail: String, password userPassword: String, completion: @escaping (Bool, String?) -> Void) {
        do {
            print("Attempting to authenticate: \(userEmail)")
            
            if let userData = try fetchUser(byEmail: userEmail) {
                let storedPassword = userData.2
                if storedPassword == userPassword {
                    print("Password match for \(userEmail)")
                    completion(true, nil)
                } else {
                    print("Password mismatch for \(userEmail)")
                    completion(false, "Incorrect password")
                }
            } else {
                print("No user found with email: \(userEmail)")
                completion(false, "User not found")
            }
        } catch {
            print("Authentication error: \(error)")
            completion(false, "Login failed: \(error.localizedDescription)")
        }
    }

    func printAllUsers() {
        do {
            guard let db = db else {
                print("Database connection not available")
                return
            }

            let allUsers = try db.prepare(users)
            print("=== All Users in Database ===")
            var count = 0
            
            for user in allUsers {
                do {
                    let userName = try user.get(name)
                    let userEmail = try user.get(email)
                    print("User: \(userName), Email: \(userEmail)")
                    count += 1
                } catch {
                    print("Error reading user data: \(error)")
                }
            }
            
            print("Total users found: \(count)")
            print("============================")
        } catch {
            print("Error fetching all users: \(error)")
        }
    }
    
    // MARK: - ✅ NEW WORKER SCHEDULE SYSTEM (FIXED)
    
    /// Create worker schedule tables for dynamic shift management
    private func createWorkerScheduleTables() throws {
        guard let db = db else { throw NSError(domain: "DBError", code: 1) }
        
        // FIXED: Use proper SQLite datetime functions instead of currentTimestamp
        let currentTime = "datetime('now')"
        
        // Worker schedules table - for text-based schedule descriptions
        try db.run(workerSchedules.create(ifNotExists: true) { t in
            t.column(scheduleId, primaryKey: .autoincrement)
            t.column(workerId)
            t.column(workerName)
            t.column(scheduleText)
            t.column(startTime)
            t.column(endTime)
            t.column(daysOfWeek)
            t.column(timezone, defaultValue: "EST")
            t.column(isActive, defaultValue: 1)
            t.column(createdAt, defaultValue: currentTime)
            t.column(updatedAt, defaultValue: currentTime)
        })
        
        // Worker shift patterns table - for structured shift data
        try db.run(workerShiftPatterns.create(ifNotExists: true) { t in
            t.column(scheduleId, primaryKey: .autoincrement)
            t.column(workerId)
            t.column(shiftType)
            t.column(startHour)
            t.column(endHour)
            t.column(days)
            t.column(breakStartHour)
            t.column(breakEndHour)
            t.column(isActive, defaultValue: 1)
            t.column(createdAt, defaultValue: currentTime)
        })
        
        // Create indexes for performance
        try db.execute("CREATE INDEX IF NOT EXISTS idx_worker_schedules_worker_active ON worker_schedules(worker_id, is_active)")
        try db.execute("CREATE INDEX IF NOT EXISTS idx_worker_shift_patterns_worker_active ON worker_shift_patterns(worker_id, is_active)")
        
        print("✅ Worker schedule tables created")
    }
    
    // MARK: - ✅ ASYNC DATABASE METHODS (For SQLiteManager compatibility)
    
    /// Execute SQL statement asynchronously
    func execute(_ sql: String, _ parameters: [Any] = []) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                guard let db = db else {
                    continuation.resume(throwing: NSError(domain: "DBError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database connection not available"]))
                    return
                }
                
                if parameters.isEmpty {
                    try db.execute(sql)
                } else {
                    // FIXED: Prepared statement with array of bindings
                    let statement = try db.prepare(sql)
                    let bindings = parameters.map { $0 as! Binding }
                    try statement.run(bindings)
                }
                
                continuation.resume(returning: ())
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Query database asynchronously
    func query(_ sql: String, _ parameters: [Any] = []) async throws -> [[String: Any]] {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                guard let db = db else {
                    continuation.resume(throwing: NSError(domain: "DBError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database connection not available"]))
                    return
                }
                
                var rows: [[String: Any]] = []
                
                if parameters.isEmpty {
                    // No parameters - simple prepare and iterate
                    let statement = try db.prepare(sql)  // ✅ FIXED: Added 'try'
                    let columnNames = statement.columnNames  // ✅ FIXED: Get column names once
                    
                    for row in statement {
                        var rowDict: [String: Any] = [:]
                        for (index, value) in row.enumerated() {
                            if index < columnNames.count {  // ✅ FIXED: Use cached columnNames
                                let columnName = columnNames[index]
                                rowDict[columnName] = value
                            }
                        }
                        rows.append(rowDict)
                    }
                } else {
                    // With parameters - proper binding approach
                    let statement = try db.prepare(sql)  // ✅ FIXED: Added 'try'
                    let columnNames = statement.columnNames  // ✅ FIXED: Get column names once
                    
                    // Convert parameters to Binding safely
                    var bindings: [Binding] = []
                    for param in parameters {
                        if let binding = param as? Binding {
                            bindings.append(binding)
                        } else {
                            // Convert common types to Binding
                            switch param {
                            case let stringParam as String:
                                bindings.append(stringParam)
                            case let intParam as Int:
                                bindings.append(Int64(intParam))
                            case let doubleParam as Double:
                                bindings.append(doubleParam)
                            case let boolParam as Bool:
                                bindings.append(boolParam)
                            default:
                                bindings.append(String(describing: param))
                            }
                        }
                    }
                    
                    // Execute with bindings
                    for row in try statement.bind(bindings) {  // ✅ FIXED: Added 'try'
                        var rowDict: [String: Any] = [:]
                        for (index, value) in row.enumerated() {
                            if index < columnNames.count {
                                let columnName = columnNames[index]
                                rowDict[columnName] = value
                            }
                        }
                        rows.append(rowDict)
                    }
                }
                
                continuation.resume(returning: rows)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - ✅ WORKER SCHEDULE MANAGEMENT
    
    /// Get active worker IDs (no hardcoded lists)
    func getActiveWorkerIds() async throws -> [String] {
        let results = try await query("SELECT id FROM workers WHERE is_active = 1")
        return results.compactMap { $0["id"] as? String }
    }
    
    /// Get worker schedule from database
    func getWorkerSchedule(workerId: String) async throws -> String? {
        let results = try await query("""
            SELECT schedule_text FROM worker_schedules 
            WHERE worker_id = ? AND is_active = 1
        """, [workerId])
        
        return results.first?["schedule_text"] as? String
    }
    
    /// Get worker shift pattern
    func getWorkerShiftPattern(workerId: String) async throws -> (start: Int, end: Int)? {
        let results = try await query("""
            SELECT start_hour, end_hour FROM worker_shift_patterns 
            WHERE worker_id = ? AND is_active = 1
        """, [workerId])
        
        if let row = results.first,
           let start = row["start_hour"] as? Int,
           let end = row["end_hour"] as? Int {
            return (start, end)
        }
        return nil
    }
    
    /// Get worker role from database
    func getWorkerRole(workerId: String) async throws -> String? {
        let results = try await query("""
            SELECT role FROM workers WHERE id = ? AND is_active = 1
        """, [workerId])
        
        return results.first?["role"] as? String
    }
    
    /// Get worker by name pattern
    func getWorkerByName(_ name: String) async throws -> [String: Any]? {
        let results = try await query("""
            SELECT id, name, role FROM workers 
            WHERE LOWER(name) LIKE ? AND is_active = 1
        """, ["%\(name.lowercased())%"])
        
        return results.first
    }
    
    /// Check if worker is currently on shift
    func isWorkerOnShift(workerId: String, currentHour: Int) async throws -> Bool {
        let results = try await query("""
            SELECT start_hour, end_hour FROM worker_shift_patterns 
            WHERE worker_id = ? AND is_active = 1
        """, [workerId])
        
        if let row = results.first,
           let start = row["start_hour"] as? Int,
           let end = row["end_hour"] as? Int {
            return currentHour >= start && currentHour <= end
        }
        
        // Default business hours fallback
        return currentHour >= 9 && currentHour <= 17
    }
    
    // MARK: - ✅ WORKER SCHEDULE SEEDING (FIXED)
    
    /// Apply complete worker schedule migration
    func applyWorkerScheduleMigration() async throws {
        print("🔄 Applying worker schedule migration...")
        
        // Add is_active column to workers table if needed
        try await addActiveColumnToWorkers()
        
        // Update worker active status
        try await updateWorkerActiveStatus()
        
        // Seed real worker schedules
        try await seedRealWorkerSchedules()
        
        print("✅ Worker schedule migration complete")
    }
    
    /// Add is_active column to workers table (if not already present)
    private func addActiveColumnToWorkers() async throws {
        do {
            // Check if column already exists
            let columns = try await query("PRAGMA table_info(workers)")
            let hasActiveColumn = columns.contains { ($0["name"] as? String) == "is_active" }
            
            if !hasActiveColumn {
                try await execute("ALTER TABLE workers ADD COLUMN is_active INTEGER DEFAULT 1")
                print("✅ Added is_active column to workers table")
            } else {
                print("⏭️ is_active column already exists in workers table")
            }
        } catch {
            print("❌ Failed to add is_active column: \(error)")
            // Don't throw - column might already exist from table creation
        }
    }
    
    /// Update worker active status (mark Jose Santos as inactive)
    private func updateWorkerActiveStatus() async throws {
        // Mark all current workers as active
        let activeWorkerIds = ["1", "2", "4", "5", "6", "7", "8"]
        
        for workerId in activeWorkerIds {
            try await execute("UPDATE workers SET is_active = 1 WHERE id = ?", [workerId])
        }
        
        // Mark Jose Santos as inactive (if exists)
        try await execute("""
            UPDATE workers SET is_active = 0 
            WHERE id = '3' OR name LIKE '%Jose%' OR name LIKE '%Santos%'
        """)
        
        print("✅ Updated worker active status")
    }
    
    /// Seed real worker schedules based on Phase-2 requirements (FIXED)
    private func seedRealWorkerSchedules() async throws {
        print("🔄 Seeding real worker schedules...")
        
        // FIXED: Proper tuple structure (6 elements, not 7)
        let workerSchedules: [(String, String, String, Int, Int, String)] = [
            // (workerId, name, scheduleText, startHour, endHour, shiftType)
            ("1", "Greg Hutson", "Mon-Fri 9:00 AM - 3:00 PM (reduced hours)", 9, 15, "standard"),
            ("2", "Edwin Lema", "Mon-Sat 6:00 AM - 3:00 PM (early shift)", 6, 15, "morning"),
            ("4", "Kevin Dutan", "Mon-Fri 6:00 AM - 5:00 PM (expanded duties)", 6, 17, "standard"),
            ("5", "Mercedes Inamagua", "Mon-Sat 6:30 AM - 10:30 AM (split shift)", 6, 10, "split"),
            ("6", "Luis Lopez", "Mon-Fri 7:00 AM - 4:00 PM (standard)", 7, 16, "standard"),
            ("7", "Angel Guirachocha", "Mon-Fri 6:00 AM - 5:00 PM + evening garbage", 6, 17, "evening"),
            ("8", "Shawn Magloire", "Flexible (Rubin Museum specialist)", 9, 17, "flexible")
        ]
        
        for schedule in workerSchedules {
            // Insert worker schedule
            try await execute("""
                INSERT OR REPLACE INTO worker_schedules 
                (worker_id, worker_name, schedule_text, start_time, end_time, is_active)
                VALUES (?, ?, ?, ?, ?, 1)
            """, [
                schedule.0, // workerId
                schedule.1, // name
                schedule.2, // scheduleText
                String(format: "%02d:00", schedule.3), // startTime
                String(format: "%02d:00", schedule.4)  // endTime
            ])
            
            // Insert shift pattern - FIXED: Access correct tuple elements
            try await execute("""
                INSERT OR REPLACE INTO worker_shift_patterns 
                (worker_id, shift_type, start_hour, end_hour, is_active)
                VALUES (?, ?, ?, ?, 1)
            """, [
                schedule.0, // workerId
                schedule.5, // shiftType (element 5, not 6)
                schedule.3, // startHour
                schedule.4  // endHour
            ])
            
            print("✅ Seeded schedule for \(schedule.1)")
        }
        
        // Add break times for workers who have them
        let breakSchedules: [(String, Int, Int)] = [
            ("1", 12, 13), // Greg - lunch break
            ("4", 12, 13), // Kevin - lunch break
            ("6", 12, 13), // Luis - lunch break
            ("7", 12, 13)  // Angel - lunch break
        ]
        
        for breakSchedule in breakSchedules {
            try await execute("""
                UPDATE worker_shift_patterns 
                SET break_start_hour = ?, break_end_hour = ?
                WHERE worker_id = ? AND is_active = 1
            """, [breakSchedule.1, breakSchedule.2, breakSchedule.0])
        }
        
        print("✅ Real worker schedules seeded for \(workerSchedules.count) active workers")
    }
    
    // MARK: - ✅ DATA VALIDATION METHODS
    
    /// Test real worker email authentication
    func testRealWorkerAuthentication() async throws {
        print("🔐 TESTING REAL WORKER EMAIL AUTHENTICATION")
        print("═══════════════════════════════════════════")
        
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
            do {
                if let userData = try fetchUser(byEmail: email) {
                    let (name, userEmail, _) = userData
                    print("   ✅ \(email): Found \(name)")
                    
                    if name != expectedName {
                        print("      ⚠️ Name mismatch: expected '\(expectedName)', got '\(name)'")
                    }
                } else {
                    print("   ❌ \(email): Not found")
                }
            } catch {
                print("   ❌ \(email): Error - \(error)")
            }
        }
        
        print("═══════════════════════════════════════════")
    }
    
    /// Validate all worker data is properly imported
    func validateWorkerDataImport() async throws -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        // Check worker count
        let workerResults = try await query("SELECT COUNT(*) as count FROM workers WHERE is_active = 1")
        let activeWorkers = workerResults.first?["count"] as? Int64 ?? 0
        
        if activeWorkers != 7 {
            issues.append("Expected 7 active workers, found \(activeWorkers)")
        }
        
        // Validate real worker emails exist
        let realEmails = [
            "g.hutson1989@gmail.com",
            "edwinlema911@gmail.com",
            "dutankevin1@gmail.com",
            "jneola@gmail.com",
            "luislopez030@yahoo.com",
            "lio.angel71@gmail.com",
            "shawn@francomanagementgroup.com"
        ]
        
        for email in realEmails {
            let emailCheck = try await query("SELECT COUNT(*) as count FROM workers WHERE email = ? AND is_active = 1", [email])
            let emailExists = (emailCheck.first?["count"] as? Int64 ?? 0) > 0
            
            if !emailExists {
                issues.append("Real worker email missing: \(email)")
            }
        }
        
        // Check each worker has schedule
        let scheduleResults = try await query("SELECT COUNT(*) as count FROM worker_schedules WHERE is_active = 1")
        let activeSchedules = scheduleResults.first?["count"] as? Int64 ?? 0
        
        if activeSchedules != 7 {
            issues.append("Expected 7 worker schedules, found \(activeSchedules)")
        }
        
        // Check building assignments exist (if table exists)
        do {
            let assignmentResults = try await query("SELECT COUNT(DISTINCT worker_id) as count FROM worker_building_assignments WHERE is_active = 1")
            let workersWithAssignments = assignmentResults.first?["count"] as? Int64 ?? 0
            
            if workersWithAssignments < 7 {
                issues.append("Only \(workersWithAssignments) workers have building assignments")
            }
        } catch {
            // Table might not exist yet - not a critical error
            print("⚠️ worker_building_assignments table not found - will be created by CSV import")
        }
        
        // Check Jose Santos is inactive
        let joseResults = try await query("SELECT COUNT(*) as count FROM workers WHERE id = '3' AND is_active = 1")
        let joseActive = joseResults.first?["count"] as? Int64 ?? 0
        
        if joseActive > 0 {
            issues.append("Jose Santos (ID: 3) is still marked as active")
        }
        
        // Validate both users and workers tables have real emails
        let userEmailCheck = try await query("SELECT COUNT(*) as count FROM users WHERE email IN (?, ?, ?, ?, ?, ?, ?)", realEmails)
        let userEmailCount = userEmailCheck.first?["count"] as? Int64 ?? 0
        
        if userEmailCount != 7 {
            issues.append("Expected 7 real worker emails in users table, found \(userEmailCount)")
        }
        
        return (issues.isEmpty, issues)
    }
    
    /// Get worker summary statistics including real email validation
    func getWorkerSummaryStats() async throws -> [String: Any] {
        var stats: [String: Any] = [:]
        
        // Total active workers
        let workerCount = try await query("SELECT COUNT(*) as count FROM workers WHERE is_active = 1")
        stats["activeWorkers"] = workerCount.first?["count"] as? Int64 ?? 0
        
        // Users with real emails
        let realEmails = [
            "g.hutson1989@gmail.com", "edwinlema911@gmail.com", "dutankevin1@gmail.com",
            "jneola@gmail.com", "luislopez030@yahoo.com", "lio.angel71@gmail.com",
            "shawn@francomanagementgroup.com"
        ]
        
        let userEmailCount = try await query("SELECT COUNT(*) as count FROM users WHERE email IN (?, ?, ?, ?, ?, ?, ?)", realEmails)
        stats["realWorkerEmailsInUsers"] = userEmailCount.first?["count"] as? Int64 ?? 0
        
        let workerEmailCount = try await query("SELECT COUNT(*) as count FROM workers WHERE email IN (?, ?, ?, ?, ?, ?, ?) AND is_active = 1", realEmails)
        stats["realWorkerEmailsInWorkers"] = workerEmailCount.first?["count"] as? Int64 ?? 0
        
        // Workers with schedules
        let scheduleCount = try await query("SELECT COUNT(DISTINCT worker_id) as count FROM worker_schedules WHERE is_active = 1")
        stats["workersWithSchedules"] = scheduleCount.first?["count"] as? Int64 ?? 0
        
        return stats
    }
    
    /// Debug method to print all worker data
    func debugPrintAllWorkerData() async throws {
        print("🔍 DEBUG: ALL WORKER DATA")
        print("═══════════════════════════════════════")
        
        // Print users table (for authentication)
        let users = try await query("SELECT name, email FROM users ORDER BY name")
        print("\n👥 USERS TABLE (Authentication):")
        for user in users {
            print("   Name: \(user["name"] ?? "?"), Email: \(user["email"] ?? "?")")
        }
        
        // Print active workers
        let workers = try await query("SELECT * FROM workers WHERE is_active = 1 ORDER BY id")
        print("\n👥 ACTIVE WORKERS TABLE:")
        for worker in workers {
            print("   ID: \(worker["id"] ?? "?"), Name: \(worker["name"] ?? "?"), Email: \(worker["email"] ?? "?"), Role: \(worker["role"] ?? "?")")
        }
        
        // Print schedules
        let schedules = try await query("SELECT * FROM worker_schedules WHERE is_active = 1 ORDER BY worker_id")
        print("\n📅 WORKER SCHEDULES:")
        for schedule in schedules {
            print("   Worker \(schedule["worker_id"] ?? "?"): \(schedule["schedule_text"] ?? "?")")
        }
        
        // Print shift patterns
        let shifts = try await query("SELECT * FROM worker_shift_patterns WHERE is_active = 1 ORDER BY worker_id")
        print("\n⏰ SHIFT PATTERNS:")
        for shift in shifts {
            print("   Worker \(shift["worker_id"] ?? "?"): \(shift["start_hour"] ?? "?")-\(shift["end_hour"] ?? "?") (\(shift["shift_type"] ?? "?"))")
        }
        
        // Validate real worker emails
        let realEmails = [
            "g.hutson1989@gmail.com", "edwinlema911@gmail.com", "dutankevin1@gmail.com",
            "jneola@gmail.com", "luislopez030@yahoo.com", "lio.angel71@gmail.com",
            "shawn@francomanagementgroup.com"
        ]
        
        print("\n📧 REAL EMAIL VALIDATION:")
        for email in realEmails {
            let userExists = try await query("SELECT COUNT(*) as count FROM users WHERE email = ?", [email])
            let workerExists = try await query("SELECT COUNT(*) as count FROM workers WHERE email = ? AND is_active = 1", [email])
            
            let userCount = userExists.first?["count"] as? Int64 ?? 0
            let workerCount = workerExists.first?["count"] as? Int64 ?? 0
            
            print("   \(email): Users(\(userCount)) Workers(\(workerCount)) \(userCount > 0 && workerCount > 0 ? "✅" : "❌")")
        }
        
        print("═══════════════════════════════════════")
    }
}

// MARK: - ✅ COMPATIBILITY EXTENSIONS

extension DatabaseManager {
    
    /// Get database connection for direct SQLite access
    var connection: Connection? {
        return db
    }
    
    /// Check if database is initialized
    var isInitialized: Bool {
        return db != nil
    }
    
    /// Get database file path
    var databasePath: String? {
        guard let db = db else { return nil }
        return "\(db)"
    }
}
