//
//  ClientDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ V6.0: FIXED - Explicit CoreTypes.BuildingAnalytics namespacing
//  ✅ Uses BuildingService.CoreTypes.BuildingAnalytics (returned by getCoreTypes.BuildingAnalytics)
//  ✅ Integrates with IntelligenceService for portfolio insights
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - Type Aliases for Internal Use
    private typealias LocalCoreTypes.BuildingAnalytics = BuildingService.CoreTypes.BuildingAnalytics
    
    // MARK: - Published Properties
    @Published var portfolioIntelligence: CoreTypes.CoreTypes.PortfolioIntelligence?
    @Published var buildingsList: [NamedCoordinate] = []
    @Published var buildingAnalytics: [String: LocalCoreTypes.BuildingAnalytics] = []  // FIXED: Use type alias
    @Published var portfolioInsights: [CoreTypes.IntelligenceInsight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Service Dependencies
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let intelligenceService = IntelligenceService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupAutoRefresh()
    }
    
    // MARK: - Public Methods
    
    /// Load complete portfolio data using existing service methods
    func loadPortfolioData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Use existing BuildingService.getAllBuildings()
            buildingsList = try await buildingService.getAllBuildings()
            
            // Load analytics for each building using existing method
            var analytics: [String: LocalCoreTypes.BuildingAnalytics] = [:]  // FIXED: Use type alias
            var totalTasks = 0
            var totalCompleted = 0
            var totalWorkers = 0
            
            for building in buildingsList {
                // This returns BuildingService.CoreTypes.BuildingAnalytics
                let buildingAnalytic = try await buildingService.getCoreTypes.BuildingAnalytics(building.id)
                analytics[building.id] = buildingAnalytic
                
                // Aggregate totals for portfolio overview
                totalTasks += buildingAnalytic.totalTasks
                totalCompleted += buildingAnalytic.completedTasks
                totalWorkers += buildingAnalytic.uniqueWorkers
            }
            
            // FIXED: Create portfolio intelligence using CoreTypes
            let portfolio = CoreTypes.CoreTypes.PortfolioIntelligence(
                totalBuildings: buildingsList.count,
                totalCompletedTasks: totalCompleted,
                averageComplianceScore: calculateOverallCompliance(analytics),
                totalActiveWorkers: totalWorkers,
                overallEfficiency: totalTasks > 0 ? Double(totalCompleted) / Double(totalTasks) : 0.0,
                trendDirection: calculatePortfolioTrend(analytics)
            )
            
            // Load portfolio insights from IntelligenceService
            let insights = try await intelligenceService.generatePortfolioInsights()
            
            // Update UI
            self.buildingAnalytics = analytics
            self.portfolioIntelligence = portfolio
            self.portfolioInsights = insights
            self.lastUpdateTime = Date()
            
        } catch {
            errorMessage = "Failed to load portfolio data: \(error.localizedDescription)"
            print("❌ ClientDashboardViewModel error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Get top performing buildings for dashboard highlights
    func getTopPerformingBuildings() -> [NamedCoordinate] {
        return buildingsList
            .compactMap { building -> (NamedCoordinate, Double)? in
                guard let analytics = buildingAnalytics[building.id] else { return nil }
                return (building, analytics.completionRate)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }
    }
    
    /// Get buildings needing attention for alerts
    func getBuildingsNeedingAttention() -> [NamedCoordinate] {
        return buildingsList.compactMap { building in
            guard let analytics = buildingAnalytics[building.id] else { return nil }
            return analytics.overdueTasks > 0 || analytics.completionRate < 0.8 ? building : nil
        }
    }
    
    /// Get portfolio summary for header display
    func getPortfolioSummary() -> String {
        guard let portfolio = portfolioIntelligence else { return "Loading..." }
        
        let efficiency = Int(portfolio.overallEfficiency * 100)
        let compliance = Int(portfolio.averageComplianceScore * 100)
        
        return "\(portfolio.totalBuildings) Buildings • \(efficiency)% Efficiency • \(compliance)% Compliance"
    }
    
    /// Refresh specific building data using existing methods
    func refreshBuilding(_ buildingId: String) async {
        do {
            // Use existing BuildingService.getCoreTypes.BuildingAnalytics()
            let updatedAnalytics = try await buildingService.getCoreTypes.BuildingAnalytics(buildingId)
            buildingAnalytics[buildingId] = updatedAnalytics
            
            // Recalculate portfolio overview
            if let currentPortfolio = portfolioIntelligence {
                let newPortfolio = CoreTypes.CoreTypes.PortfolioIntelligence(
                    totalBuildings: currentPortfolio.totalBuildings,
                    totalCompletedTasks: buildingAnalytics.values.reduce(0) { $0 + $1.completedTasks },
                    averageComplianceScore: calculateOverallCompliance(buildingAnalytics),
                    totalActiveWorkers: buildingAnalytics.values.reduce(0) { $0 + $1.uniqueWorkers },
                    overallEfficiency: calculateOverallEfficiency(buildingAnalytics),
                    trendDirection: calculatePortfolioTrend(buildingAnalytics)
                )
                portfolioIntelligence = newPortfolio
            }
            
        } catch {
            errorMessage = "Failed to refresh building data: \(error.localizedDescription)"
        }
    }
    
    /// Get building analytics for a specific building
    func getCoreTypes.BuildingAnalytics(for buildingId: String) -> LocalCoreTypes.BuildingAnalytics? {  // FIXED: Use type alias
        return buildingAnalytics[buildingId]
    }
    
    /// Check if building needs attention
    func buildingNeedsAttention(_ buildingId: String) -> Bool {
        guard let analytics = buildingAnalytics[buildingId] else { return false }
        return analytics.overdueTasks > 0 || analytics.completionRate < 0.8
    }
    
    /// Get high-priority insights for executive dashboard
    func getHighPriorityInsights() -> [CoreTypes.IntelligenceInsight] {
        return portfolioInsights.filter {
            $0.priority == .high || $0.priority == .critical
        }.prefix(5).map { $0 }
    }
    
    /// Get actionable insights for immediate attention
    func getActionableInsights() -> [CoreTypes.IntelligenceInsight] {
        return portfolioInsights.filter { $0.actionable }.prefix(3).map { $0 }
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateOverallCompliance(_ analytics: [String: LocalCoreTypes.BuildingAnalytics]) -> Double {  // FIXED: Use type alias
        guard !analytics.isEmpty else { return 0.0 }
        
        let totalCompliance = analytics.values.reduce(0.0) { result, buildingAnalytics in
            // Compliance is based on completion rate and overdue tasks
            let baseCompliance = buildingAnalytics.completionRate
            let overdueReduction = Double(buildingAnalytics.overdueTasks) * 0.1 // Each overdue task reduces compliance by 10%
            return result + max(0.0, baseCompliance - overdueReduction)
        }
        
        return totalCompliance / Double(analytics.count)
    }
    
    private func calculateOverallEfficiency(_ analytics: [String: LocalCoreTypes.BuildingAnalytics]) -> Double {  // FIXED: Use type alias
        guard !analytics.isEmpty else { return 0.0 }
        
        let totalTasks = analytics.values.reduce(0) { $0 + $1.totalTasks }
        let totalCompleted = analytics.values.reduce(0) { $0 + $1.completedTasks }
        
        return totalTasks > 0 ? Double(totalCompleted) / Double(totalTasks) : 0.0
    }
    
    private func calculatePortfolioTrend(_ analytics: [String: LocalCoreTypes.BuildingAnalytics]) -> CoreTypes.TrendDirection {  // FIXED: Use type alias
        guard !analytics.isEmpty else { return .stable }  // FIXED: Use .stable instead of .unknown
        
        let highPerformingCount = analytics.values.filter { $0.completionRate > 0.8 }.count
        let lowPerformingCount = analytics.values.filter { $0.completionRate < 0.6 }.count
        
        if highPerformingCount > lowPerformingCount {
            return .up  // FIXED: Use .up instead of .improving
        } else if lowPerformingCount > highPerformingCount {
            return .down  // FIXED: Use .down instead of .declining
        } else {
            return .stable
        }
    }
    
    private func setupAutoRefresh() {
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.loadPortfolioData()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Helper Models for UI Display

/// Building item for client dashboard list display
struct ClientBuildingItem: Identifiable {
    let id: String
    let building: NamedCoordinate
    let analytics: BuildingService.CoreTypes.BuildingAnalytics  // FIXED: Back to explicit namespace for clarity
    
    init(building: NamedCoordinate, analytics: BuildingService.CoreTypes.BuildingAnalytics) {  // FIXED: Explicit namespace
        self.id = building.id
        self.building = building
        self.analytics = analytics
    }
    
    var statusColor: Color {
        if analytics.completionRate >= 0.9 { return .green }
        if analytics.completionRate >= 0.8 { return .blue }
        if analytics.completionRate >= 0.7 { return .orange }
        return .red
    }
    
    var statusText: String {
        if analytics.overdueTasks > 0 { return "Needs Attention" }
        if analytics.completionRate >= 0.9 { return "Excellent" }
        if analytics.completionRate >= 0.8 { return "Good" }
        return "Fair"
    }
    
    var efficiencyPercentage: Int {
        return Int(analytics.completionRate * 100)
    }
}

/// Portfolio health summary for client view
struct PortfolioHealthSummary {
    let portfolio: CoreTypes.CoreTypes.PortfolioIntelligence
    let insights: [CoreTypes.IntelligenceInsight]
    let alertBuildings: [NamedCoordinate]
    
    var overallStatus: String {
        let efficiency = portfolio.overallEfficiency
        let compliance = portfolio.averageComplianceScore
        let average = (efficiency + compliance) / 2
        
        if average >= 0.9 { return "Excellent" }
        if average >= 0.8 { return "Good" }
        if average >= 0.7 { return "Fair" }
        return "Needs Improvement"
    }
    
    var statusColor: Color {
        let efficiency = portfolio.overallEfficiency
        let compliance = portfolio.averageComplianceScore
        let average = (efficiency + compliance) / 2
        
        if average >= 0.9 { return .green }
        if average >= 0.8 { return .blue }
        if average >= 0.7 { return .orange }
        return .red
    }
    
    var criticalIssuesCount: Int {
        insights.filter { $0.priority == .critical }.count
    }
    
    var actionRequiredCount: Int {
        insights.filter { $0.actionable }.count
    }
}

// MARK: - Extensions for CoreTypes Compatibility

extension CoreTypes.CoreTypes.PortfolioIntelligence {
    /// Computed properties for UI display
    var efficiencyPercentage: Int {
        return Int(overallEfficiency * 100)
    }
    
    var compliancePercentage: Int {
        return Int(averageComplianceScore * 100)
    }
    
    var status: String {
        if overallEfficiency > 0.9 && averageComplianceScore > 0.9 {
            return "Excellent"
        } else if overallEfficiency > 0.8 && averageComplianceScore > 0.8 {
            return "Good"
        } else if overallEfficiency > 0.7 && averageComplianceScore > 0.7 {
            return "Fair"
        } else {
            return "Needs Improvement"
        }
    }
    
    var statusColor: Color {
        if overallEfficiency > 0.9 && averageComplianceScore > 0.9 {
            return .green
        } else if overallEfficiency > 0.8 && averageComplianceScore > 0.8 {
            return .blue
        } else if overallEfficiency > 0.7 && averageComplianceScore > 0.7 {
            return .orange
        } else {
            return .red
        }
    }
}
