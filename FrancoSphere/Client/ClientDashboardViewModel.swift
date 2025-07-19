//
//  ClientDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ CORRECTED: Uses existing architecture and types
//  ✅ INTEGRATED: With existing ViewModels pattern
//  ✅ ALIGNED: With CoreTypes namespace and services
//  ✅ NO CONFLICTS: Uses established type patterns
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
    
    // MARK: - Executive Summary Data (Using Existing Types)
    @Published var executiveSummary: ExecutiveSummary?
    @Published var portfolioBenchmarks: [PortfolioBenchmark] = []
    @Published var strategicRecommendations: [StrategicRecommendation] = []
    
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
        do {
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
            
        } catch {
            print("⚠️ Failed to load compliance issues: \(error)")
            self.complianceIssues = []
        }
    }
    
    // MARK: - Executive Summary Generation
    private func generateExecutiveSummary() async {
        let totalBuildings = buildingsList.count
        let averageEfficiency = calculateAverageEfficiency()
        let complianceRate = calculateComplianceRate()
        let criticalIssues = complianceIssues.filter {
            CoreTypes.ComplianceSeverity(rawValue: $0.severity) == .critical
        }.count
        let actionableInsights = intelligenceInsights.filter { $0.actionRequired }.count
        let monthlyTrend = portfolioIntelligence?.monthlyTrend ?? .stable
        
        executiveSummary = ExecutiveSummary(
            totalBuildings: totalBuildings,
            portfolioEfficiency: averageEfficiency,
            complianceRate: complianceRate,
            criticalIssues: criticalIssues,
            actionableInsights: actionableInsights,
            monthlyTrend: monthlyTrend,
            lastUpdated: Date()
        )
        
        generatePortfolioBenchmarks()
        generateStrategicRecommendations()
        
        print("✅ Executive summary generated")
    }
    
    // MARK: - Portfolio Benchmarks Generation
    private func generatePortfolioBenchmarks() {
        guard let intelligence = portfolioIntelligence else { return }
        
        portfolioBenchmarks = [
            PortfolioBenchmark(
                category: "Task Completion",
                currentValue: intelligence.completionRate * 100,
                industryAverage: 75.0,
                targetValue: 90.0,
                trend: intelligence.completionRate > 0.8 ? .up : .down
            ),
            PortfolioBenchmark(
                category: "Compliance Score",
                currentValue: Double(intelligence.complianceScore),
                industryAverage: 82.0,
                targetValue: 95.0,
                trend: intelligence.complianceScore > 85 ? .up : .stable
            ),
            PortfolioBenchmark(
                category: "Critical Issues",
                currentValue: Double(intelligence.criticalIssues),
                industryAverage: 8.0,
                targetValue: 2.0,
                trend: intelligence.criticalIssues < 5 ? .up : .down
            ),
            PortfolioBenchmark(
                category: "Worker Efficiency",
                currentValue: intelligence.totalBuildings > 0 ?
                    Double(intelligence.activeWorkers) / Double(intelligence.totalBuildings) * 100 : 0,
                industryAverage: 150.0,
                targetValue: 200.0,
                trend: intelligence.activeWorkers > intelligence.totalBuildings ? .up : .down
            )
        ]
    }
    
    // MARK: - Strategic Recommendations Generation
    private func generateStrategicRecommendations() {
        guard let intelligence = portfolioIntelligence else { return }
        
        var recommendations: [StrategicRecommendation] = []
        
        // Completion rate recommendations
        if intelligence.completionRate < 0.8 {
            recommendations.append(StrategicRecommendation(
                title: "Improve Task Completion Rate",
                description: "Current completion rate is \(Int(intelligence.completionRate * 100))%. Consider optimizing worker schedules and task prioritization.",
                priority: .high,
                estimatedImpact: "+15% efficiency",
                timeframe: "3-6 months"
            ))
        }
        
        // Critical issues recommendations
        if intelligence.criticalIssues > 5 {
            recommendations.append(StrategicRecommendation(
                title: "Address Critical Issues",
                description: "\(intelligence.criticalIssues) critical issues require immediate attention. Prioritize resolution to prevent escalation.",
                priority: .critical,
                estimatedImpact: "Risk reduction",
                timeframe: "Immediate"
            ))
        }
        
        // Compliance recommendations
        if intelligence.complianceScore < 90 {
            recommendations.append(StrategicRecommendation(
                title: "Enhance Compliance Program",
                description: "Compliance score of \(intelligence.complianceScore)% indicates room for improvement. Review audit processes.",
                priority: .medium,
                estimatedImpact: "+10% compliance",
                timeframe: "6-12 months"
            ))
        }
        
        // Nova AI integration recommendation
        if intelligenceInsights.count > 0 {
            let highPriorityInsights = intelligenceInsights.filter {
                $0.priority == .high || $0.priority == .critical
            }
            if highPriorityInsights.count > 3 {
                recommendations.append(StrategicRecommendation(
                    title: "Implement AI-Driven Optimization",
                    description: "Nova AI has identified \(highPriorityInsights.count) high-priority optimization opportunities across your portfolio.",
                    priority: .medium,
                    estimatedImpact: "+25% operational efficiency",
                    timeframe: "2-4 months"
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
            monthlyTrend: .unknown
        )
        
        buildingsList = []
        buildingMetrics = [:]
        intelligenceInsights = []
        updateDashboardMetrics(from: portfolioIntelligence!)
        
        executiveSummary = ExecutiveSummary(
            totalBuildings: 0,
            portfolioEfficiency: 0.0,
            complianceRate: 0.0,
            criticalIssues: 0,
            actionableInsights: 0,
            monthlyTrend: .unknown,
            lastUpdated: Date()
        )
        
        portfolioBenchmarks = []
        strategicRecommendations = [
            StrategicRecommendation(
                title: "System Recovery",
                description: "Portfolio data is temporarily unavailable. Attempting to restore connection...",
                priority: .medium,
                estimatedImpact: "Service restoration",
                timeframe: "Immediate"
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
    
    func getInsights(filtered by priority: CoreTypes.InsightPriority? = nil) -> [CoreTypes.IntelligenceInsight] {
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
                    workerCount: existingMetrics.workerCount
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

// MARK: - Client-Specific Supporting Types (No Conflicts)

/// Executive summary for client dashboard
struct ExecutiveSummary {
    let totalBuildings: Int
    let portfolioEfficiency: Double
    let complianceRate: Double
    let criticalIssues: Int
    let actionableInsights: Int
    let monthlyTrend: CoreTypes.TrendDirection
    let lastUpdated: Date
    
    var efficiencyGrade: String {
        switch portfolioEfficiency {
        case 0.9...: return "A"
        case 0.8..<0.9: return "B"
        case 0.7..<0.8: return "C"
        default: return "D"
        }
    }
    
    var complianceGrade: String {
        switch complianceRate {
        case 0.95...: return "A+"
        case 0.9..<0.95: return "A"
        case 0.8..<0.9: return "B"
        default: return "C"
        }
    }
}

/// Portfolio benchmark for client dashboard
struct PortfolioBenchmark {
    let category: String
    let currentValue: Double
    let industryAverage: Double
    let targetValue: Double
    let trend: CoreTypes.TrendDirection
}

/// Strategic recommendation for client dashboard
struct StrategicRecommendation {
    let title: String
    let description: String
    let priority: CoreTypes.InsightPriority
    let estimatedImpact: String
    let timeframe: String
}
