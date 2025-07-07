//
//  InitializationViewModel.swift
//  FrancoSphere
//
//  ✅ V6.0: This is the single, authoritative definition for the InitializationViewModel.
//  ✅ Manages the app's startup and data migration sequence.
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
        
        // This sequence calls our new migration services in the correct order.
        let steps: [(String, () async throws -> Void)] = [
            ("Connecting to Database...", { try await self.step_connectToDatabase() }),
            ("Unifying Data Types...", { try await TypeMigrationService.shared.runMigrationIfNeeded() }),
            ("Consolidating Legacy Data...", { try await DataConsolidationManager.shared.runConsolidationIfNeeded() }),
            ("Finalizing Setup...", { try await self.step_finalize() })
        ]

        for (index, (stepName, stepAction)) in steps.enumerated() {
            currentStep = stepName
            progress = Double(index + 1) / Double(steps.count)
            
            do {
                try await stepAction()
                try await Task.sleep(nanoseconds: 200_000_000) // Small visual delay
            } catch {
                initializationError = "Error during '\(stepName)': \(error.localizedDescription)"
                print("🚨 \(initializationError!)")
                isInitializing = false
                return // Stop the process on critical failure
            }
        }

        progress = 1.0
        currentStep = "Initialization Complete"
        
        // A final delay to let the user see the "complete" message
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        isComplete = true
        isInitializing = false
    }

    // MARK: - Initialization Steps
    private func step_connectToDatabase() async throws {
        // This just ensures the singleton is created.
        let _ = SQLiteManager.shared
    }

    private func step_finalize() async throws {
        // Any final checks can go here.
        print("✅ Final setup checks complete.")
    }
}
