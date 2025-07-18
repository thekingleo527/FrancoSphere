//
//  IntelligenceService+OperationalFallback.swift
//  FrancoSphere v6.0 - FIXED: OperationalDataManager Fallback for Intelligence
//
//  ✅ REAL INSIGHTS: Generated from OperationalDataManager when database empty
//  ✅ FALLBACK: Graceful degradation with meaningful insights
//

import Foundation

extension IntelligenceService {
    
    /// FIXED: Generate portfolio insights with OperationalDataManager fallback
    func generatePortfolioInsightsWithFallback() async throws -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Try to get data from existing services
        let buildingService = BuildingService.shared
        let taskService = TaskService.shared
        let workerService = WorkerService.shared
        
        do {
            let buildings = try await buildingService.getAllBuildings()
            var allTasks: [ContextualTask] = []
            
            // Try database tasks first, fall back to operational
            do {
                allTasks = try await taskService.getAllTasks()
                if allTasks.isEmpty {
                    // Fallback to operational data
                    allTasks = await generateTasksFromOperationalData()
                }
            } catch {
                // Fallback to operational data
                allTasks = await generateTasksFromOperationalData()
            }
            
            let activeWorkers = try await workerService.getAllActiveWorkers()
            
            print("📊 Generating insights from: \(buildings.count) buildings, \(allTasks.count) tasks, \(activeWorkers.count) workers")
            
            // Generate insights if we have data
            if !allTasks.isEmpty {
                insights.append(contentsOf: await generatePerformanceInsightsFromReal(
                    buildings: buildings, 
                    tasks: allTasks
                ))
                insights.append(contentsOf: await generateMaintenanceInsightsFromReal(
                    buildings: buildings, 
                    tasks: allTasks
                ))
                insights.append(contentsOf: await generateEfficiencyInsightsFromReal(
                    buildings: buildings, 
                    tasks: allTasks, 
                    workers: activeWorkers
                ))
            } else {
                // Generate operational insights directly from OperationalDataManager
                insights.append(contentsOf: await generateOperationalInsights())
            }
            
        } catch {
            print("⚠️ Error generating insights: \(error)")
            
            // Final fallback: Operational insights
            insights.append(contentsOf: await generateOperationalInsights())
        }
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    // MARK: - Real Data Insight Generation
    
    private func generatePerformanceInsightsFromReal(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let totalTasks = tasks.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        
        if completionRate < 0.7 && totalTasks > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Portfolio Performance Needs Attention",
                description: "Current completion rate is \(Int(completionRate * 100))% across \(totalTasks) tasks. Target is 70% or higher.",
                type: .performance,
                priority: completionRate < 0.5 ? .critical : .high,
                actionRequired: true,
                affectedBuildings: buildings.map { $0.id }
            ))
        } else if completionRate > 0.9 && totalTasks > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Excellent Portfolio Performance",
                description: "Outstanding completion rate of \(Int(completionRate * 100))% across \(totalTasks) tasks.",
                type: .performance,
                priority: .low,
                actionRequired: false,
                affectedBuildings: buildings.map { $0.id }
            ))
        }
        
        return insights
    }
    
    private func generateMaintenanceInsightsFromReal(buildings: [NamedCoordinate], tasks: [ContextualTask]) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let maintenanceTasks = tasks.filter { $0.category == .maintenance }
        let overdueMaintenance = maintenanceTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }
        
        if overdueMaintenance.count > 5 {
            // Group by building
            let buildingGroups = Dictionary(grouping: overdueMaintenance) { $0.buildingId ?? "unknown" }
            let affectedBuildings = Array(buildingGroups.keys).filter { $0 != "unknown" }
            
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Multiple Overdue Maintenance Tasks",
                description: "\(overdueMaintenance.count) maintenance tasks are overdue across \(affectedBuildings.count) buildings.",
                type: .maintenance,
                priority: .critical,
                actionRequired: true,
                affectedBuildings: affectedBuildings
            ))
        }
        
        return insights
    }
    
    private func generateEfficiencyInsightsFromReal(buildings: [NamedCoordinate], tasks: [ContextualTask], workers: [WorkerProfile]) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let tasksPerWorker = workers.count > 0 ? Double(tasks.count) / Double(workers.count) : 0.0
        
        if tasksPerWorker > 20 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Task Load Per Worker",
                description: "Average of \(Int(tasksPerWorker)) tasks per worker. Consider redistributing workload.",
                type: .efficiency,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: buildings.map { $0.id }
            ))
        } else if tasksPerWorker < 5 && workers.count > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Optimal Resource Utilization",
                description: "Excellent task distribution with \(Int(tasksPerWorker)) tasks per worker.",
                type: .efficiency,
                priority: .low,
                actionRequired: false,
                affectedBuildings: buildings.map { $0.id }
            ))
        }
        
        return insights
    }
    
    // MARK: - Operational Data Insights (Direct from OperationalDataManager)
    
    private func generateOperationalInsights() async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        let operationalData = OperationalDataManager.shared
        let realTasks = await operationalData.realWorldTasks
        
        // Task distribution analysis
        let tasksByBuilding = Dictionary(grouping: realTasks) { $0.building }
        let tasksByWorker = Dictionary(grouping: realTasks) { $0.assignedWorker }
        
        // High workload buildings
        let busyBuildings = tasksByBuilding.filter { $1.count > 10 }
        if !busyBuildings.isEmpty {
            let buildingNames = busyBuildings.keys.joined(separator: ", ")
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Activity Buildings Identified",
                description: "Buildings with high task volume: \(buildingNames). Monitor for potential staffing needs.",
                type: .efficiency,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: [] // Would need building ID mapping
            ))
        }
        
        // Worker workload analysis
        let busyWorkers = tasksByWorker.filter { $1.count > 15 }
        if !busyWorkers.isEmpty {
            let workerNames = busyWorkers.keys.joined(separator: ", ")
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Workload Workers",
                description: "Workers with heavy task loads: \(workerNames). Consider workload balancing.",
                type: .efficiency,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: []
            ))
        }
        
        // Category analysis
        let tasksByCategory = Dictionary(grouping: realTasks) { $0.category }
        let maintenanceTasks = tasksByCategory["Maintenance"]?.count ?? 0
        let cleaningTasks = tasksByCategory["Cleaning"]?.count ?? 0
        
        if maintenanceTasks > cleaningTasks * 2 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Maintenance Task Volume",
                description: "Maintenance tasks (\(maintenanceTasks)) significantly outnumber cleaning tasks (\(cleaningTasks)). Review preventive maintenance programs.",
                type: .maintenance,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: []
            ))
        }
        
        // Kevin's Rubin Museum insight
        let kevinTasks = realTasks.filter { $0.assignedWorker == "Kevin Dutan" }
        let rubinTasks = kevinTasks.filter { $0.building.contains("Rubin") }
        
        if !rubinTasks.isEmpty {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Specialized Building Assignment",
                description: "Kevin Dutan has \(rubinTasks.count) specialized tasks at Rubin Museum. Excellent specialized coverage.",
                type: .performance,
                priority: .low,
                actionRequired: false,
                affectedBuildings: []
            ))
        }
        
        return insights
    }
    
    // MARK: - Task Generation from OperationalDataManager
    
    private func generateTasksFromOperationalData() async -> [ContextualTask] {
        let operationalData = OperationalDataManager.shared
        var tasks: [ContextualTask] = []
        
        for (index, opTask) in await operationalData.realWorldTasks.enumerated() {
            let category: CoreTypes.TaskCategory
            switch opTask.category.lowercased() {
            case "cleaning": category = .cleaning
            case "maintenance": category = .maintenance
            case "inspection": category = .inspection
            case "security": category = .security
            default: category = .maintenance
            }
            
            let urgency: CoreTypes.TaskUrgency
            switch opTask.skillLevel.lowercased() {
            case "advanced": urgency = .critical
            case "intermediate": urgency = .urgent
            default: urgency = .normal
            }
            
            let task = ContextualTask(
                id: "op_insight_\(index)",
                title: opTask.taskName,
                description: "Operational assignment at \(opTask.building)",
                buildingId: nil, // Would need mapping
                buildingName: opTask.building,
                category: category,
                urgency: urgency,
                isCompleted: false,
                scheduledDate: Date(),
                dueDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date())
            )
            
            tasks.append(task)
        }
        
        return tasks
    }
}
