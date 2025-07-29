
//
//  NovaDataService.swift
//  FrancoSphere v6.0
//
//  Data aggregation service for Nova AI
//  (Renamed from NovaDataAggregator for consistency)
//

import Foundation

/// Comprehensive structure holding aggregated metrics for Nova
public struct NovaAggregatedData: Codable {
    public let buildingCount: Int
    public let taskCount: Int
    public let workerCount: Int
    public let completedTaskCount: Int
    public let urgentTaskCount: Int
    public let overdueTaskCount: Int
    public let averageCompletionRate: Double
    public let timestamp: Date
    
    public init(
        buildingCount: Int,
        taskCount: Int,
        workerCount: Int,
        completedTaskCount: Int = 0,
        urgentTaskCount: Int = 0,
        overdueTaskCount: Int = 0,
        averageCompletionRate: Double = 0.0,
        timestamp: Date = Date()
    ) {
        self.buildingCount = buildingCount
        self.taskCount = taskCount
        self.workerCount = workerCount
        self.completedTaskCount = completedTaskCount
        self.urgentTaskCount = urgentTaskCount
        self.overdueTaskCount = overdueTaskCount
        self.averageCompletionRate = averageCompletionRate
        self.timestamp = timestamp
    }
}

/// Data service for aggregating portfolio and building metrics
public actor NovaDataService {
    nonisolated public static let shared = NovaDataService()
    
    // MARK: - Dependencies
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    
    // MARK: - Cache
    private var portfolioCache: (data: NovaAggregatedData, timestamp: Date)?
    private var buildingCache: [String: (data: NovaAggregatedData, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Portfolio Data Aggregation
    
    /// Gather comprehensive portfolio metrics from GRDB data
    public func aggregatePortfolioData() async throws -> NovaAggregatedData {
        // Check cache first
        if let cached = portfolioCache,
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            print("📦 Using cached portfolio data")
            return cached.data
        }
        
        print("🔄 Aggregating fresh portfolio data...")
        
        // Fetch real data using existing services
        async let buildings = buildingService.getAllBuildings()
        async let tasks = taskService.getAllTasks()
        async let workers = workerService.getAllActiveWorkers()
        
        // Wait for all data
        let allBuildings = try await buildings
        let allTasks = try await tasks
        let allWorkers = try await workers
        
        // Calculate task metrics
        let completedTasks = allTasks.filter { $0.isCompleted }
        let urgentTasks = allTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
        let overdueTasks = allTasks.filter { task in
            !task.isCompleted && task.isOverdue
        }
        
        // Calculate average completion rate
        let completionRate = allTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(allTasks.count)
        
        let aggregated = NovaAggregatedData(
            buildingCount: allBuildings.count,
            taskCount: allTasks.count,
            workerCount: allWorkers.count,
            completedTaskCount: completedTasks.count,
            urgentTaskCount: urgentTasks.count,
            overdueTaskCount: overdueTasks.count,
            averageCompletionRate: completionRate
        )
        
        // Cache the result
        portfolioCache = (aggregated, Date())
        
        print("✅ Portfolio data aggregated: \(allBuildings.count) buildings, \(allTasks.count) tasks, \(allWorkers.count) workers")
        
        return aggregated
    }
    
    /// Gather portfolio data with specific date range
    public func aggregatePortfolioData(from startDate: Date, to endDate: Date) async throws -> NovaAggregatedData {
        // For now, return current data
        // In full implementation, would filter by date range
        return try await aggregatePortfolioData()
    }
    
    // MARK: - Building Data Aggregation
    
    /// Gather comprehensive metrics for a specific building
    public func aggregateBuildingData(for buildingId: CoreTypes.BuildingID) async throws -> NovaAggregatedData {
        // Check cache first
        if let cached = buildingCache[buildingId],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            print("📦 Using cached data for building \(buildingId)")
            return cached.data
        }
        
        print("🔄 Aggregating fresh data for building \(buildingId)...")
        
        // Fetch building-specific data
        async let building = buildingService.getBuilding(buildingId: buildingId)
        async let allTasks = taskService.getAllTasks()
        async let workers = workerService.getActiveWorkersForBuilding(buildingId)
        
        // Get building metrics if available
        let metrics = try? await buildingMetricsService.calculateMetrics(for: buildingId)
        
        // Filter tasks for this building
        let tasks = try await allTasks
        let buildingTasks = tasks.filter { task in
            task.buildingId == buildingId || task.building?.id == buildingId
        }
        
        // Calculate task metrics
        let completedTasks = buildingTasks.filter { $0.isCompleted }
        let urgentTasks = buildingTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
        let overdueTasks = buildingTasks.filter { task in
            !task.isCompleted && task.isOverdue
        }
        
        // Use metrics if available, otherwise calculate
        let completionRate = metrics?.completionRate ??
            (buildingTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(buildingTasks.count))
        
        let buildingData = try await building
        let buildingWorkers = try await workers
        
        let aggregated = NovaAggregatedData(
            buildingCount: buildingData == nil ? 0 : 1,
            taskCount: buildingTasks.count,
            workerCount: buildingWorkers.count,
            completedTaskCount: completedTasks.count,
            urgentTaskCount: urgentTasks.count,
            overdueTaskCount: overdueTasks.count,
            averageCompletionRate: completionRate
        )
        
        // Cache the result
        buildingCache[buildingId] = (aggregated, Date())
        
        print("✅ Building data aggregated: \(buildingTasks.count) tasks, \(buildingWorkers.count) workers")
        
        return aggregated
    }
    
    // MARK: - Worker Data Aggregation
    
    /// Gather metrics for a specific worker
    public func aggregateWorkerData(for workerId: CoreTypes.WorkerID) async throws -> NovaAggregatedData {
        print("🔄 Aggregating data for worker \(workerId)...")
        
        // Get worker profile
        let worker = try await workerService.getWorkerProfile(for: workerId)
        
        // Get worker's tasks
        let allTasks = try await taskService.getAllTasks()
        let workerTasks = allTasks.filter { task in
            task.assignedWorkerId == workerId || task.worker?.id == workerId
        }
        
        // Calculate metrics
        let completedTasks = workerTasks.filter { $0.isCompleted }
        let urgentTasks = workerTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
        let overdueTasks = workerTasks.filter { task in
            !task.isCompleted && task.isOverdue
        }
        
        let completionRate = workerTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(workerTasks.count)
        
        return NovaAggregatedData(
            buildingCount: 0, // Workers don't have buildings
            taskCount: workerTasks.count,
            workerCount: worker == nil ? 0 : 1,
            completedTaskCount: completedTasks.count,
            urgentTaskCount: urgentTasks.count,
            overdueTaskCount: overdueTasks.count,
            averageCompletionRate: completionRate
        )
    }
    
    // MARK: - Specialized Aggregation
    
    /// Aggregate data by task category
    public func aggregateByCategory(_ category: TaskCategory) async throws -> NovaAggregatedData {
        let allTasks = try await taskService.getAllTasks()
        let categoryTasks = allTasks.filter { $0.category == category }
        
        let completedTasks = categoryTasks.filter { $0.isCompleted }
        let urgentTasks = categoryTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
        let overdueTasks = categoryTasks.filter { task in
            !task.isCompleted && task.isOverdue
        }
        
        let completionRate = categoryTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(categoryTasks.count)
        
        // Get unique buildings and workers
        let buildingIds = Set(categoryTasks.compactMap { $0.buildingId })
        let workerIds = Set(categoryTasks.compactMap { $0.assignedWorkerId })
        
        return NovaAggregatedData(
            buildingCount: buildingIds.count,
            taskCount: categoryTasks.count,
            workerCount: workerIds.count,
            completedTaskCount: completedTasks.count,
            urgentTaskCount: urgentTasks.count,
            overdueTaskCount: overdueTasks.count,
            averageCompletionRate: completionRate
        )
    }
    
    /// Aggregate compliance-related data
    public func aggregateComplianceData() async throws -> NovaAggregatedData {
        // Get all buildings and check compliance
        let buildings = try await buildingService.getAllBuildings()
        var compliantCount = 0
        var issueCount = 0
        
        for building in buildings {
            if let metrics = try? await buildingMetricsService.calculateMetrics(for: building.id) {
                if metrics.complianceScore >= 0.8 {
                    compliantCount += 1
                } else {
                    issueCount += 1
                }
            }
        }
        
        let complianceRate = buildings.isEmpty ? 0.0 : Double(compliantCount) / Double(buildings.count)
        
        return NovaAggregatedData(
            buildingCount: buildings.count,
            taskCount: 0, // Not relevant for compliance
            workerCount: 0, // Not relevant for compliance
            completedTaskCount: compliantCount,
            urgentTaskCount: issueCount,
            overdueTaskCount: 0,
            averageCompletionRate: complianceRate
        )
    }
}
