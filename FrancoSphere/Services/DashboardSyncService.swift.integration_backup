//
//  DashboardSyncService.swift
//  FrancoSphere
//
//  ✅ CROSS-DASHBOARD COORDINATION: Real-time synchronization between Worker/Admin/Client
//  ✅ INTEGRATION: Hooks into existing services and ViewModels
//  ✅ ACTOR-SAFE: Compatible with existing actor-based architecture
//  ✅ REAL-TIME: Live updates with intelligent broadcasting
//

import Foundation
import Combine
import SwiftUI

// MARK: - Cross-Dashboard Update Types

public struct DashboardUpdate: Identifiable {
    public let id = UUID()
    public let source: DashboardSource
    public let type: UpdateType
    public let buildingId: String?
    public let workerId: String?
    public let data: [String: Any]
    public let timestamp = Date()
    
    public init(source: DashboardSource, type: UpdateType, buildingId: String?, workerId: String?, data: [String: Any]) {
        self.source = source
        self.type = type
        self.buildingId = buildingId
        self.workerId = workerId
        self.data = data
    }
}

public enum DashboardSource: String, CaseIterable {
    case worker = "worker"
    case admin = "admin"
    case client = "client"
    
    public var displayName: String {
        switch self {
        case .worker: return "Worker"
        case .admin: return "Admin"
        case .client: return "Client"
        }
    }
    
    public var color: Color {
        switch self {
        case .worker: return .blue
        case .admin: return .orange
        case .client: return .purple
        }
    }
    
    public var icon: String {
        switch self {
        case .worker: return "person.fill.checkmark"
        case .admin: return "chart.line.uptrend.xyaxis"
        case .client: return "building.2.fill"
        }
    }
}

public enum UpdateType: String, CaseIterable {
    case taskCompleted = "task_completed"
    case taskStarted = "task_started"
    case workerClockedIn = "worker_clocked_in"
    case workerClockedOut = "worker_clocked_out"
    case buildingMetricsChanged = "building_metrics_changed"
    case portfolioUpdated = "portfolio_updated"
    case complianceChanged = "compliance_changed"
    case intelligenceGenerated = "intelligence_generated"
    case performanceChanged = "performance_changed"
    
    public var displayName: String {
        switch self {
        case .taskCompleted: return "Task Completed"
        case .taskStarted: return "Task Started"
        case .workerClockedIn: return "Worker Clocked In"
        case .workerClockedOut: return "Worker Clocked Out"
        case .buildingMetricsChanged: return "Metrics Updated"
        case .portfolioUpdated: return "Portfolio Updated"
        case .complianceChanged: return "Compliance Changed"
        case .intelligenceGenerated: return "New Insights"
        case .performanceChanged: return "Performance Update"
        }
    }
}

// MARK: - Live Update Feed Types

public struct LiveWorkerUpdate: Identifiable {
    public let id = UUID()
    public let workerName: String
    public let action: String
    public let buildingName: String
    public let timestamp = Date()
}

public struct LiveAdminAlert: Identifiable {
    public let id = UUID()
    public let title: String
    public let severity: DashboardAlertSeverity
    public let buildingId: String
    public let timestamp = Date()
}

public struct LiveClientMetric: Identifiable {
    public let id = UUID()
    public let name: String
    public let value: String
    public let trend: CoreTypes.TrendDirection
    public let timestamp = Date()
}

public enum DashboardAlertSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
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
    @Published public var unifiedPortfolioState: PortfolioState?
    @Published public var isLive = true
    @Published public var lastSyncTime: Date?
    
    // MARK: - Service Dependencies
    
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    
    private init() {
        setupRealTimeSynchronization()
        setupAutoSync()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Public Broadcasting Methods
    
    /// Broadcast update from Worker Dashboard (task completion, clock-in, etc.)
    public func broadcastWorkerUpdate(_ update: DashboardUpdate) {
        crossDashboardSubject.send(update)
        workerUpdatesSubject.send(update)
        
        // Create live update for other dashboards
        createLiveWorkerUpdate(from: update)
        
        // Update unified state
        updateUnifiedState(from: update)
        
        // Trigger dependent updates
        triggerDependentUpdates(from: update)
        
        lastSyncTime = Date()
        print("📡 Worker update broadcast: \(update.type.displayName)")
    }
    
    /// Broadcast update from Admin Dashboard (portfolio changes, analytics, etc.)
    public func broadcastAdminUpdate(_ update: DashboardUpdate) {
        crossDashboardSubject.send(update)
        adminUpdatesSubject.send(update)
        
        // Create live alert for other dashboards
        createLiveAdminAlert(from: update)
        
        // Update unified state
        updateUnifiedState(from: update)
        
        // Trigger dependent updates
        triggerDependentUpdates(from: update)
        
        lastSyncTime = Date()
        print("📡 Admin update broadcast: \(update.type.displayName)")
    }
    
    /// Broadcast update from Client Dashboard (portfolio review, strategic changes, etc.)
    public func broadcastClientUpdate(_ update: DashboardUpdate) {
        crossDashboardSubject.send(update)
        clientUpdatesSubject.send(update)
        
        // Create live metric for other dashboards
        createLiveClientMetric(from: update)
        
        // Update unified state
        updateUnifiedState(from: update)
        
        lastSyncTime = Date()
        print("📡 Client update broadcast: \(update.type.displayName)")
    }
    
    // MARK: - Integration Hooks for Existing Services
    
    /// Hook into WorkerContextEngine task completion
    public func onTaskCompleted(taskId: String, workerId: String, buildingId: String, evidence: ActionEvidence) {
        let update = DashboardUpdate(
            source: .worker,
            type: .taskCompleted,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "taskId": taskId,
                "completionTime": Date(),
                "evidence": evidence.description,
                "photoCount": evidence.photoURLs.count
            ]
        )
        
        broadcastWorkerUpdate(update)
    }
    
    /// Hook into ClockInManager clock-in events
    public func onWorkerClockedIn(workerId: String, buildingId: String, buildingName: String) {
        let update = DashboardUpdate(
            source: .worker,
            type: .workerClockedIn,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "buildingName": buildingName,
                "clockInTime": Date()
            ]
        )
        
        broadcastWorkerUpdate(update)
    }
    
    /// Hook into ClockInManager clock-out events
    public func onWorkerClockedOut(workerId: String, buildingId: String?) {
        let update = DashboardUpdate(
            source: .worker,
            type: .workerClockedOut,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "clockOutTime": Date()
            ]
        )
        
        broadcastWorkerUpdate(update)
    }
    
    /// Hook into BuildingMetricsService metrics updates
    public func onBuildingMetricsChanged(buildingId: String, metrics: CoreTypes.BuildingMetrics) {
        // Update unified state first
        unifiedBuildingMetrics[buildingId] = metrics
        
        let update = DashboardUpdate(
            source: .admin,
            type: .buildingMetricsChanged,
            buildingId: buildingId,
            workerId: nil,
            data: [
                "completionRate": metrics.completionRate,
                "pendingTasks": metrics.pendingTasks,
                "overdueTasks": metrics.overdueTasks,
                "activeWorkers": metrics.activeWorkers,
                "isCompliant": metrics.isCompliant,
                "overallScore": metrics.overallScore
            ]
        )
        
        broadcastAdminUpdate(update)
    }
    
    /// Hook into IntelligenceService portfolio insights
    public func onPortfolioIntelligenceUpdated(insights: [CoreTypes.IntelligenceInsight]) {
        let criticalInsights = insights.filter { $0.priority == .critical }
        
        let update = DashboardUpdate(
            source: .admin,
            type: .intelligenceGenerated,
            buildingId: nil,
            workerId: nil,
            data: [
                "totalInsights": insights.count,
                "criticalInsights": criticalInsights.count,
                "actionableInsights": insights.filter { $0.actionRequired }.count
            ]
        )
        
        broadcastAdminUpdate(update)
        
        // Create alerts for critical insights
        for insight in criticalInsights {
            let alert = LiveAdminAlert(
                title: insight.title,
                severity: .critical,
                buildingId: insight.affectedBuildings.first ?? ""
            )
            
            liveAdminAlerts.append(alert)
            limitLiveUpdates()
        }
    }
    
    // MARK: - Live Update Management
    
    private func createLiveWorkerUpdate(from update: DashboardUpdate) {
        guard let workerId = update.workerId else { return }
        
        let buildingName = update.data["buildingName"] as? String ?? getBuildingName(update.buildingId)
        let workerName = getWorkerName(workerId) ?? "Unknown Worker"
        let action = generateActionDescription(for: update)
        
        let liveUpdate = LiveWorkerUpdate(
            workerName: workerName,
            action: action,
            buildingName: buildingName ?? "Unknown Building"
        )
        
        liveWorkerUpdates.append(liveUpdate)
        limitLiveUpdates()
    }
    
    private func createLiveAdminAlert(from update: DashboardUpdate) {
        guard update.type == .buildingMetricsChanged || update.type == .intelligenceGenerated else {
            return
        }
        
        let severity: DashboardAlertSeverity = {
            if let overdueTasks = update.data["overdueTasks"] as? Int, overdueTasks > 10 {
                return .critical
            } else if let completionRate = update.data["completionRate"] as? Double, completionRate < 0.5 {
                return .high
            } else {
                return .medium
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
        
        let metric = LiveClientMetric(
            name: update.type.displayName,
            value: "Updated",
            trend: .stable // Can be enhanced with real trend calculation
        )
        
        liveClientMetrics.append(metric)
        limitLiveUpdates()
    }
    
    private func limitLiveUpdates() {
        // Keep only last 10 updates for performance
        if liveWorkerUpdates.count > 10 {
            liveWorkerUpdates.removeFirst(liveWorkerUpdates.count - 10)
        }
        if liveAdminAlerts.count > 10 {
            liveAdminAlerts.removeFirst(liveAdminAlerts.count - 10)
        }
        if liveClientMetrics.count > 10 {
            liveClientMetrics.removeFirst(liveClientMetrics.count - 10)
        }
    }
    
    // MARK: - Unified State Management
    
    private func updateUnifiedState(from update: DashboardUpdate) {
        // Update building metrics if relevant
        if let buildingId = update.buildingId,
           update.type == .buildingMetricsChanged || update.type == .taskCompleted {
            
            Task {
                do {
                    let metrics = try await buildingMetricsService.calculateMetrics(for: buildingId)
                    await MainActor.run {
                        self.unifiedBuildingMetrics[buildingId] = metrics
                    }
                } catch {
                    print("❌ Failed to update unified building metrics: \(error)")
                }
            }
        }
        
        // Update portfolio state for client-level changes
        if update.type == .portfolioUpdated || update.type == .intelligenceGenerated {
            Task {
                await refreshPortfolioState()
            }
        }
    }
    
    private func triggerDependentUpdates(from update: DashboardUpdate) {
        // Worker task completion triggers admin metrics refresh
        if update.source == .worker && update.type == .taskCompleted {
            Task {
                try await refreshAdminMetrics()
            }
        }
        
        // Admin metrics changes trigger client portfolio refresh
        if update.source == .admin && (update.type == .buildingMetricsChanged || update.type == .intelligenceGenerated) {
            Task {
                await refreshClientPortfolio()
            }
        }
    }
    
    // MARK: - Cross-Dashboard Refresh Triggers
    
    private func refreshAdminMetrics() async throws {
        // Trigger admin dashboard to refresh its metrics
        let update = DashboardUpdate(
            source: .admin,
            type: .performanceChanged,
            buildingId: nil,
            workerId: nil,
            data: ["triggeredBy": "worker_task_completion"]
        )
        
        await MainActor.run {
            self.adminUpdatesSubject.send(update)
        }
    }
    
    private func refreshClientPortfolio() async {
        // Trigger client dashboard to refresh portfolio
        let update = DashboardUpdate(
            source: .client,
            type: .portfolioUpdated,
            buildingId: nil,
            workerId: nil,
            data: ["triggeredBy": "admin_metrics_change"]
        )
        
        await MainActor.run {
            self.clientUpdatesSubject.send(update)
        }
    }
    
    private func refreshPortfolioState() async {
        // Update unified portfolio state
        unifiedPortfolioState = PortfolioState(
            totalBuildings: unifiedBuildingMetrics.count,
            averageScore: calculateAverageScore(),
            lastUpdated: Date()
        )
    }
    
    // MARK: - Real-Time Synchronization Setup
    
    private func setupRealTimeSynchronization() {
        // Subscribe to cross-dashboard updates for logging
        crossDashboardUpdates
            .sink { update in
                print("🔄 Cross-dashboard sync: \(update.source.displayName) → \(update.type.displayName)")
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoSync() {
        // Auto-sync every 30 seconds to ensure consistency
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performAutoSync()
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
            
        } catch {
            print("❌ Auto-sync failed: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getBuildingName(_ buildingId: String?) -> String? {
        guard let buildingId = buildingId else { return nil }
        
        // This would be enhanced to use a building name cache
        // For now, return a placeholder
        return "Building \(buildingId)"
    }
    
    private func getWorkerName(_ workerId: String) -> String? {
        // This would be enhanced to use a worker name cache
        // For now, return a placeholder
        return "Worker \(workerId)"
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
    
    private func calculateAverageScore() -> Double {
        guard !unifiedBuildingMetrics.isEmpty else { return 0.0 }
        
        let totalScore = unifiedBuildingMetrics.values.reduce(0) { $0 + $1.overallScore }
        return Double(totalScore) / Double(unifiedBuildingMetrics.count)
    }
}

// MARK: - Portfolio State Type

public struct PortfolioState {
    public let totalBuildings: Int
    public let averageScore: Double
    public let lastUpdated: Date
}

// MARK: - Extensions for SwiftUI Integration

extension DashboardSyncService {
    
    /// Enable cross-dashboard synchronization (called from DashboardView)
    public func enableCrossDashboardSync() {
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
        // This would be enhanced with actual update history storage
        return []
    }
    
    /// Clear live update feeds
    public func clearLiveUpdates() {
        liveWorkerUpdates.removeAll()
        liveAdminAlerts.removeAll()
        liveClientMetrics.removeAll()
    }
}
