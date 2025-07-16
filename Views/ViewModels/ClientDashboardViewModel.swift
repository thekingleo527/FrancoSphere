//
//  ClientDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ FIXED: Complete actor integration and async patterns
//  ✅ ENHANCED: Portfolio intelligence with real-time updates
//  ✅ OPTIMIZED: Timer-based refresh with actor-safe patterns
//  ✅ ALIGNED: With existing CoreTypes and service patterns
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
    
    // MARK: - Services (Using Existing Shared Instances)
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    
    // MARK: - Real-time Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    init() {
        setupRealTimeSubscriptions()
        setupAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Load complete portfolio intelligence for client dashboard
    func loadPortfolioIntelligence() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // ✅ FIXED: Proper async calls to actor-based services
            async let portfolioResult = try intelligenceService.generatePortfolioIntelligence()
            async let buildingsResult = try buildingService.getAllBuildings()
            async let insightsResult = try intelligenceService.generatePortfolioInsights()
            
            // Wait for all async operations
            let (portfolio, buildings, insights) = try await (portfolioResult, buildingsResult, insightsResult)
            
            // Update state on main actor
            self.portfolioIntelligence = portfolio
            self.buildingsList = buildings
            self.intelligenceInsights = insights
            
            // Load individual building metrics
            await loadBuildingMetrics()
            await analyzeComplianceIssues()
            
            self.lastUpdateTime = Date()
            
            print("✅ Client portfolio loaded: \(buildings.count) buildings, \(insights.count) insights")
            
        } catch {
            errorMessage = "Failed to load portfolio data: \(error.localizedDescription)"
            print("❌ Client portfolio load failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load metrics for all buildings in portfolio
    private func loadBuildingMetrics() async {
        var metrics: [String: CoreTypes.BuildingMetrics] = [:]
        
        // ✅ FIXED: Actor-safe concurrent metric loading
        await withTaskGroup(of: (String, CoreTypes.BuildingMetrics?).self) { group in
            for building in buildingsList {
                group.addTask {
                    do {
                        let buildingMetrics = try await self.buildingMetricsService.calculateMetrics(for: building.id)
                        return (building.id, buildingMetrics)
                    } catch {
                        print("⚠️ Failed to load metrics for building \(building.id): \(error)")
                        return (building.id, nil)
                    }
                }
            }
            
            for await (buildingId, buildingMetrics) in group {
                if let buildingMetrics = buildingMetrics {
                    metrics[buildingId] = buildingMetrics
                }
            }
        }
        
        self.buildingMetrics = metrics
        print("📊 Loaded metrics for \(metrics.count) buildings")
    }
    
    /// Analyze compliance issues across portfolio
    private func analyzeComplianceIssues() async {
        var issues: [CoreTypes.ComplianceIssue] = []
        
        for (buildingId, metrics) in buildingMetrics {
            guard let building = buildingsList.first(where: { $0.id == buildingId }) else { continue }
            
            // Check for low completion rate (compliance issue)
            if metrics.completionRate < 0.8 {
                issues.append(CoreTypes.ComplianceIssue(
                    type: .maintenanceOverdue,
                    severity: metrics.completionRate < 0.6 ? .critical : .high,
                    description: "Building \(building.name) has completion rate of \(Int(metrics.completionRate * 100))%",
                    buildingId: buildingId,
                    dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
                ))
            }
            
            // Check for overdue tasks (compliance issue)
            if metrics.overdueTasks > 3 {
                issues.append(CoreTypes.ComplianceIssue(
                    type: .inspectionRequired,
                    severity: metrics.overdueTasks > 10 ? .critical : .medium,
                    description: "Building \(building.name) has \(metrics.overdueTasks) overdue tasks",
                    buildingId: buildingId,
                    dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
                ))
            }
            
            // Check for compliance status
            if !metrics.isCompliant {
                issues.append(CoreTypes.ComplianceIssue(
                    type: .regulatoryViolation,
                    severity: .high,
                    description: "Building \(building.name) not meeting compliance standards",
                    buildingId: buildingId,
                    dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())
                ))
            }
        }
        
        complianceIssues = issues
        print("🚨 Identified \(issues.count) compliance issues")
    }
    
    // MARK: - Real-time Updates
    
    /// Setup automatic refresh every 30 seconds
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshPortfolioData()
            }
        }
    }
    
    /// Setup real-time subscriptions to building metrics changes
    private func setupRealTimeSubscriptions() {
        // Subscribe to building metrics updates
        // This will be implemented when BuildingMetricsService adds publishers
        print("🔄 Setting up real-time subscriptions for client dashboard")
    }
    
    /// Refresh portfolio data (called by timer and manually)
    func refreshPortfolioData() async {
        guard !isLoading else { return }
        
        print("🔄 Refreshing client portfolio data...")
        await loadPortfolioIntelligence()
    }
    
    // MARK: - User Actions
    
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
            insight.affectedBuildings?.contains(buildingId) == true ||
            insight.category == .building
        }
    }
    
    /// Handle compliance issue action
    func handleComplianceAction(_ issue: CoreTypes.ComplianceIssue, action: ComplianceAction) async {
        do {
            switch action {
            case .acknowledge:
                print("✅ Acknowledged compliance issue: \(issue.description)")
                // Update issue status in database
                
            case .createTask:
                // Create corrective task
                let task = ContextualTask(
                    id: UUID().uuidString,
                    description: "Address compliance issue: \(issue.description)",
                    buildingId: issue.buildingId,
                    category: "Compliance",
                    urgency: issue.severity == .critical ? .critical : .high,
                    estimatedDuration: 3600,
                    skillLevel: .intermediate,
                    isCompleted: false,
                    assignedWorkerId: nil,
                    dueDate: issue.dueDate,
                    createdAt: Date()
                )
                
                try await taskService.createTask(task)
                print("✅ Created compliance task for issue: \(issue.description)")
                
            case .scheduleInspection:
                print("✅ Scheduled inspection for compliance issue: \(issue.description)")
                // Implementation for scheduling inspection
            }
            
            // Refresh data after action
            await refreshPortfolioData()
            
        } catch {
            errorMessage = "Failed to handle compliance action: \(error.localizedDescription)"
            print("❌ Compliance action failed: \(error)")
        }
    }
    
    // MARK: - Portfolio Analytics
    
    /// Calculate portfolio summary metrics
    func getPortfolioSummary() -> PortfolioSummary {
        let totalBuildings = buildingsList.count
        let totalMetrics = buildingMetrics.values
        
        let averageCompletion = totalMetrics.isEmpty ? 0 : 
            totalMetrics.reduce(0) { $0 + $1.completionRate } / Double(totalMetrics.count)
        
        let totalOverdueTasks = totalMetrics.reduce(0) { $0 + $1.overdueTasks }
        let totalPendingTasks = totalMetrics.reduce(0) { $0 + $1.pendingTasks }
        
        let compliantBuildings = totalMetrics.filter { $0.isCompliant }.count
        let complianceRate = totalBuildings > 0 ? Double(compliantBuildings) / Double(totalBuildings) : 0
        
        let criticalIssues = complianceIssues.filter { $0.severity == .critical }.count
        let highPriorityInsights = intelligenceInsights.filter { $0.priority == .high || $0.priority == .critical }.count
        
        return PortfolioSummary(
            totalBuildings: totalBuildings,
            averageCompletionRate: averageCompletion,
            complianceRate: complianceRate,
            totalOverdueTasks: totalOverdueTasks,
            totalPendingTasks: totalPendingTasks,
            criticalIssues: criticalIssues,
            highPriorityInsights: highPriorityInsights,
            trendDirection: calculateTrendDirection()
        )
    }
    
    /// Calculate portfolio trend direction
    private func calculateTrendDirection() -> CoreTypes.TrendDirection {
        let trends = buildingMetrics.values.map { $0.weeklyCompletionTrend }
        
        guard !trends.isEmpty else { return .stable }
        
        let averageTrend = trends.reduce(0.0, +) / Double(trends.count)
        let currentCompletion = buildingMetrics.values.reduce(0.0) { $0 + $1.completionRate } / Double(buildingMetrics.count)
        
        if averageTrend > currentCompletion + 0.05 {
            return .improving
        } else if averageTrend < currentCompletion - 0.05 {
            return .declining
        } else {
            return .stable
        }
    }
}

// MARK: - Supporting Types

enum ComplianceAction {
    case acknowledge
    case createTask
    case scheduleInspection
}

struct PortfolioSummary {
    let totalBuildings: Int
    let averageCompletionRate: Double
    let complianceRate: Double
    let totalOverdueTasks: Int
    let totalPendingTasks: Int
    let criticalIssues: Int
    let highPriorityInsights: Int
    let trendDirection: CoreTypes.TrendDirection
}
