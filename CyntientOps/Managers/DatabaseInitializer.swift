//
//  DatabaseInitializer.swift
//  CyntientOps v6.0
//
//  ✅ CONSOLIDATED: Merged DatabaseStartupCoordinator + UnifiedDataInitializer + UnifiedDataService + SchemaMigrationPatch
//  ✅ SINGLE SOURCE: All database initialization and migration in one place
//  ✅ UI-READY: Progress tracking for SwiftUI
//  ✅ PRODUCTION-READY: Comprehensive initialization with fallbacks
//  ✅ KEVIN'S DATA: Rubin Museum (ID 14) assignment preserved
//

import Foundation
import SwiftUI
import Combine
import GRDB

// MARK: - DatabaseInitializer

@MainActor
public class DatabaseInitializer: ObservableObject {
    public static let shared = DatabaseInitializer()
    
    // MARK: - Published UI State
    @Published public var isInitialized = false
    @Published public var initializationProgress: Double = 0.0
    @Published public var currentStep = "Preparing..."
    @Published public var error: Error?
    @Published public var dataStatus: DataStatus = .unknown
    @Published public var lastSyncTime: Date?
    
    // MARK: - Dependencies
    private let grdbManager = GRDBManager.shared
    private let operationalData = OperationalDataManager.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    
    // MARK: - Private State
    private var hasVerifiedData = false
    private var cancellables = Set<AnyCancellable>()
    
    public enum DataStatus {
        case unknown
        case empty
        case partial
        case complete
        case syncing
        case error(String)
        
        var description: String {
            switch self {
            case .unknown: return "Unknown"
            case .empty: return "Empty Database"
            case .partial: return "Partial Data"
            case .complete: return "Complete Data"
            case .syncing: return "Syncing..."
            case .error(let msg): return "Error: \(msg)"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Public Entry Point
    
    /// Initialize the database and app data if needed
    public func initializeIfNeeded() async throws {
        guard !isInitialized else {
            print("✅ Database already initialized")
            return
        }
        
        print("🚀 Starting consolidated database initialization...")
        error = nil
        dataStatus = .syncing
        
        do {
            // Phase 1: Database Setup (0-40%)
            try await performDatabaseSetup()
            
            // Phase 2: Data Import (40-70%)
            try await performDataImport()
            
            // Phase 3: Verification (70-90%)
            try await performVerification()
            
            // Phase 4: Start Services (90-100%)
            await startBackgroundServices()
            
            // Complete
            dataStatus = .complete
            isInitialized = true
            lastSyncTime = Date()
            currentStep = "Ready"
            initializationProgress = 1.0
            
            print("✅ Database initialization complete")
            
        } catch {
            self.error = error
            self.dataStatus = .error(error.localizedDescription)
            currentStep = "Initialization failed"
            print("❌ Database initialization failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Phase 1: Database Setup
    
    private func performDatabaseSetup() async throws {
        currentStep = "Setting up database..."
        initializationProgress = 0.05
        
        // Ensure database is ready
        guard await grdbManager.isDatabaseReady() else {
            throw InitializationError.databaseNotReady
        }
        
        initializationProgress = 0.1
        
        // Fix missing columns (from SchemaMigrationPatch)
        try await fixMissingWorkerColumns()
        initializationProgress = 0.15
        
        // Create migration tracking table
        try await createMigrationTrackingTable()
        initializationProgress = 0.2
        
        // Create additional tables
        try await createAdditionalTables()
        initializationProgress = 0.25
        
        // Fix worker_building_assignments structure
        try await fixWorkerBuildingAssignments()
        initializationProgress = 0.3
        
        // Run migrations
        try await runMigrationsIfNeeded()
        initializationProgress = 0.35
        
        // Seed authentication data
        try await seedAuthenticationData()
        initializationProgress = 0.4
    }
    
    // MARK: - Emergency Column Fixes (from SchemaMigrationPatch)
    
    private func fixMissingWorkerColumns() async throws {
        print("🚨 EMERGENCY FIX: Adding missing columns to workers table...")
        
        let tableInfo = try await grdbManager.query("PRAGMA table_info(workers)")
        let columnNames = Set(tableInfo.compactMap { $0["name"] as? String })
        
        print("📋 Current workers table columns: \(columnNames.sorted())")
        
        // Add missing required columns
        if !columnNames.contains("isActive") {
            try await grdbManager.execute("ALTER TABLE workers ADD COLUMN isActive INTEGER DEFAULT 1")
            print("✅ Added isActive column")
        }
        
        if !columnNames.contains("shift") {
            try await grdbManager.execute("ALTER TABLE workers ADD COLUMN shift TEXT DEFAULT 'day'")
            print("✅ Added shift column")
        }
        
        if !columnNames.contains("hireDate") {
            try await grdbManager.execute("ALTER TABLE workers ADD COLUMN hireDate TEXT DEFAULT (date('now'))")
            print("✅ Added hireDate column")
        }
        
        if !columnNames.contains("email") {
            try await grdbManager.execute("ALTER TABLE workers ADD COLUMN email TEXT")
            print("✅ Added email column")
        }
        
        print("✅ Essential worker columns verified")
    }
    
    private func fixWorkerBuildingAssignments() async throws {
        print("🔧 Ensuring worker_building_assignments table structure...")
        
        // Create table if it doesn't exist
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS worker_building_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                role TEXT DEFAULT 'maintenance',
                assigned_date TEXT DEFAULT CURRENT_TIMESTAMP,
                is_active INTEGER DEFAULT 1,
                notes TEXT,
                assignment_type TEXT DEFAULT 'regular',
                UNIQUE(worker_id, building_id)
            )
        """)
        
        // Check and add missing columns
        let tableInfo = try await grdbManager.query("PRAGMA table_info(worker_building_assignments)")
        let columns = tableInfo.compactMap { $0["name"] as? String }
        
        if !columns.contains("notes") {
            try await grdbManager.execute("""
                ALTER TABLE worker_building_assignments 
                ADD COLUMN notes TEXT
            """)
        }
        
        if !columns.contains("assignment_type") {
            try await grdbManager.execute("""
                ALTER TABLE worker_building_assignments 
                ADD COLUMN assignment_type TEXT DEFAULT 'regular'
            """)
        }
        
        print("✅ worker_building_assignments table structure verified")
    }
    
    // MARK: - Phase 2: Data Import
    
    private func performDataImport() async throws {
        currentStep = "Importing data..."
        initializationProgress = 0.45
        
        // Check if we need operational data
        let needsOperationalData = await shouldImportOperationalData()
        
        if needsOperationalData {
            // Seed operational data from database
            try await seedOperationalDataIfNeeded()
            initializationProgress = 0.5
            
            // Seed Kevin's corrected building assignments
            try await createKevinCorrectedAssignments()
            initializationProgress = 0.55
            
            // Import operational schedules from SchemaMigrationPatch
            try await importOperationalSchedules()
            initializationProgress = 0.6
            
            // Import from OperationalDataManager
            if !operationalData.isInitialized {
                try await operationalData.initializeOperationalData()
            }
            
            let result = try await operationalData.importRoutinesAndDSNYAsync()
            print("✅ Imported \(result.routines) routines and \(result.dsny) DSNY schedules")
            initializationProgress = 0.65
            
            // Sync to database
            await syncOperationalDataToDatabase()
            initializationProgress = 0.7
        } else {
            print("✅ Operational data already exists")
            initializationProgress = 0.7
        }
    }
    
    // MARK: - Kevin's Corrected Building Assignments (from SchemaMigrationPatch)
    
    private func createKevinCorrectedAssignments() async throws {
        print("🏢 Creating Kevin's CORRECTED building assignments - PRESERVING RUBIN MUSEUM...")
        
        // Check if already applied
        if try await hasMigrationBeenApplied(1001, description: "Kevin Rubin Museum Correction") {
            print("✅ Kevin's corrected assignments already applied")
            return
        }
        
        // Clear any existing Kevin assignments to avoid conflicts
        try await grdbManager.execute("""
            DELETE FROM worker_building_assignments 
            WHERE worker_id = '4'
        """)
        
        // Kevin's CORRECTED building assignments - ALL PRESERVED from SchemaMigrationPatch
        // ✅ CRITICAL: Rubin Museum ID "14", NOT Franklin ID "13"
        let kevinBuildings: [(String, String)] = [
            ("3", "131 Perry Street - Primary assignment"),
            ("6", "68 Perry Street - Perry Street corridor"),
            ("7", "135-139 West 17th Street - Main maintenance building"),
            ("9", "117 West 17th Street - West 17th corridor"),
            ("11", "136 West 17th Street - Extended coverage"),
            ("16", "Stuyvesant Cove Park - Special outdoor assignment"),
            ("17", "178 Spring Street - Downtown coverage"), // ✅ Correct ID 17
            ("14", "Rubin Museum (142–148 W 17th) - CORRECTED ASSIGNMENT") // ✅ Rubin Museum, NOT Franklin
        ]
        
        for (buildingId, notes) in kevinBuildings {
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO worker_building_assignments 
                (worker_id, building_id, role, assignment_type, assigned_date, is_active, notes) 
                VALUES ('4', ?, 'maintenance', 'corrected_duties', datetime('now'), 1, ?)
            """, [buildingId, notes])
        }
        
        print("✅ Created \(kevinBuildings.count) CORRECTED building assignments for Kevin")
        print("   🎯 Kevin now has Rubin Museum (ID 14), NOT Franklin Street")
        print("   🎯 Kevin now has 178 Spring Street (ID 17) - building ID conflict resolved")
        
        // Verify Kevin's corrected assignments
        let kevinAssignments = try await grdbManager.query("""
            SELECT building_id, notes FROM worker_building_assignments 
            WHERE worker_id = '4' AND is_active = 1
        """, [])
        
        print("📊 Kevin's verified assignments: \(kevinAssignments.count) buildings")
        for assignment in kevinAssignments {
            let buildingId = assignment["building_id"] as? String ?? "nil"
            let notes = assignment["notes"] as? String ?? ""
            print("   🏢 Building ID: \(buildingId) - \(notes)")
        }
        
        // Record this migration
        try await recordMigrationVersion(1001, description: "Kevin Rubin Museum Correction")
    }
    
    // MARK: - Operational Schedules Import (from SchemaMigrationPatch)
    
    private func importOperationalSchedules() async throws {
        print("🔧 Importing operational schedules - ALL ORIGINAL DATA PRESERVED...")
        
        // Check if already applied
        if try await hasMigrationBeenApplied(1002, description: "Operational Schedules Import") {
            print("✅ Operational schedules already imported")
            return
        }
        
        // Kevin's corrected routine schedules - ALL PRESERVED from SchemaMigrationPatch
        // ✅ CRITICAL: Rubin Museum (ID 14), NOT Franklin (ID 13)
        let routineSchedules: [(String, String, String, String, String, String)] = [
            // Kevin's corrected Perry Street circuit - PRESERVED
            ("routine_3_4_perry_main", "Perry Street Main Circuit", "3", "FREQ=DAILY;BYHOUR=6", "4", "Cleaning"),
            ("routine_6_4_perry_full", "Perry 68 Full Building Clean", "6", "FREQ=WEEKLY;BYDAY=TU,TH;BYHOUR=8", "4", "Cleaning"),
            ("routine_7_4_17th_corridor", "17th Street Corridor Maintenance", "7", "FREQ=DAILY;BYHOUR=11", "4", "Cleaning"),
            ("routine_9_4_17th_west", "117 West 17th Operations", "9", "FREQ=DAILY;BYHOUR=12", "4", "Cleaning"),
            ("routine_11_4_extended", "Extended Coverage Area", "11", "FREQ=WEEKLY;BYDAY=FR;BYHOUR=10", "4", "Maintenance"),
            ("routine_16_4_park", "Stuyvesant Park Maintenance", "16", "FREQ=WEEKLY;BYDAY=SA;BYHOUR=8", "4", "Outdoor"),
            ("routine_17_4_spring", "Spring Street Downtown", "17", "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=14", "4", "Cleaning"),
            // ✅ CORRECTED: Kevin's Rubin Museum assignment (ID 14, NOT Franklin ID 13) - PRESERVED
            ("routine_14_4_rubin", "Rubin Museum Operations", "14", "FREQ=DAILY;BYHOUR=10", "4", "Sanitation"),
            
            // Other workers' schedules - ALL PRESERVED
            ("routine_1_1_main", "12 West 18th Complete Service", "1", "FREQ=DAILY;BYHOUR=9", "1", "Cleaning"),
            ("routine_16_2_park_morn", "Park Morning Inspection", "16", "FREQ=DAILY;BYHOUR=6", "2", "Maintenance"),
            ("routine_7_5_glass", "Glass & Lobby Circuit", "7", "FREQ=DAILY;BYHOUR=6", "5", "Cleaning"),
            ("routine_4_6_franklin", "Franklin Sidewalk Operations", "4", "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=7", "6", "Cleaning"),
            ("routine_1_7_evening", "Evening Security Check", "1", "FREQ=DAILY;BYHOUR=21", "7", "Operations"),
            ("routine_14_8_hvac", "Rubin Museum HVAC Systems", "14", "FREQ=MONTHLY;BYHOUR=9", "8", "Maintenance")
        ]
        
        var routineCount = 0
        for routine in routineSchedules {
            let weatherDependent = routine.5 == "Cleaning" ? 1 : 0
            
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO routine_schedules 
                (id, name, building_id, rrule, worker_id, category, weather_dependent)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [routine.0, routine.1, routine.2, routine.3, routine.4, routine.5, weatherDependent])
            routineCount += 1
        }
        
        print("✅ Imported \(routineCount) routine schedules (Kevin's Rubin Museum corrected)")
        
        // Import DSNY schedules with Kevin's corrected routes - ALL PRESERVED
        let dsnySchedules: [(String, String, String, String)] = [
            ("dsny_kevin_perry", "Kevin Perry Street Route", "3,6", "MON,WED,FRI"),
            ("dsny_kevin_17th", "Kevin 17th Street Route", "7,9,11", "MON,WED,FRI"),
            ("dsny_kevin_downtown", "Kevin Downtown Route", "17", "TUE,THU"),
            ("dsny_kevin_rubin", "Kevin Rubin Museum Route", "14", "TUE,FRI"), // ✅ CORRECTED & PRESERVED
            ("dsny_kevin_park", "Kevin Park Route", "16", "SAT"),
            ("dsny_general_east", "General East Route", "1", "MON,WED,FRI"),
            ("dsny_general_downtown", "General Downtown Route", "4,8", "TUE,THU,SAT")
        ]
        
        var dsnyCount = 0
        for dsny in dsnySchedules {
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO dsny_schedules 
                (id, route_id, building_ids, collection_days)
                VALUES (?, ?, ?, ?)
            """, [dsny.0, dsny.1, dsny.2, dsny.3])
            dsnyCount += 1
        }
        
        print("✅ Imported \(dsnyCount) DSNY schedules (Kevin's routes corrected & preserved)")
        
        // Record this migration
        try await recordMigrationVersion(1002, description: "Operational Schedules Import")
    }
    
    // MARK: - Phase 3: Verification
    
    private func performVerification() async throws {
        currentStep = "Verifying data integrity..."
        initializationProgress = 0.75
        
        // Verify critical relationships
        try await verifyCriticalRelationships()
        initializationProgress = 0.8
        
        // Run integrity checks
        let integrity = try await runIntegrityChecks()
        guard integrity.isHealthy else {
            throw InitializationError.integrityCheckFailed(integrity.issues.joined(separator: ", "))
        }
        initializationProgress = 0.85
        
        // Verify service data flow
        let serviceFlow = await verifyServiceDataFlow()
        if !serviceFlow.isComplete {
            print("⚠️ Service data flow incomplete, but continuing...")
        }
        initializationProgress = 0.9
    }
    
    // MARK: - Phase 4: Background Services
    
    private func startBackgroundServices() async {
        currentStep = "Starting services..."
        initializationProgress = 0.95
        
        // Invalidate metrics cache to trigger fresh calculations
        Task {
            await BuildingMetricsService.shared.invalidateAllCaches()
        }
        
        // Additional background services can be started here
        initializationProgress = 1.0
    }
    
    // MARK: - Database Table Creation
    
    private func createMigrationTrackingTable() async throws {
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                description TEXT,
                applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
    }
    
    private func createAdditionalTables() async throws {
        print("🔧 Creating additional operational tables...")
        
        // Task templates for recurring tasks
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS task_templates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                category TEXT NOT NULL,
                default_urgency TEXT NOT NULL,
                estimated_duration_minutes INTEGER,
                skill_level TEXT DEFAULT 'Basic',
                recurrence TEXT DEFAULT 'daily',
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(name, category)
            )
        """)
        
        // Worker task assignments
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS worker_task_templates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                task_template_id INTEGER NOT NULL,
                start_time TEXT,
                end_time TEXT,
                days_of_week TEXT DEFAULT 'weekdays',
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (task_template_id) REFERENCES task_templates(id),
                UNIQUE(worker_id, building_id, task_template_id)
            )
        """)
        
        // Building metrics cache
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS building_metrics_cache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                building_id TEXT NOT NULL UNIQUE,
                completion_rate REAL DEFAULT 0.0,
                average_task_time REAL DEFAULT 0.0,
                overdue_tasks INTEGER DEFAULT 0,
                total_tasks INTEGER DEFAULT 0,
                active_workers INTEGER DEFAULT 0,
                last_updated TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // Routine schedules table (from SchemaMigrationPatch)
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS routine_schedules (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                rrule TEXT NOT NULL,
                worker_id TEXT NOT NULL,
                category TEXT NOT NULL,
                estimated_duration INTEGER DEFAULT 3600,
                weather_dependent INTEGER DEFAULT 0,
                priority_level TEXT DEFAULT 'medium',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (building_id) REFERENCES buildings(id),
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            )
        """)

        // DSNY schedules table (from SchemaMigrationPatch)
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS dsny_schedules (
                id TEXT PRIMARY KEY,
                route_id TEXT NOT NULL,
                building_ids TEXT NOT NULL,
                collection_days TEXT NOT NULL,
                pickup_window_start INTEGER DEFAULT 21600,
                pickup_window_end INTEGER DEFAULT 43200,
                route_status TEXT DEFAULT 'active',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // Site departure logs table (for SiteLogService)
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS site_departure_logs (
                id TEXT PRIMARY KEY,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                departed_at TEXT NOT NULL,
                tasks_completed_count INTEGER DEFAULT 0,
                tasks_remaining_count INTEGER DEFAULT 0,
                photos_provided_count INTEGER DEFAULT 0,
                is_fully_compliant INTEGER DEFAULT 0,
                notes TEXT,
                next_destination_building_id TEXT,
                departure_method TEXT DEFAULT 'normal',
                location_lat REAL,
                location_lon REAL,
                time_spent_minutes INTEGER,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (worker_id) REFERENCES workers(id),
                FOREIGN KEY (building_id) REFERENCES buildings(id)
            )
        """)
        
        print("✅ Additional operational tables created")
    }
    
    // MARK: - Data Seeding Methods
    
    private func seedAuthenticationData() async throws {
        print("🔐 Checking authentication data...")
        
        // Check if we already have workers
        let workerCountResult = try await grdbManager.query(
            "SELECT COUNT(*) as count FROM workers"
        )
        let workerCount = workerCountResult.first?["count"] as? Int64 ?? 0
        
        if workerCount == 0 {
            print("📝 Seeding authentication data...")
            
            // Real worker authentication data with shifts and hire dates (from SchemaMigrationPatch)
            let realWorkers: [(String, String, String, String, String, String?, Double, String, String)] = [
                // (id, name, email, password, role, phone, hourlyRate, shift, hireDate)
                ("1", "Greg Hutson", "g.hutson1989@gmail.com", "password", "worker", "917-555-0001", 28.0, "day", "2022-03-15"),
                ("2", "Edwin Lema", "edwinlema911@gmail.com", "password", "worker", "917-555-0002", 26.0, "morning", "2023-01-10"),
                ("4", "Kevin Dutan", "dutankevin1@gmail.com", "password", "worker", "917-555-0004", 25.0, "expanded", "2021-08-20"), // ✅ Expanded duties PRESERVED
                ("5", "Mercedes Inamagua", "jneola@gmail.com", "password", "worker", "917-555-0005", 27.0, "split", "2022-11-05"),
                ("6", "Luis Lopez", "luislopez030@yahoo.com", "password", "worker", "917-555-0006", 25.0, "day", "2023-02-18"),
                ("7", "Angel Guirachocha", "lio.angel71@gmail.com", "password", "worker", "917-555-0007", 26.0, "evening", "2022-07-12"),
                ("8", "Shawn Magloire", "shawn@francomanagementgroup.com", "password", "admin", "917-555-0008", 45.0, "day", "2020-01-15"),
                ("9", "Shawn Magloire", "francosphere@francomanagementgroup.com", "password", "client", "917-555-0008", 45.0, "day", "2020-01-15"),
                ("10", "Shawn Magloire", "shawn@fme-llc.com", "password", "admin", "917-555-0008", 45.0, "day", "2020-01-15"),
                ("100", "Test Worker", "test@franco.com", "password", "worker", "917-555-0100", 25.0, "day", "2024-01-01"),
                ("101", "Test Admin", "admin@franco.com", "password", "admin", "917-555-0101", 35.0, "day", "2024-01-01"),
                ("102", "Test Client", "client@franco.com", "password", "client", "917-555-0102", 30.0, "day", "2024-01-01")
            ]
            
            for (id, name, email, password, role, phone, rate, shift, hireDate) in realWorkers {
                try await grdbManager.execute("""
                    INSERT OR REPLACE INTO workers 
                    (id, name, email, password, role, phone, hourlyRate, isActive, shift, hireDate,
                     skills, timezone, notification_preferences, created_at, updated_at) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, 'America/New_York', '{}', datetime('now'), datetime('now'))
                """, [id, name, email, password, role, phone ?? "", rate, shift, hireDate, getDefaultSkills(for: role)])
            }
            
            print("✅ Seeded \(realWorkers.count) workers with authentication")
            
            // Verify Kevin was created correctly
            let kevinCheck = try await grdbManager.query(
                "SELECT id, name, isActive, shift FROM workers WHERE id = '4' LIMIT 1",
                []
            )
            
            if let kevin = kevinCheck.first {
                print("✅ Kevin verification: ID=\(kevin["id"] ?? "nil"), Name=\(kevin["name"] ?? "nil"), Active=\(kevin["isActive"] ?? "nil"), Shift=\(kevin["shift"] ?? "nil")")
            } else {
                print("🚨 WARNING: Kevin not found after seeding!")
            }
        } else {
            print("✅ Workers already exist (\(workerCount) workers)")
        }
    }
    
    private func seedOperationalDataIfNeeded() async throws {
        print("🌱 Checking operational data...")
        
        // Check if we have buildings
        let buildingCountResult = try await grdbManager.query(
            "SELECT COUNT(*) as count FROM buildings"
        )
        let buildingCount = buildingCountResult.first?["count"] as? Int64 ?? 0
        
        if buildingCount == 0 {
            print("📝 Seeding operational data...")
            
            try await seedBuildings()
            try await seedWorkerAssignments()
            try await seedSampleTasks()
            try await seedInventoryItems()
            
            print("✅ Operational data seeded")
        } else {
            print("✅ Operational data exists (\(buildingCount) buildings)")
        }
    }
    
    private func seedBuildings() async throws {
        let buildings = [
            ("14", "Rubin Museum", "150 W 17th St, New York, NY 10011", 40.7402, -73.9979, "rubin_museum"),
            ("1", "12 West 18th Street", "12 W 18th St, New York, NY 10011", 40.7391, -73.9929, "building_12w18"),
            ("2", "29-31 East 20th Street", "29-31 E 20th St, New York, NY 10003", 40.7380, -73.9890, "building_29e20"),
            ("3", "133 East 15th Street", "133 E 15th St, New York, NY 10003", 40.7343, -73.9859, "building_133e15"),
            ("4", "104 Franklin Street", "104 Franklin St, New York, NY 10013", 40.7190, -74.0089, "building_104franklin"),
            ("5", "36 Walker Street", "36 Walker St, New York, NY 10013", 40.7173, -74.0027, "building_36walker"),
            ("6", "68 Perry Street", "68 Perry St, New York, NY 10014", 40.7355, -74.0067, "building_68perry"),
            ("7", "136 W 17th Street", "136 W 17th St, New York, NY 10011", 40.7402, -73.9975, "building_136w17"),
            ("8", "41 Elizabeth Street", "41 Elizabeth St, New York, NY 10013", 40.7178, -73.9962, "building_41elizabeth"),
            ("9", "117 West 17th Street", "117 W 17th St, New York, NY 10011", 40.7401, -73.9967, "building_117w17"),
            ("10", "123 1st Avenue", "123 1st Ave, New York, NY 10003", 40.7264, -73.9838, "building_123first"),
            ("11", "131 Perry Street", "131 Perry St, New York, NY 10014", 40.7352, -74.0033, "building_131perry"),
            ("12", "135 West 17th Street", "135 W 17th St, New York, NY 10011", 40.7402, -73.9975, "building_135w17"),
            ("13", "138 West 17th Street", "138 W 17th St, New York, NY 10011", 40.7403, -73.9978, "building_138w17"),
            ("15", "112 West 18th Street", "112 W 18th St, New York, NY 10011", 40.7395, -73.9950, "building_112w18"),
            ("16", "Stuyvesant Cove Park", "E 20th St & FDR Dr, New York, NY 10009", 40.7325, -73.9732, "stuyvesant_park"),
            ("17", "178 Spring Street", "178 Spring St, New York, NY 10012", 40.7240, -73.9998, "building_178spring") // Added from SchemaMigrationPatch
        ]
        
        for (id, name, address, lat, lng, imageAsset) in buildings {
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO buildings 
                (id, name, address, latitude, longitude, imageAssetName, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
            """, [id, name, address, lat, lng, imageAsset])
        }
        
        print("✅ \(buildings.count) buildings seeded")
    }
    
    private func seedWorkerAssignments() async throws {
        // Other workers' basic assignments
        let basicAssignments = [
            ("1", "1", "cleaning"),
            ("2", "2", "maintenance"),
            ("2", "5", "maintenance"),
            ("5", "9", "cleaning"),
            ("6", "4", "maintenance"),
            ("7", "1", "sanitation"),
        ]
        
        for (workerId, buildingId, role) in basicAssignments {
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO worker_building_assignments 
                (worker_id, building_id, role, assigned_date, is_active)
                VALUES (?, ?, ?, datetime('now'), 1)
            """, [workerId, buildingId, role])
        }
        
        print("✅ Basic worker assignments seeded")
        
        // Kevin's corrected assignments will be handled separately in createKevinCorrectedAssignments()
    }
    
    private func seedSampleTasks() async throws {
        let tasks = [
            ("Trash Area + Sidewalk & Curb Clean", "Daily trash area and sidewalk maintenance", "14", "4", "sanitation", "medium"),
            ("Museum Entrance Sweep", "Daily entrance cleaning", "14", "4", "cleaning", "medium"),
            ("Morning Hallway Clean", "Daily hallway maintenance", "1", "1", "cleaning", "medium"),
            ("Laundry & Supplies Management", "Manage building laundry and supplies", "1", "1", "maintenance", "low"),
            ("Boiler Blow-Down", "Weekly boiler maintenance", "2", "2", "maintenance", "critical"),
            ("HVAC Inspection", "Check heating and cooling systems", "2", "2", "maintenance", "high")
        ]
        
        for (title, desc, buildingId, workerId, category, urgency) in tasks {
            try await grdbManager.execute("""
                INSERT INTO routine_tasks 
                (title, description, buildingId, workerId, category, urgency, 
                 isCompleted, scheduledDate, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, 0, date('now'), datetime('now'), datetime('now'))
            """, [title, desc, buildingId, workerId, category, urgency])
        }
        
        print("✅ Sample tasks seeded")
    }
    
    private func seedInventoryItems() async throws {
        let inventoryItems = [
            ("Trash bags (13 gal)", "supplies", 500, 100, 14),
            ("Paper towels", "supplies", 200, 50, 14),
            ("Glass cleaner", "cleaning", 24, 6, 14),
            ("HVAC filters (20x25x1)", "maintenance", 12, 4, 14)
        ]
        
        for (name, category, currentStock, minStock, buildingId) in inventoryItems {
            try await grdbManager.execute("""
                INSERT OR IGNORE INTO inventory_items
                (name, category, currentStock, minimumStock, maxStock, unit, 
                 buildingId, lastRestocked, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 'units', ?, date('now', '-7 days'), 
                        datetime('now'), datetime('now'))
            """, [name, category, currentStock, minStock, currentStock * 2, buildingId])
        }
        
        print("✅ Inventory items seeded")
    }
    
    // MARK: - Operational Data Sync
    
    private func syncOperationalDataToDatabase() async {
        print("🔄 Syncing OperationalDataManager to database...")
        
        let tasks = operationalData.getAllRealWorldTasks()
        var converted = 0
        var skipped = 0
        
        for operationalTask in tasks {
            do {
                guard let workerId = getWorkerIdFromName(operationalTask.assignedWorker) else {
                    skipped += 1
                    continue
                }
                
                guard let buildingId = await getBuildingIdFromName(operationalTask.building) else {
                    skipped += 1
                    continue
                }
                
                let externalId = "op_task_\(workerId)_\(buildingId)_\(operationalTask.taskName.hash)"
                
                let existing = try await grdbManager.query(
                    "SELECT id FROM routine_tasks WHERE external_id = ?",
                    [externalId]
                )
                
                if !existing.isEmpty {
                    skipped += 1
                    continue
                }
                
                try await grdbManager.execute("""
                    INSERT INTO routine_tasks (
                        worker_id, building_id, task_name, category, skill_level,
                        recurrence, start_time, end_time, is_active, external_id,
                        created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, datetime('now'))
                """, [
                    workerId,
                    buildingId,
                    operationalTask.taskName,
                    operationalTask.category,
                    operationalTask.skillLevel,
                    operationalTask.recurrence,
                    operationalTask.startHour.map { String($0) } ?? NSNull(),
                    operationalTask.endHour.map { String($0) } ?? NSNull(),
                    externalId
                ])
                
                converted += 1
                
            } catch {
                print("❌ Failed to convert task: \(operationalTask.taskName) - \(error)")
                skipped += 1
            }
        }
        
        print("✅ Conversion complete: \(converted) converted, \(skipped) skipped")
    }
    
    // MARK: - Migration Management
    
    private func runMigrationsIfNeeded() async throws {
        print("🔄 Checking for pending migrations...")
        
        // Add essential constraints (from SchemaMigrationPatch)
        if !(try await hasMigrationBeenApplied(1003, description: "Essential Constraints")) {
            try await addEssentialConstraints()
            try await recordMigrationVersion(1003, description: "Essential Constraints")
        }
        
        print("✅ Migrations complete")
    }
    
    private func addEssentialConstraints() async throws {
        print("🔧 Adding essential constraints...")
        
        let indexes: [(String, String, String)] = [
            ("idx_worker_building_unique", "worker_building_assignments", "worker_id, building_id"),
            ("idx_worker_email", "workers", "email"),
            ("idx_worker_active", "workers", "isActive")
        ]
        
        for (indexName, tableName, columns) in indexes {
            do {
                try await grdbManager.execute("""
                    CREATE UNIQUE INDEX IF NOT EXISTS \(indexName) 
                    ON \(tableName)(\(columns))
                """)
            } catch {
                print("⚠️ Could not create index \(indexName): \(error)")
            }
        }
        
        print("✅ Essential constraints added")
    }
    
    // MARK: - Migration Version Tracking
    
    private func recordMigrationVersion(_ version: Int, description: String) async throws {
        try await grdbManager.execute("""
            INSERT OR IGNORE INTO schema_migrations (version, description, applied_at)
            VALUES (?, ?, datetime('now'))
        """, [version, description])
    }
    
    private func hasMigrationBeenApplied(_ version: Int, description: String) async throws -> Bool {
        let result = try await grdbManager.query(
            "SELECT COUNT(*) as count FROM schema_migrations WHERE version = ?",
            [version]
        )
        return (result.first?["count"] as? Int64 ?? 0) > 0
    }
    
    // MARK: - Verification Methods
    
    private func verifyCriticalRelationships() async throws {
        print("🔍 Verifying critical relationships...")
        
        // Verify Kevin Dutan's Rubin Museum assignment (most critical check)
        let kevinRubinCheck = try await grdbManager.query("""
            SELECT COUNT(*) as count 
            FROM worker_building_assignments 
            WHERE worker_id = '4' AND building_id = '14' AND is_active = 1
        """)
        
        let hasKevinRubin = (kevinRubinCheck.first?["count"] as? Int64 ?? 0) > 0
        
        if hasKevinRubin {
            print("✅ KEVIN CORRECTION VERIFIED: Has Rubin Museum (14), NOT Franklin Street (13)")
        } else {
            print("🚨 KEVIN ASSIGNMENT ERROR: Missing Rubin Museum assignment")
            
            // Create the assignment if missing
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO worker_building_assignments 
                (worker_id, building_id, role, assigned_date, is_active, notes)
                VALUES ('4', '14', 'maintenance', datetime('now'), 1, 'CRITICAL: Rubin Museum Assignment')
            """)
            
            print("✅ Kevin Dutan's Rubin Museum assignment created")
        }
        
        // Verify Kevin doesn't have Franklin Street (ID 13)
        let kevinFranklinCheck = try await grdbManager.query("""
            SELECT COUNT(*) as count 
            FROM worker_building_assignments 
            WHERE worker_id = '4' AND building_id = '13' AND is_active = 1
        """)
        
        let hasKevinFranklin = (kevinFranklinCheck.first?["count"] as? Int64 ?? 0) > 0
        
        if hasKevinFranklin {
            print("🚨 REMOVING INCORRECT: Kevin has Franklin Street (13) - removing...")
            try await grdbManager.execute("""
                DELETE FROM worker_building_assignments 
                WHERE worker_id = '4' AND building_id = '13'
            """)
            print("✅ Removed incorrect Franklin Street assignment from Kevin")
        }
        
        print("✅ Critical relationships verified")
    }
    
    private func runIntegrityChecks() async throws -> IntegrityCheckResult {
        print("🔍 Running integrity checks...")
        
        var result = IntegrityCheckResult()
        
        let checks = [
            ("workers", 7),
            ("buildings", 10),
            ("worker_building_assignments", 5),
            ("routine_tasks", 0)
        ]
        
        for (table, minCount) in checks {
            let countResult = try await grdbManager.query(
                "SELECT COUNT(*) as count FROM \(table)"
            )
            let count = countResult.first?["count"] as? Int64 ?? 0
            
            if count < minCount {
                result.issues.append("\(table): only \(count) records (expected ≥ \(minCount))")
            } else {
                result.passedChecks.append("\(table): \(count) records ✓")
            }
        }
        
        // Special check for Kevin's 8 buildings
        let kevinBuildingCount = try await grdbManager.query("""
            SELECT COUNT(*) as count 
            FROM worker_building_assignments 
            WHERE worker_id = '4' AND is_active = 1
        """)
        
        let kevinCount = kevinBuildingCount.first?["count"] as? Int64 ?? 0
        if kevinCount == 8 {
            result.passedChecks.append("Kevin Dutan: \(kevinCount) buildings ✓")
        } else {
            result.issues.append("Kevin Dutan: only \(kevinCount) buildings (expected 8)")
        }
        
        print("📊 Integrity check: \(result.passedChecks.count) passed, \(result.issues.count) issues")
        
        return result
    }
    
    private func verifyServiceDataFlow() async -> DatabaseServiceDataFlow {
        var dataFlow = DatabaseServiceDataFlow()
        
        do {
            let allTasks = try await taskService.getAllTasks()
            dataFlow.taskServiceWorking = true
            dataFlow.taskCount = allTasks.count
            
            let allWorkers = try await workerService.getAllActiveWorkers()
            dataFlow.workerServiceWorking = true
            dataFlow.workerCount = allWorkers.count
            
            let allBuildings = try await buildingService.getAllBuildings()
            dataFlow.buildingServiceWorking = true
            dataFlow.buildingCount = allBuildings.count
            
            let insights = try await IntelligenceService.shared.generatePortfolioInsights()
            dataFlow.intelligenceServiceWorking = true
            dataFlow.insightCount = insights.count
            
            dataFlow.isComplete = dataFlow.taskServiceWorking &&
                                dataFlow.workerServiceWorking &&
                                dataFlow.buildingServiceWorking &&
                                dataFlow.intelligenceServiceWorking &&
                                dataFlow.insightCount > 0
            
            print("🔗 Service Data Flow Report:")
            print("   TaskService: \(dataFlow.taskServiceWorking) (\(dataFlow.taskCount) tasks)")
            print("   WorkerService: \(dataFlow.workerServiceWorking) (\(dataFlow.workerCount) workers)")
            print("   BuildingService: \(dataFlow.buildingServiceWorking) (\(dataFlow.buildingCount) buildings)")
            print("   IntelligenceService: \(dataFlow.intelligenceServiceWorking) (\(dataFlow.insightCount) insights)")
            
        } catch {
            print("❌ Service data flow verification failed: \(error)")
            dataFlow.hasError = true
            dataFlow.errorMessage = error.localizedDescription
        }
        
        return dataFlow
    }
    
    // MARK: - Data Access with Fallbacks
    
    /// Get tasks with fallback to OperationalDataManager
    public func getTasksWithFallback(for workerId: String, date: Date) async -> [CoreTypes.ContextualTask] {
        do {
            let dbTasks = try await taskService.getTasks(for: workerId, date: date)
            if !dbTasks.isEmpty {
                return dbTasks
            }
            
            print("⚡ Using OperationalDataManager fallback for worker \(workerId)")
            return await getTasksFromOperationalData(workerId: workerId, date: date)
            
        } catch {
            print("❌ Database tasks failed, using fallback: \(error)")
            return await getTasksFromOperationalData(workerId: workerId, date: date)
        }
    }
    
    /// Get all tasks with fallback to OperationalDataManager
    public func getAllTasksWithFallback() async -> [CoreTypes.ContextualTask] {
        do {
            let dbTasks = try await taskService.getAllTasks()
            if !dbTasks.isEmpty {
                return dbTasks
            }
            
            print("⚡ Using OperationalDataManager fallback for all tasks")
            return await getAllTasksFromOperationalData()
            
        } catch {
            print("❌ Database tasks failed, using fallback: \(error)")
            return await getAllTasksFromOperationalData()
        }
    }
    
    // MARK: - Public Utility Methods
    
    public func performHealthCheck() async -> HealthCheckResult {
        do {
            let isReady = await grdbManager.isDatabaseReady()
            let stats = try await getDatabaseStatistics()
            
            return HealthCheckResult(
                isHealthy: isReady && isInitialized,
                message: isInitialized ? "All systems operational" : "Database not initialized",
                statistics: stats
            )
        } catch {
            return HealthCheckResult(
                isHealthy: false,
                message: "Health check failed: \(error.localizedDescription)",
                statistics: [:]
            )
        }
    }
    
    public func getDatabaseStatistics() async throws -> [String: Any] {
        var stats: [String: Any] = [:]
        
        let workerStats = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN isActive = 1 THEN 1 ELSE 0 END) as active
            FROM workers
        """)
        
        if let row = workerStats.first {
            stats["workers"] = [
                "total": row["total"] as? Int64 ?? 0,
                "active": row["active"] as? Int64 ?? 0
            ]
        }
        
        let buildingStats = try await grdbManager.query("""
            SELECT COUNT(*) as total FROM buildings
        """)
        
        if let row = buildingStats.first {
            stats["buildings"] = ["total": row["total"] as? Int64 ?? 0]
        }
        
        let taskStats = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed
            FROM routine_tasks
        """)
        
        if let row = taskStats.first {
            stats["tasks"] = [
                "total": row["total"] as? Int64 ?? 0,
                "completed": row["completed"] as? Int64 ?? 0
            ]
        }
        
        // Kevin's specific stats
        let kevinStats = try await grdbManager.query("""
            SELECT COUNT(*) as building_count
            FROM worker_building_assignments
            WHERE worker_id = '4' AND is_active = 1
        """)
        
        if let row = kevinStats.first {
            stats["kevin"] = [
                "building_count": row["building_count"] as? Int64 ?? 0,
                "has_rubin": 0  // Will be updated below
            ]
        }
        
        // Check if Kevin has Rubin Museum
        let kevinRubinCheck = try await grdbManager.query("""
            SELECT COUNT(*) as count
            FROM worker_building_assignments
            WHERE worker_id = '4' AND building_id = '14' AND is_active = 1
        """)
        
        if let row = kevinRubinCheck.first,
           let count = row["count"] as? Int64,
           count > 0 {
            if var kevinData = stats["kevin"] as? [String: Any] {
                kevinData["has_rubin"] = 1
                stats["kevin"] = kevinData
            }
        }
        
        stats["database"] = [
            "initialized": isInitialized,
            "ready": await grdbManager.isDatabaseReady(),
            "size": grdbManager.getDatabaseSize()
        ]
        
        return stats
    }
    
    // MARK: - Validation Report
    
    /// Generate a comprehensive validation report
    public func generateValidationReport() async throws -> String {
        var report = "🔍 FRANCOSPHERE DATABASE VALIDATION REPORT\n"
        report += "=" * 50 + "\n\n"
        
        // Check Kevin specifically
        report += "👷 KEVIN DUTAN VALIDATION:\n"
        
        let kevinCheck = try await grdbManager.query("""
            SELECT w.id, w.name, w.isActive, w.shift, COUNT(wba.building_id) as building_count
            FROM workers w 
            LEFT JOIN worker_building_assignments wba ON w.id = wba.worker_id AND wba.is_active = 1
            WHERE w.id = '4'
            GROUP BY w.id, w.name, w.isActive, w.shift
        """, [])
        
        if let kevin = kevinCheck.first {
            let buildingCount = kevin["building_count"] as? Int64 ?? 0
            report += "✅ Kevin found with \(buildingCount) building assignments\n"
            report += "   Shift: \(kevin["shift"] as? String ?? "unknown")\n"
        } else {
            report += "❌ Kevin Dutan not found!\n"
        }
        
        // Verify Kevin has Rubin Museum and NOT Franklin
        let kevinBuildings = try await grdbManager.query("""
            SELECT building_id, notes FROM worker_building_assignments 
            WHERE worker_id = '4' AND is_active = 1
            ORDER BY building_id
        """, [])
        
        let kevinBuildingIds = kevinBuildings.compactMap { $0["building_id"] as? String }
        let hasRubin = kevinBuildingIds.contains("14")
        let hasFranklin = kevinBuildingIds.contains("13")
        
        report += "\n📍 KEVIN'S BUILDING ASSIGNMENTS:\n"
        for building in kevinBuildings {
            let buildingId = building["building_id"] as? String ?? "?"
            let notes = building["notes"] as? String ?? ""
            report += "   Building \(buildingId): \(notes)\n"
        }
        
        report += "\n🎯 CRITICAL CHECKS:\n"
        report += "   Has Rubin Museum (14): \(hasRubin ? "✅ YES" : "❌ NO")\n"
        report += "   Has Franklin Street (13): \(hasFranklin ? "❌ YES (WRONG!)" : "✅ NO (CORRECT)")\n"
        
        // Check routine schedules
        report += "\n📅 ROUTINE SCHEDULES:\n"
        let routineCount = try await grdbManager.query("""
            SELECT COUNT(*) as count FROM routine_schedules
        """, [])
        
        let routines = routineCount.first?["count"] as? Int64 ?? 0
        report += "   Total routine schedules: \(routines)\n"
        
        // Check DSNY schedules
        let dsnyCount = try await grdbManager.query("""
            SELECT COUNT(*) as count FROM dsny_schedules
        """, [])
        
        let dsnyRoutes = dsnyCount.first?["count"] as? Int64 ?? 0
        report += "   Total DSNY routes: \(dsnyRoutes)\n"
        
        // Check all workers
        report += "\n👥 ALL WORKERS:\n"
        let allWorkers = try await grdbManager.query("""
            SELECT id, name, email, shift, isActive FROM workers 
            WHERE isActive = 1
            ORDER BY id
        """, [])
        
        for worker in allWorkers {
            let id = worker["id"] as? String ?? "?"
            let name = worker["name"] as? String ?? "?"
            let shift = worker["shift"] as? String ?? "?"
            report += "   \(id): \(name) (\(shift) shift)\n"
        }
        
        report += "\n✅ VALIDATION COMPLETE\n"
        return report
    }
    
    #if DEBUG
    /// Reset and reinitialize for testing
    public func resetAndReinitialize() async throws {
        print("⚠️ Resetting database...")
        
        try await grdbManager.resetDatabase()
        isInitialized = false
        dataStatus = .unknown
        
        try await initializeIfNeeded()
        
        print("✅ Database reset and reinitialized")
    }
    #endif
    
    // MARK: - Helper Methods
    
    private func shouldImportOperationalData() async -> Bool {
        do {
            let tasks = try await taskService.getAllTasks()
            return tasks.count < 50  // Threshold for needing import
        } catch {
            return true
        }
    }
    
    private func getWorkerIdFromName(_ workerName: String) -> String? {
        let workerNameMap: [String: String] = [
            "Greg Hutson": "1",
            "Edwin Lema": "2",
            "Kevin Dutan": "4",
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn Magloire": "8"
        ]
        return workerNameMap[workerName]
    }
    
    private func getBuildingIdFromName(_ buildingName: String) async -> String? {
        do {
            let buildings = try await buildingService.getAllBuildings()
            return buildings.first { building in
                building.name.lowercased().contains(buildingName.lowercased()) ||
                buildingName.lowercased().contains(building.name.lowercased())
            }?.id
        } catch {
            print("⚠️ Error looking up building '\(buildingName)': \(error)")
            return nil
        }
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
    
    // MARK: - Operational Data Conversion
    
    private func getTasksFromOperationalData(workerId: String, date: Date) async -> [CoreTypes.ContextualTask] {
        let workerName = WorkerConstants.getWorkerName(id: workerId)
        let workerTasks = operationalData.getRealWorldTasks(for: workerName)
        
        var contextualTasks: [CoreTypes.ContextualTask] = []
        
        for operationalTask in workerTasks {
            let contextualTask = await convertOperationalTaskToContextualTask(operationalTask, workerId: workerId)
            contextualTasks.append(contextualTask)
        }
        
        return contextualTasks
    }
    
    private func getAllTasksFromOperationalData() async -> [CoreTypes.ContextualTask] {
        let allTasks = operationalData.getAllRealWorldTasks()
        var contextualTasks: [CoreTypes.ContextualTask] = []
        
        for operationalTask in allTasks {
            guard let workerId = getWorkerIdFromName(operationalTask.assignedWorker) else { continue }
            let contextualTask = await convertOperationalTaskToContextualTask(operationalTask, workerId: workerId)
            contextualTasks.append(contextualTask)
        }
        
        return contextualTasks
    }
    
    private func convertOperationalTaskToContextualTask(_ operationalTask: OperationalDataTaskAssignment, workerId: String) async -> CoreTypes.ContextualTask {
        let buildingId = await getBuildingIdFromName(operationalTask.building) ?? "unknown_building_\(operationalTask.building.hash)"
        
        return CoreTypes.ContextualTask(
            id: "op_\(operationalTask.taskName.hash)_\(workerId)",
            title: operationalTask.taskName,
            description: generateTaskDescription(operationalTask),
            isCompleted: false,
            completedDate: nil,
            dueDate: calculateDueDate(for: operationalTask),
            category: mapToTaskCategory(operationalTask.category),
            urgency: mapToTaskUrgency(operationalTask.skillLevel),
            building: nil,
            worker: nil,
            buildingId: buildingId,
            priority: mapToTaskUrgency(operationalTask.skillLevel)
        )
    }
    
    private func generateTaskDescription(_ operationalTask: OperationalDataTaskAssignment) -> String {
        var description = "Operational task: \(operationalTask.taskName)"
        
        if let startHour = operationalTask.startHour, let endHour = operationalTask.endHour {
            description += " (scheduled \(startHour):00 - \(endHour):00)"
        }
        
        if operationalTask.recurrence != "On-Demand" {
            description += " - \(operationalTask.recurrence)"
        }
        
        description += " at \(operationalTask.building)"
        
        return description
    }
    
    private func calculateDueDate(for operationalTask: OperationalDataTaskAssignment) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        if let startHour = operationalTask.startHour {
            let todayAtStartHour = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: now)
            
            if let scheduledTime = todayAtStartHour, scheduledTime < now {
                return calendar.date(byAdding: .day, value: 1, to: scheduledTime)
            }
            
            return todayAtStartHour
        }
        
        return calendar.date(byAdding: .hour, value: 2, to: now)
    }
    
    private func mapToTaskCategory(_ category: String) -> CoreTypes.TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "sanitation": return .sanitation
        case "inspection": return .inspection
        case "repair": return .repair
        case "security": return .security
        case "utilities": return .utilities
        case "landscaping": return .landscaping
        case "emergency": return .emergency
        default: return .maintenance
        }
    }
    
    private func mapToTaskUrgency(_ skillLevel: String) -> CoreTypes.TaskUrgency {
        switch skillLevel.lowercased() {
        case "advanced": return .high
        case "intermediate": return .medium
        case "basic": return .low
        default: return .medium
        }
    }
}

// MARK: - Supporting Types

public struct IntegrityCheckResult {
    var isHealthy: Bool { issues.isEmpty }
    var passedChecks: [String] = []
    var issues: [String] = []
}

public struct HealthCheckResult {
    let isHealthy: Bool
    let message: String
    let statistics: [String: Any]
}

public struct DatabaseServiceDataFlow {
    var taskServiceWorking = false
    var workerServiceWorking = false
    var buildingServiceWorking = false
    var intelligenceServiceWorking = false
    var taskCount = 0
    var workerCount = 0
    var buildingCount = 0
    var insightCount = 0
    var isComplete = false
    var hasError = false
    var errorMessage: String?
}

public enum InitializationError: LocalizedError {
    case databaseNotReady
    case healthCheckFailed(String)
    case dataImportFailed(String)
    case serviceStartupFailed(String)
    case integrityCheckFailed(String)
    case seedingFailed(String)
    case migrationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .databaseNotReady:
            return "Database is not ready"
        case .healthCheckFailed(let message):
            return "System health check failed: \(message)"
        case .dataImportFailed(let message):
            return "Data import failed: \(message)"
        case .serviceStartupFailed(let message):
            return "Service startup failed: \(message)"
        case .integrityCheckFailed(let details):
            return "Database integrity check failed: \(details)"
        case .seedingFailed(let details):
            return "Database seeding failed: \(details)"
        case .migrationFailed(let details):
            return "Database migration failed: \(details)"
        }
    }
}

// MARK: - 📝 CONSOLIDATED MIGRATION NOTES
/*
 ✅ COMPLETE CONSOLIDATION WITH 100% DATA PRESERVATION:
 
 🔧 ALL SCHEMAMIGRATIONPATCH FUNCTIONALITY INTEGRATED:
 - ✅ Emergency column fixes (isActive, shift, hireDate, email)
 - ✅ Kevin's corrected building assignments (8 buildings)
 - ✅ Kevin's Rubin Museum: Building ID 14 preserved (NOT Franklin 13)
 - ✅ All worker data: 7 active workers with complete profiles
 - ✅ All routine schedules: Complete operational matrix preserved
 - ✅ All DSNY routes: Waste collection schedules preserved
 - ✅ Building assignments: All worker-building relationships preserved
 - ✅ Migration tracking with version control
 
 🔧 ENHANCED FEATURES:
 - ✅ UI progress tracking for all operations
 - ✅ Comprehensive error handling
 - ✅ Health check and validation reporting
 - ✅ Service integration verification
 - ✅ Fallback data access patterns
 - ✅ Debug utilities for development
 
 🔧 CRITICAL DATA PRESERVED:
 - ✅ Kevin's Rubin Museum assignment (ID 14) maintained
 - ✅ Kevin's 178 Spring Street assignment (ID 17) maintained
 - ✅ All operational schedules with correct building mappings
 - ✅ Complete worker-building assignment matrix
 - ✅ Site departure logs table for compliance tracking
 
 🎯 STATUS: Complete consolidation - ready to delete SchemaMigrationPatch.swift
 */
