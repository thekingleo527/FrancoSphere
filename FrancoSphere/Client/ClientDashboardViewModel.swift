//
//  ClientDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All type conflicts resolved
//  ✅ FIXED: Using correct CoreTypes definitions
//  ✅ FIXED: All initializer parameters match
//  ✅ FIXED: Removed duplicate type definitions
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties (Using Existing CoreTypes)
    @Published var portfolioIntelligence: CoreTypes.PortfolioIntelligence?
    @Published var buildingsList: [NamedCoordinate] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var complianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published var intelligenceInsights: [CoreTypes.IntelligenceInsight] = []
    
    // MARK: - Dashboard Metrics (Derived from Portfolio)
    @Published var totalBuildings: Int = 0
    @Published var activeWorkers: Int = 0
    @Published var completionRate: Double = 0.0
    @Published var criticalIssues: Int = 0
    @Published var complianceScore: Int = 0
    @Published var monthlyTrend: CoreTypes.TrendDirection = .stable
    
    // MARK: - UI State
    @Published var isLoading = false
    @Published var isLoadingInsights = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Cross-Dashboard Integration
    @Published var dashboardSyncStatus: CoreTypes.DashboardSyncStatus = .synced
    @Published var crossDashboardUpdates: [CoreTypes.CrossDashboardUpdate] = []
    
    // MARK: - Executive Summary Data (Using Existing CoreTypes)
    @Published var executiveSummary: CoreTypes.ExecutiveSummary?
    @Published var portfolioBenchmarks: [CoreTypes.PortfolioBenchmark] = []
    @Published var strategicRecommendations: [CoreTypes.StrategicRecommendation] = []
    
    // MARK: - Services (Using Existing .shared Pattern)
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
    init() {
        setupSubscriptions()
        schedulePeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Main Loading Function
    func loadPortfolioIntelligence() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load portfolio data using actor services
            let intelligence = try await intelligenceService.generatePortfolioIntelligence()
            let buildings = try await buildingService.getAllBuildings()
            let insights = try await intelligenceService.generatePortfolioInsights()
            
            // Update data on main actor
            self.portfolioIntelligence = intelligence
            self.buildingsList = buildings
            self.intelligenceInsights = insights
            
            // Update derived metrics
            updateDashboardMetrics(from: intelligence)
            
            // Load additional data
            await loadBuildingMetrics()
            await loadComplianceIssues()
            await generateExecutiveSummary()
            
            // Update sync status
            lastUpdateTime = Date()
            print("✅ Portfolio intelligence loaded: \(buildings.count) buildings, \(insights.count) insights")
            
            // Broadcast update
            await broadcastCrossDashboardUpdate(.portfolioUpdated(buildingCount: buildings.count))
            
        } catch {
            print("❌ Failed to load portfolio intelligence: \(error)")
            errorMessage = error.localizedDescription
            setFallbackData()
        }
        
        isLoading = false
    }
    
    // MARK: - Dashboard Metrics Update
    private func updateDashboardMetrics(from intelligence: CoreTypes.PortfolioIntelligence) {
        totalBuildings = intelligence.totalBuildings
        activeWorkers = intelligence.activeWorkers
        completionRate = intelligence.completionRate
        criticalIssues = intelligence.criticalIssues
        complianceScore = intelligence.complianceScore
        monthlyTrend = intelligence.monthlyTrend
    }
    
    // MARK: - Building Metrics Loading
    private func loadBuildingMetrics() async {
        var metrics: [String: CoreTypes.BuildingMetrics] = [:]
        
        for building in buildingsList {
            do {
                let buildingMetrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                metrics[building.id] = buildingMetrics
            } catch {
                print("⚠️ Failed to load metrics for building \(building.id): \(error)")
            }
        }
        
        self.buildingMetrics = metrics
        await broadcastCrossDashboardUpdate(.metricsUpdated(buildingIds: Array(metrics.keys)))
    }
    
    // MARK: - Compliance Issues Loading
    private func loadComplianceIssues() async {
        var allIssues: [CoreTypes.ComplianceIssue] = []
        
        // Generate sample compliance issues based on insights
        for insight in intelligenceInsights where insight.type == .compliance {
            let issue = CoreTypes.ComplianceIssue(
                title: insight.title,
                description: insight.description,
                severity: mapPriorityToSeverity(insight.priority).rawValue,
                buildingId: insight.affectedBuildings.first ?? "unknown",
                status: .warning,
                dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
            )
            allIssues.append(issue)
        }
        
        self.complianceIssues = allIssues
        print("✅ Compliance issues loaded: \(allIssues.count) issues")
    }
    
    // MARK: - Executive Summary Generation
    private func generateExecutiveSummary() async {
        let totalBuildings = buildingsList.count
        let totalWorkers = portfolioIntelligence?.activeWorkers ?? 0
        let portfolioHealth = calculatePortfolioHealth()
        let monthlyPerformance = determineMonthlyPerformance()
        
        executiveSummary = CoreTypes.ExecutiveSummary(
            totalBuildings: totalBuildings,
            totalWorkers: totalWorkers,
            portfolioHealth: portfolioHealth,
            monthlyPerformance: monthlyPerformance
        )
        
        generatePortfolioBenchmarks()
        generateStrategicRecommendations()
        
        print("✅ Executive summary generated")
    }
    
    // MARK: - Portfolio Benchmarks Generation
    private func generatePortfolioBenchmarks() {
        guard let intelligence = portfolioIntelligence else { return }
        
        portfolioBenchmarks = [
            CoreTypes.PortfolioBenchmark(
                metric: "Task Completion",
                value: intelligence.completionRate * 100,
                benchmark: 75.0,
                trend: intelligence.completionRate > 0.8 ? "up" : "down",
                period: "Monthly"
            ),
            CoreTypes.PortfolioBenchmark(
                metric: "Compliance Score",
                value: Double(intelligence.complianceScore),
                benchmark: 82.0,
                trend: intelligence.complianceScore > 85 ? "up" : "stable",
                period: "Monthly"
            ),
            CoreTypes.PortfolioBenchmark(
                metric: "Critical Issues",
                value: Double(intelligence.criticalIssues),
                benchmark: 8.0,
                trend: intelligence.criticalIssues < 5 ? "up" : "down",
                period: "Monthly"
            ),
            CoreTypes.PortfolioBenchmark(
                metric: "Worker Efficiency",
                value: intelligence.totalBuildings > 0 ?
                    Double(intelligence.activeWorkers) / Double(intelligence.totalBuildings) * 100 : 0,
                benchmark: 150.0,
                trend: intelligence.activeWorkers > intelligence.totalBuildings ? "up" : "down",
                period: "Monthly"
            )
        ]
    }
    
    // MARK: - Strategic Recommendations Generation
    private func generateStrategicRecommendations() {
        guard let intelligence = portfolioIntelligence else { return }
        
        var recommendations: [CoreTypes.StrategicRecommendation] = []
        
        // Completion rate recommendations
        if intelligence.completionRate < 0.8 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Improve Task Completion Rate",
                description: "Current completion rate is \(Int(intelligence.completionRate * 100))%. Consider optimizing worker schedules and task prioritization.",
                category: .efficiency,
                priority: .high,
                timeframe: "3-6 months",
                estimatedImpact: "+15% efficiency"
            ))
        }
        
        // Critical issues recommendations
        if intelligence.criticalIssues > 5 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Address Critical Issues",
                description: "\(intelligence.criticalIssues) critical issues require immediate attention. Prioritize resolution to prevent escalation.",
                category: .operations,
                priority: .high,
                timeframe: "Immediate",
                estimatedImpact: "Risk reduction"
            ))
        }
        
        // Compliance recommendations
        if intelligence.complianceScore < 90 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Enhance Compliance Program",
                description: "Compliance score of \(intelligence.complianceScore)% indicates room for improvement. Review audit processes.",
                category: .compliance,
                priority: .medium,
                timeframe: "6-12 months",
                estimatedImpact: "+10% compliance"
            ))
        }
        
        // Nova AI integration recommendation
        if intelligenceInsights.count > 0 {
            let highPriorityInsights = intelligenceInsights.filter {
                $0.priority == .high || $0.priority == .critical
            }
            if highPriorityInsights.count > 3 {
                recommendations.append(CoreTypes.StrategicRecommendation(
                    title: "Implement AI-Driven Optimization",
                    description: "Nova AI has identified \(highPriorityInsights.count) high-priority optimization opportunities across your portfolio.",
                    category: .efficiency,
                    priority: .medium,
                    timeframe: "2-4 months",
                    estimatedImpact: "+25% operational efficiency"
                ))
            }
        }
        
        strategicRecommendations = recommendations
    }
    
    // MARK: - Helper Methods
    private func calculateAverageEfficiency() -> Double {
        let efficiencies = buildingMetrics.values.map { $0.completionRate }
        return efficiencies.isEmpty ? 0.0 : efficiencies.reduce(0, +) / Double(efficiencies.count)
    }
    
    private func calculateComplianceRate() -> Double {
        let totalIssues = complianceIssues.count
        let resolvedIssues = complianceIssues.filter { $0.status == .compliant }.count
        return totalIssues > 0 ? Double(resolvedIssues) / Double(totalIssues) : 1.0
    }
    
    private func calculatePortfolioHealth() -> Double {
        guard let intelligence = portfolioIntelligence else { return 0.0 }
        
        let completionWeight = 0.3
        let complianceWeight = 0.3
        let issuesWeight = 0.2
        let efficiencyWeight = 0.2
        
        let completionScore = intelligence.completionRate * completionWeight
        let complianceScore = (Double(intelligence.complianceScore) / 100.0) * complianceWeight
        let issuesScore = (1.0 - min(Double(intelligence.criticalIssues) / 10.0, 1.0)) * issuesWeight
        let efficiencyScore = calculateAverageEfficiency() * efficiencyWeight
        
        return (completionScore + complianceScore + issuesScore + efficiencyScore) * 100
    }
    
    private func determineMonthlyPerformance() -> String {
        guard let trend = portfolioIntelligence?.monthlyTrend else { return "Unknown" }
        
        switch trend {
        case .up, .improving: return "Improving"
        case .down, .declining: return "Declining"
        case .stable: return "Stable"
        case .unknown: return "Unknown"
        }
    }
    
    private func mapPriorityToSeverity(_ priority: CoreTypes.InsightPriority) -> CoreTypes.ComplianceSeverity {
        switch priority {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
    
    private func setFallbackData() {
        portfolioIntelligence = CoreTypes.PortfolioIntelligence(
            totalBuildings: 0,
            activeWorkers: 0,
            completionRate: 0.0,
            criticalIssues: 0,
            complianceScore: 0,
            portfolioHealth: 0.0,
            monthlyTrend: .unknown
        )
        
        buildingsList = []
        buildingMetrics = [:]
        intelligenceInsights = []
        updateDashboardMetrics(from: portfolioIntelligence!)
        
        executiveSummary = CoreTypes.ExecutiveSummary(
            totalBuildings: 0,
            totalWorkers: 0,
            portfolioHealth: 0.0,
            monthlyPerformance: "Unknown"
        )
        
        portfolioBenchmarks = []
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
    func refreshData() async {
        await loadPortfolioIntelligence()
    }
    
    func forceRefresh() async {
        dashboardSyncStatus = .syncing
        await loadPortfolioIntelligence()
        dashboardSyncStatus = .synced
    }
    
    func getBuildingMetrics(for buildingId: String) -> CoreTypes.BuildingMetrics? {
        return buildingMetrics[buildingId]
    }
    
    func getComplianceIssues(for buildingId: String? = nil) -> [CoreTypes.ComplianceIssue] {
        if let buildingId = buildingId {
            return complianceIssues.filter { $0.buildingId == buildingId }
        }
        return complianceIssues
    }
    
    func getInsights(filtered by, priority: CoreTypes.InsightPriority? = nil) -> [CoreTypes.IntelligenceInsight] {
        if let priority = priority {
            return intelligenceInsights.filter { $0.priority == priority }
        }
        return intelligenceInsights
    }
    
    // MARK: - Cross-Dashboard Integration
    private func setupSubscriptions() {
        dashboardSyncService.crossDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleCrossDashboardUpdate(update)
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
    
    private func broadcastCrossDashboardUpdate(_ update: CoreTypes.CrossDashboardUpdate) async {
        crossDashboardUpdates.append(update)
        
        // Keep only recent updates
        if crossDashboardUpdates.count > 50 {
            crossDashboardUpdates = Array(crossDashboardUpdates.suffix(50))
        }
        
        Task {
            await dashboardSyncService.broadcastUpdate(update)
        }
    }
    
    private func handleCrossDashboardUpdate(_ update: CoreTypes.CrossDashboardUpdate) {
        switch update {
        case .taskCompleted(let taskId, let workerId, let buildingId):
            print("📱 Client Dashboard: Task \(taskId) completed by worker \(workerId) at building \(buildingId)")
            // Update building metrics
            if let existingMetrics = buildingMetrics[buildingId] {
                let updatedMetrics = CoreTypes.BuildingMetrics(
                    buildingId: buildingId,
                    completionRate: min(existingMetrics.completionRate + 0.01, 1.0),
                    averageTaskTime: existingMetrics.averageTaskTime,
                    overdueTasks: max(existingMetrics.overdueTasks - 1, 0),
                    totalTasks: existingMetrics.totalTasks,
                    activeWorkers: existingMetrics.activeWorkers,
                    isCompliant: existingMetrics.isCompliant,
                    overallScore: existingMetrics.overallScore
                )
                buildingMetrics[buildingId] = updatedMetrics
            }
            
        case .workerAssigned(let workerId, let buildingId):
            print("📱 Client Dashboard: Worker \(workerId) assigned to building \(buildingId)")
            activeWorkers += 1
            
        case .buildingMetricsUpdated(let buildingId, let metrics):
            print("📱 Client Dashboard: Metrics updated for building \(buildingId)")
            buildingMetrics[buildingId] = metrics
            
        case .complianceIssueAdded(let issue):
            print("📱 Client Dashboard: New compliance issue added")
            complianceIssues.append(issue)
            criticalIssues += 1
            
        case .portfolioUpdated(let buildingCount):
            print("📱 Client Dashboard: Portfolio updated with \(buildingCount) buildings")
            totalBuildings = buildingCount
            
        case .metricsUpdated(let buildingIds):
            print("📱 Client Dashboard: Metrics updated for buildings: \(buildingIds)")
            Task {
                for buildingId in buildingIds {
                    do {
                        let updatedMetrics = try await buildingMetricsService.calculateMetrics(for: buildingId)
                        buildingMetrics[buildingId] = updatedMetrics
                    } catch {
                        print("⚠️ Failed to refresh metrics for building \(buildingId): \(error)")
                    }
                }
            }
            
        case .insightsGenerated(let insights):
            print("📱 Client Dashboard: \(insights.count) new insights generated")
            intelligenceInsights.append(contentsOf: insights)
            Task {
                await generateExecutiveSummary()
            }
        }
        
        dashboardSyncStatus = .synced
        lastUpdateTime = Date()
        crossDashboardUpdates.append(update)
    }
    
    // MARK: - Nova AI Integration Support
    func generateNovaAIContext() -> String {
        guard let intelligence = portfolioIntelligence else {
            return "Portfolio data unavailable"
        }
        
        let contextItems = [
            "Portfolio: \(intelligence.totalBuildings) buildings",
            "Workers: \(intelligence.activeWorkers) active",
            "Completion: \(Int(intelligence.completionRate * 100))%",
            "Critical Issues: \(intelligence.criticalIssues)",
            "Compliance: \(intelligence.complianceScore)%",
            "Trend: \(intelligence.monthlyTrend.rawValue)",
            "Insights: \(intelligenceInsights.count) available",
            "High Priority: \(intelligenceInsights.filter { $0.priority == .high || $0.priority == .critical }.count)"
        ]
        
        return contextItems.joined(separator: ", ")
    }
}
