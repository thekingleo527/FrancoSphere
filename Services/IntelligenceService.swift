//
//  IntelligenceService.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Actor isolation and service singleton patterns
//  ✅ ENHANCED: Proper nonisolated shared access pattern
//  ✅ INTEGRATED: With real data from existing services
//

import Foundation

actor IntelligenceService {
    // ✅ FIXED: nonisolated shared for cross-actor access
    nonisolated static let shared = IntelligenceService()
    
    // ✅ FIXED: Private init for singleton
    private init() {}
    
    // MARK: - Main Intelligence Generation
    
    /// Generate portfolio-wide intelligence insights from real data
    func generatePortfolioInsights() async throws -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // ✅ FIXED: Use shared instances for proper singleton pattern
        let buildingService = BuildingService.shared
        let taskService = TaskService.shared
        let workerService = WorkerService.shared
        
        // Get real data from services
        let buildings = try await buildingService.getAllBuildings()
        let allTasks = try await taskService.getAllTasks()
        let activeWorkers = try await workerService.getAllActiveWorkers()
        
        // Generate insights from real data
        insights.append(contentsOf: await generatePerformanceInsights(buildings: buildings, tasks: allTasks))
        insights.append(contentsOf: await generateMaintenanceInsights(buildings: buildings, tasks: allTasks))
        insights.append(contentsOf: await generateEfficiencyInsights(buildings: buildings, tasks: allTasks, workers: activeWorkers))
        insights.append(contentsOf: await generateComplianceInsights(buildings: buildings, tasks: allTasks))
        insights.append(contentsOf: await generateCostInsights(buildings: buildings, workers: activeWorkers, tasks: allTasks))
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    /// Generate insights for a specific building
    func generateBuildingInsights(for buildingId: String) async throws -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // ✅ FIXED: Use shared instances
        let buildingService = BuildingService.shared
        let taskService = TaskService.shared
        
        guard let building = try await buildingService.getBuilding(buildingId) else {
            throw IntelligenceError.buildingNotFound(buildingId)
        }
        
        let buildingTasks = try await taskService.getTasks(for: buildingId)
        let analytics = try await buildingService.getBuildingAnalytics(buildingId)
        
        // Generate building-specific insights
        if analytics.completionRate < 0.7 {
            insights.append(createLowCompletionInsight(building: building, analytics: analytics))
        }
        
        if analytics.overdueTasks > 5 {
            insights.append(createOverdueTasksInsight(building: building, count: analytics.overdueTasks))
        }
        
        return insights
    }
    
    // MARK: - Portfolio Intelligence Generation
    
    func generatePortfolioIntelligence() async throws -> CoreTypes.PortfolioIntelligence {
        // ✅ FIXED: Use shared instances
        let buildingService = BuildingService.shared
        let taskService = TaskService.shared
        let buildingMetricsService = BuildingMetricsService.shared
        
        let buildings = try await buildingService.getAllBuildings()
        
        // Calculate portfolio metrics
        var totalCompletionRate: Double = 0
        var totalPendingTasks = 0
        var totalOverdueTasks = 0
        var complianceIssues: [CoreTypes.ComplianceIssue] = []
        
        for building in buildings {
            let metrics = try await buildingMetricsService.calculateMetrics(for: building.id)
            totalCompletionRate += metrics.completionRate
            totalPendingTasks += metrics.pendingTasks
            totalOverdueTasks += metrics.overdueTasks
            
            // Check for compliance issues
            if !metrics.isCompliant {
                complianceIssues.append(CoreTypes.ComplianceIssue(
                    type: .maintenanceOverdue,
                    severity: .medium,
                    description: "Building \(building.name) not compliant",
                    buildingId: building.id,
                    dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
                ))
            }
        }
        
        let averageCompletionRate = buildings.isEmpty ? 0 : totalCompletionRate / Double(buildings.count)
        
        return CoreTypes.PortfolioIntelligence(
            totalBuildings: buildings.count,
            averageCompletionRate: averageCompletionRate,
            totalPendingTasks: totalPendingTasks,
            totalOverdueTasks: totalOverdueTasks,
            complianceIssues: complianceIssues,
            trendDirection: await calculateTrendDirection(buildings: buildings),
            lastUpdated: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func generatePerformanceInsights(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Calculate overall performance metrics
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let totalTasks = tasks.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
        
        if completionRate < 0.8 {
            insights.append(IntelligenceInsight(
                title: "Portfolio Performance Below Target",
                description: "Overall task completion rate is \(Int(completionRate * 100))%, below 80% target",
                type: .performance,
                priority: .high,
                category: .portfolio,
                dataSource: "TaskService",
                confidence: 0.9,
                impact: InsightImpact(
                    severity: .significant,
                    scope: .portfolio,
                    financialImpact: 5000.0,
                    timeImpact: 3600,
                    qualityImpact: 0.15,
                    riskLevel: 0.6
                ),
                recommendations: [
                    "Review task assignment distribution",
                    "Identify bottlenecks in workflow",
                    "Consider additional resource allocation"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateMaintenanceInsights(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        let maintenanceTasks = tasks.filter { $0.category == "Maintenance" }
        let overdueMaintenance = maintenanceTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency.priorityValue > 3 // High priority maintenance
        }
        
        if overdueMaintenance.count > 3 {
            insights.append(IntelligenceInsight(
                title: "Critical Maintenance Backlog",
                description: "\(overdueMaintenance.count) high-priority maintenance tasks overdue",
                type: .maintenance,
                priority: .critical,
                category: .portfolio,
                dataSource: "TaskService",
                confidence: 1.0,
                impact: InsightImpact(
                    severity: .major,
                    scope: .portfolio,
                    financialImpact: Double(overdueMaintenance.count) * 500.0,
                    timeImpact: TimeInterval(overdueMaintenance.count * 1800),
                    qualityImpact: 0.25,
                    riskLevel: 0.8
                ),
                recommendations: [
                    "Prioritize critical maintenance tasks",
                    "Allocate emergency maintenance budget",
                    "Review preventive maintenance schedule"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateEfficiencyInsights(buildings: [NamedCoordinate], tasks: [ContextualTask], workers: [WorkerProfile]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Calculate worker efficiency
        let activeWorkerCount = workers.filter { $0.role == .worker }.count
        let tasksPerWorker = activeWorkerCount > 0 ? Double(tasks.count) / Double(activeWorkerCount) : 0
        
        if tasksPerWorker > 15 {
            insights.append(IntelligenceInsight(
                title: "High Worker Task Load",
                description: "Average \(Int(tasksPerWorker)) tasks per worker, above recommended 12-task limit",
                type: .efficiency,
                priority: .medium,
                category: .workforce,
                dataSource: "WorkerService",
                confidence: 0.8,
                impact: InsightImpact(
                    severity: .moderate,
                    scope: .workforce,
                    financialImpact: 3000.0,
                    timeImpact: 7200,
                    qualityImpact: 0.1,
                    riskLevel: 0.4
                ),
                recommendations: [
                    "Consider hiring additional workers",
                    "Optimize task scheduling",
                    "Review task complexity distribution"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateComplianceInsights(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Check for compliance-related tasks
        let complianceTasks = tasks.filter { task in
            task.description.lowercased().contains("compliance") ||
            task.description.lowercased().contains("inspection") ||
            task.description.lowercased().contains("regulation")
        }
        
        let overdueCompliance = complianceTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency.priorityValue > 2
        }
        
        if !overdueCompliance.isEmpty {
            insights.append(IntelligenceInsight(
                title: "Compliance Tasks Require Attention",
                description: "\(overdueCompliance.count) compliance-related tasks need immediate attention",
                type: .compliance,
                priority: .high,
                category: .compliance,
                dataSource: "TaskService",
                confidence: 0.95,
                impact: InsightImpact(
                    severity: .significant,
                    scope: .compliance,
                    financialImpact: Double(overdueCompliance.count) * 1000.0,
                    timeImpact: TimeInterval(overdueCompliance.count * 3600),
                    qualityImpact: 0.2,
                    riskLevel: 0.7
                ),
                recommendations: [
                    "Prioritize compliance tasks immediately",
                    "Schedule compliance review meetings",
                    "Update compliance tracking procedures"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateCostInsights(buildings: [NamedCoordinate], workers: [WorkerProfile], tasks: [ContextualTask]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Estimate emergency vs planned task costs
        let emergencyTasks = tasks.filter { task in
            task.description.lowercased().contains("emergency") ||
            task.description.lowercased().contains("urgent")
        }
        
        if emergencyTasks.count > 5 {
            let estimatedExtraCost = Double(emergencyTasks.count) * 200.0 // Emergency premium
            
            insights.append(IntelligenceInsight(
                title: "High Emergency Task Costs",
                description: "\(emergencyTasks.count) emergency tasks generating estimated $\(Int(estimatedExtraCost)) in premium costs",
                type: .cost,
                priority: .medium,
                category: .portfolio,
                dataSource: "TaskService",
                confidence: 0.8,
                impact: InsightImpact(
                    severity: .moderate,
                    scope: .portfolio,
                    financialImpact: estimatedExtraCost,
                    timeImpact: 3600,
                    qualityImpact: 0.05,
                    riskLevel: 0.5
                ),
                recommendations: [
                    "Review preventive maintenance schedules",
                    "Identify root causes of emergencies",
                    "Consider proactive maintenance investments"
                ]
            ))
        }
        
        return insights
    }
    
    private func calculateTrendDirection(buildings: [NamedCoordinate]) async -> CoreTypes.TrendDirection {
        // Simple trend calculation - in a full implementation, this would analyze historical data
        let buildingMetricsService = BuildingMetricsService.shared
        
        var totalTrend: Double = 0
        var trendCount = 0
        
        for building in buildings {
            do {
                let metrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                totalTrend += metrics.weeklyCompletionTrend
                trendCount += 1
            } catch {
                // Skip buildings with metric errors
                continue
            }
        }
        
        guard trendCount > 0 else { return .stable }
        
        let averageTrend = totalTrend / Double(trendCount)
        
        if averageTrend > 0.05 {
            return .improving
        } else if averageTrend < -0.05 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func createLowCompletionInsight(building: NamedCoordinate, analytics: BuildingAnalytics) -> IntelligenceInsight {
        return IntelligenceInsight(
            title: "Low Task Completion Rate",
            description: "Building \(building.name) has completion rate of \(Int(analytics.completionRate * 100))%",
            type: .performance,
            priority: .high,
            category: .building,
            dataSource: "BuildingService",
            confidence: 0.9,
            impact: InsightImpact(
                severity: .significant,
                scope: .single,
                financialImpact: 2500.0,
                timeImpact: 1800,
                qualityImpact: 0.2,
                riskLevel: 0.6
            ),
            recommendations: [
                "Review worker assignments for this building",
                "Check for resource constraints",
                "Analyze task complexity"
            ],
            affectedBuildings: [building.id]
        )
    }
    
    private func createOverdueTasksInsight(building: NamedCoordinate, count: Int) -> IntelligenceInsight {
        return IntelligenceInsight(
            title: "Multiple Overdue Tasks",
            description: "Building \(building.name) has \(count) overdue tasks requiring attention",
            type: .maintenance,
            priority: count > 10 ? .critical : .high,
            category: .building,
            dataSource: "TaskService",
            confidence: 1.0,
            impact: InsightImpact(
                severity: count > 10 ? .major : .significant,
                scope: .single,
                financialImpact: Double(count) * 100.0,
                timeImpact: TimeInterval(count * 300),
                qualityImpact: 0.15,
                riskLevel: 0.7
            ),
            recommendations: [
                "Prioritize overdue tasks",
                "Reassign workers if needed",
                "Review task scheduling"
            ],
            affectedBuildings: [building.id]
        )
    }
}

// MARK: - Supporting Types

enum IntelligenceError: Error, LocalizedError {
    case buildingNotFound(String)
    case dataUnavailable
    case analysisFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .buildingNotFound(let id):
            return "Building with ID \(id) not found"
        case .dataUnavailable:
            return "Required data not available for analysis"
        case .analysisFailure(let reason):
            return "Intelligence analysis failed: \(reason)"
        }
    }
}
