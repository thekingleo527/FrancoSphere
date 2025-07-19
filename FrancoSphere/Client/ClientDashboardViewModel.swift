//
//  ClientDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With actual CoreTypes.PortfolioIntelligence structure
//  ✅ CORRECTED: Function declarations and property access
//  ✅ INTEGRATED: Cross-dashboard synchronization
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties (Aligned with CoreTypes)
    @Published var portfolioIntelligence: CoreTypes.PortfolioIntelligence?
    @Published var buildingsList: [NamedCoordinate] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var complianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published var intelligenceInsights: [CoreTypes.IntelligenceInsight] = []
    
    // MARK: - Dashboard Metrics (Derived from PortfolioIntelligence)
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
    
    // MARK: - Executive Summary Data
    @Published var executiveSummary: ClientExecutiveSummary?
    @Published var portfolioBenchmarks: [ClientPortfolioBenchmark] = []
    @Published var strategicRecommendations: [ClientStrategicRecommendation] = []
    
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
    init() {
        setupSubscriptions()
        schedulePeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Main Loading Function (FIXED)
    func loadPortfolioIntelligence() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load core portfolio data
            async let portfolioData = intelligenceService.generatePortfolioIntelligence()
            async let buildingsData = buildingService.getAllBuildings()
            async let insightsData = intelligenceService.generatePortfolioInsights()
            
            let intelligence = try await portfolioData
            let buildings = try await buildingsData
            let insights = try await insightsData
            
            // Update main data
            self.portfolioIntelligence = intelligence
            self.buildingsList = buildings
            self.intelligenceInsights = insights
            
            // Update derived metrics
            updateDashboardMetrics(from: intelligence)
            
            // Load building-specific metrics
            await loadBuildingMetrics()
            
            // Generate executive summary
            await generateExecutiveSummary()
            
            // Update timestamp
            lastUpdateTime = Date()
            
            print("✅ Portfolio intelligence loaded: \(buildings.count) buildings, \(insights.count) insights")
            
            // Broadcast cross-dashboard update
            broadcastCrossDashboardUpdate(.portfolioUpdated(buildingCount: buildings.count))
            
        } catch {
            print("❌ Failed to load portfolio intelligence: \(error)")
            errorMessage = error.localizedDescription
            setFallbackData()
        }
        
        isLoading = false
    }
    
    // MARK: - Dashboard Metrics Update (FIXED)
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
        broadcastCrossDashboardUpdate(.metricsUpdated(buildingIds: Array(metrics.keys)))
    }
    
    // MARK: - Executive Summary Generation
    private func generateExecutiveSummary() async {
        guard let intelligence = portfolioIntelligence else { return }
        
        // Calculate portfolio efficiency (using completion rate as proxy)
        let portfolioEfficiency = intelligence.completionRate
        
        // Calculate compliance rate (from compliance score)
        let complianceRate = Double(intelligence.complianceScore) / 100.0
        
        // Calculate monthly trend direction
        let monthlyTrendDirection = intelligence.monthlyTrend
        
        // Create executive summary
        executiveSummary = ClientExecutiveSummary(
            totalBuildings: intelligence.totalBuildings,
            portfolioEfficiency: portfolioEfficiency,
            complianceRate: complianceRate,
            criticalIssues: intelligence.criticalIssues,
            actionableInsights: intelligenceInsights.filter { $0.actionable }.count,
            monthlyTrend: monthlyTrendDirection,
            lastUpdated: Date()
        )
        
        // Generate benchmarks
        generatePortfolioBenchmarks()
        
        // Generate strategic recommendations
        generateStrategicRecommendations()
    }
    
    // MARK: - Portfolio Benchmarks
    private func generatePortfolioBenchmarks() {
        guard let intelligence = portfolioIntelligence else { return }
        
        portfolioBenchmarks = [
            ClientPortfolioBenchmark(
                category: "Task Completion",
                currentValue: intelligence.completionRate * 100,
                industryAverage: 75.0,
                targetValue: 90.0,
                trend: intelligence.completionRate > 0.8 ? .up : .down
            ),
            ClientPortfolioBenchmark(
                category: "Compliance Score",
                currentValue: Double(intelligence.complianceScore),
                industryAverage: 82.0,
                targetValue: 95.0,
                trend: intelligence.complianceScore > 85 ? .up : .stable
            ),
            ClientPortfolioBenchmark(
                category: "Critical Issues",
                currentValue: Double(intelligence.criticalIssues),
                industryAverage: 8.0,
                targetValue: 2.0,
                trend: intelligence.criticalIssues < 5 ? .up : .down
            )
        ]
    }
    
    // MARK: - Strategic Recommendations
    private func generateStrategicRecommendations() {
        guard let intelligence = portfolioIntelligence else { return }
        
        var recommendations: [ClientStrategicRecommendation] = []
        
        // Completion rate recommendations
        if intelligence.completionRate < 0.8 {
            recommendations.append(ClientStrategicRecommendation(
                title: "Improve Task Completion Rate",
                description: "Current completion rate is \(Int(intelligence.completionRate * 100))%. Consider optimizing worker schedules and task prioritization.",
                priority: .high,
                estimatedImpact: "+15% efficiency",
                timeframe: "3-6 months"
            ))
        }
        
        // Critical issues recommendations
        if intelligence.criticalIssues > 5 {
            recommendations.append(ClientStrategicRecommendation(
                title: "Address Critical Issues",
                description: "\(intelligence.criticalIssues) critical issues require immediate attention. Prioritize resolution to prevent escalation.",
                priority: .critical,
                estimatedImpact: "Risk reduction",
                timeframe: "Immediate"
            ))
        }
        
        // Compliance recommendations
        if intelligence.complianceScore < 90 {
            recommendations.append(ClientStrategicRecommendation(
                title: "Enhance Compliance Program",
                description: "Compliance score of \(intelligence.complianceScore)% indicates room for improvement. Review audit processes.",
                priority: .medium,
                estimatedImpact: "+10% compliance",
                timeframe: "6-12 months"
            ))
        }
        
        // Growth recommendations
        if intelligence.totalBuildings > 10 && intelligence.activeWorkers < intelligence.totalBuildings * 2 {
            recommendations.append(ClientStrategicRecommendation(
                title: "Consider Workforce Expansion",
                description: "With \(intelligence.totalBuildings) buildings and \(intelligence.activeWorkers) workers, consider expanding the team.",
                priority: .low,
                estimatedImpact: "+20% capacity",
                timeframe: "12+ months"
            ))
        }
        
        strategicRecommendations = recommendations
    }
    
    // MARK: - Refresh and Sync
    func refreshData() async {
        await loadPortfolioIntelligence()
    }
    
    func forceRefresh() async {
        dashboardSyncStatus = .syncing
        await loadPortfolioIntelligence()
        dashboardSyncStatus = .synced
    }
    
    // MARK: - Cross-Dashboard Integration
    private func setupSubscriptions() {
        // Listen for cross-dashboard updates
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
    
    private func broadcastCrossDashboardUpdate(_ update: CoreTypes.CrossDashboardUpdate) {
        Task {
            await dashboardSyncService.broadcastUpdate(update)
        }
    }
    
    private func handleCrossDashboardUpdate(_ update: CoreTypes.CrossDashboardUpdate) {
        crossDashboardUpdates.append(update)
        
        switch update {
        case .taskCompleted, .workerClockedIn, .metricsUpdated, .complianceUpdated:
            Task {
                await loadBuildingMetrics()
                await generateExecutiveSummary()
            }
        case .portfolioUpdated, .insightsUpdated:
            Task {
                await loadPortfolioIntelligence()
            }
        default:
            break
        }
    }
    
    // MARK: - Fallback Data
    private func setFallbackData() {
        portfolioIntelligence = CoreTypes.PortfolioIntelligence(
            totalBuildings: 8,
            activeWorkers: 12,
            completionRate: 0.85,
            criticalIssues: 3,
            monthlyTrend: .stable,
            completedTasks: 156,
            complianceScore: 88,
            weeklyTrend: 0.05
        )
        
        updateDashboardMetrics(from: portfolioIntelligence!)
        
        // Generate fallback insights
        intelligenceInsights = [
            CoreTypes.IntelligenceInsight(
                title: "Portfolio Performance Strong",
                description: "Overall completion rate of 85% exceeds industry benchmarks",
                type: .performance,
                priority: .medium,
                actionable: false,
                buildingId: nil,
                recommendedAction: nil,
                metadata: [:]
            ),
            CoreTypes.IntelligenceInsight(
                title: "Compliance Review Needed",
                description: "3 critical compliance issues require attention",
                type: .compliance,
                priority: .high,
                actionable: true,
                buildingId: nil,
                recommendedAction: "Schedule compliance audit",
                metadata: [:]
            )
        ]
        
        lastUpdateTime = Date()
    }
}

// MARK: - Supporting Types (Client-Specific)

struct ClientExecutiveSummary: Codable {
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

struct ClientPortfolioBenchmark: Codable {
    let category: String
    let currentValue: Double
    let industryAverage: Double
    let targetValue: Double
    let trend: CoreTypes.TrendDirection
}

struct ClientStrategicRecommendation: Codable {
    let title: String
    let description: String
    let priority: CoreTypes.InsightPriority
    let estimatedImpact: String
    let timeframe: String
}
