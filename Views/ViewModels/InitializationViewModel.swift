//
//  InitializationViewModel.swift
//  FrancoSphere v6.0
//
//  🚨 CRITICAL FIX: Added DatabaseStartupCoordinator integration
//  ✅ FIXED: Progress 0/0 issue by ensuring data import runs at startup
//  ✅ ADDED: Real operational data verification
//  ✅ ENHANCED: Kevin-specific validation for user stories
//

import Foundation
import SwiftUI

@MainActor
class InitializationViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var currentStep: String = "Preparing FrancoSphere..."
    @Published var isInitializing: Bool = false
    @Published var isComplete: Bool = false
    @Published var initializationError: String?

    func startInitialization() async {
        guard !isInitializing else { return }
        isInitializing = true
        initializationError = nil
        
        // CRITICAL: Enhanced initialization sequence with real data import
        let steps: [(String, Double, () async throws -> Void)] = [
            ("Connecting to Database...", 0.2, {
                try await GRDBManager.shared.configure()
            }),
            
            ("Verifying Database Structure...", 0.4, {
                try await self.verifyDatabaseStructure()
            }),
            
            ("Importing Real Operational Data...", 0.6, {
                // CRITICAL FIX: This ensures real tasks are in database
                try await DatabaseStartupCoordinator.shared.ensureDataIntegrity()
            }),
            
            ("Validating Kevin's Assignments...", 0.8, {
                try await self.validateKevinWorkflow()
            }),
            
            ("Finalizing Setup...", 1.0, {
                try await Task.sleep(nanoseconds: 200_000_000)
            })
        ]

        for (stepName, stepProgress, stepAction) in steps {
            currentStep = stepName
            progress = stepProgress
            
            do {
                try await stepAction()
                print("✅ Completed: \(stepName)")
            } catch {
                let errorMsg = "Error during '\(stepName)': \(error.localizedDescription)"
                print("❌ \(errorMsg)")
                initializationError = errorMsg
                isInitializing = false
                return
            }
        }

        currentStep = "Initialization Complete"
        try? await Task.sleep(nanoseconds: 300_000_000)
        isComplete = true
        isInitializing = false
        
        print("✅ FrancoSphere v6.0 initialization completed successfully")
    }
    
    // MARK: - Validation Methods
    
    /// Verify database structure exists
    private func verifyDatabaseStructure() async throws {
        let manager = GRDBManager.shared
        
        // Check critical tables exist
        let requiredTables = ["routine_tasks", "workers", "buildings", "worker_assignments"]
        
        for tableName in requiredTables {
            let rows = try await manager.query("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name=?
            """, [tableName])
            
            guard !rows.isEmpty else {
                throw InitializationError.missingTable(tableName)
            }
        }
        
        print("✅ Database structure verification passed")
    }
    
    /// Validate Kevin's workflow requirements (CRITICAL for user stories)
    private func validateKevinWorkflow() async throws {
        let manager = GRDBManager.shared
        
        // Verify Kevin exists and is active
        let kevinCheck = try await manager.query("""
            SELECT id, name, isActive FROM workers WHERE id = '4'
        """)
        
        guard let kevin = kevinCheck.first,
              let isActive = kevin["isActive"] as? Int64,
              isActive == 1 else {
            throw InitializationError.kevinNotFound
        }
        
        // Verify Kevin has tasks
        let kevinTasks = try await manager.query("""
            SELECT COUNT(*) as task_count FROM routine_tasks WHERE workerId = '4'
        """)
        
        let taskCount = kevinTasks.first?["task_count"] as? Int64 ?? 0
        guard taskCount > 0 else {
            throw InitializationError.kevinHasNoTasks
        }
        
        // Verify Kevin has building assignments (especially Rubin Museum)
        let kevinBuildings = try await manager.query("""
            SELECT DISTINCT buildingId FROM routine_tasks WHERE workerId = '4'
        """)
        
        let buildingIds = kevinBuildings.compactMap { $0["buildingId"] as? String }
        let hasRubinMuseum = buildingIds.contains("rubin-museum")
        
        guard buildingIds.count >= 3 else {
            throw InitializationError.kevinInsufficientBuildings(buildingIds.count)
        }
        
        guard hasRubinMuseum else {
            throw InitializationError.kevinMissingRubinMuseum
        }
        
        print("✅ Kevin workflow validation passed:")
        print("   Tasks: \(taskCount)")
        print("   Buildings: \(buildingIds.count)")
        print("   Rubin Museum: ✅")
    }
}

// MARK: - Initialization Errors

enum InitializationError: LocalizedError {
    case timeout(String)
    case unknown
    case missingTable(String)
    case kevinNotFound
    case kevinHasNoTasks
    case kevinInsufficientBuildings(Int)
    case kevinMissingRubinMuseum
    case dataImportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .timeout(let message):
            return "Timeout: \(message)"
        case .unknown:
            return "Unknown initialization error"
        case .missingTable(let table):
            return "Required database table missing: \(table)"
        case .kevinNotFound:
            return "Kevin Dutan not found in workers table"
        case .kevinHasNoTasks:
            return "Kevin has no tasks assigned (critical for user stories)"
        case .kevinInsufficientBuildings(let count):
            return "Kevin has only \(count) buildings (needs at least 3)"
        case .kevinMissingRubinMuseum:
            return "Kevin missing Rubin Museum assignment (critical requirement)"
        case .dataImportFailed(let details):
            return "Data import failed: \(details)"
        }
    }
}

// MARK: - Progress Tracking Extension

extension InitializationViewModel {
    
    /// Get detailed initialization status for debugging
    var detailedStatus: String {
        let progressPercent = Int(progress * 100)
        
        if let error = initializationError {
            return "❌ Error (\(progressPercent)%): \(error)"
        }
        
        if isComplete {
            return "✅ Complete (100%): FrancoSphere ready"
        }
        
        if isInitializing {
            return "🔄 Progress (\(progressPercent)%): \(currentStep)"
        }
        
        return "⏸️ Not started"
    }
    
    /// Check if initialization is in a failure state
    var hasFailed: Bool {
        return initializationError != nil
    }
    
    /// Retry initialization after failure
    func retryInitialization() async {
        guard hasFailed else { return }
        
        // Reset state
        initializationError = nil
        progress = 0.0
        currentStep = "Retrying initialization..."
        
        // Start again
        await startInitialization()
    }
}
