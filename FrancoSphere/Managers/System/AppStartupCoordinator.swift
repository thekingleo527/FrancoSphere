//
//  AppStartupCoordinator.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 8/4/25.
//


//
//  AppStartupCoordinator.swift
//  CyntientOps (formerly FrancoSphere)
//
//  Phase 0.1: App Startup Coordinator
//  Manages the complete app initialization sequence
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppStartupCoordinator: ObservableObject {
    
    // MARK: - Published State
    @Published public private(set) var startupPhase: StartupPhase = .notStarted
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var statusMessage: String = "Initializing..."
    @Published public private(set) var error: Error?
    @Published public private(set) var isReady: Bool = false
    
    // MARK: - Startup Phases
    public enum StartupPhase: Int, CaseIterable {
        case notStarted = 0
        case checkingDatabase = 1
        case initializingServices = 2
        case loadingOperationalData = 3
        case verifyingData = 4
        case configuringNetwork = 5
        case ready = 6
        
        var description: String {
            switch self {
            case .notStarted: return "Starting up..."
            case .checkingDatabase: return "Checking database..."
            case .initializingServices: return "Initializing services..."
            case .loadingOperationalData: return "Loading operational data..."
            case .verifyingData: return "Verifying Kevin's 38 tasks..."
            case .configuringNetwork: return "Configuring network..."
            case .ready: return "Ready!"
            }
        }
        
        var progressValue: Double {
            return Double(self.rawValue) / Double(StartupPhase.allCases.count - 1)
        }
    }
    
    // MARK: - Dependencies
    private let databaseInitializer = DatabaseInitializer.shared
    private let operationalData = OperationalDataManager.shared
    private let networkMonitor = NetworkMonitor.shared
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Public Methods
    
    /// Start the app initialization sequence
    public func startInitialization() async {
        guard startupPhase == .notStarted else {
            print("⚠️ Initialization already started")
            return
        }
        
        do {
            // Phase 1: Check Database
            await updatePhase(.checkingDatabase)
            if !databaseInitializer.isInitialized {
                try await databaseInitializer.initializeIfNeeded()
            }
            
            // Verify database is ready
            let dbReady = await verifyDatabaseReady()
            guard dbReady else {
                throw StartupError.databaseNotReady
            }
            
            // Phase 2: Initialize Services
            await updatePhase(.initializingServices)
            try await initializeServices()
            
            // Phase 3: Load Operational Data
            await updatePhase(.loadingOperationalData)
            try await loadOperationalData()
            
            // Phase 4: Verify Data (especially Kevin's tasks)
            await updatePhase(.verifyingData)
            try await verifyKevinTasks()
            
            // Phase 5: Configure Network
            await updatePhase(.configuringNetwork)
            await configureNetworkMonitoring()
            
            // Phase 6: Ready
            await updatePhase(.ready)
            isReady = true
            
            print("✅ App startup completed successfully")
            
        } catch {
            self.error = error
            print("❌ App startup failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func updatePhase(_ phase: StartupPhase) async {
        startupPhase = phase
        progress = phase.progressValue
        statusMessage = phase.description
        
        // Give UI time to update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    private func verifyDatabaseReady() async -> Bool {
        do {
            // Test database connectivity
            let result = try await GRDBManager.shared.query("SELECT 1 as test")
            return !result.isEmpty
        } catch {
            print("❌ Database connectivity check failed: \(error)")
            return false
        }
    }
    
    private func initializeServices() async throws {
        // Services that need initialization
        await BuildingMetricsService.initializeForCrossDashboardIntegration()
        
        // Initialize ClockInManager
        await ClockInManager.shared.initialize()
        
        print("✅ Services initialized")
    }
    
    private func loadOperationalData() async throws {
        guard !operationalData.isInitialized else {
            print("✅ Operational data already loaded")
            return
        }
        
        // Import operational data if needed
        try await operationalData.importOperationalDataIfNeeded()
        
        // Wait for initialization
        var attempts = 0
        while !operationalData.isInitialized && attempts < 10 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            attempts += 1
        }
        
        guard operationalData.isInitialized else {
            throw StartupError.operationalDataNotLoaded
        }
    }
    
    private func verifyKevinTasks() async throws {
        // Verify Kevin (ID 4) has exactly 38 tasks
        let kevinTasks = operationalData.getKevinTasks()
        
        guard kevinTasks.count == 38 else {
            throw StartupError.kevinTaskCountMismatch(found: kevinTasks.count, expected: 38)
        }
        
        // Verify Rubin Museum (ID 14) is included
        let hasRubinMuseum = kevinTasks.contains { task in
            task.buildingId == "14" || task.building.contains("Rubin")
        }
        
        guard hasRubinMuseum else {
            throw StartupError.kevinMissingRubinMuseum
        }
        
        print("✅ Kevin's 38 tasks verified, including Rubin Museum")
    }
    
    private func configureNetworkMonitoring() async {
        // Force update network status
        networkMonitor.forceUpdate()
        
        // Wait for initial status
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        print("✅ Network monitoring configured: \(networkMonitor.isConnected ? "Online" : "Offline")")
    }
}

// MARK: - Startup Errors

public enum StartupError: LocalizedError {
    case databaseNotReady
    case operationalDataNotLoaded
    case kevinTaskCountMismatch(found: Int, expected: Int)
    case kevinMissingRubinMuseum
    case servicesInitializationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .databaseNotReady:
            return "Database is not ready"
        case .operationalDataNotLoaded:
            return "Failed to load operational data"
        case .kevinTaskCountMismatch(let found, let expected):
            return "Kevin has \(found) tasks but should have \(expected)"
        case .kevinMissingRubinMuseum:
            return "Kevin is missing Rubin Museum assignment"
        case .servicesInitializationFailed(let service):
            return "Failed to initialize \(service)"
        }
    }
}