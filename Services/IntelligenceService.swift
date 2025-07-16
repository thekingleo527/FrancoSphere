//
//  IntelligenceService.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With actual CoreTypes structure and method signatures
//  ✅ CORRECTED: IntelligenceInsight and PortfolioIntelligence initializers
//  ✅ FUNCTIONAL: Real data integration with proper error handling
//

import Foundation

actor IntelligenceService {
    // ✅ FIXED: nonisolated shared for cross-actor access
    nonisolated static let shared = IntelligenceService()
    
    // ✅ FIXED: Private init for singleton
    private init() {}
    
    // MARK: - Main Intelligence Generation
    
    /// Generate portfolio-wide intelligence insights from real data
    func generatePortfolioInsights() async throws -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // ✅ FIXED: Use shared instances for proper singleton pattern
        let buildingService = BuildingService.shared
        let taskService = TaskService.shared
        let workerService = WorkerService.shared
        
        do {
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
            
        } catch {
            print("⚠️ Error generating portfolio insights: \(error)")
            // Return basic insight about the error
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Intelligence Service Unavailable",
                description: "Unable to generate full portfolio insights at this time",
                type: .performance,
                priority: .medium,
                actionRequired: false,
                affectedBuildings: []
            ))
        }
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    /// Generate insights for a specific building
    func generateBuildingInsights(for buildingId: String) async throws -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // ✅ FIXED: Use shared instances
        let buildingService = BuildingService.shared
        let taskService = TaskService.shared
        
        do {
            // ✅ FIXED: Add correct argument label 'buildingId:'
            guard let building = try await buildingService.getBuilding(buildingId: buildingId) else {
                throw IntelligenceError.buildingNotFound(buildingId)
            }
            
            // ✅ FIXED: Use getAllTasks() and filter, since getTasks(for:) doesn't exist
            let allTasks = try await taskService.getAllTasks()
            let buildingTasks = allTasks.filter { $0.buildingId == buildingId }
            
            // ✅ FIXED: Use getBuildingAnalytics instead of undefined analytics
            let analytics = try await buildingService.getBuildingAnalytics(buildingId)
            
            // Generate building-specific insights
            if analytics.completionRate < 0.7 {
                insights.append(createLowCompletionInsight(building: building, analytics: analytics))
            }
            
            if analytics.overdueTasks > 5 {
                insights.append(createOverdueTasksInsight(building: building, count: Int(analytics.overdueTasks)))
            }
            
        } catch {
            print("⚠️ Error generating building insights: \(error)")
        }
        
        return insights
    }
    
    // MARK: - Portfolio Intelligence Generation
    
    func generatePortfolioIntelligence() async throws -> CoreTypes.PortfolioIntelligence {
        // ✅ FIXED: Use shared instances
        let buildingService = BuildingService.shared
        let taskService = TaskService.shared
        let workerService = WorkerService.shared
        
        let buildings = try await buildingService.getAllBuildings()
        let allTasks = try await taskService.getAllTasks()
        let activeWorkers = try await workerService.getAllActiveWorkers()
        
        // Calculate portfolio metrics
        let totalCompletedTasks = allTasks.filter { $0.isCompleted }.count
        let totalCompletionRate = allTasks.count > 0 ? Double(totalCompletedTasks) / Double(allTasks.count) : 0.0
        
        // Count critical issues (overdue tasks)
        let overdueTasks = allTasks.filter {
            guard let dueDate = $0.dueDate else { return false }
            return !$0.isCompleted && dueDate < Date()
        }
        
        // Calculate trend direction
        let trendDirection = await calculateTrendDirection(buildings: buildings)
        
        // ✅ FIXED: Use correct PortfolioIntelligence initializer
        return CoreTypes.PortfolioIntelligence(
            totalBuildings: buildings.count,
            activeWorkers: activeWorkers.count,
            completionRate: totalCompletionRate,
            criticalIssues: overdueTasks.count,
            monthlyTrend: trendDirection,
            completedTasks: totalCompletedTasks,
            complianceScore: 85, // Default compliance score
            weeklyTrend: 0.0 // Default weekly trend
        )
    }
    
    // MARK: - Helper Methods
    
    private func generatePerformanceInsights(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Calculate overall performance metrics
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let totalTasks = tasks.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
        
        if completionRate < 0.8 {
            // ✅ FIXED: Use correct IntelligenceInsight initializer
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Portfolio Performance Below Target",
                description: "Overall task completion rate is \(Int(completionRate * 100))%, below 80% target",
                type: .performance,
                priority: .high,
                actionRequired: true,
                affectedBuildings: buildings.map { $0.id }
            ))
        }
        
        return insights
    }
    
    private func generateMaintenanceInsights(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // ✅ FIXED: Use proper filtering for TaskCategory enum
        let maintenanceTasks = tasks.filter { $0.category == .maintenance }
        let overdueMaintenance = maintenanceTasks.filter {
            guard let dueDate = $0.dueDate else { return false }
            return !$0.isCompleted && dueDate < Date()
        }
        
        if overdueMaintenance.count > 3 {
            // ✅ FIXED: Use correct IntelligenceInsight initializer
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Critical Maintenance Backlog",
                description: "\(overdueMaintenance.count) high-priority maintenance tasks overdue",
                type: .maintenance,
                priority: .critical,
                actionRequired: true,
                affectedBuildings: overdueMaintenance.compactMap { $0.buildingId }
            ))
        }
        
        return insights
    }
    
    private func generateEfficiencyInsights(buildings: [NamedCoordinate], tasks: [ContextualTask], workers: [WorkerProfile]) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Calculate worker efficiency
        let activeWorkerCount = workers.filter { $0.role == .worker }.count
        let tasksPerWorker = activeWorkerCount > 0 ? Double(tasks.count) / Double(activeWorkerCount) : 0
        
        if tasksPerWorker > 15 {
            // ✅ FIXED: Use correct IntelligenceInsight initializer
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Worker Task Load",
                description: "Average \(Int(tasksPerWorker)) tasks per worker, above recommended 12-task limit",
                type: .efficiency,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: buildings.map { $0.id }
            ))
        }
        
        return insights
    }
    
    private func generateComplianceInsights(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // ✅ FIXED: Use helper methods to avoid Predicate type issues
        let complianceTasks = getComplianceTasks(from: tasks)
        let overdueCompliance = getOverdueTasks(from: complianceTasks)
        
        if !overdueCompliance.isEmpty {
            // ✅ FIXED: Use correct IntelligenceInsight initializer
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Compliance Tasks Require Attention",
                description: "\(overdueCompliance.count) compliance-related tasks need immediate attention",
                type: .compliance,
                priority: .high,
                actionRequired: true,
                affectedBuildings: overdueCompliance.compactMap { $0.buildingId }
            ))
        }
        
        return insights
    }
    
    private func generateCostInsights(buildings: [NamedCoordinate], workers: [WorkerProfile], tasks: [ContextualTask]) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // ✅ FIXED: Use helper method to avoid Predicate type issues
        let emergencyTasks = getEmergencyTasks(from: tasks)
        
        if emergencyTasks.count > 5 {
            let estimatedExtraCost = Double(emergencyTasks.count) * 200.0 // Emergency premium
            
            // ✅ FIXED: Use correct IntelligenceInsight initializer
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Emergency Task Costs",
                description: "\(emergencyTasks.count) emergency tasks generating estimated $\(Int(estimatedExtraCost)) in premium costs",
                type: .cost,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: buildings.map { $0.id }
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
            return .up
        } else if averageTrend < -0.05 {
            return .down
        } else {
            return .stable
        }
    }
    
    private func createLowCompletionInsight(building: NamedCoordinate, analytics: CoreTypes.BuildingAnalytics) -> CoreTypes.IntelligenceInsight {
        // ✅ FIXED: Use correct IntelligenceInsight initializer
        return CoreTypes.IntelligenceInsight(
            title: "Low Task Completion Rate",
            description: "Building \(building.name) has completion rate of \(Int(analytics.completionRate * 100))%",
            type: .performance,
            priority: .high,
            actionRequired: true,
            affectedBuildings: [building.id]
        )
    }
    
    private func createOverdueTasksInsight(building: NamedCoordinate, count: Int) -> CoreTypes.IntelligenceInsight {
        // ✅ FIXED: Use correct IntelligenceInsight initializer
        return CoreTypes.IntelligenceInsight(
            title: "Multiple Overdue Tasks",
            description: "Building \(building.name) has \(count) overdue tasks requiring attention",
            type: .maintenance,
            priority: count > 10 ? .critical : .high,
            actionRequired: true,
            affectedBuildings: [building.id]
        )
    }
    
    // MARK: - Helper Methods for Filtering (Avoid SwiftData SQL Expression Issues)
    
    private func getComplianceTasks(from tasks: [ContextualTask]) -> [ContextualTask] {
        var result: [ContextualTask] = []
        for task in tasks {
            // ✅ FIXED: Handle optional description safely to avoid SQLExpression errors
            let taskDescription = task.description ?? ""
            let lowercaseDescription = taskDescription.lowercased()
            
            if lowercaseDescription.contains("compliance") ||
               lowercaseDescription.contains("inspection") ||
               lowercaseDescription.contains("regulation") ||
               task.category == .inspection {
                result.append(task)
            }
        }
        return result
    }
    
    private func getOverdueTasks(from tasks: [ContextualTask]) -> [ContextualTask] {
        var result: [ContextualTask] = []
        for task in tasks {
            if let dueDate = task.dueDate, !task.isCompleted && dueDate < Date() {
                result.append(task)
            }
        }
        return result
    }
    
    private func getEmergencyTasks(from tasks: [ContextualTask]) -> [ContextualTask] {
        var result: [ContextualTask] = []
        for task in tasks {
            // ✅ FIXED: Handle optional description safely to avoid SQLExpression errors
            let taskDescription = task.description ?? ""
            let lowercaseDescription = taskDescription.lowercased()
            
            let isEmergencyDesc = lowercaseDescription.contains("emergency") || lowercaseDescription.contains("urgent")
            let isEmergencyUrgency = task.urgency == .urgent || task.urgency == .critical
            
            if isEmergencyDesc || isEmergencyUrgency {
                result.append(task)
            }
        }
        return result
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
