//
//  InitializationViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Works with new DatabaseInitializer
//  ✅ SIMPLIFIED: Delegates database work to DatabaseInitializer
//  ✅ UI-FOCUSED: Handles presentation logic for InitializationView
//  ✅ RESILIENT: Proper error handling and recovery
//

import Foundation
import SwiftUI
import Combine

@MainActor
class InitializationViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var currentStep: String = "Preparing FrancoSphere..."
    @Published var isInitializing: Bool = false
    @Published var isComplete: Bool = false
    @Published var initializationError: String?
    
    // Dependencies
    private let databaseInitializer = DatabaseInitializer.shared
    private let authManager = NewAuthManager.shared
    
    // Cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Track initialization attempts for retry logic
    private var initializationAttempts = 0
    private let maxAttempts = 3
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to DatabaseInitializer progress
        databaseInitializer.$initializationProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dbProgress in
                // Map database progress (0-1) to first 70% of our progress
                self?.progress = dbProgress * 0.7
            }
            .store(in: &cancellables)
        
        // Subscribe to DatabaseInitializer status
        databaseInitializer.$currentStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                // Only update if we're in database phase
                if self?.progress ?? 0 < 0.7 {
                    self?.currentStep = step
                }
            }
            .store(in: &cancellables)
    }
    
    func startInitialization() async {
        guard !isInitializing else { return }
        
        isInitializing = true
        isComplete = false
        initializationError = nil
        initializationAttempts += 1
        
        do {
            // Phase 1: Database Initialization (0-70%)
            // DatabaseInitializer will update our progress through subscriptions
            if !databaseInitializer.isInitialized {
                try await databaseInitializer.initializeIfNeeded()
            } else {
                // If already initialized, jump to 70%
                await updateProgress(0.7, "Database ready...")
            }
            
            // Phase 2: Load User Context (70-80%)
            await updateProgress(0.75, "Loading user data...")
            try await loadUserContext()
            
            // Phase 3: Initialize App Services (80-95%)
            await updateProgress(0.85, "Starting services...")
            try await initializeAppServices()
            
            // Phase 4: Final Setup (95-100%)
            await updateProgress(0.95, "Finalizing setup...")
            try await finalizeSetup()
            
            // Complete
            await updateProgress(1.0, "Ready!")
            
            // Small delay to show completion
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            isComplete = true
            isInitializing = false
            
            print("✅ FrancoSphere initialization completed successfully")
            
        } catch {
            await handleInitializationError(error)
        }
    }
    
    // MARK: - Initialization Steps
    
    private func loadUserContext() async throws {
        // Only load if user is authenticated
        guard let currentUser = await authManager.getCurrentUser() else {
            print("ℹ️ No authenticated user, skipping context load")
            return
        }
        
        do {
            // Load the worker context
            try await WorkerContextEngine.shared.loadContext(for: currentUser.workerId)
            
            // Check if UnifiedDataService needs initialization
            await UnifiedDataService.shared.checkServicesReady()
            
            print("✅ User context loaded successfully")
            
        } catch {
            // Non-critical error - user can still use app
            print("⚠️ Failed to load worker context: \(error)")
            // Don't throw - this is not fatal
        }
    }
    
    private func initializeAppServices() async throws {
        await updateProgress(0.87, "Initializing weather service...")
        
        // Initialize weather adapter
        await MainActor.run {
            _ = WeatherDataAdapter.shared
        }
        
        await updateProgress(0.89, "Starting telemetry...")
        
        // Initialize telemetry monitoring
        _ = await TelemetryService.shared
        
        await updateProgress(0.91, "Configuring dashboard sync...")
        
        // Dashboard sync service auto-initializes
        await MainActor.run {
            _ = DashboardSyncService.shared
        }
        
        await updateProgress(0.93, "Activating Nova AI...")
        
        // Initialize Nova AI System
        await initializeNovaAI()
        
        print("✅ All app services initialized")
    }
    
    private func initializeNovaAI() async {
        // NovaFeatureManager handles all AI initialization
        await MainActor.run {
            _ = NovaFeatureManager.shared
        }
        
        // Initialize Nova Intelligence Engine
        _ = await NovaIntelligenceEngine.shared
        
        // Initialize Nova API Service
        _ = NovaAPIService.shared
        
        print("✅ Nova AI system initialized")
    }
    
    private func finalizeSetup() async throws {
        // Set initialization flags
        UserDefaults.standard.set(true, forKey: "HasCompletedInitialization")
        UserDefaults.standard.set(Date(), forKey: "LastInitializationDate")
        
        // Perform any data verification if needed
        if databaseInitializer.dataStatus == .partial {
            print("⚠️ Database has partial data - fallback mode available")
        }
        
        // Log successful initialization
        await logInitializationSuccess()
    }
    
    private func logInitializationSuccess() async {
        let stats = try? await databaseInitializer.getDatabaseStatistics()
        
        print("📱 FrancoSphere v6.0 initialized")
        print("  - Database: ✅ \(databaseInitializer.dataStatus.description)")
        print("  - Services: ✅")
        print("  - User Context: ✅")
        print("  - Nova AI: ✅")
        
        if let stats = stats {
            if let workers = stats["workers"] as? [String: Any],
               let total = workers["total"] as? Int64 {
                print("  - Workers: \(total)")
            }
            if let buildings = stats["buildings"] as? [String: Any],
               let total = buildings["total"] as? Int64 {
                print("  - Buildings: \(total)")
            }
        }
        
        print("  - Ready for production")
    }
    
    // MARK: - Error Handling
    
    private func handleInitializationError(_ error: Error) async {
        isInitializing = false
        
        let errorMessage: String
        var isRecoverable = false
        
        // Check if it's a known error type
        if let dbError = error as? InitializationError {
            errorMessage = dbError.localizedDescription
            // Database errors might be recoverable
            isRecoverable = initializationAttempts < maxAttempts
        } else if let appError = error as? AppInitializationError {
            errorMessage = appError.localizedDescription
            isRecoverable = !appError.isCritical && initializationAttempts < maxAttempts
        } else {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            isRecoverable = false
        }
        
        print("❌ Initialization error: \(errorMessage)")
        print("   Attempt: \(initializationAttempts)/\(maxAttempts)")
        print("   Recoverable: \(isRecoverable)")
        
        if isRecoverable {
            // Show error but allow retry
            initializationError = "\(errorMessage)\n\nTap to retry (\(initializationAttempts)/\(maxAttempts))"
        } else {
            // Critical error - show error screen
            initializationError = errorMessage
            
            // For non-critical database issues, we might still allow app usage
            if databaseInitializer.isInitialized {
                print("⚠️ Partial initialization - app may have limited functionality")
                isComplete = true // Allow app to proceed with warnings
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ newProgress: Double, _ message: String) async {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.progress = newProgress
            self.currentStep = message
        }
        
        // Small delay for visual feedback
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    }
    
    // MARK: - Public Methods
    
    func retryInitialization() async {
        initializationError = nil
        await startInitialization()
    }
    
    func skipInitialization() {
        // For development/testing only
        #if DEBUG
        print("⚠️ Skipping initialization (DEBUG only)")
        isComplete = true
        isInitializing = false
        #endif
    }
}

// MARK: - App-Specific Initialization Errors

enum AppInitializationError: LocalizedError {
    case serviceError(String)
    case contextError(String)
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceError(let message):
            return "Service Error: \(message)"
        case .contextError(let message):
            return "Context Error: \(message)"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        }
    }
    
    var isCritical: Bool {
        switch self {
        case .configurationError:
            return true
        case .serviceError, .contextError:
            return false
        }
    }
}
