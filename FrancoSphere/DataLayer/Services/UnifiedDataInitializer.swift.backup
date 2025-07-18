//
//  UnifiedDataInitializer.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ CONSOLIDATED: Single source of truth for all data initialization
//  ✅ REFACTORED: Combines best parts of existing seeders
//  ✅ FIXED: Proper initialization order and dependencies
//

import Foundation
import SwiftUI

@MainActor
public class UnifiedDataInitializer: ObservableObject {
    public static let shared = UnifiedDataInitializer()
    
    @Published public var isInitialized = false
    @Published public var initializationProgress: Double = 0.0
    @Published public var currentStep = ""
    @Published public var error: Error?
    
    private let grdb = GRDBManager.shared
    private let operationalData = OperationalDataManager.shared
    
    private init() {}
    
    // MARK: - Main Initialization
    
    public func initializeIfNeeded() async throws {
        // Check if already initialized
        guard !UserDefaults.standard.bool(forKey: "UnifiedDataInitialized_v6") else {
            print("✅ Data already initialized")
            isInitialized = true
            
            // Auto-login for development
            #if DEBUG
            await autoLoginDefaultWorker()
            #endif
            
            return
        }
        
        print("🚀 Starting unified data initialization...")
        
        do {
            // Step 1: Database Setup
            currentStep = "Setting up database..."
            initializationProgress = 0.1
            try await setupDatabase()
            
            // Step 2: Schema & Migrations
            currentStep = "Running migrations..."
            initializationProgress = 0.3
            try await runMigrations()
            
            // Step 3: Operational Data
            currentStep = "Loading operational data..."
            initializationProgress = 0.5
            try await initializeOperationalData()
            
            // Step 4: Seed Real Data
            currentStep = "Seeding real-world data..."
            initializationProgress = 0.7
            try await seedRealWorldData()
            
            // Step 5: Verify Integrity
            currentStep = "Verifying data integrity..."
            initializationProgress = 0.9
            let stats = try await verifyDataIntegrity()
            
            // Step 6: Mark Complete
            UserDefaults.standard.set(true, forKey: "UnifiedDataInitialized_v6")
            UserDefaults.standard.synchronize()
            
            currentStep = "Initialization complete!"
            initializationProgress = 1.0
            isInitialized = true
            
            print("✅ Unified initialization complete: \(stats)")
            
            // Auto-login for development
            #if DEBUG
            await autoLoginDefaultWorker()
            #endif
            
        } catch {
            self.error = error
            currentStep = "Failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Step 1: Database Setup
    
    private func setupDatabase() async throws {
        if !grdb.isDatabaseReady() {
            grdb.quickInitialize()
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        print("✅ Database setup complete")
    }
    
    // MARK: - Step 2: Schema & Migrations
    
    private func runMigrations() async throws {
        // Create all tables with proper schema
        try await grdb.execute("""
            -- Workers table
            CREATE TABLE IF NOT EXISTS workers (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                role TEXT DEFAULT 'worker',
                isActive INTEGER DEFAULT 1,
                hourlyRate REAL DEFAULT 25.0,
                created_at TEXT DEFAULT (datetime('now'))
            );
            
            -- Buildings table
            CREATE TABLE IF NOT EXISTS buildings (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                address TEXT,
                latitude REAL,
                longitude REAL,
                imageAssetName TEXT,
                category TEXT DEFAULT 'commercial',
                created_at TEXT DEFAULT (datetime('now'))
            );
            
            -- Worker assignments
            CREATE TABLE IF NOT EXISTS worker_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                is_primary INTEGER DEFAULT 0,
                is_active INTEGER DEFAULT 1,
                assigned_date TEXT DEFAULT (datetime('now')),
                FOREIGN KEY (worker_id) REFERENCES workers(id),
                FOREIGN KEY (building_id) REFERENCES buildings(id),
                UNIQUE(worker_id, building_id)
            );
            
            -- Tasks table
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT,
                building_id TEXT,
                worker_id TEXT,
                category TEXT DEFAULT 'maintenance',
                urgency TEXT DEFAULT 'normal',
                status TEXT DEFAULT 'pending',
                created_at TEXT DEFAULT (datetime('now')),
                completed_at TEXT,
                FOREIGN KEY (building_id) REFERENCES buildings(id),
                FOREIGN KEY (worker_id) REFERENCES workers(id)
            );
            
            -- App settings
            CREATE TABLE IF NOT EXISTS app_settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                updated_at TEXT DEFAULT (datetime('now'))
            );
        """)
        
        print("✅ Schema migrations complete")
    }
    
    // MARK: - Step 3: Operational Data
    
    private func initializeOperationalData() async throws {
        if !operationalData.isInitialized {
            try await operationalData.initializeOperationalData()
        }
        
        // FIXED: Import routines and DSNY data with correct tuple unpacking
        let (imported, dsnyCount) = try await operationalData.importRoutinesAndDSNY()
        print("✅ Imported \(imported) operational records, \(dsnyCount) DSNY schedules")
    }
    
    // MARK: - Step 4: Seed Real World Data
    
    private func seedRealWorldData() async throws {
        // Seed Workers (using real names from WorkerConstants)
        try await seedWorkers()
        
        // Seed Buildings (real portfolio)
        try await seedBuildings()
        
        // Seed Assignments (worker-building relationships)
        try await seedAssignments()
        
        // Seed Initial Tasks
        try await seedInitialTasks()
        
        print("✅ Real world data seeded")
    }
    
    private func seedWorkers() async throws {
        // Use REAL worker data from WorkerConstants
        let workers = [
            ("1", WorkerConstants.workerNames["1"]!, WorkerConstants.workerEmails["1"]!, "worker"),
            ("2", WorkerConstants.workerNames["2"]!, WorkerConstants.workerEmails["2"]!, "worker"),
            ("4", WorkerConstants.workerNames["4"]!, WorkerConstants.workerEmails["4"]!, "worker"),
            ("5", WorkerConstants.workerNames["5"]!, WorkerConstants.workerEmails["5"]!, "worker"),
            ("6", WorkerConstants.workerNames["6"]!, WorkerConstants.workerEmails["6"]!, "worker"),
            ("7", WorkerConstants.workerNames["7"]!, WorkerConstants.workerEmails["7"]!, "worker"),
            ("8", WorkerConstants.workerNames["8"]!, WorkerConstants.workerEmails["8"]!, "worker")
        ]
        
        for worker in workers {
            try await grdb.execute("""
                INSERT OR REPLACE INTO workers (id, name, email, password, role, isActive)
                VALUES (?, ?, ?, 'password', ?, 1)
            """, [worker.0, worker.1, worker.2, worker.3])
        }
        
        print("✅ Seeded \(workers.count) workers with real names from WorkerConstants")
    }
    
    private func seedBuildings() async throws {
        // Get unique building names from OperationalDataManager via public methods
        let buildingCoverage = operationalData.getBuildingCoverage()
        let uniqueBuildings = Set(buildingCoverage.keys)
        
        // CORRECTED: Real Franco Management portfolio addresses
        let buildingData: [(String, String, String, Double, Double, String)] = [
            ("1", "12 West 18th Street", "12 W 18th St", 40.738976, -73.992345, "12_West_18th_Street"),
            ("2", "29-31 East 20th Street", "29-31 E 20th St", 40.739567, -73.989123, "29_31_East_20th_Street"),
            ("3", "135-139 West 17th Street", "135-139 W 17th St", 40.739654, -73.996789, "135West17thStreet"),
            ("4", "104 Franklin Street", "104 Franklin St", 40.719234, -74.009876, "104_Franklin_Street"),
            ("5", "138 West 17th Street", "138 W 17th St", 40.739876, -73.996543, "138West17thStreet"),
            ("6", "68 Perry Street", "68 Perry St", 40.735123, -74.004567, "68_Perry_Street"),
            ("7", "112 West 18th Street", "112 W 18th St", 40.740123, -73.995432, "112_West_18th_Street"),
            ("8", "41 Elizabeth Street", "41 Elizabeth St", 40.718456, -73.995123, "41_Elizabeth_Street"),
            ("9", "117 West 17th Street", "117 W 17th St", 40.739432, -73.995678, "117_West_17th_Street"),
            ("10", "131 Perry Street", "131 Perry St", 40.735678, -74.003456, "131_Perry_Street"),
            ("11", "123 1st Avenue", "123 1st Ave", 40.722890, -73.984567, "123_1st_Avenue"),
            ("13", "136 West 17th Street", "136 W 17th St", 40.739321, -73.996123, "136_West_17th_Street"),
            ("14", "Rubin Museum (142-148 West 17th Street)", "142-148 W 17th St", 40.740567, -73.997890, "Rubin_Museum_142_148_West_17th_Street"),
            ("15", "133 East 15th Street", "133 E 15th St", 40.734567, -73.985432, "133_East_15th_Street"),
            ("16", "Stuyvesant Cove Park", "FDR Drive & E 20th St", 40.731234, -73.971456, "Stuyvesant_Cove_Park"),
            ("17", "178 Spring Street", "178 Spring St", 40.724567, -73.996123, "178_Spring_Street"),
            ("18", "36 Walker Street", "36 Walker St", 40.718234, -74.001234, "36_Walker_Street"),
            ("19", "115 7th Avenue", "115 7th Ave", 40.740000, -73.995000, "115_7th_Avenue"),
            ("20", "FrancoSphere HQ", "Management Office", 40.740000, -73.990000, "FrancoSphere_HQ")
        ]
        
        for building in buildingData {
            try await grdb.execute("""
                INSERT OR REPLACE INTO buildings (id, name, address, latitude, longitude, imageAssetName)
                VALUES (?, ?, ?, ?, ?, ?)
            """, [building.0, building.1, building.2, building.3, building.4, building.5])
        }
        
        print("✅ Seeded \(buildingData.count) buildings from operational data")
        print("📊 Found \(uniqueBuildings.count) unique buildings in tasks: \(uniqueBuildings)")
    }
    
    private func seedAssignments() async throws {
        // FIXED: Create assignments based on REAL operational data using public API
        let workerBuildingMap = operationalData.getBuildingCoverage()
        
        // Process each worker's assignments from operational data
        for (workerId, workerName) in WorkerConstants.workerNames {
            // Find all buildings this worker has tasks at using public data
            var assignedBuildings = Set<String>()
            
            // Use the building coverage map to find worker assignments
            for (buildingName, workers) in workerBuildingMap {
                if workers.contains(workerName) {
                    assignedBuildings.insert(buildingName)
                }
            }
            
            // Map building names to IDs and create assignments
            for buildingName in assignedBuildings {
                if let buildingId = await getBuildingIdForName(buildingName) {
                    // Determine if this is primary building (first one or special cases)
                    let isPrimary = determinePrimaryBuilding(workerId: workerId, buildingName: buildingName)
                    
                    try await grdb.execute("""
                        INSERT OR REPLACE INTO worker_assignments (worker_id, building_id, is_primary)
                        VALUES (?, ?, ?)
                    """, [workerId, buildingId, isPrimary ? 1 : 0])
                    
                    print("✅ Assigned \(workerName) to \(buildingName) (primary: \(isPrimary))")
                }
            }
        }
        
        print("✅ Seeded worker assignments from operational data")
    }
    
    private func getBuildingIdForName(_ name: String) async -> String? {
        // CORRECTED: Map operational building names to actual Franco Management IDs
        let buildingMap: [String: String] = [
            "12 West 18th Street": "1",
            "29-31 East 20th Street": "2",
            "135-139 West 17th Street": "3",
            "104 Franklin Street": "4",
            "138 West 17th Street": "5",
            "68 Perry Street": "6",
            "112 West 18th Street": "7",
            "41 Elizabeth Street": "8",
            "117 West 17th Street": "9",
            "131 Perry Street": "10",
            "123 1st Avenue": "11",
            "136 West 17th Street": "13",
            "Rubin Museum (142-148 West 17th Street)": "14",
            "Rubin Museum (142–148 W 17th)": "14",
            "Rubin Museum": "14",
            "133 East 15th Street": "15",
            "Stuyvesant Cove Park": "16",
            "178 Spring Street": "17",
            "36 Walker Street": "18",
            "115 7th Avenue": "19",
            "FrancoSphere HQ": "20"
        ]
        
        // Try exact match first
        if let id = buildingMap[name] {
            return id
        }
        
        // Try partial match
        for (buildingName, id) in buildingMap {
            if name.contains(buildingName) || buildingName.contains(name) {
                return id
            }
        }
        
        return nil
    }
    
    private func determinePrimaryBuilding(workerId: String, buildingName: String) -> Bool {
        // CORRECTED: Use operational data patterns with correct building names
        switch workerId {
        case "4": // Kevin Dutan - Rubin Museum specialist
            return buildingName.contains("Rubin")
        case "2": // Edwin Lema - Park operations
            return buildingName.contains("Stuyvesant") || buildingName.contains("Park")
        case "5": // Mercedes Inamagua - Perry Street
            return buildingName.contains("131 Perry")
        case "6": // Luis Lopez - Elizabeth Street and Walker Street
            return buildingName.contains("41 Elizabeth") || buildingName.contains("36 Walker")
        case "1": // Greg Hutson - 12 West 18th Street
            return buildingName.contains("12 West 18th")
        case "7": // Angel Guirachocha - West 17th Street
            return buildingName.contains("136 West 17th") || buildingName.contains("117 West 17th")
        case "8": // Shawn Magloire - Portfolio Management
            return buildingName.contains("FrancoSphere HQ")
        default:
            return false
        }
    }
    
    private func seedInitialTasks() async throws {
        // FIXED: Create tasks from operational data using public API
        var taskCount = 0
        let workerBuildingMap = operationalData.getBuildingCoverage()
        
        // Generate tasks based on worker-building relationships
        for (buildingName, workers) in workerBuildingMap {
            for (index, workerName) in workers.enumerated() {
                // Get worker ID from name
                guard let workerId = WorkerConstants.workerNames.first(where: { $0.value == workerName })?.key else {
                    continue
                }
                
                // Get building ID from name
                guard let buildingId = await getBuildingIdForName(buildingName) else {
                    continue
                }
                
                // Create sample task for this worker-building combination
                let taskId = "task_\(buildingId)_\(workerId)_\(index + 1)"
                let taskName = "Daily Maintenance Check"
                let urgency = "normal"
                
                try await grdb.execute("""
                    INSERT OR REPLACE INTO tasks (id, title, description, building_id, worker_id, category, urgency, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
                """, [
                    taskId,
                    taskName,
                    "Routine maintenance and inspection",
                    buildingId,
                    workerId,
                    "maintenance",
                    urgency
                ])
                
                taskCount += 1
            }
        }
        
        print("✅ Seeded \(taskCount) initial tasks from operational data")
    }
    
    // MARK: - Step 5: Verify Integrity
    
    private func verifyDataIntegrity() async throws -> String {
        let workerCount = try await grdb.query("SELECT COUNT(*) as count FROM workers").first?["count"] as? Int64 ?? 0
        let buildingCount = try await grdb.query("SELECT COUNT(*) as count FROM buildings").first?["count"] as? Int64 ?? 0
        let assignmentCount = try await grdb.query("SELECT COUNT(*) as count FROM worker_assignments").first?["count"] as? Int64 ?? 0
        let taskCount = try await grdb.query("SELECT COUNT(*) as count FROM tasks").first?["count"] as? Int64 ?? 0
        
        // Verify Kevin's Rubin Museum assignment (building ID 14)
        let kevinRubin = try await grdb.query("""
            SELECT w.name, b.name as building
            FROM worker_assignments wa
            JOIN workers w ON wa.worker_id = w.id
            JOIN buildings b ON wa.building_id = b.id
            WHERE w.id = '4' AND b.id = '14' AND wa.is_primary = 1
        """).first
        
        let stats = """
        Workers: \(workerCount), Buildings: \(buildingCount), 
        Assignments: \(assignmentCount), Tasks: \(taskCount)
        Kevin->Rubin: \(kevinRubin != nil ? "✅" : "❌")
        """
        
        return stats
    }
    
    // MARK: - Development Helpers
    
    #if DEBUG
    private func autoLoginDefaultWorker() async {
        print("🔐 Auto-login for development...")
        
        do {
            // FIXED: Auto-login as Kevin (worker 4) using correct method name
            let authManager = NewAuthManager.shared
            let kevinEmail = WorkerConstants.workerEmails["4"]!
            try await authManager.login(email: kevinEmail, password: "password")
            print("✅ Auto-logged in as Kevin Dutan (\(kevinEmail))")
        } catch {
            print("⚠️ Auto-login failed: \(error)")
        }
    }
    
    public func resetAndReinitialize() async throws {
        // Clear all data
        UserDefaults.standard.removeObject(forKey: "UnifiedDataInitialized_v6")
        UserDefaults.standard.synchronize()
        
        // Clear database
        try await grdb.execute("DELETE FROM tasks")
        try await grdb.execute("DELETE FROM worker_assignments")
        try await grdb.execute("DELETE FROM buildings")
        try await grdb.execute("DELETE FROM workers")
        try await grdb.execute("DELETE FROM app_settings")
        
        // Reinitialize
        isInitialized = false
        try await initializeIfNeeded()
    }
    #endif
}

// MARK: - Convenience Extensions

extension UnifiedDataInitializer {
    /// Quick check if system is ready
    public var isReady: Bool {
        isInitialized && error == nil
    }
    
    /// Get initialization status message
    public var statusMessage: String {
        if let error = error {
            return "Failed: \(error.localizedDescription)"
        } else if isInitialized {
            return "Ready"
        } else {
            return currentStep
        }
    }
}
