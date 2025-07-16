//
//  AdminDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Using correct service methods that actually exist
//  ✅ FIXED: Service reference inconsistencies (using .shared pattern)
//  ✅ FIXED: Proper integration with BuildingMetricsService and IntelligenceService
//  ✅ ALIGNED: With actual implementation and available methods
//

import Foundation
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
    
    // MARK: - Services (Using .shared pattern consistently)
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    
    // MARK: - Real-time Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    init() {
        setupAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Setup Methods
    
    private func setupAutoRefresh() {
        // Refresh dashboard data every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshDashboardData()
            }
        }
    }
    
    // MARK: - Main Data Loading
    
    /// Loads all dashboard data including buildings, workers, tasks, and metrics
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load core data concurrently
            async let buildingsResult = buildingService.getAllBuildings()
            async let workersResult = workerService.getAllActiveWorkers()
            async let tasksResult = taskService.getAllTasks()
            
            let (buildings, workers, tasks) = await (
                try buildingsResult,
                try workersResult,
                try tasksResult
            )
            
            // Update UI with loaded data
            self.buildings = buildings
            self.activeWorkers = workers
            self.ongoingTasks = tasks.filter { !$0.isCompleted }
            self.lastUpdateTime = Date()
            
            // Load building metrics for all buildings
            await loadBuildingMetrics()
            
            // Load portfolio insights
            await loadPortfolioInsights()
            
            self.isLoading = false
            
            print("✅ Admin dashboard loaded: \(buildings.count) buildings, \(workers.count) workers, \(ongoingTasks.count) ongoing tasks")
            
        } catch {
            self.errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
            self.isLoading = false
            print("🚨 Failed to load admin dashboard data: \(error)")
        }
    }
    
    /// Loads metrics for all buildings using BuildingMetricsService
    private func loadBuildingMetrics() async {
        let buildingIds = buildings.map { $0.id }
        
        do {
            // Get metrics for each building individually since getDashboardMetrics might not exist
            var metricsDict: [String: CoreTypes.BuildingMetrics] = [:]
            
            for buildingId in buildingIds {
                do {
                    let metrics = try await buildingMetricsService.getPropertyCardMetrics(for: buildingId)
                    metricsDict[buildingId] = metrics
                } catch {
                    print("⚠️ Failed to load metrics for building \(buildingId): \(error)")
                    // Continue with other buildings
                }
            }
            
            self.buildingMetrics = metricsDict
            print("📊 Loaded metrics for \(metricsDict.count) buildings")
            
        } catch {
            print("⚠️ Failed to load building metrics: \(error)")
        }
    }
    
    /// Loads portfolio insights using IntelligenceService
    private func loadPortfolioInsights() async {
        isLoadingInsights = true
        
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            
            self.portfolioInsights = insights
            self.isLoadingInsights = false
            
            print("💡 Generated \(insights.count) portfolio insights")
            
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
            // ✅ FIXED: Use IntelligenceService method that actually exists
            let insights = try await intelligenceService.generateBuildingInsights(for: buildingId)
            
            self.selectedBuildingInsights = insights
            self.isLoadingIntelligence = false
            
            print("✅ Intelligence loaded for building \(buildingId): \(insights.count) insights")
            
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
    
    /// Refreshes metrics for a specific building
    func refreshBuildingMetrics(for buildingId: String) async {
        do {
            let metrics = try await buildingMetricsService.getPropertyCardMetrics(for: buildingId)
            
            self.buildingMetrics[buildingId] = metrics
            
            print("🔄 Refreshed metrics for building \(buildingId)")
            
        } catch {
            print("⚠️ Failed to refresh metrics for building \(buildingId): \(error)")
        }
    }
    
    /// Refreshes all dashboard data (called by timer)
    private func refreshDashboardData() async {
        guard !isLoading else { return }
        
        print("🔄 Auto-refreshing admin dashboard...")
        
        // Refresh building metrics only (lighter operation)
        await loadBuildingMetrics()
        
        // Update timestamp
        self.lastUpdateTime = Date()
    }
    
    /// Manual refresh triggered by user
    func refreshDashboard() async {
        print("🔄 Manual dashboard refresh requested")
        await loadDashboardData()
    }
    
    /// Refresh selected building intelligence
    func refreshSelectedBuildingIntelligence() async {
        guard let buildingId = selectedBuildingId else {
            print("⚠️ No building selected for intelligence refresh")
            return
        }
        
        await fetchBuildingIntelligence(for: buildingId)
    }
    
    // MARK: - Computed Properties for Admin Dashboard
    
    /// Dashboard summary statistics
    var dashboardSummary: (
        totalBuildings: Int,
        activeWorkers: Int,
        ongoingTasks: Int,
        completionRate: String,
        overallScore: Int
    ) {
        let totalMetrics = buildingMetrics.values
        let avgCompletionRate = totalMetrics.isEmpty ? 0.0 :
            totalMetrics.reduce(0.0) { $0 + $1.completionRate } / Double(totalMetrics.count)
        let avgScore = totalMetrics.isEmpty ? 0 :
            totalMetrics.reduce(0) { $0 + $1.overallScore } / totalMetrics.count
        
        return (
            totalBuildings: buildings.count,
            activeWorkers: activeWorkers.count,
            ongoingTasks: ongoingTasks.count,
            completionRate: "\(Int(avgCompletionRate * 100))%",
            overallScore: avgScore
        )
    }
    
    /// Buildings requiring immediate attention
    var buildingsNeedingAttention: [NamedCoordinate] {
        return buildings.filter { building in
            guard let metrics = buildingMetrics[building.id] else { return false }
            return metrics.overdueTasks > 3 || metrics.completionRate < 0.7 || metrics.urgentTasksCount > 5
        }.sorted { building1, building2 in
            let score1 = buildingMetrics[building1.id]?.overallScore ?? 0
            let score2 = buildingMetrics[building2.id]?.overallScore ?? 0
            return score1 < score2 // Sort by lowest score first
        }
    }
    
    /// Workers currently assigned to buildings
    var activeAssignedWorkers: [WorkerProfile] {
        return activeWorkers.filter { $0.isActive }
    }
    
    /// High priority insights requiring action
    var actionableInsights: [CoreTypes.IntelligenceInsight] {
        return portfolioInsights.filter { insight in
            insight.actionRequired && (insight.priority == .high || insight.priority == .critical)
        }
    }
    
    /// Portfolio health score based on all building metrics
    var portfolioHealthScore: Int {
        guard !buildingMetrics.isEmpty else { return 0 }
        
        let scores = buildingMetrics.values.map { $0.overallScore }
        return scores.reduce(0, +) / scores.count
    }
    
    /// Critical insights that need immediate attention
    var criticalInsights: [CoreTypes.IntelligenceInsight] {
        return portfolioInsights.filter { $0.priority == .critical }
    }
    
    /// Building-specific insights for selected building
    var selectedBuildingCriticalInsights: [CoreTypes.IntelligenceInsight] {
        return selectedBuildingInsights.filter { $0.priority == .critical || $0.priority == .high }
    }
    
    // MARK: - Helper Methods
    
    /// Get metrics for a specific building
    func getMetrics(for buildingId: String) -> CoreTypes.BuildingMetrics? {
        return buildingMetrics[buildingId]
    }
    
    /// Check if a building needs attention
    func buildingNeedsAttention(_ buildingId: String) -> Bool {
        guard let metrics = buildingMetrics[buildingId] else { return false }
        return metrics.overdueTasks > 3 || metrics.completionRate < 0.7
    }
    
    /// Get worker count for a specific building
    func getWorkerCount(for buildingId: String) -> Int {
        return buildingMetrics[buildingId]?.activeWorkers ?? 0
    }
    
    /// Get insights count for a specific building
    func getInsightsCount(for buildingId: String) -> Int {
        return portfolioInsights.filter { $0.affectedBuildings.contains(buildingId) }.count
    }
    
    /// Get critical issues count across portfolio
    var criticalIssuesCount: Int {
        return portfolioInsights.filter { $0.priority == .critical }.count
    }
    
    /// Get buildings with critical issues
    var buildingsWithCriticalIssues: [String] {
        let criticalInsights = portfolioInsights.filter { $0.priority == .critical }
        var buildingIds: Set<String> = []
        
        for insight in criticalInsights {
            buildingIds.formUnion(insight.affectedBuildings)
        }
        
        return Array(buildingIds)
    }
    
    /// Check if portfolio has any urgent issues
    var hasUrgentIssues: Bool {
        return portfolioInsights.contains { $0.priority == .critical || $0.priority == .high }
    }
    
    /// Get portfolio efficiency score as percentage
    var portfolioEfficiencyPercentage: String {
        let summary = dashboardSummary
        return summary.completionRate
    }
}

// MARK: - AdminDashboardViewModel Extensions

extension AdminDashboardViewModel {
    
    /// Filter buildings by attention level
    func filterBuildings(needingAttention: Bool) -> [NamedCoordinate] {
        if needingAttention {
            return buildingsNeedingAttention
        } else {
            return buildings
        }
    }
    
    /// Get insights for specific building
    func getInsights(for buildingId: String) -> [CoreTypes.IntelligenceInsight] {
        return portfolioInsights.filter { $0.affectedBuildings.contains(buildingId) }
    }
    
    /// Get building performance score (0-100)
    func getBuildingPerformanceScore(for buildingId: String) -> Int {
        return buildingMetrics[buildingId]?.overallScore ?? 0
    }
    
    /// Check if building has critical issues
    func buildingHasCriticalIssues(_ buildingId: String) -> Bool {
        return portfolioInsights.contains { insight in
            insight.affectedBuildings.contains(buildingId) && insight.priority == .critical
        }
    }
    
    /// Get formatted last update time
    var formattedLastUpdateTime: String {
        guard let lastUpdateTime = lastUpdateTime else { return "Never" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        return formatter.string(from: lastUpdateTime)
    }
}
