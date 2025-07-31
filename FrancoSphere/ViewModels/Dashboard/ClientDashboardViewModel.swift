//
//  ClientDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: DashboardUpdate properly namespaced as CoreTypes.DashboardUpdate
//  ✅ FIXED: Enum member references use full paths
//  ✅ FIXED: Nil parameters properly typed
//  ✅ REFACTORED: Cleaner architecture and consistent patterns
//  ✅ ALIGNED: Works with existing service architecture
//  ✅ STREAM A MODIFIED: Enhanced error handling for localization
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties (Using Existing CoreTypes)
    @Published public var portfolioIntelligence: CoreTypes.PortfolioIntelligence?
    @Published public var buildingsList: [CoreTypes.NamedCoordinate] = []
    @Published public var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published public var complianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published public var intelligenceInsights: [CoreTypes.IntelligenceInsight] = []
    
    // MARK: - Dashboard Metrics (Derived from Portfolio)
    @Published public var totalBuildings: Int = 0
    @Published public var activeWorkers: Int = 0
    @Published public var completionRate: Double = 0.0
    @Published public var criticalIssues: Int = 0
    @Published public var complianceScore: Int = 0
    @Published public var monthlyTrend: CoreTypes.TrendDirection = .stable
    
    // MARK: - UI State
    @Published public var isLoading = false
    @Published public var isLoadingInsights = false
    @Published public var errorMessage: String?
    @Published public var lastUpdateTime: Date?
    
    // MARK: - Cross-Dashboard Integration
    @Published public var dashboardSyncStatus: CoreTypes.DashboardSyncStatus = .synced
    @Published public var dashboardUpdates: [CoreTypes.DashboardUpdate] = []
    
    // MARK: - Executive Summary Data
    @Published public var executiveSummary: CoreTypes.ExecutiveSummary?
    @Published public var portfolioBenchmarks: [CoreTypes.PortfolioBenchmark] = []
    @Published public var strategicRecommendations: [CoreTypes.StrategicRecommendation] = []
    
    // MARK: - Services
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    private let dashboardSyncService = DashboardSyncService.shared
    
    // MARK: - Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    public init() {
        setupSubscriptions()
        schedulePeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Primary Data Loading
    
    /// Load portfolio intelligence for executive client view
    public func loadPortfolioIntelligence() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load building list first
            buildingsList = try await buildingService.getAllBuildings()
            totalBuildings = buildingsList.count
            
            // Generate portfolio intelligence using the actual method
            let intelligence = try await intelligenceService.generatePortfolioIntelligence()
            self.portfolioIntelligence = intelligence
            
            // Extract metrics from intelligence
            totalBuildings = intelligence.totalBuildings
            activeWorkers = intelligence.activeWorkers
            completionRate = intelligence.completionRate
            criticalIssues = intelligence.criticalIssues
            complianceScore = Int(intelligence.complianceScore)
            monthlyTrend = intelligence.monthlyTrend
            
            // Load building metrics for all buildings
            await loadBuildingMetrics()
            
            // Generate compliance issues from task data
            await generateComplianceIssues()
            
            // Load intelligence insights using the actual method
            await loadIntelligenceInsights()
            
            // Generate executive summary locally
            await generateExecutiveSummary()
            
            // Generate strategic recommendations from insights
            await loadStrategicRecommendations()
            
            // Generate portfolio benchmarks from metrics
            await loadPortfolioBenchmarks()
            
            // Create and broadcast update
            let update = CoreTypes.DashboardUpdate(
                source: CoreTypes.DashboardUpdate.Source.client,
                type: CoreTypes.DashboardUpdate.UpdateType.buildingMetricsChanged,
                buildingId: "",  // Empty string instead of nil
                workerId: "",    // Empty string instead of nil
                data: [
                    "totalBuildings": String(totalBuildings),
                    "completionRate": String(completionRate),
                    "activeWorkers": String(activeWorkers),
                    "updateType": "portfolioUpdated"
                ]
            )
            broadcastDashboardUpdate(update)
            
            lastUpdateTime = Date()
            isLoading = false
            
            print("✅ Client portfolio intelligence loaded: \(totalBuildings) buildings, \(activeWorkers) workers")
            
        } catch {
            // ✅ STREAM A MODIFICATION: More robust and localizable error handling
            isLoading = false
            let baseError = NSLocalizedString("could_not_load_portfolio",
                                            value: "Could not load portfolio information",
                                            comment: "Client dashboard loading error")
            errorMessage = "\(baseError). \(error.localizedDescription)"
            print("❌ Failed to load portfolio intelligence: \(error)")
            await loadFallbackData()
        }
    }
    
    /// Load building metrics for client portfolio view
    private func loadBuildingMetrics() async {
        for building in buildingsList {
            do {
                let metrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                buildingMetrics[building.id] = metrics
            } catch {
                print("⚠️ Failed to load metrics for building \(building.id): \(error)")
            }
        }
        
        // Create and broadcast update
        let update = CoreTypes.DashboardUpdate(
            source: CoreTypes.DashboardUpdate.Source.client,
            type: CoreTypes.DashboardUpdate.UpdateType.buildingMetricsChanged,
            buildingId: "",  // Empty string for portfolio-wide update
            workerId: "",    // Empty string when not worker-specific
            data: [
                "buildingCount": String(buildingMetrics.count),
                "averageCompletion": String(calculateAverageCompletion())
            ]
        )
        broadcastDashboardUpdate(update)
    }
    
    /// Generate compliance issues from task data
    private func generateComplianceIssues() async {
        do {
            // Get all tasks
            let allTasks = try await taskService.getAllTasks()
            
            // Generate compliance issues from overdue and critical tasks
            var issues: [CoreTypes.ComplianceIssue] = []
            
            // Check for overdue tasks
            let overdueTasks = allTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
            
            // Create compliance issues for overdue tasks grouped by building
            let overdueByBuilding = Dictionary(grouping: overdueTasks) { $0.buildingId ?? "unknown" }
            
            for (buildingId, tasks) in overdueByBuilding {
                if tasks.count > 2 {
                    let buildingName = buildingsList.first { $0.id == buildingId }?.name ?? "Building \(buildingId)"
                    
                    issues.append(CoreTypes.ComplianceIssue(
                        title: "Multiple Overdue Tasks",
                        description: "\(tasks.count) overdue tasks at \(buildingName) require immediate attention",
                        severity: tasks.count > 5 ? .critical : .high,
                        buildingId: buildingId,
                        status: .open,
                        createdAt: Date()
                    ))
                }
            }
            
            // Check for inspection tasks
            let inspectionTasks = allTasks.filter { $0.category == .inspection }
            let overdueInspections = inspectionTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
            
            if overdueInspections.count > 0 {
                issues.append(CoreTypes.ComplianceIssue(
                    title: "Overdue Inspections",
                    description: "\(overdueInspections.count) inspection tasks are overdue across the portfolio",
                    severity: .critical,
                    buildingId: nil,
                    status: .open,
                    createdAt: Date()
                ))
            }
            
            // Check for safety-related tasks
            let safetyTasks = allTasks.filter { task in
                let title = task.title.lowercased()
                return title.contains("safety") || title.contains("hazard") || title.contains("emergency")
            }
            
            let incompleteSafetyTasks = safetyTasks.filter { !$0.isCompleted }
            
            if incompleteSafetyTasks.count > 3 {
                issues.append(CoreTypes.ComplianceIssue(
                    title: "Safety Tasks Pending",
                    description: "\(incompleteSafetyTasks.count) safety-related tasks need completion",
                    severity: .high,
                    buildingId: nil,
                    status: .open,
                    createdAt: Date()
                ))
            }
            
            self.complianceIssues = issues
            
            // Count critical issues
            criticalIssues = issues.filter { $0.severity == .critical }.count
            
            print("✅ Generated \(issues.count) compliance issues (\(criticalIssues) critical)")
            
        } catch {
            print("⚠️ Failed to generate compliance issues: \(error)")
            self.complianceIssues = []
        }
    }
    
    /// Load AI-generated intelligence insights using the actual service method
    private func loadIntelligenceInsights() async {
        isLoadingInsights = true
        
        do {
            // Use the actual method that exists in IntelligenceService
            let insights = try await intelligenceService.generatePortfolioInsights()
            self.intelligenceInsights = insights
            isLoadingInsights = false
            
            print("✅ Loaded \(insights.count) intelligence insights")
            
        } catch {
            self.intelligenceInsights = []
            isLoadingInsights = false
            print("⚠️ Failed to load intelligence insights: \(error)")
        }
    }
    
    /// Generate executive summary from available data
    private func generateExecutiveSummary() async {
        // Generate summary from existing data
        self.executiveSummary = CoreTypes.ExecutiveSummary(
            totalBuildings: totalBuildings,
            totalWorkers: activeWorkers,
            portfolioHealth: completionRate,
            monthlyPerformance: monthlyTrend.rawValue,
            generatedAt: Date()
        )
        
        print("✅ Executive summary generated")
    }
    
    /// Generate strategic recommendations from insights
    private func loadStrategicRecommendations() async {
        // Generate recommendations from insights and metrics
        var recommendations: [CoreTypes.StrategicRecommendation] = []
        
        // Analyze completion rate
        if completionRate < 0.7 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Improve Task Completion Rate",
                description: "Current completion rate of \(Int(completionRate * 100))% is below target. Consider adding resources or reviewing task assignments.",
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
                description: "\(criticalIssues) critical issues require immediate attention to avoid penalties and ensure safety.",
                category: .compliance,
                priority: .critical,
                timeframe: "Immediate",
                estimatedImpact: "Risk mitigation and compliance restoration"
            ))
        }
        
        // Analyze worker efficiency
        if activeWorkers > 0 && totalBuildings > 0 {
            let buildingsPerWorker = Double(totalBuildings) / Double(activeWorkers)
            if buildingsPerWorker > 3 {
                recommendations.append(CoreTypes.StrategicRecommendation(
                    title: "Optimize Worker Distribution",
                    description: "Each worker is covering \(String(format: "%.1f", buildingsPerWorker)) buildings on average. Consider hiring additional staff.",
                    category: .operations,
                    priority: .medium,
                    timeframe: "Next quarter",
                    estimatedImpact: "Improved coverage and response times"
                ))
            }
        }
        
        // Analyze from insights
        let highPriorityInsights = intelligenceInsights.filter { $0.priority == .high || $0.priority == .critical }
        if highPriorityInsights.count > 3 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Focus on High-Priority Issues",
                description: "\(highPriorityInsights.count) high-priority insights require strategic attention for portfolio optimization.",
                category: .operations,
                priority: .high,
                timeframe: "Next 60 days",
                estimatedImpact: "Significant operational improvements"
            ))
        }
        
        self.strategicRecommendations = recommendations
        
        print("✅ Generated \(recommendations.count) strategic recommendations")
    }
    
    /// Generate portfolio benchmarks from metrics
    private func loadPortfolioBenchmarks() async {
        var benchmarks: [CoreTypes.PortfolioBenchmark] = []
        
        // Task completion benchmark
        benchmarks.append(CoreTypes.PortfolioBenchmark(
            metric: "Task Completion",
            value: completionRate,
            benchmark: 0.90,
            trend: monthlyTrend.rawValue,
            period: "This Month"
        ))
        
        // Compliance benchmark
        let complianceRate = Double(complianceScore) / 100.0
        benchmarks.append(CoreTypes.PortfolioBenchmark(
            metric: "Compliance Score",
            value: complianceRate,
            benchmark: 0.95,
            trend: complianceRate >= 0.90 ? "Stable" : "Declining",
            period: "This Month"
        ))
        
        // Worker efficiency benchmark
        if activeWorkers > 0 && totalBuildings > 0 {
            let buildingsPerWorker = Double(totalBuildings) / Double(activeWorkers)
            let efficiency = min(3.0 / buildingsPerWorker, 1.0) // Optimal is 3 buildings per worker
            
            benchmarks.append(CoreTypes.PortfolioBenchmark(
                metric: "Worker Efficiency",
                value: efficiency,
                benchmark: 1.0,
                trend: efficiency >= 0.8 ? "Stable" : "Declining",
                period: "This Month"
            ))
        }
        
        // Response time benchmark (simulated from metrics)
        let avgResponseTime = buildingMetrics.values.compactMap { $0.averageTaskTime }.reduce(0, +) / Double(max(buildingMetrics.count, 1))
        let responseEfficiency = avgResponseTime > 0 ? min(120.0 / avgResponseTime, 1.0) : 0.85 // 120 minutes is target
        
        benchmarks.append(CoreTypes.PortfolioBenchmark(
            metric: "Response Time",
            value: responseEfficiency,
            benchmark: 1.0,
            trend: "Stable",
            period: "This Month"
        ))
        
        self.portfolioBenchmarks = benchmarks
        
        print("✅ Generated \(benchmarks.count) portfolio benchmarks")
    }
    
    // MARK: - Helper Methods
    
    private func calculateAverageCompletion() -> Double {
        guard !buildingMetrics.isEmpty else { return 0.0 }
        
        let totalCompletion = buildingMetrics.values.reduce(0) { $0 + $1.completionRate }
        return totalCompletion / Double(buildingMetrics.count)
    }
    
    /// Load fallback data when services fail
    private func loadFallbackData() async {
        print("📱 Loading fallback data for client dashboard")
        
        // Create minimal portfolio intelligence
        portfolioIntelligence = CoreTypes.PortfolioIntelligence(
            totalBuildings: 0,
            activeWorkers: 0,
            completionRate: 0.0,
            criticalIssues: 0,
            monthlyTrend: .unknown,
            complianceScore: 0.0,
            generatedAt: Date()
        )
        
        // Create fallback executive summary
        executiveSummary = CoreTypes.ExecutiveSummary(
            totalBuildings: 0,
            totalWorkers: 0,
            portfolioHealth: 0.0,
            monthlyPerformance: "Unknown",
            generatedAt: Date()
        )
        
        portfolioBenchmarks = []
        
        // Create fallback strategic recommendation
        strategicRecommendations = [
            CoreTypes.StrategicRecommendation(
                title: "System Recovery",
                description: "Portfolio data is temporarily unavailable. Attempting to restore connection...",
                category: .operations,
                priority: .medium,
                timeframe: "Immediate",
                estimatedImpact: "Service restoration"
            )
        ]
    }
    
    // MARK: - Public Interface
    
    public func refreshData() async {
        await loadPortfolioIntelligence()
    }
    
    public func forceRefresh() async {
        dashboardSyncStatus = .syncing
        await loadPortfolioIntelligence()
        dashboardSyncStatus = .synced
    }
    
    public func getBuildingMetrics(for buildingId: String) -> CoreTypes.BuildingMetrics? {
        return buildingMetrics[buildingId]
    }
    
    public func getComplianceIssues(for buildingId: String? = nil) -> [CoreTypes.ComplianceIssue] {
        if let buildingId = buildingId {
            return complianceIssues.filter { $0.buildingId == buildingId }
        }
        return complianceIssues
    }
    
    public func getInsights(filteredBy priority: CoreTypes.AIPriority? = nil) -> [CoreTypes.IntelligenceInsight] {
        if let priority = priority {
            return intelligenceInsights.filter { $0.priority == priority }
        }
        return intelligenceInsights
    }
    
    // MARK: - Cross-Dashboard Integration
    
    private func setupSubscriptions() {
        dashboardSyncService.clientDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleDashboardUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func schedulePeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.refreshData()
            }
        }
    }
    
    /// Broadcast client dashboard update
    private func broadcastDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        dashboardUpdates.append(update)
        
        // Keep only recent updates
        if dashboardUpdates.count > 50 {
            dashboardUpdates = Array(dashboardUpdates.suffix(50))
        }
        
        dashboardSyncService.broadcastClientUpdate(update)
    }
    
    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        switch update.type {
        case .taskCompleted:
            if let taskId = update.data["taskId"],
               !update.workerId.isEmpty,
               !update.buildingId.isEmpty {
                print("📱 Client Dashboard: Task \(taskId) completed by worker \(update.workerId) at building \(update.buildingId)")
                // Use existing BuildingMetricsService to get updated metrics
                Task { @MainActor in
                    if let updatedMetrics = try? await buildingMetricsService.calculateMetrics(for: update.buildingId) {
                        buildingMetrics[update.buildingId] = updatedMetrics
                    }
                    // Recalculate completion rate
                    completionRate = calculateAverageCompletion()
                }
            }
            
        case .workerClockedIn:
            if !update.workerId.isEmpty,
               !update.buildingId.isEmpty {
                print("📱 Client Dashboard: Worker \(update.workerId) clocked in at building \(update.buildingId)")
                activeWorkers += 1
            }
            
        case .workerClockedOut:
            if !update.workerId.isEmpty,
               !update.buildingId.isEmpty {
                print("📱 Client Dashboard: Worker \(update.workerId) clocked out from building \(update.buildingId)")
                activeWorkers = max(0, activeWorkers - 1)
            }
            
        case .buildingMetricsChanged:
            if !update.buildingId.isEmpty {
                print("📱 Client Dashboard: Metrics updated for building \(update.buildingId)")
                // Use service to get updated metrics
                Task { @MainActor in
                    if let updatedMetrics = try? await buildingMetricsService.calculateMetrics(for: update.buildingId) {
                        buildingMetrics[update.buildingId] = updatedMetrics
                        // Recalculate completion rate
                        completionRate = calculateAverageCompletion()
                    }
                }
            }
            
        case .complianceStatusChanged:
            if !update.buildingId.isEmpty,
               let severity = update.data["severity"],
               let title = update.data["title"],
               let description = update.data["description"] {
                
                // Map severity string to enum
                let severityEnum: CoreTypes.ComplianceSeverity = {
                    switch severity.lowercased() {
                    case "critical": return .critical
                    case "high": return .high
                    case "medium": return .medium
                    default: return .low
                    }
                }()
                
                let newIssue = CoreTypes.ComplianceIssue(
                    title: title,
                    description: description,
                    severity: severityEnum,
                    buildingId: update.buildingId,
                    status: .open,
                    createdAt: Date()
                )
                
                complianceIssues.append(newIssue)
                
                // Update critical issues count
                criticalIssues = complianceIssues.filter { $0.severity == .critical }.count
                
                print("📱 Client Dashboard: New compliance issue - \(title)")
            }
            
        default:
            print("📱 Client Dashboard: Received update type \(update.type)")
        }
    }
}

// MARK: - Supporting Types

extension ClientDashboardViewModel {
    /// Client-specific filter options
    public enum FilterOption: String, CaseIterable {
        case all = "All"
        case critical = "Critical"
        case highPriority = "High Priority"
        case compliance = "Compliance"
        case efficiency = "Efficiency"
        
        public var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .critical: return "exclamationmark.triangle.fill"
            case .highPriority: return "flag.fill"
            case .compliance: return "shield.fill"
            case .efficiency: return "speedometer"
            }
        }
    }
    
    /// Executive dashboard time range
    public enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case quarter = "This Quarter"
        case year = "This Year"
        
        public var days: Int {
            switch self {
            case .today: return 1
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ClientDashboardViewModel {
    static func preview() -> ClientDashboardViewModel {
        let viewModel = ClientDashboardViewModel()
        
        // Mock portfolio intelligence
        viewModel.portfolioIntelligence = CoreTypes.PortfolioIntelligence(
            totalBuildings: 12,
            activeWorkers: 8,
            completionRate: 0.85,
            criticalIssues: 2,
            monthlyTrend: .improving,
            complianceScore: 92.5,
            generatedAt: Date()
        )
        
        // Mock buildings
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
        
        // Mock metrics
        viewModel.totalBuildings = 12
        viewModel.activeWorkers = 8
        viewModel.completionRate = 0.85
        viewModel.criticalIssues = 2
        viewModel.complianceScore = 92
        
        return viewModel
    }
}
#endif
