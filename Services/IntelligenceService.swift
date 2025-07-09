//
//  IntelligenceService.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/9/25.
//


//
//  IntelligenceService.swift
//  FrancoSphere
//
//  Intelligence service that generates insights from real data
//  Integrates with OperationalDataManager, BuildingService, TaskService
//

import Foundation

actor IntelligenceService {
    static let shared = IntelligenceService()
    
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let operationalManager = OperationalDataManager.shared
    
    private init() {}
    
    // MARK: - Main Intelligence Generation
    
    /// Generate portfolio-wide intelligence insights from real data
    func generatePortfolioInsights() async throws -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
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
        
        guard let building = try await buildingService.getBuilding(buildingId) else {
            return insights
        }
        
        let tasks = try await taskService.getTasksForBuilding(buildingId, date: Date())
        let buildingAnalytics = try await buildingService.getBuildingAnalytics(buildingId)
        
        // Building-specific insights
        if buildingAnalytics.completionRate < 0.7 {
            insights.append(IntelligenceInsight(
                title: "Low Task Completion Rate",
                description: "\(building.name) has a completion rate of \(Int(buildingAnalytics.completionRate * 100))%, below the 70% threshold",
                type: .performance,
                priority: .high,
                actionable: true
            ))
        }
        
        if buildingAnalytics.overdueTasks > 5 {
            insights.append(IntelligenceInsight(
                title: "High Overdue Task Count",
                description: "\(buildingAnalytics.overdueTasks) tasks are overdue at \(building.name)",
                type: .maintenance,
                priority: .high,
                actionable: true
            ))
        }
        
        return insights
    }
    
    // MARK: - Performance Insights
    
    private func generatePerformanceInsights(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Calculate portfolio completion rate
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let totalTasks = tasks.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        
        if completionRate > 0.9 {
            insights.append(IntelligenceInsight(
                title: "Excellent Portfolio Performance",
                description: "Portfolio completion rate is \(Int(completionRate * 100))% - exceeding performance targets",
                type: .performance,
                priority: .low,
                actionable: false
            ))
        } else if completionRate < 0.7 {
            insights.append(IntelligenceInsight(
                title: "Performance Improvement Needed",
                description: "Portfolio completion rate is \(Int(completionRate * 100))% - below target threshold",
                type: .performance,
                priority: .high,
                actionable: true
            ))
        }
        
        // High performing buildings
        let highPerformingCount = await getHighPerformingBuildingsCount(buildings)
        if highPerformingCount > buildings.count / 2 {
            insights.append(IntelligenceInsight(
                title: "Strong Building Performance",
                description: "\(highPerformingCount) out of \(buildings.count) buildings performing above 85% efficiency",
                type: .performance,
                priority: .medium,
                actionable: false
            ))
        }
        
        return insights
    }
    
    // MARK: - Maintenance Insights
    
    private func generateMaintenanceInsights(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Find overdue maintenance tasks
        let overdueTasks = tasks.filter { task in
            !task.isCompleted && 
            (task.category == .maintenance || task.category == .repair) &&
            (task.dueDate ?? Date.distantFuture) < Date()
        }
        
        if overdueTasks.count > 3 {
            insights.append(IntelligenceInsight(
                title: "Maintenance Backlog Alert",
                description: "\(overdueTasks.count) maintenance tasks are overdue across portfolio",
                type: .maintenance,
                priority: .high,
                actionable: true
            ))
        }
        
        // Preventive maintenance opportunities
        let maintenanceTasks = tasks.filter { 
            $0.category == .maintenance || $0.category == .preventiveMaintenance 
        }
        let completedMaintenanceRate = maintenanceTasks.isEmpty ? 0.0 :
            Double(maintenanceTasks.filter { $0.isCompleted }.count) / Double(maintenanceTasks.count)
        
        if completedMaintenanceRate > 0.95 {
            insights.append(IntelligenceInsight(
                title: "Preventive Maintenance Excellence",
                description: "Portfolio maintenance completion rate is \(Int(completedMaintenanceRate * 100))%",
                type: .maintenance,
                priority: .low,
                actionable: false
            ))
        }
        
        return insights
    }
    
    // MARK: - Efficiency Insights
    
    private func generateEfficiencyInsights(buildings: [NamedCoordinate], tasks: [ContextualTask], workers: [WorkerProfile]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Worker utilization analysis
        let averageTasksPerWorker = workers.isEmpty ? 0.0 : Double(tasks.count) / Double(workers.count)
        
        if averageTasksPerWorker > 8 {
            insights.append(IntelligenceInsight(
                title: "High Worker Utilization",
                description: "Average of \(String(format: "%.1f", averageTasksPerWorker)) tasks per worker - consider capacity planning",
                type: .efficiency,
                priority: .medium,
                actionable: true
            ))
        }
        
        // Task distribution efficiency
        let buildingTaskCounts = Dictionary(grouping: tasks, by: { $0.buildingId })
            .mapValues { $0.count }
        
        let maxTasks = buildingTaskCounts.values.max() ?? 0
        let minTasks = buildingTaskCounts.values.min() ?? 0
        
        if maxTasks > 0 && (Double(maxTasks - minTasks) / Double(maxTasks)) > 0.5 {
            insights.append(IntelligenceInsight(
                title: "Uneven Task Distribution",
                description: "Task allocation varies significantly across buildings - optimization opportunity",
                type: .efficiency,
                priority: .medium,
                actionable: true
            ))
        }
        
        return insights
    }
    
    // MARK: - Compliance Insights
    
    private func generateComplianceInsights(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Safety and compliance task completion
        let complianceTasks = tasks.filter { 
            $0.category == .safety || $0.category == .inspection || $0.category == .compliance 
        }
        
        let overdueTasks = complianceTasks.filter { task in
            !task.isCompleted && (task.dueDate ?? Date.distantFuture) < Date()
        }
        
        if !overdueTasks.isEmpty {
            insights.append(IntelligenceInsight(
                title: "Compliance Tasks Overdue",
                description: "\(overdueTasks.count) compliance-related tasks require immediate attention",
                type: .compliance,
                priority: .high,
                actionable: true
            ))
        }
        
        // Calculate compliance score
        let complianceRate = complianceTasks.isEmpty ? 1.0 :
            Double(complianceTasks.filter { $0.isCompleted }.count) / Double(complianceTasks.count)
        
        if complianceRate >= 0.95 {
            insights.append(IntelligenceInsight(
                title: "Excellent Compliance Status",
                description: "Portfolio maintains \(Int(complianceRate * 100))% compliance rate",
                type: .compliance,
                priority: .low,
                actionable: false
            ))
        }
        
        return insights
    }
    
    // MARK: - Cost Insights
    
    private func generateCostInsights(buildings: [NamedCoordinate], workers: [WorkerProfile], tasks: [ContextualTask]) async -> [IntelligenceInsight] {
        var insights: [IntelligenceInsight] = []
        
        // Worker efficiency analysis
        let averageBuildingsPerWorker = workers.isEmpty ? 0.0 : Double(buildings.count) / Double(workers.count)
        
        if averageBuildingsPerWorker < 1.5 {
            insights.append(IntelligenceInsight(
                title: "Worker Optimization Opportunity",
                description: "Current ratio suggests potential for worker assignment optimization",
                type: .cost,
                priority: .medium,
                actionable: true
            ))
        }
        
        // Task efficiency trends
        let longRunningTasks = tasks.filter { task in
            task.estimatedDuration > 4 * 3600 // More than 4 hours
        }
        
        if longRunningTasks.count > tasks.count / 4 {
            insights.append(IntelligenceInsight(
                title: "Task Duration Optimization",
                description: "\(longRunningTasks.count) tasks exceed 4-hour duration - efficiency review recommended",
                type: .cost,
                priority: .medium,
                actionable: true
            ))
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    
    private func getHighPerformingBuildingsCount(_ buildings: [NamedCoordinate]) async -> Int {
        var count = 0
        
        for building in buildings {
            do {
                let analytics = try await buildingService.getBuildingAnalytics(building.id)
                if analytics.completionRate > 0.85 {
                    count += 1
                }
            } catch {
                // Skip building if analytics unavailable
                continue
            }
        }
        
        return count
    }
}

// MARK: - Extensions

extension IntelligenceInsight {
    var createdAt: Date { timestamp }
}

extension InsightPriority {
    var priorityValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

// MARK: - Task Category Extensions

extension TaskCategory {
    static let compliance = TaskCategory(rawValue: "Compliance") ?? .maintenance
    static let safety = TaskCategory(rawValue: "Safety") ?? .maintenance
    static let preventiveMaintenance = TaskCategory(rawValue: "Preventive Maintenance") ?? .maintenance
}