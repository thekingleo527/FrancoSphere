//
//  AdminDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With forensic developer's punchlist requirements
//  ✅ ENHANCED: Cross-dashboard integration ready
//  ✅ INTEGRATED: Real-time synchronization compatible
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AdminDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties for Admin UI
    @Published var buildings: [NamedCoordinate] = []
    @Published var activeWorkers: [WorkerProfile] = []
    @Published var ongoingTasks: [ContextualTask] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var portfolioInsights: [CoreTypes.IntelligenceInsight] = []
    
    // MARK: - Building Intelligence Panel
    @Published var selectedBuildingInsights: [CoreTypes.IntelligenceInsight] = []
    @Published var selectedBuildingId: String?
    @Published var isLoadingIntelligence = false
    
    // MARK: - Loading States
    @Published var isLoading = false
    @Published var isLoadingInsights = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Cross-Dashboard Integration (Per Forensic Punchlist)
    @Published var dashboardSyncStatus: DashboardSyncStatus = .synced
    @Published var crossDashboardUpdates: [CrossDashboardUpdate] = []
    
    // MARK: - Services (Using .shared pattern consistently)
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    
    // MARK: - Real-time Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupAutoRefresh()
        setupCrossDashboardSync()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Data Loading Methods
    
    /// Loads all dashboard data
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load core data concurrently
            async let buildingsLoad = buildingService.getAllBuildings()
            async let workersLoad = workerService.getAllActiveWorkers()
            async let tasksLoad = taskService.getAllTasks()
            
            // Wait for results
            let (buildings, workers, tasks) = try await (buildingsLoad, workersLoad, tasksLoad)
            
            // Update UI
            self.buildings = buildings
            self.activeWorkers = workers
            self.ongoingTasks = tasks
            self.lastUpdateTime = Date()
            
            // Load metrics and insights
            await loadBuildingMetrics()
            await loadPortfolioInsights()
            
            print("✅ Admin dashboard data loaded: \(buildings.count) buildings, \(workers.count) workers, \(tasks.count) tasks")
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Failed to load admin dashboard data: \(error)")
        }
        
        isLoading = false
    }
    
    /// Loads building metrics for all buildings
    private func loadBuildingMetrics() async {
        var metrics: [String: CoreTypes.BuildingMetrics] = [:]
        
        for building in buildings {
            do {
                let buildingMetrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                metrics[building.id] = buildingMetrics
            } catch {
                print("⚠️ Failed to load metrics for building \(building.id): \(error)")
            }
        }
        
        self.buildingMetrics = metrics
        broadcastCrossDashboardUpdate(.metricsUpdated(buildingIds: Array(metrics.keys)))
    }
    
    /// Loads portfolio-wide intelligence insights
    func loadPortfolioInsights() async {
        isLoadingInsights = true
        
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            self.portfolioInsights = insights
            self.isLoadingInsights = false
            
            print("✅ Portfolio insights loaded: \(insights.count) insights")
            broadcastCrossDashboardUpdate(.insightsUpdated(count: insights.count))
            
        } catch {
            self.portfolioInsights = []
            self.isLoadingInsights = false
            print("⚠️ Failed to load portfolio insights: \(error)")
        }
    }
    
    // MARK: - Building Intelligence Methods
    
    /// Fetches detailed intelligence for a specific building
    func fetchBuildingIntelligence(for buildingId: String) async {
        guard !buildingId.isEmpty else {
            print("⚠️ Invalid building ID provided")
            return
        }
        
        isLoadingIntelligence = true
        selectedBuildingInsights = []
        selectedBuildingId = buildingId
        
        do {
            let insights = try await intelligenceService.generateBuildingInsights(for: buildingId)
            
            self.selectedBuildingInsights = insights
            self.isLoadingIntelligence = false
            
            print("✅ Intelligence loaded for building \(buildingId): \(insights.count) insights")
            broadcastCrossDashboardUpdate(.buildingIntelligenceUpdated(buildingId: buildingId))
            
        } catch {
            self.isLoadingIntelligence = false
            self.errorMessage = "Failed to fetch intelligence: \(error.localizedDescription)"
            print("🚨 Failed to fetch intelligence for building \(buildingId): \(error)")
        }
    }
    
    /// Clears the selected building intelligence
    func clearBuildingIntelligence() {
        selectedBuildingInsights = []
        selectedBuildingId = nil
        errorMessage = nil
        print("🧹 Cleared selected building intelligence")
    }
    
    // MARK: - Real-time Update Methods
    
    /// Refreshes all dashboard data
    func refreshDashboardData() async {
        guard !isLoading else { return }
        
        print("🔄 Refreshing admin dashboard data...")
        dashboardSyncStatus = .syncing
        await loadDashboardData()
        dashboardSyncStatus = .synced
    }
    
    /// Refreshes metrics for a specific building
    func refreshBuildingMetrics(for buildingId: String) async {
        do {
            let metrics = try await buildingMetricsService.calculateMetrics(for: buildingId)
            buildingMetrics[buildingId] = metrics
            print("✅ Refreshed metrics for building \(buildingId)")
            broadcastCrossDashboardUpdate(.metricsUpdated(buildingIds: [buildingId]))
        } catch {
            print("❌ Failed to refresh metrics for building \(buildingId): \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get building metrics for a specific building
    func getBuildingMetrics(for buildingId: String) -> CoreTypes.BuildingMetrics? {
        return buildingMetrics[buildingId]
    }
    
    /// ✅ FIXED: Get insights for a specific building (corrected property references)
    func getInsightsForBuilding(_ buildingId: String) -> [CoreTypes.IntelligenceInsight] {
        return portfolioInsights.filter { insight in
            // ✅ FIXED: affectedBuildings is [String], not [String]? - removed optional chaining
            insight.affectedBuildings.contains(buildingId)
        }
    }
    
    /// ✅ FIXED: Calculate portfolio summary metrics (no ambiguous type)
    func getAdminPortfolioSummary() -> AdminPortfolioSummary {
        let totalBuildings = buildings.count
        let totalWorkers = activeWorkers.count
        let totalTasks = ongoingTasks.count
        let completedTasks = ongoingTasks.filter { $0.isCompleted }.count
        
        let averageCompletion = buildingMetrics.values.isEmpty ? 0 :
            buildingMetrics.values.reduce(0) { $0 + $1.completionRate } / Double(buildingMetrics.count)
        
        let criticalInsights = portfolioInsights.filter { $0.priority == .critical }.count
        let actionableInsights = portfolioInsights.filter { $0.actionRequired }.count
        
        return AdminPortfolioSummary(
            totalBuildings: totalBuildings,
            totalWorkers: totalWorkers,
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            averageCompletion: averageCompletion,
            criticalInsights: criticalInsights,
            actionableInsights: actionableInsights,
            efficiencyStatus: calculateEfficiencyStatus(averageCompletion)
        )
    }
    
    /// Calculate efficiency status based on completion rate
    private func calculateEfficiencyStatus(_ completion: Double) -> EfficiencyStatus {
        switch completion {
        case 0.9...: return .excellent
        case 0.7..<0.9: return .good
        default: return .needsImprovement
        }
    }
    
    // MARK: - Cross-Dashboard Integration (Per Forensic Punchlist)
    
    /// Setup cross-dashboard synchronization
    private func setupCrossDashboardSync() {
        // TODO: Integrate with DashboardSyncService when created
        // This is prepared for Phase 1.2 implementation
        print("🔗 Admin dashboard prepared for cross-dashboard sync")
    }
    
    /// Broadcast update to other dashboards
    private func broadcastCrossDashboardUpdate(_ update: CrossDashboardUpdate) {
        crossDashboardUpdates.append(update)
        // TODO: Send to DashboardSyncService when created
        print("📡 Broadcasting update: \(update)")
    }
    
    /// Setup auto-refresh timer
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.refreshDashboardData()
            }
        }
    }
    
    /// Handle cross-dashboard update received from other dashboards
    func handleCrossDashboardUpdate(_ update: CrossDashboardUpdate) {
        switch update {
        case .taskCompleted(let buildingId):
            Task {
                await refreshBuildingMetrics(for: buildingId)
            }
        case .workerClockedIn(let buildingId):
            Task {
                await refreshBuildingMetrics(for: buildingId)
            }
        case .complianceUpdated(let buildingIds):
            Task {
                for buildingId in buildingIds {
                    await refreshBuildingMetrics(for: buildingId)
                }
            }
        default:
            break
        }
    }
}

// MARK: - Supporting Types (✅ FIXED: No ambiguous types)

/// Admin-specific portfolio summary to avoid type conflicts
struct AdminPortfolioSummary {
    let totalBuildings: Int
    let totalWorkers: Int
    let totalTasks: Int
    let completedTasks: Int
    let averageCompletion: Double
    let criticalInsights: Int
    let actionableInsights: Int
    let efficiencyStatus: EfficiencyStatus
    
    var completionPercentage: String {
        return "\(Int(averageCompletion * 100))%"
    }
    
    var efficiencyDescription: String {
        switch efficiencyStatus {
        case .excellent: return "Excellent Performance"
        case .good: return "Good Performance"
        case .needsImprovement: return "Needs Improvement"
        }
    }
}

enum EfficiencyStatus {
    case excellent
    case good
    case needsImprovement
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .needsImprovement: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "hand.thumbsup.fill"
        case .needsImprovement: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Cross-Dashboard Types (Per Forensic Punchlist)

enum DashboardSyncStatus {
    case synced
    case syncing
    case error
    
    var description: String {
        switch self {
        case .synced: return "Synced"
        case .syncing: return "Syncing..."
        case .error: return "Sync Error"
        }
    }
    
    var color: Color {
        switch self {
        case .synced: return .green
        case .syncing: return .blue
        case .error: return .red
        }
    }
}

enum CrossDashboardUpdate {
    case taskCompleted(buildingId: String)
    case workerClockedIn(buildingId: String)
    case metricsUpdated(buildingIds: [String])
    case insightsUpdated(count: Int)
    case buildingIntelligenceUpdated(buildingId: String)
    case complianceUpdated(buildingIds: [String])
    
    var description: String {
        switch self {
        case .taskCompleted(let buildingId):
            return "Task completed at building \(buildingId)"
        case .workerClockedIn(let buildingId):
            return "Worker clocked in at building \(buildingId)"
        case .metricsUpdated(let buildingIds):
            return "Metrics updated for \(buildingIds.count) buildings"
        case .insightsUpdated(let count):
            return "\(count) portfolio insights updated"
        case .buildingIntelligenceUpdated(let buildingId):
            return "Intelligence updated for building \(buildingId)"
        case .complianceUpdated(let buildingIds):
            return "Compliance updated for \(buildingIds.count) buildings"
        }
    }
}
