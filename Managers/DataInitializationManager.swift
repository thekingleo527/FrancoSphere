//
//  DataInitializationManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//  CLEAN VERSION - ONLY the Manager class, NO duplicate DataInitializationView

import Foundation
import SwiftUI

@MainActor
class DataInitializationManager: ObservableObject {
    static let shared = DataInitializationManager()
    
    @Published var currentStatus: String = "Starting..."
    @Published var initializationProgress: Double = 0.0
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""
    
    private var sqliteManager: SQLiteManager?
    
    // Debug logger
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "🔍 [\(timestamp)] \(message)"
        print(logMessage)
        
        // Also update the UI
        Task { @MainActor in
            self.currentStatus = message
        }
    }
    
    // Test minimal initialization first
    func testMinimalInit() async throws {
        log("TEST: Starting minimal initialization test")
        
        // Test 1: Can we create SQLiteManager?
        log("TEST 1: Creating SQLiteManager...")
        do {
            let sql = try await SQLiteManager.start()
            self.sqliteManager = sql
            log("✅ TEST 1: SQLiteManager created successfully")
        } catch {
            log("❌ TEST 1: Failed to create SQLiteManager: \(error)")
            throw error
        }
        
        // Test 2: Can we query the database?
        log("TEST 2: Testing basic query...")
        do {
            let result = try await sqliteManager?.query("SELECT 1 as test", [])
            log("✅ TEST 2: Query successful, result: \(result ?? [])")
        } catch {
            log("❌ TEST 2: Query failed: \(error)")
            throw error
        }
        
        // Test 3: Check if tables exist
        log("TEST 3: Checking tables...")
        do {
            let tables = try await sqliteManager?.query(
                "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;",
                []
            )
            log("✅ TEST 3: Found \(tables?.count ?? 0) tables")
            tables?.forEach { table in
                if let name = table["name"] as? String {
                    log("   - Table: \(name)")
                }
            }
        } catch {
            log("❌ TEST 3: Table check failed: \(error)")
        }
        
        log("✅ All minimal tests passed!")
    }
    
    // Main initialization with detailed logging
    func initializeAllData() async throws -> InitializationStatus {
        log("🚀 Starting full initialization at \(Date())")
        
        var errors: [String] = []
        let startTime = Date()
        
        do {
            // Step 1: Initialize SQLite with timeout
            log("Step 1: Initializing SQLite...")
            currentStatus = "Initializing database..."
            initializationProgress = 0.1
            
            let sqliteTask = Task { () -> SQLiteManager in
                return try await SQLiteManager.start()
            }
            
            // Add timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                throw InitializationError.timeout("SQLite initialization timeout")
            }
            
            do {
                let result = try await withThrowingTaskGroup(of: SQLiteManager.self) { group in
                    group.addTask { try await sqliteTask.value }
                    group.addTask {
                        try await timeoutTask.value
                        throw InitializationError.timeout("SQLite timeout")
                    }
                    
                    if let first = try await group.next() {
                        group.cancelAll()
                        return first
                    }
                    throw InitializationError.unknown
                }
                
                self.sqliteManager = result
                log("✅ SQLite initialized in \(Date().timeIntervalSince(startTime))s")
                
            } catch {
                log("❌ SQLite initialization failed: \(error)")
                throw error
            }
            
            // Step 2: Import Buildings
            log("Step 2: Importing buildings...")
            currentStatus = "Importing buildings..."
            initializationProgress = 0.3
            
            do {
                let buildingImporter = BuildingDataImporter(sqliteManager: sqliteManager!)
                let buildingCount = try await importBuildingsWithLogging(importer: buildingImporter)
                log("✅ Imported \(buildingCount) buildings")
            } catch {
                log("❌ Building import failed: \(error)")
                errors.append("Building import: \(error.localizedDescription)")
            }
            
            // Step 3: Import Workers
            log("Step 3: Importing workers...")
            currentStatus = "Importing workers..."
            initializationProgress = 0.5
            
            do {
                let workerImporter = WorkerDataImporter()
                workerImporter.sqliteManager = sqliteManager!
                let workerCount = try await importWorkersWithLogging(importer: workerImporter)
                log("✅ Imported \(workerCount) workers")
            } catch {
                log("❌ Worker import failed: \(error)")
                errors.append("Worker import: \(error.localizedDescription)")
            }
            
            // Step 4: Import Tasks (This might be the slow part!)
            log("Step 4: Importing tasks from CSV...")
            currentStatus = "Importing tasks..."
            initializationProgress = 0.7
            
            do {
                // Import in batches to avoid freezing
                let csvImporter = CSVDataImporter.shared
                csvImporter.sqliteManager = sqliteManager!
                
                log("Starting CSV task import...")
                let taskCount = try await importTasksInBatches(importer: csvImporter)
                log("✅ Imported \(taskCount) tasks")
            } catch {
                log("❌ Task import failed: \(error)")
                errors.append("Task import: \(error.localizedDescription)")
            }
            
            // Step 5: Setup Inventory
            log("Step 5: Setting up inventory...")
            currentStatus = "Setting up inventory..."
            initializationProgress = 0.9
            
            do {
                let inventoryManager = InventoryDataImporter(sqliteManager: sqliteManager!)
                try await inventoryManager.setupInitialInventory()
                log("✅ Inventory setup complete")
            } catch {
                log("❌ Inventory setup failed: \(error)")
                errors.append("Inventory: \(error.localizedDescription)")
            }
            
            // Complete
            currentStatus = "Initialization complete!"
            initializationProgress = 1.0
            
            let totalTime = Date().timeIntervalSince(startTime)
            log("✅ Full initialization completed in \(String(format: "%.2f", totalTime))s")
            
            return InitializationStatus(
                isComplete: true,
                hasErrors: !errors.isEmpty,
                errors: errors,
                timestamp: Date()
            )
            
        } catch {
            log("❌ Fatal initialization error: \(error)")
            hasError = true
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // Add the missing verifyDataImport method
    func verifyDataImport() async -> (buildings: Int, workers: Int, tasks: Int) {
        guard let sqliteManager = sqliteManager else {
            return (0, 0, 0)
        }
        
        do {
            let buildingCount = try await sqliteManager.query("SELECT COUNT(*) as count FROM buildings", [])
            let workerCount = try await sqliteManager.query("SELECT COUNT(*) as count FROM workers", [])
            let taskCount = try await sqliteManager.query("SELECT COUNT(*) as count FROM tasks", [])
            
            let buildings = buildingCount.first?["count"] as? Int ?? 0
            let workers = workerCount.first?["count"] as? Int ?? 0
            let tasks = taskCount.first?["count"] as? Int ?? 0
            
            return (buildings, workers, tasks)
        } catch {
            log("❌ Verify data import failed: \(error)")
            return (0, 0, 0)
        }
    }
    
    // Import buildings with logging
    private func importBuildingsWithLogging(importer: BuildingDataImporter) async throws -> Int {
        let buildings = FrancoSphereModels.FrancoSphere.namedCoordinates
        log("Found \(buildings.count) buildings to import")
        
        var imported = 0
        for (index, building) in buildings.enumerated() {
            if index % 10 == 0 {
                log("Importing building \(index + 1)/\(buildings.count)")
            }
            try await importer.importBuilding(building)
            imported += 1
        }
        
        return imported
    }
    
    // Import workers with logging
    private func importWorkersWithLogging(importer: WorkerDataImporter) async throws -> Int {
        let workers = FrancoSphereModels.FrancoSphere.workers
        log("Found \(workers.count) workers to import")
        
        var imported = 0
        for (index, worker) in workers.enumerated() {
            if index % 5 == 0 {
                log("Importing worker \(index + 1)/\(workers.count)")
            }
            try await importer.importWorker(worker)
            imported += 1
        }
        
        return imported
    }
    
    // Import tasks in batches to avoid blocking
    private func importTasksInBatches(importer: CSVDataImporter) async throws -> Int {
        log("Starting batch task import...")
        
        // Try to get task count first
        if let taskCount = try? await importer.getTaskCount() {
            log("CSV contains approximately \(taskCount) tasks")
        }
        
        // Import in smaller batches
        let batchSize = 50
        var totalImported = 0
        var batchNumber = 0
        
        while true {
            batchNumber += 1
            log("Importing batch \(batchNumber) (size: \(batchSize))...")
            
            let imported = try await importer.importTaskBatch(
                offset: totalImported,
                limit: batchSize
            )
            
            if imported == 0 {
                log("No more tasks to import")
                break
            }
            
            totalImported += imported
            log("Batch \(batchNumber) complete. Total imported: \(totalImported)")
            
            // Allow UI to update
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        return totalImported
    }
}

// Error types
enum InitializationError: LocalizedError {
    case timeout(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .timeout(let message):
            return "Timeout: \(message)"
        case .unknown:
            return "Unknown initialization error"
        }
    }
}

// REMOVED: DataInitializationView struct (it's in DataInitializationView.swift)
extension DataInitializationManager {
    
    /// Run schema migration as part of app initialization
    func runSchemaMigration() async throws {
        log("🔧 Running schema migration patch...")
        currentStatus = "Applying database fixes..."
        initializationProgress = 0.05
        
        do {
            // Apply the patch
            try await SchemaMigrationPatch.applyPatch()
            log("✅ Schema migration completed")
            
            // Verify Edwin now has buildings
            let hasBuildings = await SchemaMigrationPatch.edwinHasBuildings()
            if hasBuildings {
                log("🎉 Edwin now has building assignments!")
            } else {
                log("⚠️ Edwin still has no buildings - may need manual fix")
            }
            
        } catch {
            log("❌ Schema migration failed: \(error)")
            throw error
        }
    }
    
    /// Enhanced initialization that includes schema fix
    func initializeWithSchemaPatch() async throws -> InitializationStatus {
        log("🚀 Starting enhanced initialization with schema patch...")
        
        // Step 1: Run schema migration first
        try await runSchemaMigration()
        
        // Step 2: Run normal initialization
        return try await initializeAllData()
    }
}
