//
//  DatabaseStartupCoordinator.swift
//  FrancoSphere v6.0 - Database Startup Coordination
//
//  ✅ REPLACES: Complex initialization chains
//  ✅ UNIFIED: Single point of database startup
//  ✅ GRDB: Proper GRDB patterns
//

import Foundation

@MainActor
class DatabaseStartupCoordinator: ObservableObject {
    static let shared = DatabaseStartupCoordinator()
    
    @Published var initializationStatus: InitializationStatus = .pending
    @Published var currentStep: String = "Initializing..."
    @Published var progress: Double = 0.0
    
    enum InitializationStatus {
        case pending, inProgress, completed, failed
    }
    
    private let grdbManager = GRDBManager.shared
    
    private init() {}
    
    func startup() async throws {
        initializationStatus = .inProgress
        
        do {
            // Step 1: Initialize GRDB
            currentStep = "Setting up database..."
            progress = 0.2
            
            // Step 2: Apply schema patches
            currentStep = "Applying schema updates..."
            progress = 0.4
            try await SchemaMigrationPatch.shared.applyPatch()
            
            // Step 3: Verify data integrity
            currentStep = "Verifying data integrity..."
            progress = 0.6
            try await verifyDataIntegrity()
            
            // Step 4: Initialize services
            currentStep = "Starting services..."
            progress = 0.8
            await initializeServices()
            
            // Step 5: Complete
            currentStep = "Startup complete"
            progress = 1.0
            initializationStatus = .completed
            
            print("✅ DatabaseStartupCoordinator: Startup completed successfully")
            
        } catch {
            initializationStatus = .failed
            currentStep = "Startup failed: \(error.localizedDescription)"
            print("❌ DatabaseStartupCoordinator: Startup failed - \(error)")
            throw error
        }
    }
    
    private func verifyDataIntegrity() async throws {
        // Check if we have workers and buildings
        let workerCount = try await grdbManager.query("SELECT COUNT(*) as count FROM workers")
        let buildingCount = try await grdbManager.query("SELECT COUNT(*) as count FROM buildings")
        
        guard let workers = workerCount.first?["count"] as? Int64,
              let buildings = buildingCount.first?["count"] as? Int64,
              workers > 0,
              buildings > 0 else {
            throw DatabaseStartupError.dataIntegrityError("Missing core data")
        }
        
        print("✅ Data integrity verified: \(workers) workers, \(buildings) buildings")
    }
    
    private func initializeServices() async {
        // Initialize critical services
        _ = BuildingMetricsService.shared
        _ = TaskService.shared
        _ = WorkerService.shared
        
        print("✅ Services initialized")
    }
}

enum DatabaseStartupError: LocalizedError {
    case dataIntegrityError(String)
    case serviceInitializationError(String)
    
    var errorDescription: String? {
        switch self {
        case .dataIntegrityError(let message):
            return "Data integrity error: \(message)"
        case .serviceInitializationError(let message):
            return "Service initialization error: \(message)"
        }
    }
}
