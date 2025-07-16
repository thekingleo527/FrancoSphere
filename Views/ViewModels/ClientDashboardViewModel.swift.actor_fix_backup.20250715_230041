//
//  ClientDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ V6.0: Fixed with ACTUAL CoreTypes Structure
//  ✅ Uses BuildingMetricsService.calculateMetrics (correct method)
//  ✅ Uses correct CoreTypes.PortfolioIntelligence properties
//  ✅ Uses actionRequired (not actionable) from IntelligenceInsight
//  ✅ Fixed method name to loadPortfolioIntelligence for Template compatibility
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
    
    // MARK: - Initialization
    init() {
        setupAutoRefresh()
        setupRealTimeSubscriptions()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Main Portfolio Loading (Fixed Method Name for Template)
    
    /// Load complete portfolio intelligence - matches ClientDashboardTemplate call
    func loadPortfolioIntelligence() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all buildings from real database
            buildingsList = try await buildingService.getAllBuildings()
            print("📊 Loaded \(buildingsList.count) buildings for portfolio analysis")
            
            // Calculate metrics for each building using BuildingMetricsService
            await loadBuildingMetrics()
            
            // Generate portfolio intelligence from real data
            await generatePortfolioIntelligence()
            
            // Load compliance issues and insights concurrently
            async let complianceTask = loadComplianceData()
            async let insightsTask = loadIntelligenceInsights()
            
            await complianceTask
            await insightsTask
            
            lastUpdateTime = Date()
            print("✅ Portfolio intelligence loaded successfully")
            
        } catch {
            errorMessage = "Failed to load portfolio intelligence: \(error.localizedDescription)"
            print("❌ Portfolio loading error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Data Loading Methods
    
    /// Load building metrics using BuildingMetricsService.calculateMetrics (correct method)
    private func loadBuildingMetrics() async {
        var metrics: [String: CoreTypes.BuildingMetrics] = [:]
        
        // Use concurrent loading for better performance
        await withTaskGroup(of: (String, CoreTypes.BuildingMetrics?).self) { group in
            for building in buildingsList {
                group.addTask {
                    do {
                        // Use the correct BuildingMetricsService method
                        let buildingMetric = try await self.buildingMetricsService.calculateMetrics(for: building.id)
                        return (building.id, buildingMetric)
                    } catch {
                        print("⚠️ Failed to load metrics for building \(building.id): \(error)")
                        return (building.id, nil)
                    }
                }
            }
            
            for await (buildingId, result) in group {
                if let metric = result {
                    metrics[buildingId] = metric
                }
            }
        }
        
        buildingMetrics = metrics
        print("📈 Loaded metrics for \(metrics.count) buildings")
    }
    
    /// Generate portfolio intelligence using correct CoreTypes.PortfolioIntelligence structure
    private func generatePortfolioIntelligence() async {
        let totalBuildings = buildingsList.count
        let activeWorkers = buildingMetrics.values.reduce(0) { $0 + $1.activeWorkers }
        
        // Calculate overall completion rate from building metrics
        let totalCompletionRate = buildingMetrics.values.reduce(0.0) { $0 + $1.completionRate }
        let overallCompletionRate = buildingMetrics.isEmpty ? 0.0 : totalCompletionRate / Double(buildingMetrics.count)
        
        // Calculate critical issues from overdue and urgent tasks
        let criticalIssues = buildingMetrics.values.reduce(0) { sum, metric in
            sum + metric.overdueTasks + metric.urgentTasksCount
        }
        
        // Determine trend direction from recent performance
        let trendDirection = await calculatePortfolioTrend()
        
        // Use correct CoreTypes.PortfolioIntelligence initializer with actual properties
        portfolioIntelligence = CoreTypes.PortfolioIntelligence(
            totalBuildings: totalBuildings,
            activeWorkers: activeWorkers,
            completionRate: overallCompletionRate,
            criticalIssues: criticalIssues,
            monthlyTrend: trendDirection
        )
        
        print("🎯 Generated portfolio intelligence: \(totalBuildings) buildings, \(Int(overallCompletionRate * 100))% completion")
    }
    
    /// Load compliance issues from real building data using CoreTypes.ComplianceIssue
    private func loadComplianceData() async {
        var issues: [CoreTypes.ComplianceIssue] = []
        
        // Generate compliance issues from building metrics
        for (buildingId, metrics) in buildingMetrics {
            guard let building = buildingsList.first(where: { $0.id == buildingId }) else { continue }
            
            // Check for low completion rates (compliance issue)
            if metrics.completionRate < 0.7 {
                issues.append(CoreTypes.ComplianceIssue(
                    type: .maintenanceOverdue,
                    severity: metrics.completionRate < 0.5 ? .critical : .high,
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
        }
        
        complianceIssues = issues
        print("🚨 Identified \(issues.count) compliance issues")
    }
    
    /// Load intelligence insights using existing IntelligenceService
    private func loadIntelligenceInsights() async {
        isLoadingInsights = true
        
        do {
            intelligenceInsights = try await intelligenceService.generatePortfolioInsights()
            print("💡 Generated \(intelligenceInsights.count) intelligence insights")
        } catch {
            print("⚠️ Failed to load intelligence insights: \(error)")
            // Create empty array for fallback
            intelligenceInsights = []
        }
        
        isLoadingInsights = false
    }
    
    // MARK: - Calculation Methods
    
    /// Calculate portfolio trend direction from building metrics
    private func calculatePortfolioTrend() async -> CoreTypes.TrendDirection {
        // Use weeklyCompletionTrend from building metrics
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
        
        print("🔄 Refreshing portfolio data...")
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
    
    /// Get intelligence insights for a specific building (using actionRequired property)
    func getIntelligenceInsights(for buildingId: String) -> [CoreTypes.IntelligenceInsight] {
        return intelligenceInsights.filter { insight in
            insight.affectedBuildings.contains(buildingId)
        }
    }
    
    /// Force refresh all data
    func forceRefresh() async {
        await loadPortfolioIntelligence()
    }
}

// MARK: - Supporting Extensions

extension ClientDashboardViewModel {
    
    /// Get portfolio summary for dashboard cards using correct property names
    var portfolioSummary: (buildings: Int, efficiency: String, compliance: String, issues: Int) {
        guard let intelligence = portfolioIntelligence else {
            return (0, "0%", "0%", 0)
        }
        
        return (
            buildings: intelligence.totalBuildings,
            efficiency: "\(Int(intelligence.completionRate * 100))%",  // Correct property
            compliance: "\(buildingMetrics.values.filter { $0.isCompliant }.count)/\(buildingMetrics.count)",
            issues: intelligence.criticalIssues  // Correct property
        )
    }
    
    /// Get critical issues count
    var criticalIssuesCount: Int {
        return complianceIssues.filter { $0.severity == .critical && !$0.isResolved }.count
    }
    
    /// Get high priority insights count (using actionRequired property)
    var highPriorityInsightsCount: Int {
        return intelligenceInsights.filter { $0.priority == .high || $0.priority == .critical }.count
    }
    
    /// Get actionable insights count (using actionRequired property)
    var actionableInsightsCount: Int {
        return intelligenceInsights.filter { $0.actionRequired }.count
    }
}
