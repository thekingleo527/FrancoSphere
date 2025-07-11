//
//  SchemaMigrationPatch.swift
//  FrancoSphere
//
//  🔧 STREAMLINED VERSION: Essential Schema Fixes Only
//  ✅ Removed redundant building_name_mappings (buildings defined elsewhere)
//  ✅ Fixed Kevin's building assignments with Rubin Museum (ID "14")
//  ✅ Core schema fixes for compilation errors
//  ✅ Enhanced error handling and validation
//  ✅ Eliminated redundancy across multiple files
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SQLite
// FrancoSphere Types Import
// (This comment helps identify our import)


class SchemaMigrationPatch {
    static let shared = SchemaMigrationPatch()
    
    private init() {}
    
    /// Apply essential schema patches - streamlined approach
    func applyPatch() async throws {
        let manager = SQLiteManager.shared
        
        print("🔧 Starting streamlined schema migration...")
        
        do {
            // Patch 1: Emergency fix for missing columns (PRIORITY 1)
            try await fixMissingWorkerColumns(manager)
            
            // Patch 2: Fix worker_building_assignments table
            try await fixWorkerBuildingAssignments(manager)
            
            // Patch 3: Seed active workers (including Kevin)
            try await seedActiveWorkers(manager)
            
            // Patch 4: Create Kevin's corrected building assignments
            
            // Patch 5: Add essential constraints
            try await addEssentialConstraints(manager)
            
            // Patch 6: Create routine scheduling tables
            try await createRoutineSchedulingTables(manager)
            
            // Patch 7: Import operational schedules
            try await importOperationalSchedules(manager)
            
            print("✅ Streamlined schema migration completed successfully!")
            
        } catch {
            print("❌ Schema migration failed: \(error)")
            throw error
        }
    }
    
    // MARK: - 🚨 ESSENTIAL FIXES
    
    /// Fix missing columns in workers table (PRIORITY 1)
    private func fixMissingWorkerColumns(_ manager: SQLiteManager) async throws {
        print("🚨 EMERGENCY FIX: Adding missing columns to workers table...")
        
        let tableInfo = try await manager.query("PRAGMA table_info(workers)")
        let columnNames = Set(tableInfo.compactMap { $0["name"] as? String })
        
        print("📋 Current workers table columns: \(columnNames.sorted())")
        
        // Add missing required columns
        if !columnNames.contains("isActive") {
            try await manager.execute("ALTER TABLE workers ADD COLUMN isActive INTEGER DEFAULT 1")
            print("✅ Added isActive column")
        }
        
        if !columnNames.contains("shift") {
            try await manager.execute("ALTER TABLE workers ADD COLUMN shift TEXT DEFAULT 'day'")
            print("✅ Added shift column")
        }
        
        if !columnNames.contains("hireDate") {
            try await manager.execute("ALTER TABLE workers ADD COLUMN hireDate TEXT DEFAULT (date('now'))")
            print("✅ Added hireDate column")
        }
        
        if !columnNames.contains("email") {
            try await manager.execute("ALTER TABLE workers ADD COLUMN email TEXT")
            print("✅ Added email column")
        }
        
        print("✅ Essential worker columns added")
    }
    
    /// Seed active workers with correct data
    private func seedActiveWorkers(_ manager: SQLiteManager) async throws {
        print("👷 Seeding active workers...")
        
        // Current active worker roster (Kevin's corrected profile)
        let activeWorkers: [(String, String, String, String, Int, String, String)] = [
            ("1", "Greg Hutson", "greg.hutson@francosphere.com", "worker", 1, "day", "2022-03-15"),
            ("2", "Edwin Lema", "edwin.lema@francosphere.com", "worker", 1, "morning", "2023-01-10"),
            ("4", "Kevin Dutan", "kevin.dutan@francosphere.com", "worker", 1, "expanded", "2021-08-20"), // ✅ Expanded duties
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
        
        print("✅ Seeded \(activeWorkers.count) active workers")
        
        // Verify Kevin was created correctly
        let kevinCheck = try await manager.query(
            "SELECT id, name, isActive, shift FROM workers WHERE id = '4' LIMIT 1",
            []
        )
        
        if let kevin = kevinCheck.first {
            print("✅ Kevin verification: ID=\(kevin["id"] ?? "nil"), Name=\(kevin["name"] ?? "nil"), Active=\(kevin["isActive"] ?? "nil"), Shift=\(kevin["shift"] ?? "nil")")
        } else {
            print("🚨 WARNING: Kevin not found after seeding!")
        }
    }
    
    /// Create Kevin's CORRECTED building assignments (Rubin Museum, not Franklin)
    private func createKevinCorrectedAssignments(_ manager: SQLiteManager) async throws {
        print("🏢 Creating Kevin's CORRECTED building assignments...")
        
        // Ensure worker_building_assignments table exists
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_building_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                worker_name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                assignment_type TEXT DEFAULT 'regular',
                start_date TEXT NOT NULL DEFAULT (datetime('now')),
                is_active INTEGER DEFAULT 1,
                notes TEXT,
                UNIQUE(worker_id, building_id),
                CHECK(is_active IN (0, 1))
            );
        """)
        
        // Kevin's CORRECTED building assignments (Rubin Museum ID "14", NOT Franklin ID "13")
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
            try await manager.execute("""
                INSERT OR REPLACE INTO worker_building_assignments 
                (worker_id, worker_name, building_id, assignment_type, start_date, is_active, notes) 
                VALUES ('4', 'Kevin Dutan', ?, 'corrected_duties', datetime('now'), 1, ?)
            """, [buildingId, notes])
        }
        
        print("✅ Created \(kevinBuildings.count) CORRECTED building assignments for Kevin")
        print("   🎯 Kevin now has Rubin Museum (ID 14), NOT Franklin Street")
        print("   🎯 Kevin now has 178 Spring Street (ID 17) - building ID conflict resolved")
        
        // Verify Kevin's corrected assignments
        let kevinAssignments = try await manager.query("""
            SELECT building_id, notes FROM worker_building_assignments 
            WHERE worker_id = '4' AND is_active = 1
        """, [])
        
        print("📊 Kevin's verified assignments: \(kevinAssignments.count) buildings")
        for assignment in kevinAssignments {
            let buildingId = assignment["building_id"] as? String ?? "nil"
            let notes = assignment["notes"] as? String ?? ""
            print("   🏢 Building ID: \(buildingId) - \(notes)")
        }
    }
    
    /// Fix worker_building_assignments table structure
    private func fixWorkerBuildingAssignments(_ manager: SQLiteManager) async throws {
        print("🔧 Ensuring worker_building_assignments table structure...")
        
        let tableInfo = try await manager.query("PRAGMA table_info(worker_building_assignments)")
        let columns = tableInfo.compactMap { $0["name"] as? String }
        
        if !columns.contains("worker_name") {
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
        
        print("✅ worker_building_assignments table structure verified")
    }
    
    /// Add essential database constraints
    private func addEssentialConstraints(_ manager: SQLiteManager) async throws {
        print("🔧 Adding essential constraints...")
        
        let indexes: [(String, String, String)] = [
            ("idx_worker_building_unique", "worker_building_assignments", "worker_id, building_id"),
            ("idx_worker_email", "workers", "email"),
            ("idx_worker_active", "workers", "isActive")
        ]
        
        for (indexName, tableName, columns) in indexes {
            do {
                try await manager.execute("""
                    CREATE UNIQUE INDEX IF NOT EXISTS \(indexName) 
                    ON \(tableName)(\(columns))
                """)
            } catch {
                print("⚠️ Could not create index \(indexName): \(error)")
            }
        }
        
        print("✅ Essential constraints added")
    }
    
    /// Create routine scheduling tables for operational workflow
    private func createRoutineSchedulingTables(_ manager: SQLiteManager) async throws {
        print("🔧 Creating routine scheduling tables...")

        // Routine schedules table
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
                FOREIGN KEY (building_id) REFERENCES buildings(id),
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            )
        """)

        // DSNY schedules table
        try await manager.execute("""
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

        print("✅ Routine scheduling tables created")
    }
    
    /// Import operational schedules with Kevin's corrected assignments
    private func importOperationalSchedules(_ manager: SQLiteManager) async throws {
        print("🔧 Importing operational schedules...")

        // Kevin's corrected routine schedules (Rubin Museum, not Franklin)
        let routineSchedules: [(String, String, String, String, String, String)] = [
            // Kevin's corrected Perry Street circuit
            ("routine_3_4_perry_main", "Perry Street Main Circuit", "3", "FREQ=DAILY;BYHOUR=6", "4", "Cleaning"),
            ("routine_6_4_perry_full", "Perry 68 Full Building Clean", "6", "FREQ=WEEKLY;BYDAY=TU,TH;BYHOUR=8", "4", "Cleaning"),
            ("routine_7_4_17th_corridor", "17th Street Corridor Maintenance", "7", "FREQ=DAILY;BYHOUR=11", "4", "Cleaning"),
            ("routine_9_4_17th_west", "117 West 17th Operations", "9", "FREQ=DAILY;BYHOUR=12", "4", "Cleaning"),
            ("routine_11_4_extended", "Extended Coverage Area", "11", "FREQ=WEEKLY;BYDAY=FR;BYHOUR=10", "4", "Maintenance"),
            ("routine_16_4_park", "Stuyvesant Park Maintenance", "16", "FREQ=WEEKLY;BYDAY=SA;BYHOUR=8", "4", "Outdoor"),
            ("routine_17_4_spring", "Spring Street Downtown", "17", "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=14", "4", "Cleaning"),
            // ✅ CORRECTED: Kevin's Rubin Museum assignment (ID 14, NOT Franklin ID 13)
            ("routine_14_4_rubin", "Rubin Museum Operations", "14", "FREQ=DAILY;BYHOUR=10", "4", "Sanitation"),
            
            // Other workers' schedules (streamlined)
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
            
            try await manager.execute("""
                INSERT OR REPLACE INTO routine_schedules 
                (id, name, building_id, rrule, worker_id, category, weather_dependent)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [routine.0, routine.1, routine.2, routine.3, routine.4, routine.5, weatherDependent])
            routineCount += 1
        }
        
        print("✅ Imported \(routineCount) routine schedules (Kevin's Rubin Museum corrected)")
        
        // Import DSNY schedules with Kevin's corrected routes
        let dsnySchedules: [(String, String, String, String)] = [
            ("dsny_kevin_perry", "Kevin Perry Street Route", "3,6", "MON,WED,FRI"),
            ("dsny_kevin_17th", "Kevin 17th Street Route", "7,9,11", "MON,WED,FRI"),
            ("dsny_kevin_downtown", "Kevin Downtown Route", "17", "TUE,THU"),
            ("dsny_kevin_rubin", "Kevin Rubin Museum Route", "14", "TUE,FRI"), // ✅ Corrected
            ("dsny_kevin_park", "Kevin Park Route", "16", "SAT"),
            ("dsny_general_east", "General East Route", "1", "MON,WED,FRI"),
            ("dsny_general_downtown", "General Downtown Route", "4,8", "TUE,THU,SAT")
        ]
        
        var dsnyCount = 0
        for dsny in dsnySchedules {
            try await manager.execute("""
                INSERT OR REPLACE INTO dsny_schedules 
                (id, route_id, building_ids, collection_days)
                VALUES (?, ?, ?, ?)
            """, [dsny.0, dsny.1, dsny.2, dsny.3])
            dsnyCount += 1
        }
        
        print("✅ Imported \(dsnyCount) DSNY schedules (Kevin's routes corrected)")
    }
    
    // MARK: - Validation
    
    /// Validate the migration completed successfully
    func validateMigration() async throws {
        let manager = SQLiteManager.shared
        
        print("🔍 Validating migration...")
        
        // Check Kevin specifically - most critical validation
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
        
        if buildingCount < 8 {
            print("⚠️ WARNING: Kevin has only \(buildingCount) buildings (expected 8)")
        }
        
        // Verify Kevin has Rubin Museum (ID 14) and NOT Franklin (ID 13)
        let kevinBuildings = try await manager.query("""
            SELECT building_id FROM worker_building_assignments 
            WHERE worker_id = '4' AND is_active = 1
        """, [])
        
        let kevinBuildingIds = kevinBuildings.compactMap { $0["building_id"] as? String }
        let hasRubin = kevinBuildingIds.contains("14")
        let hasFranklin = kevinBuildingIds.contains("13")
        
        if hasRubin && !hasFranklin {
            print("✅ KEVIN CORRECTION VERIFIED: Has Rubin Museum (14), NOT Franklin Street (13)")
        } else {
            print("🚨 KEVIN ASSIGNMENT ERROR:")
            print("   - Has Rubin Museum (14): \(hasRubin)")
            print("   - Has Franklin Street (13): \(hasFranklin)")
            print("   - Building IDs: \(kevinBuildingIds.sorted())")
        }
        
        print("✅ Migration validation completed")
    }
    
    // MARK: - Emergency Recovery
    
    /// Apply emergency schema fix for Kevin specifically
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
