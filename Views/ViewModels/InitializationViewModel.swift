//
//  InitializationViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Now actually calls UnifiedDataInitializer instead of placeholder sleeps
//  ✅ INTEGRATED: Real database seeding and worker assignments
//  ✅ WORKING: Creates worker_assignments table and seeds real data
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
    
    // MARK: - Real Initialization with UnifiedDataInitializer
    
    func startInitialization() async {
        guard !isInitializing else { return }
        isInitializing = true
        initializationError = nil
        
        print("🚀 Starting real initialization with UnifiedDataInitializer...")
        
        do {
            // FIXED: Use UnifiedDataInitializer instead of placeholder sleeps
            let initializer = UnifiedDataInitializer.shared
            
            // Monitor progress from UnifiedDataInitializer
            await withTaskGroup(of: Void.self) { group in
                // Task 1: Run the actual initialization
                group.addTask {
                    do {
                        try await initializer.initializeIfNeeded()
                    } catch {
                        await MainActor.run {
                            self.initializationError = error.localizedDescription
                        }
                    }
                }
                
                // Task 2: Monitor progress updates
                group.addTask {
                    while !initializer.isInitialized && self.initializationError == nil {
                        await MainActor.run {
                            self.progress = initializer.initializationProgress
                            self.currentStep = initializer.currentStep
                        }
                        
                        // Update every 100ms for smooth progress
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                }
                
                // Wait for initialization to complete
                await group.waitForAll()
            }
            
            // Check final status
            if let error = initializer.error {
                await MainActor.run {
                    self.initializationError = "Initialization failed: \(error.localizedDescription)"
                    self.isInitializing = false
                }
                return
            }
            
            // Success!
            await MainActor.run {
                self.progress = 1.0
                self.currentStep = "FrancoSphere Ready!"
                print("✅ Initialization completed successfully!")
                print("   Status: \(initializer.statusMessage)")
            }
            
            // Brief pause to show completion
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                self.isComplete = true
                self.isInitializing = false
            }
            
        } catch {
            await MainActor.run {
                self.initializationError = "Critical error: \(error.localizedDescription)"
                self.isInitializing = false
            }
            print("❌ Initialization failed with error: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset initialization state (for development/testing)
    func resetInitialization() async {
        guard !isInitializing else { return }
        
        await MainActor.run {
            self.isComplete = false
            self.progress = 0.0
            self.currentStep = "Preparing FrancoSphere..."
            self.initializationError = nil
        }
        
        print("🔄 Initialization state reset")
    }
    
    /// Get detailed initialization status
    var detailedStatus: String {
        let initializer = UnifiedDataInitializer.shared
        
        if let error = initializationError {
            return "Error: \(error)"
        } else if isComplete {
            return "Ready - \(initializer.statusMessage)"
        } else if isInitializing {
            return currentStep
        } else {
            return "Waiting to start..."
        }
    }
}
