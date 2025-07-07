//
//  InitializationViewModel.swift
//  FrancoSphere
//
//  ✅ V6.0: This is the single, authoritative definition for the InitializationViewModel.
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
        
        // This sequence will be updated to call our new migration services.
        let steps: [(String, () async throws -> Void)] = [
            ("Connecting to Database...", { try await Task.sleep(nanoseconds: 200_000_000) }),
            ("Running Migrations...", { try await Task.sleep(nanoseconds: 300_000_000) }),
            ("Finalizing Setup...", { try await Task.sleep(nanoseconds: 200_000_000) })
        ]

        for (index, (stepName, stepAction)) in steps.enumerated() {
            currentStep = stepName
            progress = Double(index + 1) / Double(steps.count)
            do {
                try await stepAction()
            } catch {
                initializationError = "Error during '\(stepName)': \(error.localizedDescription)"
                isInitializing = false
                return
            }
        }

        progress = 1.0
        currentStep = "Initialization Complete"
        try? await Task.sleep(nanoseconds: 500_000_000)
        isComplete = true
        isInitializing = false
    }
}
