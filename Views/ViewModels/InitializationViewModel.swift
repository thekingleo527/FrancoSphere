//
//  InitializationViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Compilation errors resolved
//  ✅ FIXED: Uses DataInitializationManager instead of UnifiedDataInitializer
//  ✅ FIXED: Proper MainActor async/await handling
//  ✅ INTEGRATED: Real database seeding and worker assignments
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
    
    // Use the actual available initialization manager
    private let dataManager = DataInitializationManager.shared
    
    // MARK: - Real Initialization with DataInitializationManager
    
    func startInitialization() async {
        guard !isInitializing else { return }
        isInitializing = true
        initializationError = nil
        
        print("🚀 Starting real initialization with DataInitializationManager...")
        
        do {
            // Method 1: Use DataInitializationManager directly
            let status = try await dataManager.initializeAllData()
            
            // Monitor progress by observing the published properties
            while dataManager.initializationProgress < 1.0 && initializationError == nil {
                // Update from published properties
                self.progress = dataManager.initializationProgress
                self.currentStep = dataManager.currentStatus
                
                // Check for errors
                if dataManager.hasError {
                    self.initializationError = dataManager.errorMessage
                    break
                }
                
                // Update every 100ms for smooth progress
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            
            // Check final status
            if status.hasErrors {
                self.initializationError = "Initialization completed with errors: \(status.errors.joined(separator: ", "))"
            } else {
                // Success!
                self.progress = 1.0
                self.currentStep = "FrancoSphere Ready!"
                print("✅ Initialization completed successfully!")
                
                // Brief pause to show completion
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                self.isComplete = true
            }
            
        } catch {
            self.initializationError = "Critical error: \(error.localizedDescription)"
            print("❌ Initialization failed with error: \(error)")
        }
        
        isInitializing = false
    }
    
    // MARK: - Alternative Implementation using SeedDatabase directly
    
    func startInitializationAlternative() async {
        guard !isInitializing else { return }
        isInitializing = true
        initializationError = nil
        
        print("🚀 Starting initialization with SeedDatabase...")
        
        do {
            // Step 1: Database migrations
            self.currentStep = "Running database migrations..."
            self.progress = 0.2
            try await SeedDatabase.runMigrations()
            
            // Step 2: Operational data
            self.currentStep = "Initializing operational data..."
            self.progress = 0.5
            try await OperationalDataManager.shared.initializeOperationalData()
            
            // Step 3: Bootstrap additional data
            self.currentStep = "Bootstrapping data..."
            self.progress = 0.8
            DataBootstrapper.runIfNeeded()
            
            // Step 4: Validation
            self.currentStep = "Validating data integrity..."
            self.progress = 0.9
            let validation = await DatabaseSeeder.shared.validateDatabase()
            
            if !validation.success {
                self.initializationError = "Data validation failed: \(validation.message)"
                return
            }
            
            // Success!
            self.progress = 1.0
            self.currentStep = "FrancoSphere Ready!"
            print("✅ Initialization completed successfully!")
            
            // Brief pause to show completion
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            self.isComplete = true
            
        } catch {
            self.initializationError = "Critical error: \(error.localizedDescription)"
            print("❌ Initialization failed with error: \(error)")
        }
        
        isInitializing = false
    }
    
    // MARK: - Helper Methods
    
    /// Reset initialization state (for development/testing)
    func resetInitialization() async {
        guard !isInitializing else { return }
        
        self.isComplete = false
        self.progress = 0.0
        self.currentStep = "Preparing FrancoSphere..."
        self.initializationError = nil
        
        print("🔄 Initialization state reset")
    }
    
    /// Get detailed initialization status
    var detailedStatus: String {
        if let error = initializationError {
            return "Error: \(error)"
        } else if isComplete {
            return "Ready - Initialization completed successfully"
        } else if isInitializing {
            return currentStep
        } else {
            return "Waiting to start..."
        }
    }
    
    /// Progress percentage as string
    var progressPercentage: String {
        return "\(Int(progress * 100))%"
    }
    
    /// Check if we can start initialization
    var canStartInitialization: Bool {
        return !isInitializing && !isComplete
    }
}

// MARK: - Initialization Options

extension InitializationViewModel {
    /// Quick initialization for development
    func quickInitialization() async {
        guard !isInitializing else { return }
        isInitializing = true
        initializationError = nil
        
        print("🚀 Quick initialization for development...")
        
        self.currentStep = "Quick setup..."
        self.progress = 0.5
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        await dataManager.quickInitialize()
        
        self.progress = 1.0
        self.currentStep = "Quick setup complete!"
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        self.isComplete = true
        self.isInitializing = false
        
        print("✅ Quick initialization completed")
    }
    
    /// Full initialization with schema migration
    func fullInitializationWithMigration() async {
        guard !isInitializing else { return }
        isInitializing = true
        initializationError = nil
        
        print("🚀 Full initialization with schema migration...")
        
        do {
            let status = try await dataManager.initializeWithSchemaPatch()
            
            self.progress = dataManager.initializationProgress
            self.currentStep = dataManager.currentStatus
            
            if status.hasErrors {
                self.initializationError = "Migration completed with errors: \(status.errors.joined(separator: ", "))"
            } else {
                self.progress = 1.0
                self.currentStep = "Full initialization complete!"
                
                try? await Task.sleep(nanoseconds: 500_000_000)
                self.isComplete = true
            }
            
        } catch {
            self.initializationError = "Migration failed: \(error.localizedDescription)"
            print("❌ Full initialization failed: \(error)")
        }
        
        isInitializing = false
    }
}
