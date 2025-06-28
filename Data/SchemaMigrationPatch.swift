//
//  SchemaMigrationPatch.swift
//  FrancoSphere
//
//  🔧 PHASE-3B COMPLETE: Enhanced Schema Migration with Kevin Fix
//  ✅ HF-29: ROUTINE SCHEDULING & DSNY COMPLIANCE TABLES (COMPLETE)
//  ✅ Fixed missing isActive column in workers table
//  ✅ Enhanced Kevin Dutan building assignments
//  ✅ Complete emergency data recovery integration
//  ✅ Enhanced error handling and validation
//  ✅ Compatible with Phase-2 implementation
//

import Foundation
import SQLite

class SchemaMigrationPatch {
    static let shared = SchemaMigrationPatch()
    
    private init() {}
    
    /// Apply all pending schema patches including emergency fixes
    func applyPatch() async throws {
        let manager = SQLiteManager.shared
        
        print("🔧 Starting PHASE-3B comprehensive schema migration...")
        
        do {
            // Patch 0: Emergency fix for missing columns (PRIORITY 1)
            try await fixMissingWorkerColumns(manager)
            
            // Patch 1: Fix worker_building_assignments table
            try await fixWorkerBuildingAssignments(manager)
            
            // Patch 2: Seed active workers (including Kevin)
            try await seedActiveWorkers(manager)
            
            // Patch 3: Create Kevin's building assignments
            try await createKevinBuildingAssignments(manager)
            
            // Patch 4: Add missing constraints
            try await addMissingConstraints(manager)
            
            // Patch 5: Update column types
            try await updateColumnTypes(manager)
            
            // Patch 6: Add building name mappings table
            try await createBuildingNameMappings(manager)
            
            // Patch 7: Add worker shift assignments
            try await createWorkerShiftAssignments(manager)
            
            // 🔧 HF-29: ROUTINE SCHEDULING & DSNY COMPLIANCE TABLES
            try await createRoutineSchedulingTables(manager)
            
            // 🔧 HF-29: Import operational schedule data
            try await importOperationalSchedules(manager)
            
            print("✅ PHASE-3B comprehensive schema migration completed successfully!")
            
        } catch {
            print("❌ Schema migration failed: \(error)")
            throw error
        }
    }
    
    // MARK: - 🚨 EMERGENCY FIX: Missing Worker Columns
    
    /// Fix missing columns in workers table (PRIORITY 1)
    private func fixMissingWorkerColumns(_ manager: SQLiteManager) async throws {
        print("🚨 EMERGENCY FIX: Adding missing columns to workers table...")
        
        // Check current table structure
        let tableInfo = try await manager.query("PRAGMA table_info(workers)")
        let columnNames = Set(tableInfo.compactMap { $0["name"] as? String })
        
        print("📋 Current workers table columns: \(columnNames.sorted())")
        
        // Add missing isActive column (this was causing the error)
        if !columnNames.contains("isActive") {
            try await manager.execute("ALTER TABLE workers ADD COLUMN isActive INTEGER DEFAULT 1")
            print("✅ Added isActive column to workers table")
        }
        
        // Add missing shift column
        if !columnNames.contains("shift") {
            try await manager.execute("ALTER TABLE workers ADD COLUMN shift TEXT DEFAULT 'day'")
            print("✅ Added shift column to workers table")
        }
        
        // Add missing hireDate column
        if !columnNames.contains("hireDate") {
            try await manager.execute("ALTER TABLE workers ADD COLUMN hireDate TEXT DEFAULT (date('now'))")
            print("✅ Added hireDate column to workers table")
        }
        
        // Add missing email column if not exists
        if !columnNames.contains("email") {
            try await manager.execute("ALTER TABLE workers ADD COLUMN email TEXT")
            print("✅ Added email column to workers table")
        }
        
        print("✅ Emergency column fixes completed")
    }
    
    // MARK: - 👷 ACTIVE WORKERS SEEDING
    
    /// Seed active workers with correct schema (including Kevin)
    private func seedActiveWorkers(_ manager: SQLiteManager) async throws {
        print("👷 Seeding active workers with enhanced schema...")
        
        // Seed active workers with correct schema (including Kevin)
        let activeWorkers: [(String, String, String, String, Int, String, String)] = [
            ("1", "Greg Hutson", "greg.hutson@francosphere.com", "worker", 1, "day", "2022-03-15"),
            ("2", "Edwin Lema", "edwin.lema@francosphere.com", "worker", 1, "morning", "2023-01-10"),
            ("4", "Kevin Dutan", "kevin.dutan@francosphere.com", "worker", 1, "day", "2021-08-20"),
            ("5", "Mercedes Inamagua", "mercedes.inamagua@francosphere.com", "worker", 1, "split", "2022-11-05"),
            ("6", "Luis Lopez", "luis.lopez@francosphere.com", "worker", 1, "day", "2023-02-18"),
            ("7", "Angel Guirachocha", "angel.guirachocha@francosphere.com", "worker", 1, "evening", "2022-07-12"),
            ("8", "Shawn Magloire", "shawn.magloire@francosphere.com", "admin", 1, "day", "2020-01-15")
        ]
        
        for (id, name, email, role, isActive, shift, hireDate) in activeWorkers {
            try await manager.execute("""
                INSERT OR REPLACE INTO workers (id, name, email, role, isActive, shift, hireDate) 
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [id, name, email, role, isActive, shift, hireDate])
        }
        
        print("✅ Seeded \(activeWorkers.count) active workers (including Kevin)")
        
        // Verify Kevin was created
        let kevinCheck = try await manager.query(
            "SELECT id, name, isActive FROM workers WHERE id = '4' LIMIT 1",
            []
        )
        
        if let kevin = kevinCheck.first {
            print("✅ Kevin verification: ID=\(kevin["id"] ?? "nil"), Name=\(kevin["name"] ?? "nil"), Active=\(kevin["isActive"] ?? "nil")")
        } else {
            print("🚨 WARNING: Kevin not found after seeding!")
        }
    }
    
    // MARK: - 🏢 KEVIN'S BUILDING ASSIGNMENTS
    
    /// Create Kevin's building assignments (expanded duties after Jose's departure)
    private func createKevinBuildingAssignments(_ manager: SQLiteManager) async throws {
        print("🏢 Creating Kevin's expanded building assignments...")
        
        // Ensure worker_building_assignments table exists with correct structure
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_building_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                worker_name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                assignment_type TEXT DEFAULT 'regular',
                start_date TEXT NOT NULL DEFAULT (datetime('now')),
                end_date TEXT,
                is_active INTEGER DEFAULT 1,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now')),
                notes TEXT,
                UNIQUE(worker_id, building_id),
                CHECK(is_active IN (0, 1))
            );
        """)
        
        // Kevin's building assignments (expanded duties - formerly Jose's responsibilities)
        let kevinBuildings: [(String, String, String)] = [
            ("3", "131 Perry Street", "Former Jose Santos building - high priority"),
            ("6", "68 Perry Street", "Perry Street corridor - daily maintenance"),
            ("7", "135-139 West 17th Street", "Main maintenance building"),
            ("9", "117 West 17th Street", "West 17th Street corridor"),
            ("11", "136 West 17th Street", "Extended coverage area"),
            ("16", "Stuyvesant Cove Park", "Special assignment - outdoor maintenance")
        ]
        
        for (buildingId, buildingName, notes) in kevinBuildings {
            try await manager.execute("""
                INSERT OR REPLACE INTO worker_building_assignments 
                (worker_id, worker_name, building_id, assignment_type, start_date, is_active, notes) 
                VALUES ('4', 'Kevin Dutan', ?, 'expanded_duties', datetime('now'), 1, ?)
            """, [buildingId, notes])
        }
        
        print("✅ Created \(kevinBuildings.count) building assignments for Kevin (expanded duties)")
        
        // Verify Kevin's assignments were created
        let kevinAssignments = try await manager.query("""
            SELECT building_id, notes FROM worker_building_assignments 
            WHERE worker_id = '4' AND is_active = 1
        """, [])
        
        print("📊 Kevin's verified assignments: \(kevinAssignments.count) buildings")
        for assignment in kevinAssignments {
            print("   🏢 Building ID: \(assignment["building_id"] ?? "nil")")
        }
    }
    
    // MARK: - 🔧 HF-29: ROUTINE SCHEDULING INFRASTRUCTURE
    
    /// Create all routine scheduling and DSNY compliance tables
    private func createRoutineSchedulingTables(_ manager: SQLiteManager) async throws {
        print("🔧 HF-29: Adding routine scheduling tables...")

        // Create routine_schedules table for operational workflow tracking
        try await manager.execute("""
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
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (building_id) REFERENCES buildings(id),
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            )
        """)

        // Create DSNY schedules table for NYC compliance tracking
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS dsny_schedules (
                id TEXT PRIMARY KEY,
                route_id TEXT NOT NULL,
                building_ids TEXT NOT NULL,
                collection_days TEXT NOT NULL,
                earliest_setout INTEGER DEFAULT 72000,
                latest_pickup INTEGER DEFAULT 32400,
                pickup_window_start INTEGER DEFAULT 21600,
                pickup_window_end INTEGER DEFAULT 43200,
                route_status TEXT DEFAULT 'active',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)

        // Create routine_overrides table for weather/emergency postponements
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS routine_overrides (
                id TEXT PRIMARY KEY,
                routine_id TEXT NOT NULL,
                override_type TEXT NOT NULL,
                reason TEXT NOT NULL,
                original_status TEXT NOT NULL,
                new_status TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                expires_at DATETIME,
                FOREIGN KEY (routine_id) REFERENCES routine_schedules(id)
            )
        """)

        // Add indexes for performance
        try await manager.execute("""
            CREATE INDEX IF NOT EXISTS idx_routine_worker_building 
            ON routine_schedules(worker_id, building_id)
        """)
        
        try await manager.execute("""
            CREATE INDEX IF NOT EXISTS idx_dsny_routes 
            ON dsny_schedules(route_id, route_status)
        """)
        
        try await manager.execute("""
            CREATE INDEX IF NOT EXISTS idx_routine_overrides 
            ON routine_overrides(routine_id, override_type)
        """)

        print("✅ HF-29: Routine scheduling infrastructure created")
    }
    
    /// Import operational schedule data directly (fallback implementation)
    private func importOperationalSchedules(_ manager: SQLiteManager) async throws {
        print("🔧 HF-29: Importing operational schedule data...")

        // Always use fallback implementation for reliability
        try await importRoutineSchedulesFallback(manager)
        try await importDSNYSchedulesFallback(manager)
        
        print("✅ HF-29: Operational schedule data imported")
    }
    
    /// Fallback method to import routine schedules directly
    private func importRoutineSchedulesFallback(_ manager: SQLiteManager) async throws {
        let routineSchedules: [(String, String, String, String, String, String)] = [
            // Kevin's Perry Street circuit (expanded duties)
            ("routine_10_4_daily_sweep", "Daily Sidewalk Sweep", "10", "FREQ=DAILY;BYHOUR=6", "4", "Cleaning"),
            ("routine_10_4_weekly_clean", "Weekly Hallway Deep Clean", "10", "FREQ=WEEKLY;BYDAY=MO,WE;BYHOUR=7", "4", "Cleaning"),
            ("routine_6_4_building_clean", "Perry 68 Full Building Clean", "6", "FREQ=WEEKLY;BYDAY=TU,TH;BYHOUR=8", "4", "Cleaning"),
            ("routine_7_4_trash_maint", "17th Street Trash Area Maintenance", "7", "FREQ=DAILY;BYHOUR=11", "4", "Cleaning"),
            ("routine_9_4_dsny_check", "DSNY Compliance Check", "9", "FREQ=WEEKLY;BYDAY=SU,TU,TH;BYHOUR=20", "4", "Operations"),
            ("routine_3_4_jose_duties", "Former Jose Santos Building Duties", "3", "FREQ=DAILY;BYHOUR=9", "4", "Maintenance"),
            ("routine_11_4_coverage", "Extended Coverage Maintenance", "11", "FREQ=WEEKLY;BYDAY=FR;BYHOUR=10", "4", "Maintenance"),
            ("routine_16_4_park_maint", "Stuyvesant Park Maintenance", "16", "FREQ=WEEKLY;BYDAY=SA;BYHOUR=8", "4", "Outdoor"),
            
            // Mercedes' morning glass circuit (6:30-11:00 AM shift)
            ("routine_7_5_glass_lobby", "Glass & Lobby Clean", "7", "FREQ=DAILY;BYHOUR=6", "5", "Cleaning"),
            ("routine_9_5_glass_vestibule", "117 West 17th Glass & Vestibule", "9", "FREQ=DAILY;BYHOUR=7", "5", "Cleaning"),
            ("routine_11_5_glass_clean", "135-139 West 17th Glass Clean", "11", "FREQ=DAILY;BYHOUR=8", "5", "Cleaning"),
            ("routine_13_5_roof_check", "Rubin Museum Roof Drain Check", "13", "FREQ=WEEKLY;BYDAY=WE;BYHOUR=10", "5", "Maintenance"),
            
            // Edwin's maintenance rounds (6:00-15:00)
            ("routine_16_2_park_inspect", "Stuyvesant Park Morning Inspection", "16", "FREQ=DAILY;BYHOUR=6", "2", "Maintenance"),
            ("routine_8_2_boiler_check", "133 E 15th Boiler Blow-Down", "8", "FREQ=WEEKLY;BYDAY=MO;BYHOUR=9", "2", "Maintenance"),
            ("routine_7_2_filter_change", "Water Filter Change", "7", "FREQ=MONTHLY;BYHOUR=10", "2", "Maintenance"),
            
            // Luis Lopez daily circuit (7:00-16:00)
            ("routine_4_6_sidewalk_hose", "104 Franklin Sidewalk Hose", "4", "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=7", "6", "Cleaning"),
            ("routine_8_6_full_service", "41 Elizabeth Full Service", "8", "FREQ=DAILY;BYHOUR=8", "6", "Cleaning"),
            
            // Greg Hutson building specialist (9:00-15:00)
            ("routine_1_1_complete_service", "12 West 18th Complete Service", "1", "FREQ=DAILY;BYHOUR=9", "1", "Cleaning"),
            
            // Angel evening operations (18:00-22:00)
            ("routine_1_7_security_check", "Evening Security Check", "1", "FREQ=DAILY;BYHOUR=21", "7", "Operations"),
            
            // Shawn specialist maintenance (floating schedule)
            ("routine_14_8_hvac_systems", "Rubin Museum HVAC Systems", "14", "FREQ=MONTHLY;BYHOUR=9", "8", "Maintenance")
        ]
        
        var routineCount = 0
        for routine in routineSchedules {
            let weatherDependent = routine.5 == "Cleaning" ? 1 : 0
            
            try await manager.execute("""
                INSERT OR REPLACE INTO routine_schedules 
                (id, name, building_id, rrule, worker_id, category, weather_dependent)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [routine.0, routine.1, routine.2, routine.3, routine.4, routine.5, weatherDependent])
            routineCount += 1
        }
        
        print("✅ HF-29: Imported \(routineCount) routine schedules (including Kevin's expanded duties)")
    }
    
    /// Fallback method to import DSNY schedules directly
    private func importDSNYSchedulesFallback(_ manager: SQLiteManager) async throws {
        let dsnySchedules: [(String, String, String, String)] = [
            // Manhattan West 17th Street corridor (includes Kevin's buildings)
            ("dsny_man_17th_west", "MAN-17TH-WEST", "7,9,11", "MON,WED,FRI"),
            
            // Perry Street / West Village (Kevin's primary route)
            ("dsny_man_perry_village", "MAN-PERRY-VILLAGE", "3,6,10", "MON,WED,FRI"),
            
            // Downtown / Tribeca route
            ("dsny_man_downtown_tri", "MAN-DOWNTOWN-TRI", "4,8", "TUE,THU,SAT"),
            
            // East side route
            ("dsny_man_18th_east", "MAN-18TH-EAST", "1", "MON,WED,FRI"),
            
            // Special collections (Rubin Museum and parks)
            ("dsny_man_museum_special", "MAN-MUSEUM-SPECIAL", "13,14,16", "TUE,FRI")
        ]
        
        var dsnyCount = 0
        for dsny in dsnySchedules {
            try await manager.execute("""
                INSERT OR REPLACE INTO dsny_schedules 
                (id, route_id, building_ids, collection_days, earliest_setout, latest_pickup, pickup_window_start, pickup_window_end)
                VALUES (?, ?, ?, ?, 72000, 32400, 21600, 43200)
            """, [dsny.0, dsny.1, dsny.2, dsny.3])
            dsnyCount += 1
        }
        
        print("✅ HF-29: Imported \(dsnyCount) DSNY route schedules (covering Kevin's expanded coverage)")
    }
    
    // MARK: - Individual Migration Steps (existing methods enhanced)
    
    /// Fix worker_building_assignments table structure
    private func fixWorkerBuildingAssignments(_ manager: SQLiteManager) async throws {
        print("🔧 Fixing worker_building_assignments table...")
        
        // Check if table exists with correct structure
        let tableInfo = try await manager.query("PRAGMA table_info(worker_building_assignments)")
        let columns = tableInfo.compactMap { $0["name"] as? String }
        
        if !columns.contains("worker_name") {
            // Add missing worker_name column
            try await manager.execute("""
                ALTER TABLE worker_building_assignments 
                ADD COLUMN worker_name TEXT DEFAULT ''
            """)
            
            // Populate worker_name from workers table
            try await manager.execute("""
                UPDATE worker_building_assignments 
                SET worker_name = (
                    SELECT name FROM workers 
                    WHERE workers.id = worker_building_assignments.worker_id
                )
                WHERE worker_name = ''
            """)
        }
        
        if !columns.contains("assignment_type") {
            try await manager.execute("""
                ALTER TABLE worker_building_assignments 
                ADD COLUMN assignment_type TEXT DEFAULT 'regular'
            """)
        }
        
        if !columns.contains("start_date") {
            try await manager.execute("""
                ALTER TABLE worker_building_assignments 
                ADD COLUMN start_date DATETIME DEFAULT CURRENT_TIMESTAMP
            """)
        }
        
        if !columns.contains("is_active") {
            try await manager.execute("""
                ALTER TABLE worker_building_assignments 
                ADD COLUMN is_active INTEGER DEFAULT 1
            """)
        }
        
        if !columns.contains("notes") {
            try await manager.execute("""
                ALTER TABLE worker_building_assignments 
                ADD COLUMN notes TEXT
            """)
        }
        
        print("✅ worker_building_assignments table updated with enhanced structure")
    }
    
    /// Add missing database constraints
    private func addMissingConstraints(_ manager: SQLiteManager) async throws {
        print("🔧 Adding missing constraints...")
        
        // Create unique indexes to prevent duplicates
        let indexes: [(String, String, String)] = [
            ("idx_worker_building_unique", "worker_building_assignments", "worker_id, building_id"),
            ("idx_task_external_id", "tasks", "external_id"),
            ("idx_building_name", "buildings", "name"),
            ("idx_worker_email", "workers", "email")
        ]
        
        for (indexName, tableName, columns) in indexes {
            do {
                try await manager.execute("""
                    CREATE UNIQUE INDEX IF NOT EXISTS \(indexName) 
                    ON \(tableName)(\(columns))
                """)
            } catch {
                print("⚠️ Could not create index \(indexName): \(error)")
                // Continue with other indexes
            }
        }
        
        print("✅ Database constraints added")
    }
    
    /// Update column types for consistency
    private func updateColumnTypes(_ manager: SQLiteManager) async throws {
        print("🔧 Updating column types...")
        
        // SQLite doesn't support ALTER COLUMN, so we'll handle type issues in queries
        // For now, just ensure all ID columns are consistent
        
        let tables = try await manager.query("""
            SELECT name FROM sqlite_master WHERE type='table'
        """)
        
        for table in tables {
            guard let tableName = table["name"] as? String else { continue }
            
            // Skip system tables
            if tableName.hasPrefix("sqlite_") { continue }
            
            let tableInfo = try await manager.query("PRAGMA table_info(\(tableName))")
            
            for column in tableInfo {
                guard let columnName = column["name"] as? String,
                      let dataType = column["type"] as? String else { continue }
                
                // Log any potential type issues for future fixing
                if columnName.hasSuffix("_id") && !dataType.uppercased().contains("TEXT") && !dataType.uppercased().contains("INTEGER") {
                    print("⚠️ Potential type issue: \(tableName).\(columnName) has type \(dataType)")
                }
            }
        }
        
        print("✅ Column types checked")
    }
    
    /// Create building name mappings for CSV import
    private func createBuildingNameMappings(_ manager: SQLiteManager) async throws {
        print("🔧 Creating building name mappings...")
        
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS building_name_mappings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                csv_name TEXT NOT NULL,
                canonical_name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(csv_name, building_id)
            )
        """)
        
        // Insert common mappings for CSV import (including Kevin's buildings)
        let mappings: [(String, String, String)] = [
            // Kevin's Perry Street buildings
            ("131 Perry Street", "131 Perry Street", "3"),
            ("68 Perry Street", "68 Perry Street", "6"),
            
            // Kevin's 17th Street corridor buildings
            ("135–139 West 17th", "135-139 West 17th Street", "7"),
            ("135-139 West 17th", "135-139 West 17th Street", "7"),
            ("117 West 17th Street", "117 West 17th Street", "9"),
            ("136 West 17th", "136 West 17th Street", "11"),
            ("138 West 17th Street", "138 West 17th Street", "12"),
            
            // 18th Street variants
            ("12 West 18th Street", "12 West 18th Street", "1"),
            ("112 West 18th Street", "112 West 18th Street", "14"),
            
            // Downtown variants
            ("104 Franklin", "104 Franklin Street", "4"),
            ("41 Elizabeth Street", "41 Elizabeth Street", "8"),
            ("133 East 15th Street", "133 East 15th Street", "15"),
            
            // Special buildings (Kevin's park assignment)
            ("Rubin Museum (142–148 W 17th)", "Rubin Museum", "13"),
            ("Stuyvesant Cove Park", "Stuyvesant Cove Park", "16"),
            ("FrancoSphere HQ", "12 West 18th Street", "1"), // HQ maps to main building
            
            // Additional variants
            ("29–31 East 20th", "29-31 East 20th Street", "2"),
            ("123 1st Ave", "123 1st Avenue", "3"),
            ("178 Spring", "178 Spring Street", "5"),
            ("36 Walker", "36 Walker Street", "17"),
            ("115 7th Ave", "115 7th Avenue", "18")
        ]
        
        for (csvName, canonicalName, buildingId) in mappings {
            try await manager.execute("""
                INSERT OR IGNORE INTO building_name_mappings 
                (csv_name, canonical_name, building_id) 
                VALUES (?, ?, ?)
            """, [csvName, canonicalName, buildingId])
        }
        
        print("✅ Building name mappings created (\(mappings.count) entries - Kevin's buildings prioritized)")
    }
    
    /// Create worker shift assignments table
    private func createWorkerShiftAssignments(_ manager: SQLiteManager) async throws {
        print("🔧 Creating worker shift assignments...")
        
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_shift_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                shift_type TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT NOT NULL,
                days_of_week TEXT,
                is_active INTEGER DEFAULT 1,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (worker_id) REFERENCES workers(id),
                UNIQUE(worker_id, shift_type)
            )
        """)
        
        // Insert current worker shift data (Kevin gets expanded hours)
        let shifts: [(String, String, String, String, String)] = [
            ("1", "regular", "09:00", "15:00", "Mon,Tue,Wed,Thu,Fri"), // Greg Hutson
            ("2", "regular", "06:00", "15:00", "Mon,Tue,Wed,Thu,Fri,Sat,Sun"), // Edwin Lema
            ("4", "expanded", "06:00", "18:00", "Mon,Tue,Wed,Thu,Fri,Sat"), // Kevin Dutan (expanded)
            ("5", "morning", "06:30", "11:00", "Mon,Tue,Wed,Thu,Fri,Sat"), // Mercedes Inamagua
            ("6", "regular", "07:00", "16:00", "Mon,Tue,Wed,Thu,Fri,Sat"), // Luis Lopez
            ("7", "evening", "18:00", "22:00", "Mon,Tue,Wed,Thu,Fri"), // Angel Guirachocha
            ("8", "flexible", "09:00", "17:00", "Mon,Tue,Wed,Thu,Fri") // Shawn Magloire
        ]
        
        for (workerId, shiftType, startTime, endTime, daysOfWeek) in shifts {
            try await manager.execute("""
                INSERT OR IGNORE INTO worker_shift_assignments 
                (worker_id, shift_type, start_time, end_time, days_of_week) 
                VALUES (?, ?, ?, ?, ?)
            """, [workerId, shiftType, startTime, endTime, daysOfWeek])
        }
        
        print("✅ Worker shift assignments created (\(shifts.count) entries - Kevin expanded schedule)")
    }
    
    // MARK: - Validation and Cleanup
    
    /// Validate the migration completed successfully
    func validateMigration() async throws {
        let manager = SQLiteManager.shared
        
        print("🔍 Validating comprehensive migration...")
        
        // Check required tables
        let requiredTables: [String] = [
            "workers",
            "buildings",
            "worker_building_assignments",
            "building_name_mappings",
            "worker_shift_assignments",
            "routine_schedules",
            "dsny_schedules",
            "routine_overrides"
        ]
        
        for tableName in requiredTables {
            let tables = try await manager.query("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name=?
            """, [tableName])
            
            guard !tables.isEmpty else {
                throw MigrationError.missingTable(tableName)
            }
        }
        
        // Validate Kevin specifically
        let kevinCheck = try await manager.query("""
            SELECT w.id, w.name, w.isActive, COUNT(wba.building_id) as building_count
            FROM workers w 
            LEFT JOIN worker_building_assignments wba ON w.id = wba.worker_id AND wba.is_active = 1
            WHERE w.id = '4'
            GROUP BY w.id, w.name, w.isActive
        """, [])
        
        guard let kevin = kevinCheck.first else {
            throw MigrationError.noData("Kevin Dutan not found")
        }
        
        let buildingCount = kevin["building_count"] as? Int64 ?? 0
        print("✅ Kevin validation: Found with \(buildingCount) building assignments")
        
        if buildingCount < 6 {
            print("⚠️ WARNING: Kevin has only \(buildingCount) buildings (expected 6+)")
        }
        
        // Validate data integrity
        let workerBuildingCount = try await manager.query("SELECT COUNT(*) as count FROM worker_building_assignments")
        let buildingMappingCount = try await manager.query("SELECT COUNT(*) as count FROM building_name_mappings")
        let routineCount = try await manager.query("SELECT COUNT(*) as count FROM routine_schedules")
        let dsnyCount = try await manager.query("SELECT COUNT(*) as count FROM dsny_schedules")
        
        guard let wbCount = workerBuildingCount.first?["count"] as? Int64, wbCount > 0 else {
            throw MigrationError.noData("worker_building_assignments")
        }
        
        guard let bmCount = buildingMappingCount.first?["count"] as? Int64, bmCount > 0 else {
            throw MigrationError.noData("building_name_mappings")
        }
        
        print("✅ Comprehensive migration validation passed")
        print("   📊 Worker-building assignments: \(wbCount)")
        print("   📊 Building name mappings: \(bmCount)")
        
        if let rCount = routineCount.first?["count"] as? Int64 {
            print("   📊 Routine schedules: \(rCount)")
        }
        
        if let dCount = dsnyCount.first?["count"] as? Int64 {
            print("   📊 DSNY schedules: \(dCount)")
        }
    }
    
    /// Clean up any orphaned data
    func cleanupOrphanedData() async throws {
        let manager = SQLiteManager.shared
        
        print("🧹 Cleaning up orphaned data...")
        
        // Remove worker assignments for non-existent workers
        try await manager.execute("""
            DELETE FROM worker_building_assignments 
            WHERE worker_id NOT IN (SELECT id FROM workers)
        """)
        
        // Remove worker assignments for non-existent buildings
        try await manager.execute("""
            DELETE FROM worker_building_assignments 
            WHERE building_id NOT IN (SELECT id FROM buildings)
        """)
        
        // Remove inactive assignments older than 30 days (except Kevin's)
        try await manager.execute("""
            DELETE FROM worker_building_assignments 
            WHERE is_active = 0 
            AND worker_id != '4'
            AND datetime(start_date, '+30 days') < datetime('now')
        """)
        
        print("✅ Orphaned data cleanup completed (Kevin's assignments protected)")
    }
    
    // MARK: - Emergency Recovery Methods
    
    /// Apply emergency schema fix for specific worker issues
    func applyEmergencyWorkerFix(workerId: String) async throws {
        let manager = SQLiteManager.shared
        
        print("🚨 Applying emergency fix for worker \(workerId)...")
        
        // Ensure all required columns exist
        try await fixMissingWorkerColumns(manager)
        
        // Ensure worker exists using CSVDataImporter (the real data source)
        let workerCheck = try await manager.query(
            "SELECT id, name FROM workers WHERE id = ? LIMIT 1",
            [workerId]
        )
        
        if workerCheck.isEmpty {
            print("🚨 Worker \(workerId) not found - using CSVDataImporter to seed workers...")
            
            // Use CSVDataImporter to seed workers properly
            let csvImporter = CSVDataImporter.shared
            
            // Set sqliteManager on main actor since CSVDataImporter is @MainActor
            await MainActor.run {
                csvImporter.sqliteManager = manager
            }
            
            // Import real world tasks (which includes worker seeding)
            let (imported, errors) = try await csvImporter.importRealWorldTasks()
            print("📥 Emergency CSV import: \(imported) tasks imported, \(errors.count) errors")
            
            if !errors.isEmpty {
                print("⚠️ Import warnings: \(errors.prefix(3).joined(separator: ", "))")
            }
            
            // Verify worker was created
            let workerRecheck = try await manager.query(
                "SELECT id, name FROM workers WHERE id = ? LIMIT 1",
                [workerId]
            )
            
            if workerRecheck.isEmpty {
                throw MigrationError.noData("Worker \(workerId) could not be created via CSVDataImporter")
            }
        }
        
        // Specific fixes for Kevin using real data
        if workerId == "4" {
            try await createKevinBuildingAssignments(manager)
        }
        
        print("✅ Emergency fix completed for worker \(workerId)")
    }
    
    /// Get worker data for emergency creation (DEPRECATED - use CSVDataImporter instead)
    private func getWorkerData(for workerId: String) -> [Any] {
        // This method is deprecated - CSVDataImporter should be used instead
        // Keeping for legacy compatibility only
        switch workerId {
        case "4":
            return ["4" as Any, "Kevin Dutan" as Any, "kevin.dutan@francosphere.com" as Any, "worker" as Any, 1 as Any, "day" as Any, "2021-08-20" as Any]
        default:
            return [workerId as Any, "Unknown Worker" as Any, "unknown@francosphere.com" as Any, "worker" as Any, 1 as Any, "day" as Any, "2023-01-01" as Any]
        }
    }
    }

// MARK: - Migration Error Types

enum MigrationError: LocalizedError {
    case missingTable(String)
    case noData(String)
    case constraintViolation(String)
    
    var errorDescription: String? {
        switch self {
        case .missingTable(let table):
            return "Required table missing: \(table)"
        case .noData(let table):
            return "No data found in table: \(table)"
        case .constraintViolation(let message):
            return "Constraint violation: \(message)"
        }
    }
}
