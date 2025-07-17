//
//  InitializationViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Uses UnifiedDatabaseManager instead of legacy systems
//  ✅ COMPATIBLE: Maintains existing interface for Views
//  ✅ CLEAN: No dependency on removed classes
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
    
    private let databaseManager = UnifiedDatabaseManager.shared

    func startInitialization() async {
        guard !isInitializing else { return }
        isInitializing = true
        initializationError = nil
        
        print("🚀 Starting initialization with UnifiedDatabaseManager...")
        
        do {
            // Subscribe to database manager progress
            startProgressMonitoring()
            
            // Run the unified initialization
            let result = try await databaseManager.runInitialization()
            
            // Final progress sync
            progress = 1.0
            currentStep = "Initialization complete"
            isComplete = true
            
            print("✅ Initialization completed: \(result.workers) workers, \(result.buildings) buildings, \(result.tasks) tasks")
            
        } catch {
            initializationError = "Initialization failed: \(error.localizedDescription)"
            print("❌ Initialization failed: \(error)")
        }
        
        isInitializing = false
    }
    
    private func startProgressMonitoring() {
        // Monitor the database manager's progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            Task { @MainActor in
                self.progress = self.databaseManager.initializationProgress
                self.currentStep = self.databaseManager.currentStep
                
                if self.databaseManager.isInitialized || self.databaseManager.hasError {
                    timer.invalidate()
                }
                
                if let error = self.databaseManager.errorMessage {
                    self.initializationError = error
                    timer.invalidate()
                }
            }
        }
    }
}
