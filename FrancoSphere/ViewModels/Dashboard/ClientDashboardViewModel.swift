//
//  ClientDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ NAMESPACED: Proper CoreTypes usage
//  ✅ NO DUPLICATES: Clean type definitions
//  ✅ OPTIMIZED: Efficient data management
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    
    @Published public var isLoading = false
    @Published public var isRefreshing = false
    @Published public var errorMessage: String?
    @Published public var successMessage: String?
    @Published public var lastUpdateTime: Date?
    
    // Portfolio Intelligence
    @Published public var portfolioIntelligence: CoreTypes.ClientPortfolioIntelligence?
    @Published public var executiveSummary: CoreTypes.ExecutiveSummary?
    @Published public var portfolioBenchmarks: [CoreTypes.PortfolioBenchmark] = []
    @Published public var strategicRecommendations: [CoreTypes.StrategicRecommendation] = []
    
    // Buildings and Metrics
    @Published public var buildingsList: [CoreTypes.NamedCoordinate] = []
    @Published public var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published public var totalBuildings: Int = 0
    @Published public var activeWorkers: Int = 0
    @Published public var completionRate: Double = 0.0
    @Published public var criticalIssues: Int = 0
    @Published public var complianceScore: Int = 92
    @Published public var monthlyTrend: CoreTypes.TrendDirection = .stable
    
    // Real-time Metrics
    @Published public var realtimeRoutineMetrics = CoreTypes.RealtimeRoutineMetrics()
    @Published public var activeWorkerStatus = CoreTypes.ActiveWorkerStatus(
        totalActive: 0,
        byBuilding: [:],
        utilizationRate: 0.0
    )
    @Published public var monthlyMetrics = CoreTypes.MonthlyMetrics(
        currentSpend: 0,
        monthlyBudget: 10000,
        projectedSpend: 0,
        daysRemaining: 30
    )
    
    // Compliance and Intelligence
    @Published public var complianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published public var intelligenceInsights: [CoreTypes.IntelligenceInsight] = []
    @Published public var dashboardUpdates: [CoreTypes.DashboardUpdate] = []
    @Published public var dashboardSyncStatus: CoreTypes.DashboardSyncStatus = .synced
    
    // Loading states
    @Published public var isLoadingInsights = false
    @Published public var showCostData = true
    
    // MARK: - Services
    
    private let contextEngine = ClientContextEngine.shared
    private let dashboardSyncService = DashboardSyncService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let taskService = TaskService.shared
    private let intelligenceService = IntelligenceService.shared
    private let operationalDataManager = OperationalDataManager.shared
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private let updateDebouncer = Debouncer(delay: 0.3)
    
    // MARK: - Computed Properties
    
    public var hasActiveIssues: Bool {
        criticalIssues > 0 || complianceIssues.contains { $0.severity == .critical }
    }
    
    public var portfolioHealth: CoreTypes.PortfolioHealth {
        CoreTypes.PortfolioHealth(
            overallScore: completionRate,
            totalBuildings: totalBuildings,
            activeBuildings: buildingsList.count,
            criticalIssues: criticalIssues,
            trend: monthlyTrend,
            lastUpdated: Date()
        )
    }
    
    public var complianceOverview: CoreTypes.ComplianceOverview {
        CoreTypes.ComplianceOverview(
            id: UUID().uuidString,
            overallScore: Double(complianceScore) / 100.0,
            criticalViolations: complianceIssues.filter { $0.severity == .critical }.count,
            pendingInspections: complianceIssues.filter { $0.status == .pending }.count,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Initialization
    
    public init() {
        setupSubscriptions()
        schedulePeriodicRefresh()
        
        Task {
            await loadPortfolioIntelligence()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Load all portfolio intelligence data
    public func loadPortfolioIntelligence() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadBuildingsData() }
            group.addTask { await self.loadBuildingMetrics() }
            group.addTask { await self.generateComplianceIssues() }
            group.addTask { await self.loadIntelligenceInsights() }
            group.addTask { await self.generateExecutiveSummary() }
            group.addTask { await self.loadStrategicRecommendations() }
            group.addTask { await self.loadPortfolioBenchmarks() }
        }
        
        // Update computed metrics
        await MainActor.run {
            self.updateComputedMetrics()
            self.createPortfolioIntelligence()
            self.isLoading = false
            self.lastUpdateTime = Date()
        }
    }
    
    /// Refresh dashboard data
    public func refreshData() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        errorMessage = nil
        
        do {
            await loadPortfolioIntelligence()
            
            await MainActor.run {
                self.successMessage = "Dashboard updated"
                self.isRefreshing = false
            }
            
            // Clear success message after delay
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    self.successMessage = nil
                }
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to refresh: \(error.localizedDescription)"
                self.isRefreshing = false
            }
        }
    }
    
    /// Force refresh all data
    public func forceRefresh() async {
        dashboardSyncStatus = .syncing
        await loadPortfolioIntelligence()
        dashboardSyncStatus = .synced
    }
    
    /// Get building metrics for specific building
    public func getBuildingMetrics(for buildingId: String) -> CoreTypes.BuildingMetrics? {
        return buildingMetrics[buildingId]
    }
    
    /// Get compliance issues filtered by building
    public func getComplianceIssues(for buildingId: String? = nil) -> [CoreTypes.ComplianceIssue] {
        if let buildingId = buildingId {
            return complianceIssues.filter { $0.buildingId == buildingId }
        }
        return complianceIssues
    }
    
    /// Get insights filtered by priority
    public func getInsights(filteredBy priority: CoreTypes.AIPriority? = nil) -> [CoreTypes.IntelligenceInsight] {
        if let priority = priority {
            return intelligenceInsights.filter { $0.priority == priority }
        }
        return intelligenceInsights
    }
    
    // MARK: - Private Data Loading Methods
    
    private func loadBuildingsData() async {
        // Load from operational data manager
        let buildings = operationalDataManager.buildings.map { building in
            CoreTypes.NamedCoordinate(
                id: building.id,
                name: building.name,
                address: building.address,
                latitude: building.latitude,
                longitude: building.longitude
            )
        }
        
        await MainActor.run {
            self.buildingsList = buildings
            self.totalBuildings = buildings.count
        }
    }
    
    private func loadBuildingMetrics() async {
        for building in buildingsList {
            do {
                let metrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                await MainActor.run {
                    self.buildingMetrics[building.id] = metrics
                }
            } catch {
                print("⚠️ Failed to load metrics for building \(building.id): \(error)")
            }
        }
        
        await MainActor.run {
            self.updateComputedMetrics()
        }
    }
    
    private func generateComplianceIssues() async {
        do {
            let allTasks = try await taskService.getAllTasks()
            var issues: [CoreTypes.ComplianceIssue] = []
            
            // Check for overdue tasks
            let overdueTasks = allTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
            
            // Group overdue tasks by building
            let overdueByBuilding = Dictionary(grouping: overdueTasks) { $0.buildingId ?? "unknown" }
            
            for (buildingId, tasks) in overdueByBuilding {
                if tasks.count > 2 {
                    let buildingName = buildingsList.first { $0.id == buildingId }?.name ?? "Building \(buildingId)"
                    
                    issues.append(CoreTypes.ComplianceIssue(
                        title: "Multiple Overdue Tasks",
                        description: "\(tasks.count) overdue tasks at \(buildingName) require immediate attention",
                        severity: tasks.count > 5 ? .critical : .high,
                        buildingId: buildingId,
                        buildingName: buildingName,
                        status: .open,
                        type: .operational
                    ))
                }
            }
            
            // Check for inspection tasks
            let overdueInspections = allTasks.filter { task in
                guard task.category == .inspection,
                      let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
            
            if overdueInspections.count > 0 {
                issues.append(CoreTypes.ComplianceIssue(
                    title: "Overdue Inspections",
                    description: "\(overdueInspections.count) inspection tasks are overdue across the portfolio",
                    severity: .critical,
                    status: .open,
                    type: .regulatory
                ))
            }
            
            await MainActor.run {
                self.complianceIssues = issues
                self.criticalIssues = issues.filter { $0.severity == .critical }.count
            }
            
        } catch {
            print("⚠️ Failed to generate compliance issues: \(error)")
        }
    }
    
    private func loadIntelligenceInsights() async {
        isLoadingInsights = true
        
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            
            await MainActor.run {
                self.intelligenceInsights = insights
                self.isLoadingInsights = false
            }
            
        } catch {
            await MainActor.run {
                self.intelligenceInsights = []
                self.isLoadingInsights = false
            }
            print("⚠️ Failed to load intelligence insights: \(error)")
        }
    }
    
    private func generateExecutiveSummary() async {
        await MainActor.run {
            self.executiveSummary = CoreTypes.ExecutiveSummary(
                totalBuildings: totalBuildings,
                totalWorkers: activeWorkers,
                portfolioHealth: completionRate,
                monthlyPerformance: monthlyTrend.rawValue
            )
        }
    }
    
    private func loadStrategicRecommendations() async {
        var recommendations: [CoreTypes.StrategicRecommendation] = []
        
        // Analyze completion rate
        if completionRate < 0.7 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Improve Task Completion Rate",
                description: "Current completion rate of \(Int(completionRate * 100))% is below target.",
                category: .operations,
                priority: .high,
                timeframe: "Next 30 days",
                estimatedImpact: "15-20% improvement in efficiency"
            ))
        }
        
        // Analyze critical issues
        if criticalIssues > 5 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Address Critical Compliance Issues",
                description: "\(criticalIssues) critical issues require immediate attention.",
                category: .compliance,
                priority: .critical,
                timeframe: "Immediate",
                estimatedImpact: "Risk mitigation and compliance restoration"
            ))
        }
        
        await MainActor.run {
            self.strategicRecommendations = recommendations
        }
    }
    
    private func loadPortfolioBenchmarks() async {
        var benchmarks: [CoreTypes.PortfolioBenchmark] = []
        
        benchmarks.append(CoreTypes.PortfolioBenchmark(
            metric: "Task Completion",
            value: completionRate,
            benchmark: 0.90,
            trend: monthlyTrend.rawValue,
            period: "This Month"
        ))
        
        let complianceRate = Double(complianceScore) / 100.0
        benchmarks.append(CoreTypes.PortfolioBenchmark(
            metric: "Compliance Score",
            value: complianceRate,
            benchmark: 0.95,
            trend: complianceRate >= 0.90 ? "Stable" : "Declining",
            period: "This Month"
        ))
        
        await MainActor.run {
            self.portfolioBenchmarks = benchmarks
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func updateComputedMetrics() {
        // Calculate average completion rate
        if !buildingMetrics.isEmpty {
            let totalCompletion = buildingMetrics.values.reduce(0) { $0 + $1.completionRate }
            completionRate = totalCompletion / Double(buildingMetrics.count)
        }
        
        // Update real-time routine metrics
        var buildingStatuses: [String: CoreTypes.BuildingRoutineStatus] = [:]
        
        for building in buildingsList {
            if let metrics = buildingMetrics[building.id] {
                buildingStatuses[building.id] = CoreTypes.BuildingRoutineStatus(
                    buildingId: building.id,
                    buildingName: building.name,
                    completionRate: metrics.completionRate,
                    activeWorkerCount: metrics.activeWorkers,
                    isOnSchedule: metrics.overdueTasks == 0
                )
            }
        }
        
        realtimeRoutineMetrics = CoreTypes.RealtimeRoutineMetrics(
            overallCompletion: completionRate,
            activeWorkerCount: activeWorkers,
            behindScheduleCount: buildingStatuses.filter { !$0.value.isOnSchedule }.count,
            buildingStatuses: buildingStatuses
        )
        
        // Update trend based on metrics
        if completionRate > 0.85 {
            monthlyTrend = .improving
        } else if completionRate < 0.65 {
            monthlyTrend = .declining
        } else {
            monthlyTrend = .stable
        }
    }
    
    private func createPortfolioIntelligence() {
        portfolioIntelligence = CoreTypes.ClientPortfolioIntelligence(
            portfolioHealth: portfolioHealth,
            executiveSummary: executiveSummary ?? CoreTypes.ExecutiveSummary(
                totalBuildings: totalBuildings,
                totalWorkers: activeWorkers,
                portfolioHealth: completionRate,
                monthlyPerformance: monthlyTrend.rawValue
            ),
            benchmarks: portfolioBenchmarks,
            strategicRecommendations: strategicRecommendations,
            performanceTrends: generatePerformanceTrends(),
            totalProperties: totalBuildings,
            serviceLevel: completionRate,
            complianceScore: complianceScore,
            complianceIssues: criticalIssues,
            monthlyTrend: monthlyTrend,
            coveragePercentage: completionRate,
            monthlySpend: monthlyMetrics.currentSpend,
            monthlyBudget: monthlyMetrics.monthlyBudget,
            showCostData: showCostData
        )
    }
    
    private func generatePerformanceTrends() -> [Double] {
        // Generate sample trend data (would be from historical data in production)
        return [0.72, 0.74, 0.71, 0.75, 0.78, 0.76, completionRate]
    }
    
    // MARK: - Subscriptions
    
    private func setupSubscriptions() {
        // Subscribe to dashboard sync updates
        dashboardSyncService.clientDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Subscribe to context engine updates
        contextEngine.$portfolioHealth
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func schedulePeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshData()
            }
        }
    }
    
    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        updateDebouncer.debounce { [weak self] in
            Task { @MainActor in
                await self?.processUpdate(update)
            }
        }
    }
    
    private func processUpdate(_ update: CoreTypes.DashboardUpdate) async {
        switch update.type {
        case .taskCompleted:
            if let buildingId = update.buildingId {
                // Refresh metrics for specific building
                if let updatedMetrics = try? await buildingMetricsService.calculateMetrics(for: buildingId) {
                    buildingMetrics[buildingId] = updatedMetrics
                    updateComputedMetrics()
                }
            }
            
        case .workerClockedIn:
            activeWorkers += 1
            
        case .workerClockedOut:
            activeWorkers = max(0, activeWorkers - 1)
            
        case .buildingMetricsChanged:
            if let buildingId = update.buildingId {
                if let updatedMetrics = try? await buildingMetricsService.calculateMetrics(for: buildingId) {
                    buildingMetrics[buildingId] = updatedMetrics
                    updateComputedMetrics()
                }
            }
            
        case .complianceStatusChanged:
            await generateComplianceIssues()
            
        default:
            break
        }
        
        // Add to dashboard updates
        dashboardUpdates.append(update)
        if dashboardUpdates.count > 50 {
            dashboardUpdates = Array(dashboardUpdates.suffix(50))
        }
    }
}

// MARK: - Supporting Types

/// Debouncer utility for performance optimization
private final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
    
    func cancel() {
        workItem?.cancel()
    }
}

// MARK: - Preview Support

#if DEBUG
extension ClientDashboardViewModel {
    static func preview() -> ClientDashboardViewModel {
        let viewModel = ClientDashboardViewModel()
        
        // Set up preview data
        Task { @MainActor in
            viewModel.totalBuildings = 12
            viewModel.activeWorkers = 8
            viewModel.completionRate = 0.85
            viewModel.criticalIssues = 2
            viewModel.complianceScore = 92
            viewModel.monthlyTrend = .improving
            
            viewModel.buildingsList = [
                CoreTypes.NamedCoordinate(
                    id: "14",
                    name: "Rubin Museum",
                    address: "150 W 17th St, New York, NY 10011",
                    latitude: 40.7397,
                    longitude: -73.9978
                ),
                CoreTypes.NamedCoordinate(
                    id: "4",
                    name: "131 Perry Street",
                    address: "131 Perry St, New York, NY 10014",
                    latitude: 40.7350,
                    longitude: -74.0045
                )
            ]
            
            viewModel.createPortfolioIntelligence()
        }
        
        return viewModel
    }
}
#endif
