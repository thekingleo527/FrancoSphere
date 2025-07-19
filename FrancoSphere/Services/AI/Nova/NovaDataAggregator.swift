//
//  NovaDataAggregator.swift
//  FrancoSphere v6.0
//
//  ✅ NEW: Centralized data collection for Nova
//  ✅ REAL DATA: Pulls from GRDB-backed services
//

import Foundation

/// Basic structure holding aggregated metrics for Nova
struct NovaAggregatedData {
    let buildingCount: Int
    let taskCount: Int
    let workerCount: Int
}

/// Aggregates portfolio and building data for Nova's models.
actor NovaDataAggregator {
    static let shared = NovaDataAggregator()

    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared

    private init() {}

    /// Gather high level portfolio metrics from GRDB data
    func aggregatePortfolioData() async throws -> NovaAggregatedData {
        // Fetch real data using existing services (GRDB)
        async let buildings = buildingService.getAllBuildings()
        async let tasks = taskService.getAllTasks()
        async let workers = workerService.getAllActiveWorkers()

        let aggregated = NovaAggregatedData(
            buildingCount: try await buildings.count,
            taskCount: try await tasks.count,
            workerCount: try await workers.count
        )

        return aggregated
    }

    /// Gather metrics for a specific building
    func aggregateBuildingData(for buildingId: CoreTypes.BuildingID) async throws -> NovaAggregatedData {
        async let building = buildingService.getBuilding(buildingId: buildingId)
        async let tasks = taskService.getAllTasks() // Will be filtered by building
        async let workers = workerService.getActiveWorkersForBuilding(buildingId)

        let allTasks = try await tasks
        let buildingTasks = allTasks.filter { $0.building?.id == buildingId }

        let buildingData = try await building

        let aggregated = NovaAggregatedData(
            buildingCount: buildingData == nil ? 0 : 1,
            taskCount: buildingTasks.count,
            workerCount: try await workers.count
        )

        return aggregated
    }
}

