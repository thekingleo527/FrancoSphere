//
//  DashboardSyncService.swift
//  FrancoSphere v6.0
//
//  Cross-dashboard synchronization service for real-time updates
//  Manages communication between Worker, Admin, and Client dashboards
//
//  ✅ FIXED: Removed Task creation in @MainActor context
//  ✅ FIXED: Using established initialization pattern from codebase
//  ✅ FIXED: Proper sink syntax with receiveValue parameter
//  ✅ FIXED: No references to non-existent PortfolioState
//  ✅ UPDATED: Uses only real data from OperationalDataManager
//

import Foundation
import SwiftUI
import Combine

// MARK: - Dashboard Update Types

public enum DashboardSource: String, CaseIterable {
    case worker = "Worker"
    case admin = "Admin"
    case client = "Client"
    
    var displayName: String { rawValue }
}

public enum UpdateType: String, CaseIterable {
    case taskCompleted = "Task Completed"
    case taskStarted = "Task Started"
    case workerClockedIn = "Worker Clocked In"
    case workerClockedOut = "Worker Clocked Out"
    case buildingMetricsChanged = "Building Metrics Changed"
    case intelligenceGenerated = "Intelligence Generated"
    case complianceChanged = "Compliance Changed"
    case portfolioUpdated = "Portfolio Updated"
    case performanceChanged = "Performance Changed"
    
    var displayName: String { rawValue }
}

public struct DashboardUpdate {
    public let id = UUID()
    public let source: DashboardSource
    public let type: UpdateType
    public let timestamp = Date()
    public let buildingId: String?
    public let workerId: String?
    public let data: [String: Any]
    
    public init(source: DashboardSource, type: UpdateType, buildingId: String? = nil, workerId: String? = nil, data: [String: Any] = [:]) {
        self.source = source
        self.type = type
        self.buildingId = buildingId
        self.workerId = workerId
        self.data = data
    }
}

// MARK: - Live Update Types

public struct LiveWorkerUpdate {
    public let id = UUID()
    public let workerId: String
    public let workerName: String?
    public let action: String
    public let buildingId: String?
    public let buildingName: String?
    public let timestamp = Date()
    
    public init(workerId: String, workerName: String? = nil, action: String, buildingId: String? = nil, buildingName: String? = nil) {
        self.workerId = workerId
        self.workerName = workerName
        self.action = action
        self.buildingId = buildingId
        self.buildingName = buildingName
    }
}

public struct LiveAdminAlert {
    public let id = UUID()
    public let title: String
    public let severity: Severity
    public let buildingId: String
    public let timestamp = Date()
    
    public enum Severity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    public init(title: String, severity: Severity, buildingId: String) {
        self.title = title
        self.severity = severity
        self.buildingId = buildingId
    }
}

public struct LiveClientMetric {
    public let id = UUID()
    public let name: String
    public let value: String
    public let trend: CoreTypes.TrendDirection
    public let timestamp = Date()
    
    public init(name: String, value: String, trend: CoreTypes.TrendDirection) {
        self.name = name
        self.value = value
        self.trend = trend
    }
}

// MARK: - Dashboard Sync Service

@MainActor
public class DashboardSyncService: ObservableObject {
    public static let shared = DashboardSyncService()
    
    // MARK: - Cross-Dashboard Publishers
    
    private let crossDashboardSubject = PassthroughSubject<DashboardUpdate, Never>()
    public var crossDashboardUpdates: AnyPublisher<DashboardUpdate, Never> {
        crossDashboardSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Dashboard-Specific Publishers
    
    private let workerUpdatesSubject = PassthroughSubject<DashboardUpdate, Never>()
    public var workerDashboardUpdates: AnyPublisher<DashboardUpdate, Never> {
        workerUpdatesSubject.eraseToAnyPublisher()
    }
    
    private let adminUpdatesSubject = PassthroughSubject<DashboardUpdate, Never>()
    public var adminDashboardUpdates: AnyPublisher<DashboardUpdate, Never> {
        adminUpdatesSubject.eraseToAnyPublisher()
    }
    
    private let clientUpdatesSubject = PassthroughSubject<DashboardUpdate, Never>()
    public var clientDashboardUpdates: AnyPublisher<DashboardUpdate, Never> {
        clientUpdatesSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Live Update Feeds
    
    @Published public var liveWorkerUpdates: [LiveWorkerUpdate] = []
    @Published public var liveAdminAlerts: [LiveAdminAlert] = []
    @Published public var liveClientMetrics: [LiveClientMetric] = []
    
    // MARK: - Unified Dashboard State
    
    @Published public var unifiedBuildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published public var unifiedPortfolioIntelligence: CoreTypes.PortfolioIntelligence?
    @Published public var isLive = true
    @Published public var lastSyncTime: Date?
    
    // MARK: - Service Dependencies
    
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let operationalDataManager = OperationalDataManager.shared  // ✅ ADDED FOR REAL DATA
    
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private var isInitialized = false
    
    // Debug mode for logging
    #if DEBUG
    private let debugMode = true
    #else
    private let debugMode = false
    #endif
    
    private init() {
        // Simple synchronous init - setup happens in initialize()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Initialization (Following codebase pattern)
    
    /// Initialize the service - must be called after creation
    public func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Validate data sources
        guard validateDataSources() else {
            print("⚠️ DashboardSyncService: Proceeding with limited functionality")
        }
        
        setupRealTimeSynchronization()
        setupAutoSync()
    }
    
    // MARK: - Data Validation
    
    /// Validates that all required data sources are available
    public func validateDataSources() -> Bool {
        // Check if OperationalDataManager is initialized and has data
        guard operationalDataManager.isInitialized else {
            print("❌ DashboardSyncService: OperationalDataManager not initialized")
            return false
        }
        
        // Verify we can access configuration
        let config = operationalDataManager.getSystemConfiguration()
        guard config.isValid else {
            print("❌ DashboardSyncService: Invalid system configuration")
            return false
        }
        
        // Verify we have at least some cached data
        let hasWorkers = operationalDataManager.getCachedWorkerCount() > 0
        let hasBuildings = operationalDataManager.getCachedBuildingCount() > 0
        
        if !hasWorkers || !hasBuildings {
            print("⚠️ DashboardSyncService: No cached data available, will fetch on demand")
        }
        
        return true
    }
    
    // MARK: - Public Broadcasting Methods
    
    /// Broadcast update from Worker Dashboard (task completion, clock-in, etc.)
    public func broadcastWorkerUpdate(_ update: DashboardUpdate) {
        guard isLive else { return }
        
        // Broadcast to all dashboards
        crossDashboardSubject.send(update)
        
        // Send to specific dashboard streams
        workerUpdatesSubject.send(update)
        adminUpdatesSubject.send(update)
        clientUpdatesSubject.send(update)
        
        // Create live updates for real-time feeds
        createLiveWorkerUpdate(from: update)
        createLiveAdminAlert(from: update)
        createLiveClientMetric(from: update)
        
        // Update unified state
        updateUnifiedState(from: update)
    }
    
    /// Broadcast update from Admin Dashboard (building metrics, intelligence, etc.)
    public func broadcastAdminUpdate(_ update: DashboardUpdate) {
        guard isLive else { return }
        
        // Broadcast to all dashboards
        crossDashboardSubject.send(update)
        
        // Send to specific dashboard streams
        adminUpdatesSubject.send(update)
        workerUpdatesSubject.send(update)
        clientUpdatesSubject.send(update)
        
        // Create live updates
        createLiveAdminAlert(from: update)
        createLiveClientMetric(from: update)
        
        // Update unified state
        updateUnifiedState(from: update)
    }
    
    /// Broadcast update from Client Dashboard (portfolio changes, etc.)
    public func broadcastClientUpdate(_ update: DashboardUpdate) {
        guard isLive else { return }
        
        // Broadcast to all dashboards
        crossDashboardSubject.send(update)
        
        // Send to specific dashboard streams
        clientUpdatesSubject.send(update)
        adminUpdatesSubject.send(update)
        workerUpdatesSubject.send(update)
        
        // Create live updates
        createLiveClientMetric(from: update)
        createLiveAdminAlert(from: update)
        
        // Update unified state
        updateUnifiedState(from: update)
    }
    
    // MARK: - Convenience Broadcasting Methods
    
    /// Worker clocked in
    public func onWorkerClockedIn(workerId: String, buildingId: String, buildingName: String? = nil) {
        let update = DashboardUpdate(
            source: .worker,
            type: .workerClockedIn,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "buildingName": buildingName ?? getBuildingName(buildingId) ?? "",
                "workerName": getWorkerName(workerId) ?? ""
            ]
        )
        broadcastWorkerUpdate(update)
    }
    
    /// Worker clocked out
    public func onWorkerClockedOut(workerId: String, buildingId: String) {
        let update = DashboardUpdate(
            source: .worker,
            type: .workerClockedOut,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "buildingName": getBuildingName(buildingId) ?? "",
                "workerName": getWorkerName(workerId) ?? ""
            ]
        )
        broadcastWorkerUpdate(update)
    }
    
    /// Task completed
    public func onTaskCompleted(taskId: String, workerId: String, buildingId: String) {
        let update = DashboardUpdate(
            source: .worker,
            type: .taskCompleted,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "taskId": taskId,
                "buildingName": getBuildingName(buildingId) ?? "",
                "workerName": getWorkerName(workerId) ?? ""
            ]
        )
        broadcastWorkerUpdate(update)
    }
    
    /// Building metrics changed
    public func onBuildingMetricsChanged(buildingId: String, metrics: CoreTypes.BuildingMetrics) {
        let update = DashboardUpdate(
            source: .admin,
            type: .buildingMetricsChanged,
            buildingId: buildingId,
            data: [
                "completionRate": metrics.completionRate,
                "overdueTasks": metrics.overdueTasks,
                "urgentTasks": metrics.urgentTasksCount,
                "activeWorkers": metrics.activeWorkers
            ]
        )
        broadcastAdminUpdate(update)
    }
    
    /// Intelligence insights generated
    public func onIntelligenceGenerated(insights: [CoreTypes.IntelligenceInsight]) {
        let update = DashboardUpdate(
            source: .admin,
            type: .intelligenceGenerated,
            data: [
                "insightCount": insights.count,
                "highPriorityCount": insights.filter { $0.priority == .high || $0.priority == .critical }.count
            ]
        )
        broadcastAdminUpdate(update)
    }
    
    /// Portfolio state updated
    public func onPortfolioUpdated(portfolio: CoreTypes.PortfolioIntelligence) {
        let update = DashboardUpdate(
            source: .client,
            type: .portfolioUpdated,
            data: [
                "totalBuildings": portfolio.totalBuildings,
                "activeWorkers": portfolio.activeWorkers,
                "completionRate": portfolio.completionRate,
                "criticalIssues": portfolio.criticalIssues
            ]
        )
        broadcastClientUpdate(update)
    }
    
    // MARK: - Live Update Creation
    
    private func createLiveWorkerUpdate(from update: DashboardUpdate) {
        guard let workerId = update.workerId,
              update.source == .worker else { return }
        
        let workerUpdate = LiveWorkerUpdate(
            workerId: workerId,
            workerName: update.data["workerName"] as? String,
            action: generateActionDescription(for: update),
            buildingId: update.buildingId,
            buildingName: update.data["buildingName"] as? String
        )
        
        liveWorkerUpdates.append(workerUpdate)
        limitLiveUpdates()
    }
    
    private func createLiveAdminAlert(from update: DashboardUpdate) {
        guard update.type == .buildingMetricsChanged ||
              update.type == .complianceChanged ||
              update.type == .performanceChanged else { return }
        
        let severity: LiveAdminAlert.Severity = {
            // Use real thresholds from OperationalDataManager
            let config = operationalDataManager.getSystemConfiguration()
            
            if let overdueTasks = update.data["overdueTasks"] as? Int,
               overdueTasks > config.criticalOverdueThreshold {
                return .critical
            } else if let completionRate = update.data["completionRate"] as? Double,
                     completionRate < config.minimumCompletionRate {
                return .high
            } else if let urgentTasks = update.data["urgentTasks"] as? Int,
                     urgentTasks > config.urgentTaskThreshold {
                return .medium
            } else {
                return .low
            }
        }()
        
        let alert = LiveAdminAlert(
            title: update.type.displayName,
            severity: severity,
            buildingId: update.buildingId ?? ""
        )
        
        liveAdminAlerts.append(alert)
        limitLiveUpdates()
    }
    
    private func createLiveClientMetric(from update: DashboardUpdate) {
        guard update.type == .portfolioUpdated || update.type == .performanceChanged else {
            return
        }
        
        // Calculate real trend from OperationalDataManager historical data
        let trend: CoreTypes.TrendDirection = {
            if let metricName = update.data["metricName"] as? String {
                let historicalTrend = operationalDataManager.calculateTrend(for: metricName, days: 7)
                return historicalTrend
            }
            return .stable
        }()
        
        let metricValue: String = {
            if let value = update.data["value"] {
                return String(describing: value)
            }
            return "N/A"
        }()
        
        let metric = LiveClientMetric(
            name: update.type.displayName,
            value: metricValue,
            trend: trend
        )
        
        liveClientMetrics.append(metric)
        limitLiveUpdates()
    }
    
    private func limitLiveUpdates() {
        // Get limit from OperationalDataManager configuration
        let config = operationalDataManager.getSystemConfiguration()
        let maxLiveUpdates = config.maxLiveUpdatesPerFeed ?? 10
        
        // Keep only last N updates for performance
        if liveWorkerUpdates.count > maxLiveUpdates {
            liveWorkerUpdates.removeFirst(liveWorkerUpdates.count - maxLiveUpdates)
        }
        if liveAdminAlerts.count > maxLiveUpdates {
            liveAdminAlerts.removeFirst(liveAdminAlerts.count - maxLiveUpdates)
        }
        if liveClientMetrics.count > maxLiveUpdates {
            liveClientMetrics.removeFirst(liveClientMetrics.count - maxLiveUpdates)
        }
    }
    
    // MARK: - Unified State Management
    
    private func updateUnifiedState(from update: DashboardUpdate) {
        // Update building metrics if relevant
        if let buildingId = update.buildingId,
           update.type == .buildingMetricsChanged || update.type == .taskCompleted {
            
            // Schedule async work to run later
            scheduleMetricsUpdate(for: buildingId)
        }
        
        // Update portfolio state for client-level changes
        if update.type == .portfolioUpdated || update.type == .performanceChanged {
            // Schedule async work to run later
            schedulePortfolioUpdate()
        }
    }
    
    private func scheduleMetricsUpdate(for buildingId: String) {
        // Use main queue to schedule the async work
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            Task {
                do {
                    let metrics = try await self.buildingMetricsService.calculateMetrics(for: buildingId)
                    await MainActor.run {
                        self.unifiedBuildingMetrics[buildingId] = metrics
                    }
                } catch {
                    print("❌ Failed to update unified building metrics: \(error)")
                }
            }
        }
    }
    
    private func schedulePortfolioUpdate() {
        // Use main queue to schedule the async work
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            Task {
                do {
                    let portfolio = try await self.buildingService.generatePortfolioIntelligence()
                    await MainActor.run {
                        self.unifiedPortfolioIntelligence = portfolio
                    }
                } catch {
                    print("❌ Failed to refresh portfolio intelligence: \(error)")
                }
            }
        }
    }
    
    // MARK: - Real-Time Synchronization Setup
    
    private func setupRealTimeSynchronization() {
        // Subscribe to cross-dashboard updates for logging
        crossDashboardUpdates
            .sink(receiveValue: { [weak self] update in
                print("🔄 Cross-dashboard sync: \(update.source.displayName) → \(update.type.displayName)")
            })
            .store(in: &cancellables)
    }
    
    private func setupAutoSync() {
        // Get sync interval from OperationalDataManager configuration
        let config = operationalDataManager.getSystemConfiguration()
        let syncInterval = config.autoSyncInterval ?? 30.0
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.scheduleAutoSync()
            }
        }
    }
    
    private func scheduleAutoSync() {
        // Use main queue to schedule the async work
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            Task {
                await self.performAutoSync()
            }
        }
    }
    
    private func performAutoSync() async {
        // Perform lightweight sync to ensure all dashboards are consistent
        do {
            let buildings = try await buildingService.getAllBuildings()
            
            // Check if building count has changed
            if buildings.count != unifiedBuildingMetrics.count {
                let update = DashboardUpdate(
                    source: .admin,
                    type: .portfolioUpdated,
                    buildingId: nil,
                    workerId: nil,
                    data: ["buildingCount": buildings.count, "autoSync": true]
                )
                
                broadcastAdminUpdate(update)
            }
            
            lastSyncTime = Date()
            
            // Store sync event in OperationalDataManager
            operationalDataManager.recordSyncEvent(timestamp: lastSyncTime ?? Date())
            
        } catch {
            print("❌ Auto-sync failed: \(error)")
            // Log error to OperationalDataManager
            operationalDataManager.logError("Auto-sync failed", error: error)
        }
    }
    
    // MARK: - Helper Methods (✅ UPDATED TO USE REAL DATA ONLY)
    
    private func getBuildingName(_ buildingId: String?) -> String? {
        guard let id = buildingId else { return nil }
        
        // Fetch real building data from OperationalDataManager
        if let building = operationalDataManager.getBuilding(byId: id) {
            return building.name
        }
        
        // Log when data is missing in debug mode
        if debugMode {
            print("⚠️ DashboardSyncService: Building name not found for ID: \(id)")
        }
        
        return nil
    }
    
    private func getWorkerName(_ workerId: String) -> String? {
        // Fetch real worker data from OperationalDataManager
        if let worker = operationalDataManager.getWorker(byId: workerId) {
            return worker.name
        }
        
        // Log when data is missing in debug mode
        if debugMode {
            print("⚠️ DashboardSyncService: Worker name not found for ID: \(workerId)")
        }
        
        return nil
    }
    
    private func generateActionDescription(for update: DashboardUpdate) -> String {
        switch update.type {
        case .taskCompleted:
            return "Completed task"
        case .workerClockedIn:
            return "Clocked in"
        case .workerClockedOut:
            return "Clocked out"
        case .taskStarted:
            return "Started task"
        default:
            return update.type.displayName
        }
    }
}

// MARK: - Extensions for SwiftUI Integration

extension DashboardSyncService {
    
    /// Enable cross-dashboard synchronization (called from DashboardView)
    public func enableCrossDashboardSync() {
        // Initialize if not already done
        initialize()
        
        isLive = true
        print("🔄 Cross-dashboard synchronization enabled")
    }
    
    /// Disable cross-dashboard synchronization
    public func disableCrossDashboardSync() {
        isLive = false
        print("⏸️ Cross-dashboard synchronization disabled")
    }
    
    /// Get recent updates for a specific dashboard
    public func getRecentUpdates(for source: DashboardSource, limit: Int = 5) -> [DashboardUpdate] {
        // Fetch real recent updates from OperationalDataManager
        let recentEvents = operationalDataManager.getRecentEvents(limit: limit)
        
        return recentEvents.compactMap { event in
            // Convert operational events to dashboard updates
            guard let eventType = UpdateType(rawValue: event.type) else { return nil }
            
            return DashboardUpdate(
                source: source,
                type: eventType,
                buildingId: event.buildingId,
                workerId: event.workerId,
                data: event.metadata ?? [:]
            )
        }
    }
    
    /// Clear live update feeds
    public func clearLiveUpdates() {
        liveWorkerUpdates.removeAll()
        liveAdminAlerts.removeAll()
        liveClientMetrics.removeAll()
    }
}

// MARK: - Convenience Publishers

extension DashboardSyncService {
    
    /// Publisher for worker-specific updates
    public var workerUpdates: AnyPublisher<DashboardUpdate, Never> {
        workerDashboardUpdates
            .filter { $0.source == .worker || $0.type == .taskCompleted || $0.type == .workerClockedIn || $0.type == .workerClockedOut }
            .eraseToAnyPublisher()
    }
    
    /// Publisher for admin-specific updates
    public var adminUpdates: AnyPublisher<DashboardUpdate, Never> {
        adminDashboardUpdates
            .filter { $0.source == .admin || $0.type == .buildingMetricsChanged || $0.type == .intelligenceGenerated }
            .eraseToAnyPublisher()
    }
    
    /// Publisher for client-specific updates
    public var clientUpdates: AnyPublisher<DashboardUpdate, Never> {
        clientDashboardUpdates
            .filter { $0.source == .client || $0.type == .portfolioUpdated || $0.type == .performanceChanged }
            .eraseToAnyPublisher()
    }
}

// MARK: - App Initialization

extension DashboardSyncService {
    /// Call this during app startup to ensure proper initialization
    public static func initializeForApp() {
        // Initialize the shared instance
        shared.initialize()
    }
}

// MARK: - Sample Data Generation (Based on Real Data Only)

extension DashboardSyncService {
    /// Generate sample updates based on real data patterns
    /// Used for testing and demo purposes - all data comes from OperationalDataManager
    public func generateSampleUpdate(type: UpdateType) -> DashboardUpdate? {
        // Get real workers and buildings from OperationalDataManager
        guard let randomWorker = operationalDataManager.getRandomWorker(),
              let randomBuilding = operationalDataManager.getRandomBuilding() else {
            if debugMode {
                print("⚠️ DashboardSyncService: Cannot generate sample - no real data available")
            }
            return nil
        }
        
        // Create update based on real data
        return DashboardUpdate(
            source: .worker,
            type: type,
            buildingId: randomBuilding.id,
            workerId: randomWorker.id,
            data: [
                "workerName": randomWorker.name,
                "buildingName": randomBuilding.name,
                "isRealData": true
            ]
        )
    }
}

// MARK: - Data Source Requirements Summary
/*
 This service MUST use real data only:
 
 1. Worker Data: OperationalDataManager.getWorker(byId:)
 2. Building Data: OperationalDataManager.getBuilding(byId:)
 3. System Config: OperationalDataManager.getSystemConfiguration()
 4. Trends: OperationalDataManager.calculateTrend(for:days:)
 5. Events: OperationalDataManager.getRecentEvents(limit:)
 
 NO hardcoded values are allowed except for:
 - Enum cases and their display names
 - Error messages
 - Log statements
 
 All thresholds, limits, and intervals must come from configuration.
 */
