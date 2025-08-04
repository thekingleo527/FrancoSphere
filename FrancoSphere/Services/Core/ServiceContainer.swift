//
//  ServiceContainer.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 8/4/25.
//


//
//  ServiceContainer.swift
//  CyntientOps
//
//  Service Container for Dependency Injection
//  ✅ NO SINGLETONS (except allowed: GRDBManager, OperationalDataManager, LocationManager, NovaAIManager)
//  ✅ LAYERED ARCHITECTURE: Each layer depends only on lower layers
//  ✅ NOVA AI INTEGRATION: Connects to persistent Nova instance
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class ServiceContainer: ObservableObject {
    
    // MARK: - Layer 0: Database & Data
    public let database: GRDBManager
    public let operationalData: OperationalDataManager
    
    // MARK: - Layer 1: Core Services (NO SINGLETONS)
    public let auth: AuthenticationService
    public let workers: WorkerService
    public let buildings: BuildingService
    public let tasks: TaskService
    public let clockIn: ClockInService // ObservableObject wrapper
    public let photos: PhotoEvidenceService
    public let client: ClientService
    
    // MARK: - Layer 2: Business Logic
    public let dashboardSync: DashboardSyncService
    public let metrics: BuildingMetricsService
    public let compliance: ComplianceService
    public let dailyOps: DailyOpsReset
    
    // MARK: - Layer 3: Unified Intelligence
    public let intelligence: UnifiedIntelligenceService
    
    // MARK: - Layer 4: Context Engines
    public let workerContext: WorkerContextEngine
    public let adminContext: AdminContextEngine
    public let clientContext: ClientContextEngine
    
    // MARK: - Layer 5: Command Chains
    public let commands: CommandChainManager
    
    // MARK: - Layer 6: Offline Support
    public let offlineQueue: OfflineQueueManager
    public let cache: CacheManager
    
    // MARK: - Nova AI Reference
    private weak var novaManager: NovaAIManager?
    
    // MARK: - Background Tasks
    private var backgroundTasks: Set<Task<Void, Never>> = []
    
    // MARK: - Initialization Order is CRITICAL
    
    public init() async throws {
        print("🚀 Initializing ServiceContainer...")
        
        // Layer 0: Database MUST be first
        self.database = GRDBManager.shared
        self.operationalData = OperationalDataManager.shared
        print("✅ Layer 0: Database initialized")
        
        // Ensure database is initialized
        let dbInitializer = DatabaseInitializer.shared
        if !dbInitializer.isInitialized {
            print("📊 Initializing database schema...")
            try await dbInitializer.initializeIfNeeded()
        }
        
        // Layer 1: Core Services (no circular dependencies)
        print("🔧 Layer 1: Initializing core services...")
        
        self.auth = try AuthenticationService(database: database)
        self.workers = WorkerService(database: database)
        self.buildings = BuildingService(database: database)
        self.tasks = TaskService(
            database: database,
            operationalData: operationalData
        )
        
        // Create ClockInService wrapper for the actor-based ClockInManager
        self.clockIn = ClockInService(
            database: database,
            workers: workers,
            location: LocationManager.shared
        )
        
        self.photos = PhotoEvidenceService.shared // Allowed singleton
        self.client = ClientService(database: database)
        
        print("✅ Layer 1: Core services initialized")
        
        // Layer 2: Business Logic (depends on Layer 1)
        print("📈 Layer 2: Initializing business logic...")
        
        self.dashboardSync = DashboardSyncService(
            database: database,
            tasks: tasks,
            workers: workers,
            buildings: buildings
        )
        
        self.metrics = await BuildingMetricsService(
            database: database,
            buildings: buildings,
            tasks: tasks
        )
        
        self.compliance = ComplianceService(
            database: database,
            buildings: buildings,
            tasks: tasks
        )
        
        self.dailyOps = DailyOpsReset(
            database: database,
            operationalData: operationalData,
            tasks: tasks
        )
        
        print("✅ Layer 2: Business logic initialized")
        
        // Layer 3: Unified Intelligence (depends on Layer 2)
        print("🧠 Layer 3: Initializing unified intelligence...")
        
        self.intelligence = try await UnifiedIntelligenceService(
            database: database,
            workers: workers,
            buildings: buildings,
            tasks: tasks,
            metrics: metrics,
            compliance: compliance
        )
        
        print("✅ Layer 3: Intelligence initialized")
        
        // Layer 4: Context Engines (needs reference to container)
        print("🎯 Layer 4: Initializing context engines...")
        
        self.workerContext = WorkerContextEngine(container: self)
        self.adminContext = AdminContextEngine(container: self)
        self.clientContext = ClientContextEngine(container: self)
        
        print("✅ Layer 4: Context engines initialized")
        
        // Layer 5: Command Chains (needs full container)
        print("⚡ Layer 5: Initializing command chains...")
        
        self.commands = CommandChainManager(container: self)
        
        print("✅ Layer 5: Command chains initialized")
        
        // Layer 6: Offline Support
        print("💾 Layer 6: Initializing offline support...")
        
        self.offlineQueue = OfflineQueueManager()
        self.cache = CacheManager()
        
        print("✅ Layer 6: Offline support initialized")
        
        // Start background services
        await startBackgroundServices()
        
        print("✅ ServiceContainer initialization complete!")
    }
    
    // MARK: - Nova AI Integration
    
    /// Connect Nova AI Manager to the intelligence service
    public func setNovaManager(_ nova: NovaAIManager) {
        self.novaManager = nova
        self.intelligence.setNovaManager(nova)
        
        // Also connect to context engines if they need Nova
        self.workerContext.setNovaManager(nova)
        self.adminContext.setNovaManager(nova)
        self.clientContext.setNovaManager(nova)
        
        print("🧠 Nova AI Manager connected to services")
    }
    
    // MARK: - Background Services
    
    /// Start all background services and monitoring
    private func startBackgroundServices() async {
        print("🔄 Starting background services...")
        
        // 1. Daily operations reset (runs at midnight)
        let dailyOpsTask = Task {
            await dailyOps.startDailyResetScheduler()
        }
        backgroundTasks.insert(dailyOpsTask)
        
        // 2. Dashboard sync monitoring
        let syncTask = Task {
            await dashboardSync.startRealtimeSync()
        }
        backgroundTasks.insert(syncTask)
        
        // 3. Intelligence monitoring
        let intelligenceTask = Task {
            await intelligence.startIntelligenceMonitoring()
        }
        backgroundTasks.insert(intelligenceTask)
        
        // 4. Offline queue processing
        let offlineTask = Task {
            await offlineQueue.startQueueProcessing()
        }
        backgroundTasks.insert(offlineTask)
        
        // 5. Cache cleanup
        let cacheTask = Task {
            await cache.startPeriodicCleanup()
        }
        backgroundTasks.insert(cacheTask)
        
        // 6. Metrics calculation
        let metricsTask = Task {
            await metrics.startPeriodicCalculation()
        }
        backgroundTasks.insert(metricsTask)
        
        print("✅ Background services started")
    }
    
    // MARK: - Cleanup
    
    /// Stop all background services
    public func stopBackgroundServices() {
        print("🛑 Stopping background services...")
        
        for task in backgroundTasks {
            task.cancel()
        }
        backgroundTasks.removeAll()
        
        print("✅ Background services stopped")
    }
    
    // MARK: - Utility Methods
    
    /// Check if all services are ready
    public func verifyServicesReady() -> Bool {
        // Verify critical services are initialized
        let ready = database.isConnected &&
                   auth.isInitialized &&
                   !operationalData.realWorldTasks.isEmpty
        
        if !ready {
            print("⚠️ Services not ready:")
            print("   - Database connected: \(database.isConnected)")
            print("   - Auth initialized: \(auth.isInitialized)")
            print("   - Operational data loaded: \(!operationalData.realWorldTasks.isEmpty)")
        }
        
        return ready
    }
    
    /// Get service health status
    public func getServiceHealth() -> ServiceHealth {
        ServiceHealth(
            databaseConnected: database.isConnected,
            authInitialized: auth.isInitialized,
            tasksLoaded: !operationalData.realWorldTasks.isEmpty,
            intelligenceActive: intelligence.isMonitoring,
            syncActive: dashboardSync.isActive,
            offlineQueueSize: offlineQueue.pendingActions.count,
            cacheSize: cache.itemCount,
            backgroundTasksActive: backgroundTasks.count
        )
    }
    
    deinit {
        stopBackgroundServices()
    }
}

// MARK: - Supporting Types

public struct ServiceHealth {
    public let databaseConnected: Bool
    public let authInitialized: Bool
    public let tasksLoaded: Bool
    public let intelligenceActive: Bool
    public let syncActive: Bool
    public let offlineQueueSize: Int
    public let cacheSize: Int
    public let backgroundTasksActive: Int
    
    public var isHealthy: Bool {
        databaseConnected && authInitialized && tasksLoaded
    }
    
    public var summary: String {
        if isHealthy {
            return "All services operational"
        } else {
            var issues: [String] = []
            if !databaseConnected { issues.append("Database disconnected") }
            if !authInitialized { issues.append("Auth not initialized") }
            if !tasksLoaded { issues.append("Tasks not loaded") }
            return "Issues: \(issues.joined(separator: ", "))"
        }
    }
}

// MARK: - Service Container Error

public enum ServiceContainerError: LocalizedError {
    case databaseInitializationFailed
    case authenticationServiceFailed
    case criticalServiceFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .databaseInitializationFailed:
            return "Failed to initialize database"
        case .authenticationServiceFailed:
            return "Failed to initialize authentication service"
        case .criticalServiceFailed(let service):
            return "Failed to initialize critical service: \(service)"
        }
    }
}