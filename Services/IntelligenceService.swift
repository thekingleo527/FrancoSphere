//
//  IntelligenceService.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Swift 6 actor isolation issues resolved
//  ✅ ENHANCED: Proper nonisolated shared access pattern
//  ✅ INTEGRATED: With real data from existing services
//

import Foundation

actor IntelligenceService {
    // ✅ FIXED: nonisolated shared for cross-actor access
    nonisolated static let shared = IntelligenceService()
    
    // ✅ FIXED: Remove shared references from within actor
    private init() {}
    
    // MARK: - Main Intelligence Generation
    
    /// Generate portfolio-wide intelligence insights from real data
    func generatePortfolioInsights() async throws -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // ✅ FIXED: Create service instances without .shared
        let buildingService = BuildingService()
        let taskService = TaskService()
        let workerService = WorkerService()
        
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
        
        let buildingService = BuildingService()
        let taskService = TaskService()
        
        guard let building = try await buildingService.getBuilding(buildingId) else {
            return insights
        }
        
        let tasks = try await taskService.getTasksForBuilding(buildingId, date: Date())
        let buildingAnalytics = try await buildingService.getBuildingAnalytics(buildingId)
        
        // Building-specific insights
        if buildingAnalytics.completionRate < 0.7 {
            insights.append(createLowCompletionInsight(building: building, analytics: buildingAnalytics))
        }
        
        if buildingAnalytics.overdueTasks > 5 {
            insights.append(createOverdueTasksInsight(building: building, count: buildingAnalytics.overdueTasks))
        }
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    // MARK: - Insight Generation Methods
    
    private func generatePerformanceInsights(
        buildings: [NamedCoordinate],
        tasks: [ContextualTask]
    ) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        
        if completionRate < 0.8 {
            insights.append(IntelligenceInsight(
                title: "Portfolio Performance Below Target",
                description: "Overall task completion rate is \(Int(completionRate * 100))%, below the 80% target.",
                type: .performance,
                priority: completionRate < 0.6 ? .critical : .high,
                category: .portfolio,
                dataSource: "TaskService",
                confidence: 0.95,
                impact: InsightImpact(
                    severity: .significant,
                    scope: .portfolio,
                    financialImpact: 5000.0,
                    timeImpact: 3600,
                    qualityImpact: 0.15,
                    riskLevel: 0.7
                ),
                recommendations: [
                    "Review task assignment efficiency",
                    "Identify training needs for workers",
                    "Optimize task scheduling"
                ],
                affectedBuildings: buildings.map { $0.id }
            ))
        }
        
        return insights
    }
    
    private func generateMaintenanceInsights(
        buildings: [NamedCoordinate],
        tasks: [ContextualTask]
    ) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        let maintenanceTasks = tasks.filter { $0.category == .maintenance }
        let overdueMaintenance = maintenanceTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }
        
        if overdueMaintenance.count > 10 {
            insights.append(IntelligenceInsight(
                title: "High Volume of Overdue Maintenance",
                description: "\(overdueMaintenance.count) maintenance tasks are overdue across the portfolio.",
                type: .maintenance,
                priority: .high,
                category: .portfolio,
                dataSource: "TaskService",
                confidence: 0.98,
                impact: InsightImpact(
                    severity: .major,
                    scope: .portfolio,
                    financialImpact: 15000.0,
                    timeImpact: 7200,
                    qualityImpact: 0.25,
                    riskLevel: 0.8
                ),
                recommendations: [
                    "Prioritize critical maintenance tasks",
                    "Increase maintenance crew capacity",
                    "Review preventive maintenance schedules"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateEfficiencyInsights(
        buildings: [NamedCoordinate],
        tasks: [ContextualTask],
        workers: [WorkerProfile]
    ) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        let avgTasksPerWorker = workers.count > 0 ? Double(tasks.count) / Double(workers.count) : 0.0
        
        if avgTasksPerWorker > 15 {
            insights.append(IntelligenceInsight(
                title: "Worker Overload Detected",
                description: "Average of \(Int(avgTasksPerWorker)) tasks per worker exceeds recommended capacity.",
                type: .efficiency,
                priority: .medium,
                category: .system,
                dataSource: "WorkerService",
                confidence: 0.85,
                impact: InsightImpact(
                    severity: .moderate,
                    scope: .portfolio,
                    financialImpact: 8000.0,
                    timeImpact: 1800,
                    qualityImpact: 0.1,
                    riskLevel: 0.6
                ),
                recommendations: [
                    "Consider hiring additional workers",
                    "Optimize task distribution",
                    "Review task complexity and duration"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateComplianceInsights(
        buildings: [NamedCoordinate],
        tasks: [ContextualTask]
    ) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        let inspectionTasks = tasks.filter { $0.category == .inspection }
        let overdueInspections = inspectionTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }
        
        if overdueInspections.count > 0 {
            insights.append(IntelligenceInsight(
                title: "Compliance Risk: Overdue Inspections",
                description: "\(overdueInspections.count) safety/compliance inspections are overdue.",
                type: .compliance,
                priority: .critical,
                category: .portfolio,
                dataSource: "TaskService",
                confidence: 1.0,
                impact: InsightImpact(
                    severity: .critical,
                    scope: .portfolio,
                    financialImpact: 25000.0,
                    timeImpact: 0,
                    qualityImpact: 0.5,
                    riskLevel: 0.9
                ),
                recommendations: [
                    "Complete overdue inspections immediately",
                    "Review inspection scheduling",
                    "Implement compliance alerts"
                ],
                affectedBuildings: overdueInspections.map { $0.buildingId }
            ))
        }
        
        return insights
    }
    
    private func generateCostInsights(
        buildings: [NamedCoordinate],
        workers: [WorkerProfile],
        tasks: [ContextualTask]
    ) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Simple cost analysis based on task volume
        let emergencyTasks = tasks.filter { $0.urgency == .emergency || $0.urgency == .critical }
        
        if emergencyTasks.count > 5 {
            let estimatedExtraCost = Double(emergencyTasks.count) * 500.0 // Emergency premium
            
            insights.append(IntelligenceInsight(
                title: "High Emergency Task Volume",
                description: "\(emergencyTasks.count) emergency tasks detected, indicating potential cost overruns.",
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
    
    // MARK: - Helper Methods
    
    private func createLowCompletionInsight(
        building: NamedCoordinate,
        analytics: BuildingAnalytics
    ) -> IntelligenceInsight {
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
    
    private func createOverdueTasksInsight(
        building: NamedCoordinate,
        count: Int
    ) -> IntelligenceInsight {
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
