//
//  ClientDashboardViewModel.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  ClientDashboardViewModel.swift
//  FrancoSphere
//
//  🎯 PHASE 4: CLIENT DASHBOARD VIEWMODEL
//  ✅ Portfolio intelligence aggregation from BuildingService
//  ✅ Real-time data synchronization integration
//  ✅ Compliance monitoring and reporting
//  ✅ Intelligence insights generation
//  ✅ Performance analytics consolidation
//

import Foundation
import SwiftUI
import Combine

// MARK: - Client Dashboard ViewModel

@MainActor
class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var portfolioIntelligence: PortfolioIntelligence?
    @Published var buildingIntelligenceList: [BuildingIntelligenceItem] = []
    @Published var complianceOverview: ComplianceOverview?
    @Published var intelligenceInsights: [IntelligenceInsight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    @Published var refreshProgress: Double = 0.0
    
    // MARK: - Service Dependencies
    
    private let buildingService = BuildingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupDataSynchronization()
    }
    
    // MARK: - Public Methods
    
    /// Load complete portfolio intelligence
    func loadPortfolioIntelligence() async {
        isLoading = true
        errorMessage = nil
        refreshProgress = 0.0
        
        do {
            // Load all buildings
            refreshProgress = 0.2
            let buildings = try await buildingService.getAllBuildings()
            
            // Load intelligence for each building
            refreshProgress = 0.4
            var buildingIntelligenceItems: [BuildingIntelligenceItem] = []
            let totalBuildings = buildings.count
            
            for (index, building) in buildings.enumerated() {
                let analytics = try await buildingService.getBuildingAnalytics(building.id)
                let operationalInsights = try await buildingService.getBuildingOperationalInsights(building.id)
                
                let intelligenceItem = BuildingIntelligenceItem(
                    building: building,
                    analytics: analytics,
                    operationalInsights: operationalInsights,
                    lastUpdated: Date()
                )
                
                buildingIntelligenceItems.append(intelligenceItem)
                
                // Update progress
                refreshProgress = 0.4 + (Double(index + 1) / Double(totalBuildings)) * 0.4
            }
            
            // Generate portfolio overview
            refreshProgress = 0.8
            let portfolioOverview = generatePortfolioOverview(from: buildingIntelligenceItems)
            
            // Generate compliance overview
            let complianceData = await generateComplianceOverview(from: buildingIntelligenceItems)
            
            // Generate intelligence insights
            let insights = generateIntelligenceInsights(from: buildingIntelligenceItems)
            
            // Update UI
            refreshProgress = 1.0
            self.portfolioIntelligence = portfolioOverview
            self.buildingIntelligenceList = buildingIntelligenceItems.sorted { $0.analytics.completionRate > $1.analytics.completionRate }
            self.complianceOverview = complianceData
            self.intelligenceInsights = insights
            self.lastUpdateTime = Date()
            
        } catch {
            errorMessage = "Failed to load portfolio intelligence: \(error.localizedDescription)"
            print("❌ ClientDashboardViewModel error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh specific building intelligence
    func refreshBuildingIntelligence(for buildingId: String) async {
        guard let index = buildingIntelligenceList.firstIndex(where: { $0.building.id == buildingId }) else { return }
        
        do {
            let building = buildingIntelligenceList[index].building
            let analytics = try await buildingService.getBuildingAnalytics(buildingId)
            let operationalInsights = try await buildingService.getBuildingOperationalInsights(buildingId)
            
            let updatedItem = BuildingIntelligenceItem(
                building: building,
                analytics: analytics,
                operationalInsights: operationalInsights,
                lastUpdated: Date()
            )
            
            buildingIntelligenceList[index] = updatedItem
            
            // Regenerate portfolio overview
            portfolioIntelligence = generatePortfolioOverview(from: buildingIntelligenceList)
            
        } catch {
            errorMessage = "Failed to refresh building data: \(error.localizedDescription)"
        }
    }
    
    /// Get performance summary for dashboard header
    func getPerformanceSummary() -> PerformanceSummary? {
        guard let portfolio = portfolioIntelligence else { return nil }
        
        return PerformanceSummary(
            totalBuildings: portfolio.totalBuildings,
            averageEfficiency: portfolio.averageEfficiency,
            totalCompletedTasks: portfolio.totalCompletedTasks,
            complianceScore: complianceOverview?.overallScore ?? 0.0,
            trend: calculateTrend()
        )
    }
    
    // MARK: - Private Methods
    
    private func generatePortfolioOverview(from buildings: [BuildingIntelligenceItem]) -> PortfolioIntelligence {
        let totalBuildings = buildings.count
        let totalTasks = buildings.reduce(0) { $0 + $1.analytics.totalTasks }
        let completedTasks = buildings.reduce(0) { $0 + $1.analytics.completedTasks }
        let overdueTasks = buildings.reduce(0) { $0 + $1.analytics.overdueTasks }
        
        let averageEfficiency = buildings.isEmpty ? 0.0 : 
            buildings.reduce(0.0) { $0 + $1.analytics.completionRate } / Double(totalBuildings)
        
        let topPerformingBuildings = buildings
            .sorted { $0.analytics.completionRate > $1.analytics.completionRate }
            .prefix(3)
            .map { $0.building }
        
        let alertBuildings = buildings
            .filter { $0.analytics.overdueTasks > 0 || $0.operationalInsights.maintenancePriority == .high }
            .map { $0.building }
        
        return PortfolioIntelligence(
            totalBuildings: totalBuildings,
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            overdueTasks: overdueTasks,
            averageEfficiency: averageEfficiency,
            topPerformingBuildings: Array(topPerformingBuildings),
            alertBuildings: alertBuildings,
            lastUpdated: Date()
        )
    }
    
    private func generateComplianceOverview(from buildings: [BuildingIntelligenceItem]) async -> ComplianceOverview {
        // Calculate compliance metrics based on building analytics
        let totalCompliantBuildings = buildings.filter { $0.analytics.completionRate >= 0.85 }.count
        let compliancePercentage = buildings.isEmpty ? 0.0 : Double(totalCompliantBuildings) / Double(buildings.count)
        
        let pendingActions = buildings.reduce(0) { $0 + $1.analytics.overdueTasks }
        
        let criticalIssues = buildings.compactMap { building -> ComplianceIssue? in
            if building.analytics.overdueTasks > 5 || building.analytics.completionRate < 0.5 {
                return ComplianceIssue(
                    building: building.building,
                    issueType: .maintenanceOverdue,
                    severity: .high,
                    description: "Building has \(building.analytics.overdueTasks) overdue tasks",
                    dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
                )
            }
            return nil
        }
        
        return ComplianceOverview(
            overallScore: compliancePercentage * 100,
            compliantBuildings: totalCompliantBuildings,
            totalBuildings: buildings.count,
            pendingActions: pendingActions,
            criticalIssues: criticalIssues,
            lastAuditDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            nextAuditDate: Calendar.current.date(byAdding: .day, value: 23, to: Date())
        )
    }
    
    private func generateIntelligenceInsights(from buildings: [BuildingIntelligenceItem]) -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Efficiency trend insight
        let highEfficiencyCount = buildings.filter { $0.analytics.completionRate > 0.9 }.count
        if highEfficiencyCount > buildings.count / 2 {
            insights.append(IntelligenceInsight(
                title: "High Portfolio Efficiency",
                description: "\(highEfficiencyCount) out of \(buildings.count) buildings are performing at >90% efficiency",
                type: .performance,
                priority: .medium,
                actionable: false
            ))
        }
        
        // Maintenance priority insight
        let highPriorityBuildings = buildings.filter { $0.operationalInsights.maintenancePriority == .high }
        if !highPriorityBuildings.isEmpty {
            insights.append(IntelligenceInsight(
                title: "Maintenance Priority Alert",
                description: "\(highPriorityBuildings.count) buildings require immediate maintenance attention",
                type: .maintenance,
                priority: .high,
                actionable: true
            ))
        }
        
        // Cost optimization insight
        let totalWorkers = buildings.reduce(0) { $0 + $1.analytics.uniqueWorkers }
        let averageWorkersPerBuilding = Double(totalWorkers) / Double(buildings.count)
        if averageWorkersPerBuilding > 3.0 {
            insights.append(IntelligenceInsight(
                title: "Worker Optimization Opportunity",
                description: "Average of \(String(format: "%.1f", averageWorkersPerBuilding)) workers per building suggests potential for optimization",
                type: .cost,
                priority: .medium,
                actionable: true
            ))
        }
        
        // Compliance insight
        if let compliance = complianceOverview, compliance.overallScore < 80 {
            insights.append(IntelligenceInsight(
                title: "Compliance Improvement Needed",
                description: "Portfolio compliance score of \(String(format: "%.1f", compliance.overallScore))% is below target",
                type: .compliance,
                priority: .high,
                actionable: true
            ))
        }
        
        return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func calculateTrend() -> TrendDirection {
        // Placeholder trend calculation
        // In real implementation, this would compare current vs historical data
        guard let portfolio = portfolioIntelligence else { return .neutral }
        
        if portfolio.averageEfficiency > 0.85 {
            return .up
        } else if portfolio.averageEfficiency < 0.7 {
            return .down
        } else {
            return .neutral
        }
    }
    
    private func setupDataSynchronization() {
        // Set up automatic refresh every 5 minutes
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.loadPortfolioIntelligence()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Data Models

struct PortfolioIntelligence {
    let totalBuildings: Int
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let averageEfficiency: Double
    let topPerformingBuildings: [NamedCoordinate]
    let alertBuildings: [NamedCoordinate]
    let lastUpdated: Date
    
    var completionRate: Double {
        totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
    }
}

struct BuildingIntelligenceItem: Identifiable {
    let id = UUID()
    let building: NamedCoordinate
    let analytics: BuildingAnalytics
    let operationalInsights: BuildingOperationalInsights
    let lastUpdated: Date
    
    var efficiencyStatus: EfficiencyStatus {
        if analytics.completionRate >= 0.9 { return .excellent }
        if analytics.completionRate >= 0.8 { return .good }
        if analytics.completionRate >= 0.7 { return .fair }
        return .poor
    }
}

enum EfficiencyStatus: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good" 
    case fair = "Fair"
    case poor = "Poor"
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

struct ComplianceOverview {
    let overallScore: Double
    let compliantBuildings: Int
    let totalBuildings: Int
    let pendingActions: Int
    let criticalIssues: [ComplianceIssue]
    let lastAuditDate: Date?
    let nextAuditDate: Date?
    
    var compliancePercentage: Double {
        totalBuildings > 0 ? Double(compliantBuildings) / Double(totalBuildings) * 100 : 0.0
    }
}

struct ComplianceIssue: Identifiable {
    let id = UUID()
    let building: NamedCoordinate
    let issueType: ComplianceIssueType
    let severity: ComplianceSeverity
    let description: String
    let dueDate: Date?
}

enum ComplianceIssueType: String, CaseIterable {
    case maintenanceOverdue = "Maintenance Overdue"
    case safetyViolation = "Safety Violation"
    case documentationMissing = "Documentation Missing"
    case inspectionRequired = "Inspection Required"
}

enum ComplianceSeverity: String, CaseIterable {
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

struct IntelligenceInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: InsightType
    let priority: InsightPriority
    let actionable: Bool
    let createdAt = Date()
}

enum InsightType: String, CaseIterable {
    case performance = "Performance"
    case maintenance = "Maintenance"
    case cost = "Cost"
    case compliance = "Compliance"
    case efficiency = "Efficiency"
    
    var icon: String {
        switch self {
        case .performance: return "chart.line.uptrend.xyaxis"
        case .maintenance: return "wrench.and.screwdriver"
        case .cost: return "dollarsign.circle"
        case .compliance: return "checkmark.shield"
        case .efficiency: return "speedometer"
        }
    }
    
    var color: Color {
        switch self {
        case .performance: return .blue
        case .maintenance: return .orange
        case .cost: return .green
        case .compliance: return .purple
        case .efficiency: return .teal
        }
    }
}

enum InsightPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var rawValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

struct PerformanceSummary {
    let totalBuildings: Int
    let averageEfficiency: Double
    let totalCompletedTasks: Int
    let complianceScore: Double
    let trend: TrendDirection
}

enum TrendDirection: String, CaseIterable {
    case up = "Up"
    case down = "Down"
    case neutral = "Neutral"
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}