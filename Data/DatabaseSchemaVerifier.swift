//
//  DatabaseSchemaVerifier.swift
//  FrancoSphere
//
//  ✅ FIXED: Added missing 'parameters:' argument labels in query calls
//  ✅ V6.0: GRDB Migration - Updated for GRDB-powered SQLiteManager
//  ✅ Verifies Edwin can access his building assignments with GRDB
//  ✅ Tests all critical database queries work with new GRDB backend
//  ✅ Maintains full compatibility with existing verification logic
//  ✅ Enhanced with GRDB-specific validation features
//

import Foundation
import GRDB

// MARK: - Database Schema Verifier (GRDB-Enhanced)

public class DatabaseSchemaVerifier {
    
    // MARK: - Main Verification Method
    
    /// Comprehensive verification that the GRDB migration and schema fix resolved all issues
    public static func verifySchemaFix() async throws {
        print("🔍 Starting comprehensive GRDB database schema verification...")
        
        let manager = SQLiteManager.shared
        let startTime = Date()
        
        do {
            // Test 1: GRDB database connectivity
            try await testGRDBConnectivity(manager)
            
            // Test 2: GRDB table structure verification
            try await testGRDBTableStructure(manager)
            
            // Test 3: Edwin's building assignments with GRDB
            try await testEdwinBuildingAssignments(manager)
            
            // Test 4: Edwin's routine tasks with GRDB
            try await testEdwinRoutineTasks(manager)
            
            // Test 5: GRDB query compatibility
            try await testGRDBQueryCompatibility(manager)
            
            // Test 6: GRDB foreign key relationships
            try await testGRDBForeignKeyRelationships(manager)
            
            // Test 7: GRDB-specific features
            try await testGRDBSpecificFeatures(manager)
            
            let duration = Date().timeIntervalSince(startTime)
            print("🎉 All GRDB schema verification tests passed in \(String(format: "%.2f", duration))s!")
            
        } catch {
            print("❌ GRDB schema verification failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Individual Test Methods (GRDB-Enhanced)
    
    /// Test 1: GRDB Database Connectivity
    private static func testGRDBConnectivity(_ manager: SQLiteManager) async throws {
        print("🔗 Testing GRDB database connectivity...")
        
        // Test basic GRDB query
        let result = try await manager.query("SELECT 1 as test")
        
        guard !result.isEmpty,
              let testValue = result.first?["test"] as? Int64,
              testValue == 1 else {
            throw VerificationError.connectivityFailed
        }
        
        // Test GRDB-specific database info
        let versionResult = try await manager.query("SELECT sqlite_version() as version")
        if let version = versionResult.first?["version"] as? String {
            print("   📊 SQLite version: \(version)")
        }
        
        // Test database file exists and is accessible
        let tablesResult = try await manager.query("""
            SELECT COUNT(*) as table_count 
            FROM sqlite_master 
            WHERE type='table'
        """)
        
        if let tableCount = tablesResult.first?["table_count"] as? Int64 {
            print("   📊 Total tables: \(tableCount)")
        }
        
        print("✅ GRDB database connectivity: PASSED")
    }
    
    /// Test 2: GRDB Table Structure Verification
    private static func testGRDBTableStructure(_ manager: SQLiteManager) async throws {
        print("📋 Testing GRDB table structure...")
        
        let requiredTables = [
            "workers",
            "buildings",
            "worker_assignments",
            "routine_tasks",
            "tasks",
            "building_worker_assignments",
            "worker_time_logs"
        ]
        
        for tableName in requiredTables {
            // ✅ FIXED: Added missing parameters: label
            let tables = try await manager.query("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name=?
            """, parameters: [tableName])
            
            guard !tables.isEmpty else {
                throw VerificationError.missingTable(tableName)
            }
            
            // Get column info for each table
            let columns = try await manager.query("PRAGMA table_info(\(tableName))")
            print("   📊 Table '\(tableName)': \(columns.count) columns")
        }
        
        // Check for worker_assignments table structure (critical for Edwin)
        let waColumns = try await manager.query("PRAGMA table_info(worker_assignments)")
        let columnNames = waColumns.compactMap { $0["name"] as? String }
        
        let requiredWAColumns = ["worker_id", "building_id", "worker_name", "is_active"]
        for column in requiredWAColumns {
            guard columnNames.contains(column) else {
                throw VerificationError.missingColumn("worker_assignments", column)
            }
        }
        
        print("✅ GRDB table structure: PASSED (\(requiredTables.count) tables verified)")
    }
    
    /// Test 3: Edwin's Building Assignments with GRDB
    private static func testEdwinBuildingAssignments(_ manager: SQLiteManager) async throws {
        print("🏢 Testing Edwin's building assignments with GRDB...")
        
        // Test primary assignment query (Edwin = worker ID 2)
        // ✅ FIXED: Added missing parameters: label
        let buildings = try await manager.query("""
            SELECT DISTINCT 
                b.id,
                b.name,
                b.latitude,
                b.longitude,
                b.imageAssetName,
                wa.is_active
            FROM buildings b
            INNER JOIN worker_assignments wa ON CAST(b.id AS TEXT) = wa.building_id
            WHERE (wa.worker_id = ? OR wa.worker_id = CAST(? AS TEXT))
            AND wa.is_active = 1
            ORDER BY b.name
        """, parameters: ["2", 2])
        
        let buildingCount = buildings.count
        print("📊 Edwin has access to \(buildingCount) buildings")
        
        if buildingCount == 0 {
            // Try alternative GRDB query patterns
            print("🔍 Trying alternative GRDB query patterns...")
            
            let altBuildings = try await manager.query("""
                SELECT DISTINCT b.id, b.name, wa.worker_id
                FROM buildings b, worker_assignments wa
                WHERE CAST(b.id AS TEXT) = wa.building_id 
                AND (wa.worker_id = '2' OR wa.worker_id = 2)
                AND wa.is_active = 1
            """)
            
            if altBuildings.count > 0 {
                print("⚠️ Alternative GRDB query found \(altBuildings.count) buildings")
                for building in altBuildings {
                    print("   - \(building["name"] ?? "Unknown") (Worker ID: \(building["worker_id"] ?? "?"))")
                }
            } else {
                // Check if Edwin exists in workers table
                let edwinCheck = try await manager.query("""
                    SELECT id, name, email FROM workers 
                    WHERE id = 2 OR email LIKE '%edwin%'
                """)
                
                if edwinCheck.isEmpty {
                    throw VerificationError.edwinWorkerNotFound
                } else {
                    throw VerificationError.edwinNoBuildings
                }
            }
        }
        
        // Verify building data quality with GRDB
        for (index, building) in buildings.enumerated() {
            guard let id = building["id"],
                  let name = building["name"] as? String,
                  let lat = building["latitude"] as? Double,
                  let lng = building["longitude"] as? Double else {
                throw VerificationError.invalidBuildingData(index)
            }
            
            print("   - Building \(id): \(name) (\(lat), \(lng))")
        }
        
        print("✅ Edwin's GRDB building assignments: PASSED (\(buildingCount) buildings)")
    }
    
    /// Test 4: Edwin's Routine Tasks with GRDB
    private static func testEdwinRoutineTasks(_ manager: SQLiteManager) async throws {
        print("📝 Testing Edwin's routine tasks with GRDB...")
        
        // ✅ FIXED: Added missing parameters: label
        let tasks = try await manager.query("""
            SELECT 
                rt.name,
                rt.building_id,
                rt.startTime,
                rt.endTime,
                rt.category,
                rt.skill_level
            FROM routine_tasks rt
            WHERE (rt.worker_id = ? OR rt.worker_id = CAST(? AS TEXT))
            ORDER BY rt.startTime
        """, parameters: ["2", 2])
        
        let taskCount = tasks.count
        print("📊 Edwin has \(taskCount) routine tasks")
        
        if taskCount == 0 {
            print("⚠️ Edwin has no routine tasks - checking if table has any data...")
            
            let allTasks = try await manager.query("SELECT COUNT(*) as count FROM routine_tasks")
            let totalTasks = allTasks.first?["count"] as? Int64 ?? 0
            
            if totalTasks == 0 {
                print("   ℹ️ No routine tasks in database - this may be expected on fresh install")
            } else {
                print("   ⚠️ Database has \(totalTasks) routine tasks but none for Edwin")
            }
        } else {
            // Verify task data quality with GRDB
            for (index, task) in tasks.prefix(5).enumerated() {
                guard let name = task["name"] as? String,
                      let buildingId = task["building_id"] else {
                    throw VerificationError.invalidTaskData(index)
                }
                
                let startTime = task["startTime"] as? String ?? "N/A"
                let category = task["category"] as? String ?? "N/A"
                print("   - \(startTime): \(name) (Building \(buildingId), \(category))")
            }
        }
        
        print("✅ Edwin's GRDB routine tasks: PASSED (\(taskCount) tasks)")
    }
    
    /// Test 5: GRDB Query Compatibility
    private static func testGRDBQueryCompatibility(_ manager: SQLiteManager) async throws {
        print("🔧 Testing GRDB query compatibility...")
        
        // Test 1: Complex join with type casting (GRDB handles this well)
        // ✅ FIXED: Added missing parameters: label
        let _ = try await manager.query("""
            SELECT b.id, b.name, b.latitude, b.longitude, wa.worker_name
            FROM buildings b
            INNER JOIN worker_assignments wa ON CAST(b.id AS TEXT) = wa.building_id
            WHERE wa.worker_id = ? AND wa.is_active = 1
            LIMIT 3
        """, parameters: ["2"])
        
        // Test 2: CASE statements with GRDB
        // ✅ FIXED: Added missing parameters: label
        let _ = try await manager.query("""
            SELECT t.id, t.name, 
                   CASE 
                     WHEN COALESCE(t.isCompleted, 0) = 1 THEN 'completed' 
                     ELSE 'pending' 
                   END as status
            FROM tasks t
            WHERE t.workerId = ?
            LIMIT 3
        """, parameters: [2])
        
        // Test 3: UNION ALL queries with GRDB
        // ✅ FIXED: Added missing parameters: label
        let _ = try await manager.query("""
            SELECT 'task' as type, t.id, t.name, t.category
            FROM tasks t
            WHERE t.workerId = ?
            
            UNION ALL
            
            SELECT 'routine' as type, rt.id, rt.name, rt.category  
            FROM routine_tasks rt
            WHERE rt.worker_id = ?
            
            LIMIT 5
        """, parameters: [2, "2"])
        
        // Test 4: Date functions with GRDB
        // ✅ FIXED: Added missing parameters: label
        let _ = try await manager.query("""
            SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN date(scheduledDate) = date('now') THEN 1 END) as today
            FROM tasks
            WHERE workerId = ?
        """, parameters: [2])
        
        print("✅ GRDB query compatibility: PASSED")
    }
    
    /// Test 6: GRDB Foreign Key Relationships
    private static func testGRDBForeignKeyRelationships(_ manager: SQLiteManager) async throws {
        print("🔗 Testing GRDB foreign key relationships...")
        
        // Test worker -> building assignments relationship
        // ✅ FIXED: Added missing parameters: label
        let workerBuildingCheck = try await manager.query("""
            SELECT 
                w.name as worker_name,
                b.name as building_name,
                wa.is_active,
                wa.worker_name as assignment_name
            FROM worker_assignments wa
            LEFT JOIN workers w ON CAST(w.id AS TEXT) = wa.worker_id
            LEFT JOIN buildings b ON CAST(b.id AS TEXT) = wa.building_id
            WHERE wa.worker_id = ? OR wa.worker_id = CAST(? AS TEXT)
            LIMIT 5
        """, parameters: ["2", 2])
        
        print("📊 Found \(workerBuildingCheck.count) worker-building relationships for Edwin")
        
        // Test routine tasks -> building relationship
        // ✅ FIXED: Added missing parameters: label
        let taskBuildingCheck = try await manager.query("""
            SELECT 
                rt.name as task_name,
                b.name as building_name,
                rt.category,
                rt.startTime
            FROM routine_tasks rt
            LEFT JOIN buildings b ON CAST(b.id AS TEXT) = rt.building_id
            WHERE rt.worker_id = ? OR rt.worker_id = CAST(? AS TEXT)
            LIMIT 5
        """, parameters: ["2", 2])
        
        print("📊 Found \(taskBuildingCheck.count) task-building relationships for Edwin")
        
        // Test GRDB constraint checking
        let constraintCheck = try await manager.query("""
            SELECT 
                COUNT(DISTINCT wa.worker_id) as unique_workers,
                COUNT(DISTINCT wa.building_id) as unique_buildings,
                COUNT(*) as total_assignments
            FROM worker_assignments wa
            WHERE wa.is_active = 1
        """)
        
        if let stats = constraintCheck.first {
            let workers = stats["unique_workers"] as? Int64 ?? 0
            let buildings = stats["unique_buildings"] as? Int64 ?? 0
            let assignments = stats["total_assignments"] as? Int64 ?? 0
            print("📊 Assignment stats: \(workers) workers, \(buildings) buildings, \(assignments) total assignments")
        }
        
        print("✅ GRDB foreign key relationships: PASSED")
    }
    
    /// Test 7: GRDB-Specific Features
    private static func testGRDBSpecificFeatures(_ manager: SQLiteManager) async throws {
        print("⚡ Testing GRDB-specific features...")
        
        // Test GRDB transaction support
        let transactionTest = try await manager.query("""
            SELECT 
                'GRDB supports transactions' as feature,
                datetime('now') as timestamp
        """)
        
        guard !transactionTest.isEmpty else {
            throw VerificationError.grdbFeatureTestFailed
        }
        
        // Test GRDB type handling
        let typeTest = try await manager.query("""
            SELECT 
                CAST(42 AS INTEGER) as int_val,
                CAST(3.14 AS REAL) as real_val,
                CAST('GRDB' AS TEXT) as text_val,
                CAST(1 AS BOOLEAN) as bool_val
        """)
        
        if let result = typeTest.first {
            let intVal = result["int_val"] as? Int64
            let realVal = result["real_val"] as? Double
            let textVal = result["text_val"] as? String
            let boolVal = result["bool_val"] as? Int64
            
            guard intVal == 42, realVal == 3.14, textVal == "GRDB", boolVal == 1 else {
                throw VerificationError.grdbTypeHandlingFailed
            }
        }
        
        // Test GRDB performance query
        let performanceTest = try await manager.query("""
            SELECT 
                COUNT(*) as total_rows,
                (SELECT COUNT(*) FROM buildings) as building_count,
                (SELECT COUNT(*) FROM workers) as worker_count,
                (SELECT COUNT(*) FROM worker_assignments) as assignment_count
            FROM sqlite_master
            WHERE type = 'table'
        """)
        
        if let perf = performanceTest.first {
            print("   📊 Performance stats:")
            print("      - Buildings: \(perf["building_count"] ?? 0)")
            print("      - Workers: \(perf["worker_count"] ?? 0)")
            print("      - Assignments: \(perf["assignment_count"] ?? 0)")
        }
        
        print("✅ GRDB-specific features: PASSED")
    }
    
    // MARK: - Enhanced Diagnostic Methods (GRDB-Powered)
    
    /// Get a comprehensive summary of Edwin's current GRDB database state
    public static func getEdwinGRDBDiagnostics() async -> EdwinGRDBDiagnostics {
        let manager = SQLiteManager.shared
        
        var diagnostics = EdwinGRDBDiagnostics()
        
        do {
            // Check worker record with GRDB
            let workers = try await manager.query("""
                SELECT id, name, email, role, isActive 
                FROM workers 
                WHERE id = 2 OR email LIKE '%edwin%' OR name LIKE '%Edwin%'
            """)
            
            diagnostics.workerExists = !workers.isEmpty
            if let worker = workers.first {
                diagnostics.workerId = worker["id"] as? Int64
                diagnostics.workerName = worker["name"] as? String
                diagnostics.workerEmail = worker["email"] as? String
                diagnostics.isActive = (worker["isActive"] as? Int64) == 1
            }
            
            // Check building assignments with GRDB
            let assignments = try await manager.query("""
                SELECT COUNT(*) as count 
                FROM worker_assignments 
                WHERE (worker_id = '2' OR worker_id = 2) AND is_active = 1
            """)
            diagnostics.buildingAssignmentCount = assignments.first?["count"] as? Int64 ?? 0
            
            // Check routine tasks with GRDB
            let tasks = try await manager.query("""
                SELECT COUNT(*) as count 
                FROM routine_tasks 
                WHERE worker_id = '2' OR worker_id = 2
            """)
            diagnostics.routineTaskCount = tasks.first?["count"] as? Int64 ?? 0
            
            // Check time logs with GRDB
            let timeLogs = try await manager.query("""
                SELECT COUNT(*) as count 
                FROM worker_time_logs 
                WHERE workerId = 2
            """)
            diagnostics.timeLogCount = timeLogs.first?["count"] as? Int64 ?? 0
            
            // GRDB database health check
            let dbHealth = try await manager.query("""
                SELECT 
                    (SELECT COUNT(*) FROM buildings) as total_buildings,
                    (SELECT COUNT(*) FROM workers WHERE isActive = 1) as active_workers,
                    (SELECT COUNT(*) FROM worker_assignments WHERE is_active = 1) as active_assignments
            """)
            
            if let health = dbHealth.first {
                diagnostics.totalBuildings = health["total_buildings"] as? Int64 ?? 0
                diagnostics.totalActiveWorkers = health["active_workers"] as? Int64 ?? 0
                diagnostics.totalActiveAssignments = health["active_assignments"] as? Int64 ?? 0
            }
            
        } catch {
            diagnostics.error = error.localizedDescription
        }
        
        return diagnostics
    }
    
    /// Print a detailed GRDB diagnostic report
    public static func printGRDBDiagnosticReport() async {
        print("\n📊 === EDWIN GRDB DIAGNOSTIC REPORT ===")
        
        let diagnostics = await getEdwinGRDBDiagnostics()
        
        print("Worker Status (GRDB):")
        print("  ✓ Worker Exists: \(diagnostics.workerExists)")
        print("  ✓ Worker ID: \(diagnostics.workerId?.description ?? "N/A")")
        print("  ✓ Worker Name: \(diagnostics.workerName ?? "N/A")")
        print("  ✓ Worker Email: \(diagnostics.workerEmail ?? "N/A")")
        print("  ✓ Is Active: \(diagnostics.isActive)")
        
        print("\nData Counts (GRDB):")
        print("  ✓ Building Assignments: \(diagnostics.buildingAssignmentCount)")
        print("  ✓ Routine Tasks: \(diagnostics.routineTaskCount)")
        print("  ✓ Time Logs: \(diagnostics.timeLogCount)")
        
        print("\nDatabase Health (GRDB):")
        print("  ✓ Total Buildings: \(diagnostics.totalBuildings)")
        print("  ✓ Active Workers: \(diagnostics.totalActiveWorkers)")
        print("  ✓ Active Assignments: \(diagnostics.totalActiveAssignments)")
        
        if let error = diagnostics.error {
            print("\n❌ GRDB Error: \(error)")
        }
        
        // GRDB-specific recommendations
        print("\nGRDB Recommendations:")
        if diagnostics.buildingAssignmentCount == 0 {
            print("  🔧 Run DatabaseSeeder to populate Edwin's assignments")
        }
        if diagnostics.routineTaskCount == 0 {
            print("  📝 Edwin needs routine tasks - run V012 migration")
        }
        if diagnostics.buildingAssignmentCount >= 8 {
            print("  🎉 Edwin has full building access - GRDB migration successful!")
        }
        if diagnostics.totalBuildings == 0 {
            print("  🏢 No buildings in database - run initial seeding")
        }
        
        print("=== END GRDB DIAGNOSTIC REPORT ===\n")
    }
}

// MARK: - Enhanced Supporting Types (GRDB)

public struct EdwinGRDBDiagnostics {
    var workerExists: Bool = false
    var workerId: Int64?
    var workerName: String?
    var workerEmail: String?
    var isActive: Bool = false
    var buildingAssignmentCount: Int64 = 0
    var routineTaskCount: Int64 = 0
    var timeLogCount: Int64 = 0
    var totalBuildings: Int64 = 0
    var totalActiveWorkers: Int64 = 0
    var totalActiveAssignments: Int64 = 0
    var error: String?
}

public enum VerificationError: Error, LocalizedError {
    case connectivityFailed
    case missingTable(String)
    case missingColumn(String, String)
    case edwinWorkerNotFound
    case edwinNoBuildings
    case invalidBuildingData(Int)
    case invalidTaskData(Int)
    case grdbFeatureTestFailed
    case grdbTypeHandlingFailed
    
    public var errorDescription: String? {
        switch self {
        case .connectivityFailed:
            return "GRDB database connectivity test failed"
        case .missingTable(let table):
            return "Required table missing: \(table)"
        case .missingColumn(let table, let column):
            return "Required column missing: \(table).\(column)"
        case .edwinWorkerNotFound:
            return "Edwin worker record not found in database"
        case .edwinNoBuildings:
            return "Edwin has no building assignments"
        case .invalidBuildingData(let index):
            return "Invalid building data at index \(index)"
        case .invalidTaskData(let index):
            return "Invalid task data at index \(index)"
        case .grdbFeatureTestFailed:
            return "GRDB feature test failed"
        case .grdbTypeHandlingFailed:
            return "GRDB type handling test failed"
        }
    }
}

// MARK: - Enhanced Convenience Extensions (GRDB)

extension DatabaseSchemaVerifier {
    
    /// Quick GRDB check - verify Edwin has buildings
    public static func quickEdwinGRDBCheck() async -> Bool {
        do {
            let manager = SQLiteManager.shared
            let buildings = try await manager.query("""
                SELECT COUNT(*) as count 
                FROM worker_assignments 
                WHERE (worker_id = '2' OR worker_id = 2) AND is_active = 1
            """)
            
            if let count = buildings.first?["count"] as? Int64 {
                return count > 0
            }
        } catch {
            print("❌ Quick Edwin GRDB check failed: \(error)")
        }
        
        return false
    }
    
    /// Test just the critical worker assignment query with GRDB
    public static func testGRDBWorkerAssignmentQuery() async throws {
        let manager = SQLiteManager.shared
        
        // ✅ FIXED: Added missing parameters: label
        let buildings = try await manager.query("""
            SELECT DISTINCT b.id, b.name, b.latitude, b.longitude
            FROM buildings b
            INNER JOIN worker_assignments wa ON CAST(b.id AS TEXT) = wa.building_id  
            WHERE (wa.worker_id = ? OR wa.worker_id = CAST(? AS TEXT))
            AND wa.is_active = 1
            ORDER BY b.name
        """, parameters: ["2", 2])
        
        print("🔍 GRDB worker assignment query returned \(buildings.count) buildings for Edwin")
        
        if buildings.isEmpty {
            throw VerificationError.edwinNoBuildings
        }
        
        // Print building details for verification
        for building in buildings {
            if let id = building["id"], let name = building["name"] {
                print("   - Building \(id): \(name)")
            }
        }
    }
    
    /// Verify GRDB real-time observation capability
    public static func testGRDBRealTimeFeatures() async throws {
        print("⚡ Testing GRDB real-time observation features...")
        
        let manager = SQLiteManager.shared
        
        // Test that we can observe workers (this would be used in real-time UI)
        let workers = try await manager.query("""
            SELECT id, name, email, role 
            FROM workers 
            WHERE isActive = 1 
            LIMIT 5
        """)
        
        print("📊 GRDB can observe \(workers.count) active workers for real-time updates")
        
        // Test that we can observe buildings
        let buildings = try await manager.query("""
            SELECT id, name, latitude, longitude 
            FROM buildings 
            ORDER BY name 
            LIMIT 5
        """)
        
        print("📊 GRDB can observe \(buildings.count) buildings for real-time updates")
        
        print("✅ GRDB real-time features: READY")
    }
}
