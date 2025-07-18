//
//  InitializationViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Real initialization calls instead of fake delays
//  ✅ CONSOLIDATED: Single point of truth for app initialization
//  ✅ PRODUCTION READY: Proper error handling and progress tracking
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
        
        // Real initialization sequence with actual service calls
        let steps: [(String, () async throws -> Void)] = [
            ("Initializing Database...", { 
                try await DatabaseInitializationCoordinator().initializeDatabase()
                self.progress = 0.25
            }),
            ("Running Schema Migrations...", { 
                try await SeedDatabase.runMigrations()
                self.progress = 0.5
            }),
            ("Loading Operational Data...", { 
                try await OperationalDataManager.shared.initializeOperationalData()
                self.progress = 0.75
            }),
            ("Finalizing System...", { 
                try await self.verifySystemReady()
                self.progress = 1.0
            })
        ]

        for (stepName, stepAction) in steps {
            currentStep = stepName
            do {
                try await stepAction()
            } catch {
                initializationError = "Error during '\(stepName)': \(error.localizedDescription)"
                isInitializing = false
                return
            }
        }

        currentStep = "Initialization Complete"
        try? await Task.sleep(nanoseconds: 500_000_000)
        isComplete = true
        isInitializing = false
    }
    
    private func verifySystemReady() async throws {
        // Verify the system is properly initialized
        let operationalManager = OperationalDataManager.shared
        if !(await operationalManager.isInitialized) {
            throw InitializationError.systemNotReady
        }
        
        // Verify database has data
        let seeder = DatabaseSeeder.shared
        let validation = try await seeder.validateSeededData()
        if !validation.isValid {
            throw InitializationError.dataValidationFailed(validation.errors)
        }
        
        print("✅ System verification complete")
    }
}

enum InitializationError: LocalizedError {
    case systemNotReady
    case dataValidationFailed([String])
    
    var errorDescription: String? {
        switch self {
        case .systemNotReady:
            return "System initialization incomplete"
        case .dataValidationFailed(let errors):
            return "Data validation failed: \(errors.joined(separator: ", "))"
        }
    }
}
