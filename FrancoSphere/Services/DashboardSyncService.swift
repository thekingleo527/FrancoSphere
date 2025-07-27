//
//  DashboardSyncService.swift
//  FrancoSphere v6.0
//
//  Cross-dashboard synchronization service for real-time updates
//  Manages communication between Worker, Admin, and Client dashboards
//
//  ✅ FIXED: Removed references to non-existent PortfolioState
//  ✅ FIXED: Using CoreTypes.PortfolioIntelligence instead
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Proper type references and initialization
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

public enum DashboardUpdateType: String, CaseIterable {
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
    public let type: DashboardUpdateType
    public let timestamp = Date()
    public let buildingId: String?
    public let workerId: String?
    public let data: [String: Any]
    
    public init(source: DashboardSource, type: DashboardUpdateType, buildingId: String? = nil, workerId: String? = nil, data: [String: Any] = [:]) {
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
                "buildingName": (buildingName ?? getBuildingName(buildingId) ?? "Unknown Building") as Any,
                "workerName": (getWorkerName(workerId) ?? "Worker \(workerId)") as Any
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
                "buildingName": (getBuildingName(buildingId) ?? "Unknown Building") as Any,
                "workerName": (getWorkerName(workerId) ?? "Worker \(workerId)") as Any
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
                "taskId": taskId as Any,
                "buildingName": (getBuildingName(buildingId) ?? "Unknown Building") as Any,
                "workerName": (getWorkerName(workerId) ?? "Worker \(workerId)") as Any
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
                "completionRate": metrics.completionRate as Any,
                "overdueTasks": metrics.overdueTasks as Any,
                "urgentTasks": metrics.urgentTasksCount as Any,
                "activeWorkers": metrics.activeWorkers as Any
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
                "insightCount": insights.count as Any,
                "highPriorityCount": insights.filter { $0.priority == .high || $0.priority == .critical }.count as Any
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
                "totalBuildings": portfolio.totalBuildings as Any,
                "activeWorkers": portfolio.activeWorkers as Any,
                "completionRate": portfolio.completionRate as Any,
                "criticalIssues": portfolio.criticalIssues as Any
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
            
            // Create a detached task to avoid actor isolation issues
            Task.detached { [weak self] in
                guard let self = self else { return }
                do {
                    let metrics = try await buildingMetricsService.calculateMetrics(for: buildingId)
                    await self.updateBuildingMetrics(buildingId, metrics: metrics)
                } catch {
                    print("❌ Failed to update unified building metrics: \(error)")
                }
            }
        }
        
        // Update portfolio state for client-level changes
        if update.type == .portfolioUpdated || update.type == .performanceChanged {
            // Create a detached task to avoid actor isolation issues
            Task.detached { [weak self] in
                guard let self = self else { return }
                do {
                    let portfolio = try await buildingService.generatePortfolioIntelligence()
                    await self.updatePortfolioIntelligence(portfolio)
                } catch {
                    print("❌ Failed to refresh portfolio intelligence: \(error)")
                }
            }
        }
    }
    
    private func updateBuildingMetrics(_ buildingId: String, metrics: CoreTypes.BuildingMetrics) {
        self.unifiedBuildingMetrics[buildingId] = metrics
    }
    
    private func updatePortfolioIntelligence(_ portfolio: CoreTypes.PortfolioIntelligence) {
        self.unifiedPortfolioIntelligence = portfolio
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
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task.detached {
                await DashboardSyncService.shared.performAutoSync()
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
                    data: ["buildingCount": buildings.count as Any, "autoSync": true as Any]
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
        guard let id = buildingId else { return nil }
        // In a real implementation, this would fetch from database
        // For now, return a placeholder
        return "Building \(id)"
    }
    
    private func getWorkerName(_ workerId: String) -> String? {
        // Map known worker IDs to names
        switch workerId {
        case "worker_001", "4": return "Kevin Dutan"
        case "worker_002": return "Maria Rodriguez"
        case "worker_003": return "James Wilson"
        default: return "Worker \(workerId)"
        }
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
