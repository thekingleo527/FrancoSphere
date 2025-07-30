//
//  DashboardSyncService.swift
//  FrancoSphere v6.0
//
//  Cross-dashboard synchronization service for real-time updates
//  Manages communication between Worker, Admin, and Client dashboards
//
//  ✅ FIXED: Properly integrated with OperationalDataManager
//  ✅ FIXED: Uses real data from cache and database
//  ✅ FIXED: Respects system configuration thresholds
//

import Foundation
import SwiftUI
import Combine

// MARK: - Dashboard Sync Service

@MainActor
public class DashboardSyncService: ObservableObject {
    public static let shared = DashboardSyncService()
    
    // MARK: - Cross-Dashboard Publishers
    
    private let crossDashboardSubject = PassthroughSubject<CoreTypes.DashboardUpdate, Never>()
    public var crossDashboardUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        crossDashboardSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Dashboard-Specific Publishers
    
    private let workerUpdatesSubject = PassthroughSubject<CoreTypes.DashboardUpdate, Never>()
    public var workerDashboardUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        workerUpdatesSubject.eraseToAnyPublisher()
    }
    
    private let adminUpdatesSubject = PassthroughSubject<CoreTypes.DashboardUpdate, Never>()
    public var adminDashboardUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        adminUpdatesSubject.eraseToAnyPublisher()
    }
    
    private let clientUpdatesSubject = PassthroughSubject<CoreTypes.DashboardUpdate, Never>()
    public var clientDashboardUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
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
    private let operationalDataManager = OperationalDataManager.shared  // ✅ INTEGRATED
    
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
    
    // MARK: - Initialization
    
    /// Initialize the service - must be called after creation
    public func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Validate data sources
        guard validateDataSources() else {
            operationalDataManager.logError("DashboardSyncService initialization failed - limited functionality")
            return
        }
        
        setupRealTimeSynchronization()
        setupAutoSync()
    }
    
    // MARK: - Data Validation
    
    /// Validates that all required data sources are available
    private func validateDataSources() -> Bool {
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
            print("⚠️ DashboardSyncService: Limited cached data, will fetch on demand")
        }
        
        return true
    }
    
    // MARK: - Public Broadcasting Methods

    /// Broadcast update from Worker Dashboard (task completion, clock-in, etc.)
    public func broadcastWorkerUpdate(_ update: CoreTypes.DashboardUpdate) {
        guard isLive else { return }
        
        // Enrich update with real data if needed
        let enrichedUpdate = enrichUpdateWithRealData(update)
        
        // Broadcast to all dashboards
        crossDashboardSubject.send(enrichedUpdate)
        
        // Send to specific dashboard streams
        workerUpdatesSubject.send(enrichedUpdate)
        adminUpdatesSubject.send(enrichedUpdate)
        clientUpdatesSubject.send(enrichedUpdate)
        
        // Create live updates for real-time feeds
        createLiveWorkerUpdate(from: enrichedUpdate)
        createLiveAdminAlert(from: enrichedUpdate)
        createLiveClientMetric(from: enrichedUpdate)
        
        // Update unified state
        updateUnifiedState(from: enrichedUpdate)
        
        // Event tracking is handled internally by OperationalDataManager
    }

    /// Broadcast update from Admin Dashboard (building metrics, intelligence, etc.)
    public func broadcastAdminUpdate(_ update: CoreTypes.DashboardUpdate) {
        guard isLive else { return }
        
        let enrichedUpdate = enrichUpdateWithRealData(update)
        
        // Broadcast to all dashboards
        crossDashboardSubject.send(enrichedUpdate)
        
        // Send to specific dashboard streams
        adminUpdatesSubject.send(enrichedUpdate)
        workerUpdatesSubject.send(enrichedUpdate)
        clientUpdatesSubject.send(enrichedUpdate)
        
        // Create live updates
        createLiveAdminAlert(from: enrichedUpdate)
        createLiveClientMetric(from: enrichedUpdate)
        
        // Update unified state
        updateUnifiedState(from: enrichedUpdate)
        
        // Event tracking is handled internally by OperationalDataManager
    }

    /// Broadcast update from Client Dashboard (portfolio changes, etc.)
    public func broadcastClientUpdate(_ update: CoreTypes.DashboardUpdate) {
        guard isLive else { return }
        
        let enrichedUpdate = enrichUpdateWithRealData(update)
        
        // Broadcast to all dashboards
        crossDashboardSubject.send(enrichedUpdate)
        
        // Send to specific dashboard streams
        clientUpdatesSubject.send(enrichedUpdate)
        adminUpdatesSubject.send(enrichedUpdate)
        workerUpdatesSubject.send(enrichedUpdate)
        
        // Create live updates
        createLiveClientMetric(from: enrichedUpdate)
        createLiveAdminAlert(from: enrichedUpdate)
        
        // Update unified state
        updateUnifiedState(from: enrichedUpdate)
        
        // Event tracking is handled internally by OperationalDataManager
    }
    
    // MARK: - Data Enrichment
    
    private func enrichUpdateWithRealData(_ update: CoreTypes.DashboardUpdate) -> CoreTypes.DashboardUpdate {
        var enrichedData = update.data
        
        // Add real worker name if we have workerId
        if !update.workerId.isEmpty, enrichedData["workerName"] == nil || enrichedData["workerName"] == "" {
            if let worker = operationalDataManager.getWorker(byId: update.workerId) {
                enrichedData["workerName"] = worker.name
            }
        }
        
        // Add real building name if we have buildingId
        if !update.buildingId.isEmpty, enrichedData["buildingName"] == nil || enrichedData["buildingName"] == "" {
            if let building = operationalDataManager.getBuilding(byId: update.buildingId) {
                enrichedData["buildingName"] = building.name
            }
        }
        
        // Create new update with enriched data
        return CoreTypes.DashboardUpdate(
            source: update.source,
            type: update.type,
            buildingId: update.buildingId,
            workerId: update.workerId,
            data: enrichedData
        )
    }
    
    // MARK: - Convenience Broadcasting Methods
    
    /// Worker clocked in
    public func onWorkerClockedIn(workerId: String, buildingId: String, buildingName: String? = nil) {
        // Get real data from OperationalDataManager
        let workerName = operationalDataManager.getWorker(byId: workerId)?.name ?? ""
        let realBuildingName = buildingName ?? operationalDataManager.getBuilding(byId: buildingId)?.name ?? ""
        
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .workerClockedIn,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "buildingName": realBuildingName,
                "workerName": workerName
            ]
        )
        broadcastWorkerUpdate(update)
    }
    
    /// Worker clocked out
    public func onWorkerClockedOut(workerId: String, buildingId: String) {
        let workerName = operationalDataManager.getWorker(byId: workerId)?.name ?? ""
        let buildingName = operationalDataManager.getBuilding(byId: buildingId)?.name ?? ""
        
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .workerClockedOut,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "buildingName": buildingName,
                "workerName": workerName
            ]
        )
        broadcastWorkerUpdate(update)
    }
    
    /// Task completed
    public func onTaskCompleted(taskId: String, workerId: String, buildingId: String) {
        let workerName = operationalDataManager.getWorker(byId: workerId)?.name ?? ""
        let buildingName = operationalDataManager.getBuilding(byId: buildingId)?.name ?? ""
        
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .taskCompleted,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "taskId": taskId,
                "buildingName": buildingName,
                "workerName": workerName
            ]
        )
        broadcastWorkerUpdate(update)
    }
    
    /// Building metrics changed
    public func onBuildingMetricsChanged(buildingId: String, metrics: CoreTypes.BuildingMetrics) {
        // Record metric values for trend analysis
        operationalDataManager.recordMetricValue(
            metricName: "building_\(buildingId)_completion",
            value: metrics.completionRate
        )
        
        let update = CoreTypes.DashboardUpdate(
            source: .admin,
            type: .buildingMetricsChanged,
            buildingId: buildingId,
            workerId: "",
            data: [
                "completionRate": String(metrics.completionRate),
                "overdueTasks": String(metrics.overdueTasks),
                "urgentTasks": String(metrics.urgentTasksCount),
                "activeWorkers": String(metrics.activeWorkers)
            ]
        )
        broadcastAdminUpdate(update)
    }
    
    /// Intelligence insights generated
    public func onIntelligenceGenerated(insights: [CoreTypes.IntelligenceInsight]) {
        let update = CoreTypes.DashboardUpdate(
            source: .admin,
            type: .buildingMetricsChanged,  // Using existing type
            buildingId: "",
            workerId: "",
            data: [
                "insightCount": String(insights.count),
                "highPriorityCount": String(insights.filter { $0.priority == .high || $0.priority == .critical }.count),
                "intelligenceUpdate": "true"
            ]
        )
        broadcastAdminUpdate(update)
    }
    
    // MARK: - Live Update Types (moved inside class)

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
    
    // MARK: - Live Update Creation
    
    private func createLiveWorkerUpdate(from update: CoreTypes.DashboardUpdate) {
        guard !update.workerId.isEmpty,
              update.source == .worker else { return }
        
        let workerUpdate = LiveWorkerUpdate(
            workerId: update.workerId,
            workerName: update.data["workerName"],
            action: generateActionDescription(for: update),
            buildingId: update.buildingId.isEmpty ? nil : update.buildingId,
            buildingName: update.data["buildingName"]
        )
        
        liveWorkerUpdates.append(workerUpdate)
        limitLiveUpdates()
    }
    
    private func createLiveAdminAlert(from update: CoreTypes.DashboardUpdate) {
        guard update.type == .buildingMetricsChanged ||
              update.type == .complianceStatusChanged else { return }
        
        // Use real thresholds from OperationalDataManager
        let config = operationalDataManager.getSystemConfiguration()
        
        let severity: LiveAdminAlert.Severity = {
            if let overdueTasks = Int(update.data["overdueTasks"] ?? "0"),
               overdueTasks > config.criticalOverdueThreshold {
                return .critical
            } else if let completionRate = Double(update.data["completionRate"] ?? "0"),
                     completionRate < config.minimumCompletionRate {
                return .high
            } else if let urgentTasks = Int(update.data["urgentTasks"] ?? "0"),
                     urgentTasks > config.urgentTaskThreshold {
                return .medium
            } else {
                return .low
            }
        }()
        
        let alert = LiveAdminAlert(
            title: update.type.rawValue,
            severity: severity,
            buildingId: update.buildingId
        )
        
        liveAdminAlerts.append(alert)
        limitLiveUpdates()
    }
    
    private func createLiveClientMetric(from update: CoreTypes.DashboardUpdate) {
        guard update.type == .buildingMetricsChanged else { return }
        
        // Calculate real trend from OperationalDataManager historical data
        let trend: CoreTypes.TrendDirection = {
            if let metricName = update.data["metricName"] as? String {
                return operationalDataManager.calculateTrend(for: metricName, days: 7)
            }
            // Try to calculate trend for building completion if available
            if !update.buildingId.isEmpty {
                return operationalDataManager.calculateTrend(
                    for: "building_\(update.buildingId)_completion",
                    days: 7
                )
            }
            return .stable
        }()
        
        let metricValue: String = {
            if let value = update.data["completionRate"] {
                return value
            }
            return "N/A"
        }()
        
        let metric = LiveClientMetric(
            name: update.type.rawValue,
            value: metricValue,
            trend: trend
        )
        
        liveClientMetrics.append(metric)
        limitLiveUpdates()
    }
    
    private func limitLiveUpdates() {
        // Get limit from OperationalDataManager configuration
        let config = operationalDataManager.getSystemConfiguration()
        let maxLiveUpdates = config.maxLiveUpdatesPerFeed
        
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
    
    private func updateUnifiedState(from update: CoreTypes.DashboardUpdate) {
        // Update building metrics if relevant
        if !update.buildingId.isEmpty,
           update.type == .buildingMetricsChanged || update.type == .taskCompleted {
            
            // Schedule async work to run later
            scheduleMetricsUpdate(for: update.buildingId)
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
                        
                        // Record metric for trend analysis
                        self.operationalDataManager.recordMetricValue(
                            metricName: "building_\(buildingId)_completion",
                            value: metrics.completionRate
                        )
                    }
                } catch {
                    self.operationalDataManager.logError("Failed to update building metrics", error: error)
                }
            }
        }
    }
    
    // MARK: - Real-Time Synchronization Setup
    
    private func setupRealTimeSynchronization() {
        // Subscribe to cross-dashboard updates for logging
        crossDashboardUpdates
            .sink(receiveValue: { update in
                print("🔄 Cross-dashboard sync: \(update.source.rawValue) → \(update.type.rawValue)")
            })
            .store(in: &cancellables)
    }
    
    private func setupAutoSync() {
        // Get sync interval from OperationalDataManager configuration
        let config = operationalDataManager.getSystemConfiguration()
        let syncInterval = config.autoSyncInterval
        
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
                let update = CoreTypes.DashboardUpdate(
                    source: .admin,
                    type: .buildingMetricsChanged,
                    buildingId: "",
                    workerId: "",
                    data: ["buildingCount": String(buildings.count), "autoSync": "true"]
                )
                
                broadcastAdminUpdate(update)
            }
            
            lastSyncTime = Date()
            
            // Store sync event in OperationalDataManager
            operationalDataManager.recordSyncEvent(timestamp: lastSyncTime ?? Date())
            
        } catch {
            operationalDataManager.logError("Auto-sync failed", error: error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateActionDescription(for update: CoreTypes.DashboardUpdate) -> String {
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
            return update.type.rawValue
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
    public func getRecentUpdates(for source: CoreTypes.DashboardUpdate.Source, limit: Int = 5) -> [CoreTypes.DashboardUpdate] {
        // Fetch real recent updates from OperationalDataManager
        let recentEvents = operationalDataManager.getRecentEvents(limit: limit)
        
        return recentEvents.compactMap { event in
            // Convert operational events to dashboard updates
            guard let eventType = CoreTypes.DashboardUpdate.UpdateType(rawValue: event.type) else { return nil }
            
            return CoreTypes.DashboardUpdate(
                source: source,
                type: eventType,
                buildingId: event.buildingId ?? "",
                workerId: event.workerId ?? "",
                data: event.metadata as? [String: String] ?? [:]
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
    public var workerUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        workerDashboardUpdates
            .filter { $0.source == .worker || $0.type == .taskCompleted || $0.type == .workerClockedIn || $0.type == .workerClockedOut }
            .eraseToAnyPublisher()
    }
    
    /// Publisher for admin-specific updates
    public var adminUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        adminDashboardUpdates
            .filter { $0.source == .admin || $0.type == .buildingMetricsChanged }
            .eraseToAnyPublisher()
    }
    
    /// Publisher for client-specific updates
    public var clientUpdates: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        clientDashboardUpdates
            .filter { $0.source == .client || $0.type == .buildingMetricsChanged }
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

// MARK: - Sample Data Generation

extension DashboardSyncService {
    /// Generate sample updates based on real data patterns
    /// Used for testing and demo purposes - all data comes from OperationalDataManager
    public func generateSampleUpdate(type: CoreTypes.DashboardUpdate.UpdateType) -> CoreTypes.DashboardUpdate? {
        // Get real workers and buildings from OperationalDataManager
        guard let randomWorker = operationalDataManager.getRandomWorker(),
              let randomBuilding = operationalDataManager.getRandomBuilding() else {
            if debugMode {
                print("⚠️ DashboardSyncService: Cannot generate sample - no real data available")
            }
            return nil
        }
        
        // Create update based on real data
        return CoreTypes.DashboardUpdate(
            source: .worker,
            type: type,
            buildingId: randomBuilding.id,
            workerId: randomWorker.id,
            data: [
                "workerName": randomWorker.name,
                "buildingName": randomBuilding.name,
                "isRealData": "true"
            ]
        )
    }
}
