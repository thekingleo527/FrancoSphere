//
//  ClientDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With forensic developer's punchlist requirements
//  ✅ ENHANCED: Cross-dashboard integration ready
//  ✅ PREPARED: For ClientDashboardView creation (Phase 1.1)
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties (Using Correct CoreTypes)
    @Published var portfolioIntelligence: CoreTypes.PortfolioIntelligence?
    @Published var buildingsList: [NamedCoordinate] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var complianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published var intelligenceInsights: [CoreTypes.IntelligenceInsight] = []
    
    // MARK: - Loading States
    @Published var isLoading = false
    @Published var isLoadingInsights = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Cross-Dashboard Integration (Per Forensic Punchlist)
    @Published var dashboardSyncStatus: DashboardSyncStatus = .synced
    @Published var crossDashboardUpdates: [CrossDashboardUpdate] = []
    
    // MARK: - Executive Summary Data
    @Published var executiveSummary: ExecutiveSummary?
    @Published var portfolioBenchmarks: [PortfolioBenchmark] = []
    @Published var strategicRecommendations: [StrategicRecommendation] = []
    
    // MARK: - Services (Using Existing Shared Instances)
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
    
    // MARK: - Core Data Loading
    
    /// Loads portfolio intelligence and executive data
    func loadPortfolioIntelligence() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load core portfolio data
            async let buildingsLoad = buildingService.getAllBuildings()
            async let intelligenceLoad = intelligenceService.generatePortfolioInsights()
            
            let (buildings, insights) = try await (buildingsLoad, intelligenceLoad)
            
            self.buildingsList = buildings
            self.intelligenceInsights = insights
            
            // Load building metrics for all buildings
            await loadBuildingMetrics()
            
            // Generate executive summary
            await generateExecutiveSummary()
            
            // Generate portfolio benchmarks
            await generatePortfolioBenchmarks()
            
            // Generate strategic recommendations
            await generateStrategicRecommendations()
            
            self.lastUpdateTime = Date()
            print("✅ Client portfolio intelligence loaded: \(buildings.count) buildings, \(insights.count) insights")
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Failed to load portfolio intelligence: \(error)")
        }
        
        isLoading = false
    }
    
    /// Loads building metrics for portfolio analysis
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
    
    /// Loads compliance issues across portfolio
    func loadComplianceIssues() async {
        // TODO: Implement compliance loading when ComplianceService is available
        // For now, generate from building metrics
        var issues: [CoreTypes.ComplianceIssue] = []
        
        for (buildingId, metrics) in buildingMetrics {
            if !metrics.isCompliant {
                let issue = CoreTypes.ComplianceIssue(
                    type: .maintenanceOverdue,
                    severity: metrics.overdueTasks > 5 ? .critical : .medium,
                    description: "Building has \(metrics.overdueTasks) overdue maintenance tasks",
                    buildingId: buildingId,
                    dueDate: Date().addingTimeInterval(7 * 24 * 3600), // 7 days
                    resolvedDate: nil
                )
                issues.append(issue)
            }
        }
        
        self.complianceIssues = issues
    }
    
    // MARK: - Executive Intelligence Generation
    
    /// Generates executive summary from portfolio data
    private func generateExecutiveSummary() async {
        let totalBuildings = buildingsList.count
        let totalMetrics = buildingMetrics.values
        
        let averageEfficiency = totalMetrics.isEmpty ? 0.0 :
            totalMetrics.reduce(0.0) { $0 + $1.completionRate } / Double(totalMetrics.count)
        
        let compliantBuildings = totalMetrics.filter { $0.isCompliant }.count
        let complianceRate = totalBuildings > 0 ? Double(compliantBuildings) / Double(totalBuildings) : 0.0
        
        let criticalInsights = intelligenceInsights.filter { $0.priority == .critical }.count
        let actionableInsights = intelligenceInsights.filter { $0.actionRequired }.count
        
        let summary = ExecutiveSummary(
            totalBuildings: totalBuildings,
            portfolioEfficiency: averageEfficiency,
            complianceRate: complianceRate,
            criticalIssues: criticalInsights,
            actionableInsights: actionableInsights,
            monthlyTrend: calculateTrendDirection(),
            lastUpdated: Date()
        )
        
        self.executiveSummary = summary
    }
    
    /// Generates portfolio benchmarks
    private func generatePortfolioBenchmarks() async {
        let benchmarks = [
            PortfolioBenchmark(
                category: "Operational Efficiency",
                currentValue: executiveSummary?.portfolioEfficiency ?? 0.0,
                industryAverage: 0.75,
                targetValue: 0.90,
                trend: .improving
            ),
            PortfolioBenchmark(
                category: "Compliance Rate",
                currentValue: executiveSummary?.complianceRate ?? 0.0,
                industryAverage: 0.85,
                targetValue: 0.95,
                trend: calculateComplianceTrend()
            ),
            PortfolioBenchmark(
                category: "Cost Efficiency",
                currentValue: calculateCostEfficiency(),
                industryAverage: 0.70,
                targetValue: 0.85,
                trend: .stable
            )
        ]
        
        self.portfolioBenchmarks = benchmarks
    }
    
    /// Generates strategic recommendations
    private func generateStrategicRecommendations() async {
        var recommendations: [StrategicRecommendation] = []
        
        // Efficiency recommendations
        if let summary = executiveSummary, summary.portfolioEfficiency < 0.8 {
            recommendations.append(StrategicRecommendation(
                title: "Improve Operational Efficiency",
                description: "Portfolio efficiency is below target. Focus on task completion optimization.",
                priority: .high,
                category: .operational,
                estimatedImpact: "15-20% efficiency improvement",
                timeframe: "3-6 months"
            ))
        }
        
        // Compliance recommendations
        if complianceIssues.filter({ !$0.isResolved }).count > 3 {
            recommendations.append(StrategicRecommendation(
                title: "Address Compliance Issues",
                description: "Multiple compliance issues require immediate attention.",
                priority: .critical,
                category: .compliance,
                estimatedImpact: "Risk mitigation, regulatory compliance",
                timeframe: "1-2 months"
            ))
        }
        
        // Performance recommendations
        let lowPerformingBuildings = buildingMetrics.values.filter { $0.completionRate < 0.7 }.count
        if lowPerformingBuildings > 0 {
            recommendations.append(StrategicRecommendation(
                title: "Optimize Underperforming Buildings",
                description: "\(lowPerformingBuildings) buildings are below performance targets.",
                priority: .medium,
                category: .performance,
                estimatedImpact: "10-15% portfolio improvement",
                timeframe: "2-4 months"
            ))
        }
        
        self.strategicRecommendations = recommendations
    }
    
    // MARK: - Helper Methods
    
    /// Get building metrics for a specific building
    func getBuildingMetrics(for buildingId: String) -> CoreTypes.BuildingMetrics? {
        return buildingMetrics[buildingId]
    }
    
    /// Get compliance issues for a specific building
    func getComplianceIssues(for buildingId: String) -> [CoreTypes.ComplianceIssue] {
        return complianceIssues.filter { $0.buildingId == buildingId }
    }
    
    /// Get intelligence insights for a specific building
    func getIntelligenceInsights(for buildingId: String) -> [CoreTypes.IntelligenceInsight] {
        return intelligenceInsights.filter { insight in
            insight.affectedBuildings.contains(buildingId)
        }
    }
    
    /// ✅ FIXED: Get portfolio summary (no ambiguous type)
    func getClientPortfolioSummary() -> ClientPortfolioSummary {
        guard let executive = executiveSummary else {
            return ClientPortfolioSummary(
                totalBuildings: 0,
                efficiency: "0%",
                compliance: "0%",
                criticalIssues: 0,
                actionableInsights: 0,
                monthlyTrend: .unknown
            )
        }
        
        return ClientPortfolioSummary(
            totalBuildings: executive.totalBuildings,
            efficiency: "\(Int(executive.portfolioEfficiency * 100))%",
            compliance: "\(Int(executive.complianceRate * 100))%",
            criticalIssues: executive.criticalIssues,
            actionableInsights: executive.actionableInsights,
            monthlyTrend: executive.monthlyTrend
        )
    }
    
    /// Force refresh all data
    func forceRefresh() async {
        dashboardSyncStatus = .syncing
        await loadPortfolioIntelligence()
        await loadComplianceIssues()
        dashboardSyncStatus = .synced
    }
    
    // MARK: - Private Calculation Methods
    
    private func calculateTrendDirection() -> CoreTypes.TrendDirection {
        // TODO: Implement based on historical data when available
        let averageEfficiency = buildingMetrics.values.reduce(0.0) { $0 + $1.completionRate } / Double(buildingMetrics.count)
        
        switch averageEfficiency {
        case 0.9...: return .improving
        case 0.7..<0.9: return .stable
        default: return .declining
        }
    }
    
    private func calculateComplianceTrend() -> CoreTypes.TrendDirection {
        let complianceRate = Double(buildingMetrics.values.filter { $0.isCompliant }.count) / Double(buildingMetrics.count)
        
        switch complianceRate {
        case 0.9...: return .up
        case 0.8..<0.9: return .stable
        default: return .down
        }
    }
    
    private func calculateCostEfficiency() -> Double {
        // TODO: Implement cost efficiency calculation when financial data is available
        return 0.75 // Placeholder
    }
    
    // MARK: - Cross-Dashboard Integration (Per Forensic Punchlist)
    
    /// Setup cross-dashboard synchronization
    private func setupCrossDashboardSync() {
        // TODO: Integrate with DashboardSyncService when created
        print("🔗 Client dashboard prepared for cross-dashboard sync")
    }
    
    /// Broadcast update to other dashboards
    private func broadcastCrossDashboardUpdate(_ update: CrossDashboardUpdate) {
        crossDashboardUpdates.append(update)
        // TODO: Send to DashboardSyncService when created
        print("📡 Broadcasting update: \(update)")
    }
    
    /// Setup auto-refresh timer
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await self.forceRefresh()
            }
        }
    }
    
    /// Handle cross-dashboard update received from other dashboards
    func handleCrossDashboardUpdate(_ update: CrossDashboardUpdate) {
        switch update {
        case .taskCompleted, .workerClockedIn, .metricsUpdated, .complianceUpdated:
            Task {
                await loadBuildingMetrics()
                await generateExecutiveSummary()
            }
        case .insightsUpdated:
            Task {
                await loadPortfolioIntelligence()
            }
        default:
            break
        }
    }
}

// MARK: - Client-Specific Supporting Types (✅ FIXED: No ambiguous types)

/// Client-specific portfolio summary to avoid type conflicts
struct ClientPortfolioSummary {
    let totalBuildings: Int
    let efficiency: String
    let compliance: String
    let criticalIssues: Int
    let actionableInsights: Int
    let monthlyTrend: CoreTypes.TrendDirection
}

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
    
    var performance: BenchmarkPerformance {
        if currentValue >= targetValue {
            return .exceeding
        } else if currentValue >= industryAverage {
            return .meeting
        } else {
            return .below
        }
    }
    
    var currentPercentage: String {
        return "\(Int(currentValue * 100))%"
    }
}

enum BenchmarkPerformance {
    case exceeding
    case meeting
    case below
    
    var color: Color {
        switch self {
        case .exceeding: return .green
        case .meeting: return .blue
        case .below: return .orange
        }
    }
    
    var description: String {
        switch self {
        case .exceeding: return "Exceeding Target"
        case .meeting: return "Meeting Expectations"
        case .below: return "Below Target"
        }
    }
}

/// Strategic recommendation for client dashboard
struct StrategicRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: RecommendationPriority
    let category: RecommendationCategory
    let estimatedImpact: String
    let timeframe: String
}

enum RecommendationPriority {
    case critical
    case high
    case medium
    case low
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "flag.fill"
        case .medium: return "info.circle.fill"
        case .low: return "lightbulb.fill"
        }
    }
}

enum RecommendationCategory {
    case operational
    case compliance
    case performance
    case financial
    case strategic
    
    var icon: String {
        switch self {
        case .operational: return "gear.circle.fill"
        case .compliance: return "checkmark.shield.fill"
        case .performance: return "chart.line.uptrend.xyaxis.circle.fill"
        case .financial: return "dollarsign.circle.fill"
        case .strategic: return "target"
        }
    }
}
