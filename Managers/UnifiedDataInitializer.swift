//
//  UnifiedDataInitializer.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: Single source of truth for app initialization
//  ✅ GRDB: Integrates with OperationalDataManager
//  ✅ REAL-TIME: Automatic database seeding on first launch
//

import Foundation
import SwiftUI

@MainActor
class UnifiedDataInitializer: ObservableObject {
    static let shared = UnifiedDataInitializer()
    
    @Published var isInitialized = false
    @Published var initializationProgress: Double = 0.0
    @Published var currentStep = "Preparing..."
    @Published var error: Error?
    
    private let hasInitializedKey = "FrancoSphere_HasInitialized_v6"
    
    private init() {}
    
    func initializeIfNeeded() async throws {
        guard !isInitialized else { return }
        
        // Check if already initialized
        if UserDefaults.standard.bool(forKey: hasInitializedKey) {
            isInitialized = true
            return
        }
        
        error = nil
        
        do {
            // Step 1: Database setup (20%)
            currentStep = "Setting up database..."
            initializationProgress = 0.2
            
            try await SeedDatabase.runMigrations()
            
            // Step 2: Import operational data (60%)
            currentStep = "Importing operational data..."
            initializationProgress = 0.6
            
            let (imported, errors) = try await OperationalDataManager.shared.importRoutinesAndDSNY()
            print("✅ Imported \(imported) tasks, \(errors.count) errors")
            
            // Step 3: Verify data integrity (80%)
            currentStep = "Verifying data integrity..."
            initializationProgress = 0.8
            
            let verification = await verifyDataIntegrity()
            if !verification.success {
                throw InitializationError.dataVerificationFailed(verification.message)
            }
            
            // Step 4: Complete (100%)
            currentStep = "Initialization complete"
            initializationProgress = 1.0
            
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
            isInitialized = true
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    #if DEBUG
    func resetAndReinitialize() async throws {
        UserDefaults.standard.removeObject(forKey: hasInitializedKey)
        isInitialized = false
        initializationProgress = 0.0
        currentStep = "Resetting..."
        
        // Reset OperationalDataManager
        await OperationalDataManager.shared.reset()
        
        // Reinitialize
        try await initializeIfNeeded()
    }
    #endif
    
    private func verifyDataIntegrity() async -> (success: Bool, message: String) {
        do {
            let tasks = try await TaskService.shared.getAllTasks()
            let workers = try await WorkerService.shared.getAllActiveWorkers()
            let buildings = try await BuildingService.shared.getAllBuildings()
            
            let message = """
            ✅ Data verification passed:
            - Tasks: \(tasks.count)
            - Workers: \(workers.count)  
            - Buildings: \(buildings.count)
            """
            
            return (true, message)
        } catch {
            return (false, "Data verification failed: \(error.localizedDescription)")
        }
    }
}

enum InitializationError: LocalizedError {
    case dataVerificationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .dataVerificationFailed(let message):
            return "Data verification failed: \(message)"
        }
    }
}
