//
//  IntelligenceService.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: Method signatures with actual service implementations
//  ✅ CORRECTED: Optional unwrapping and error handling
//  ✅ FUNCTIONAL: Real data integration with existing services
//

import Foundation

actor IntelligenceService {
    // ✅ FIXED: nonisolated shared for cross-actor access
    nonisolated static let shared = IntelligenceService()
    
    private init() {}
    
    // MARK: - Main Intelligence Generation
    
    /// Generate portfolio-wide intelligence insights from real data
    func generatePortfolioInsights() async throws -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // ✅ FIXED: Use .shared pattern for all services
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
        
        // ✅ FIXED: Use .shared pattern
        let buildingService = BuildingService.shared
        let taskService = TaskService.shared
        
        do {
            // ✅ FIXED: Add correct argument label 'buildingId:'
            guard let building = try await buildingService.getBuilding(buildingId: buildingId) else {
                return insights
            }
            
            // ✅ FIXED: Use correct TaskService method that exists
            let allTasks = try await taskService.getAllTasks()
            // Filter tasks for this building
            let tasks = allTasks.filter { $0.buildingId == buildingId }
            
            // Building-specific insights
            let completedTasks = tasks.filter { $0.isCompleted }.count
            let completionRate = tasks.count > 0 ? Double(completedTasks) / Double(tasks.count) : 1.0
            
            if completionRate < 0.7 {
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "Low Completion Rate",
                    description: "Building \(building.name) has \(Int(completionRate * 100))% completion rate",
                    type: .performance,
                    priority: completionRate < 0.5 ? .critical : .high,
                    actionRequired: true,
                    affectedBuildings: [buildingId]
                ))
            }
            
            let overdueTasks = tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
            
            if overdueTasks.count > 3 {
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "Multiple Overdue Tasks",
                    description: "Building \(building.name) has \(overdueTasks.count) overdue tasks",
                    type: .maintenance,
                    priority: overdueTasks.count > 10 ? .critical : .high,
                    actionRequired: true,
                    affectedBuildings: [buildingId]
                ))
            }
            
        } catch {
            print("⚠️ Error generating building insights: \(error)")
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Building Analysis Unavailable",
                description: "Unable to analyze building \(buildingId) at this time",
                type: .performance,
                priority: .low,
                actionRequired: false,
                affectedBuildings: [buildingId]
            ))
        }
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    // MARK: - Private Insight Generation Methods
    
    private func generatePerformanceInsights(
        buildings: [NamedCoordinate],
        tasks: [ContextualTask]
    ) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 1.0
        
        if completionRate < 0.8 && totalTasks > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Portfolio Performance Below Target",
                description: "Overall completion rate is \(Int(completionRate * 100))%, below 80% target",
                type: .performance,
                priority: completionRate < 0.6 ? .critical : .high,
                actionRequired: true,
                affectedBuildings: buildings.map { $0.id }
            ))
        }
        
        return insights
    }
    
    private func generateMaintenanceInsights(
        buildings: [NamedCoordinate],
        tasks: [ContextualTask]
    ) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let maintenanceTasks = tasks.filter { $0.category == .maintenance }
        let overdueMaintenance = maintenanceTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }
        
        if overdueMaintenance.count > 5 {
            // ✅ FIXED: Properly handle optional strings - collect non-nil buildingIds
            let affectedBuildingIds: [String] = overdueMaintenance.compactMap { task -> String? in
                // Handle optional buildingId safely - check if nil or empty
                guard let buildingId = task.buildingId, !buildingId.isEmpty else { return nil }
                return buildingId
            }
            
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Overdue Maintenance Tasks",
                description: "\(overdueMaintenance.count) maintenance tasks are overdue across portfolio",
                type: .maintenance,
                priority: overdueMaintenance.count > 15 ? .critical : .high,
                actionRequired: true,
                affectedBuildings: Array(Set(affectedBuildingIds))
            ))
        }
        
        return insights
    }
    
    private func generateEfficiencyInsights(
        buildings: [NamedCoordinate],
        tasks: [ContextualTask],
        workers: [WorkerProfile]
    ) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let avgTasksPerWorker = workers.count > 0 ? Double(tasks.count) / Double(workers.count) : 0.0
        
        if avgTasksPerWorker > 20 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Task Load Per Worker",
                description: "Average of \(Int(avgTasksPerWorker)) tasks per worker exceeds recommended capacity",
                type: .efficiency,
                priority: avgTasksPerWorker > 30 ? .high : .medium,
                actionRequired: true,
                affectedBuildings: buildings.map { $0.id }
            ))
        }
        
        return insights
    }
    
    private func generateComplianceInsights(
        buildings: [NamedCoordinate],
        tasks: [ContextualTask]
    ) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let inspectionTasks = tasks.filter { $0.category == .inspection }
        let overdueInspections = inspectionTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }
        
        if overdueInspections.count > 0 {
            // ✅ FIXED: Properly handle optional strings - collect non-nil buildingIds
            let affectedBuildingIds: [String] = overdueInspections.compactMap { task -> String? in
                // Handle optional buildingId safely - check if nil or empty
                guard let buildingId = task.buildingId, !buildingId.isEmpty else { return nil }
                return buildingId
            }
            
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Overdue Safety Inspections",
                description: "\(overdueInspections.count) safety/compliance inspections are overdue",
                type: .compliance,
                priority: .critical,
                actionRequired: true,
                affectedBuildings: Array(Set(affectedBuildingIds))
            ))
        }
        
        return insights
    }
    
    // MARK: - Portfolio Analysis Methods
    
    /// Generate insights for worker efficiency across portfolio
    func generateWorkerEfficiencyInsights() async throws -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let workerService = WorkerService.shared
        let taskService = TaskService.shared
        
        do {
            let workers = try await workerService.getAllActiveWorkers()
            let allTasks = try await taskService.getAllTasks()
            
            // Analyze worker performance
            for worker in workers {
                // ✅ FIXED: Use correct property name for worker assignment
                let workerTasks = allTasks.filter { task in
                    // Check if this worker is assigned to this task
                    // Using assignedWorkerId (singular) instead of assignedWorkerIds
                    return task.assignedWorkerId == worker.id
                }
                let completedTasks = workerTasks.filter { $0.isCompleted }.count
                let completionRate = workerTasks.count > 0 ? Double(completedTasks) / Double(workerTasks.count) : 1.0
                
                if completionRate < 0.6 && workerTasks.count > 5 {
                    // ✅ FIXED: Safely handle optional buildingIds
                    let affectedBuildingIds: [String] = workerTasks.compactMap { task -> String? in
                        guard let buildingId = task.buildingId, !buildingId.isEmpty else { return nil }
                        return buildingId
                    }
                    
                    insights.append(CoreTypes.IntelligenceInsight(
                        title: "Worker Performance Issue",
                        description: "Worker \(worker.name) has low completion rate of \(Int(completionRate * 100))%",
                        type: .performance,
                        priority: .medium,
                        actionRequired: true,
                        affectedBuildings: Array(Set(affectedBuildingIds))
                    ))
                }
            }
            
        } catch {
            print("⚠️ Error generating worker insights: \(error)")
        }
        
        return insights
    }
    
    /// Generate cost-related insights
    func generateCostInsights() async throws -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let taskService = TaskService.shared
        
        do {
            let allTasks = try await taskService.getAllTasks()
            
            // Analyze emergency tasks (high cost impact)
            let emergencyTasks = allTasks.filter { $0.urgency == .emergency || $0.urgency == .critical }
            
            if emergencyTasks.count > 5 {
                let estimatedExtraCost = Double(emergencyTasks.count) * 500.0 // Emergency premium
                
                // ✅ FIXED: Safely handle optional buildingIds
                let affectedBuildingIds: [String] = emergencyTasks.compactMap { task -> String? in
                    guard let buildingId = task.buildingId, !buildingId.isEmpty else { return nil }
                    return buildingId
                }
                
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "High Emergency Task Volume",
                    description: "\(emergencyTasks.count) emergency tasks detected. Estimated extra cost: $\(Int(estimatedExtraCost))",
                    type: .cost,
                    priority: .medium,
                    actionRequired: true,
                    affectedBuildings: Array(Set(affectedBuildingIds))
                ))
            }
            
            // Analyze overdue tasks (cost escalation risk)
            let overdueTasks = allTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
            
            if overdueTasks.count > 20 {
                // ✅ FIXED: Safely handle optional buildingIds
                let affectedBuildingIds: [String] = overdueTasks.compactMap { task -> String? in
                    guard let buildingId = task.buildingId, !buildingId.isEmpty else { return nil }
                    return buildingId
                }
                
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "High Overdue Task Volume",
                    description: "\(overdueTasks.count) tasks are overdue, risking cost escalation",
                    type: .cost,
                    priority: .high,
                    actionRequired: true,
                    affectedBuildings: Array(Set(affectedBuildingIds))
                ))
            }
            
        } catch {
            print("⚠️ Error generating cost insights: \(error)")
        }
        
        return insights
    }
    
    // MARK: - Utility Methods
    
    /// Get insight summary statistics
    func getInsightStatistics() async throws -> InsightStatistics {
        let portfolioInsights = try await generatePortfolioInsights()
        
        let criticalCount = portfolioInsights.filter { $0.priority == .critical }.count
        let highCount = portfolioInsights.filter { $0.priority == .high }.count
        let actionableCount = portfolioInsights.filter { $0.actionRequired }.count
        
        return InsightStatistics(
            totalInsights: portfolioInsights.count,
            criticalInsights: criticalCount,
            highPriorityInsights: highCount,
            actionableInsights: actionableCount,
            lastUpdated: Date()
        )
    }
    
    /// Check if there are any critical insights requiring immediate attention
    func hasCriticalInsights() async throws -> Bool {
        let insights = try await generatePortfolioInsights()
        return insights.contains { $0.priority == .critical }
    }
    
    /// Get insights filtered by type
    func getInsightsByType(_ type: CoreTypes.InsightType) async throws -> [CoreTypes.IntelligenceInsight] {
        let allInsights = try await generatePortfolioInsights()
        return allInsights.filter { $0.type == type }
    }
}

// MARK: - Helper Types

struct InsightStatistics {
    let totalInsights: Int
    let criticalInsights: Int
    let highPriorityInsights: Int
    let actionableInsights: Int
    let lastUpdated: Date
}

// MARK: - Helper Extensions

extension CoreTypes.IntelligenceInsight {
    var isUrgent: Bool {
        return priority.priorityValue >= 3
    }
    
    var isActionable: Bool {
        return actionRequired
    }
    
    var riskScore: Double {
        switch priority {
        case .critical: return 1.0
        case .high: return 0.8
        case .medium: return 0.5
        case .low: return 0.2
        }
    }
}

extension Array where Element == CoreTypes.IntelligenceInsight {
    func filterByPriority(_ priority: CoreTypes.InsightPriority) -> [CoreTypes.IntelligenceInsight] {
        return self.filter { $0.priority == priority }
    }
    
    func filterActionable() -> [CoreTypes.IntelligenceInsight] {
        return self.filter { $0.actionRequired }
    }
    
    func sortedByPriority() -> [CoreTypes.IntelligenceInsight] {
        return self.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
}
