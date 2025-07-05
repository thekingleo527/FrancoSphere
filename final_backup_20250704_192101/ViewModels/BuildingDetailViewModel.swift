//
//  BuildingDetailViewModel.swift
//  FrancoSphere
//

import SwiftUI
import Combine

@MainActor
class BuildingDetailViewModel: ObservableObject {
    @Published var routineTasks: [ContextualTask] = []
    @Published var workersToday: [DetailedWorker] = []
    @Published var buildingStats: FrancoSphere.BuildingStatistics = FrancoSphere.BuildingStatistics(
        completionRate: 0.0,
        tasksCompleted: 0,
        tasksRemaining: 0,
        averageCompletionTime: 0.0
    )
    @Published var buildingInsights: [FrancoSphere.BuildingInsight] = []
    @Published var isLoading = false
    @Published var selectedTab: FrancoSphere.BuildingTab = .overview
    
    private let buildingService = BuildingService.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    
    func loadBuildingData(for building: FrancoSphere.NamedCoordinate) async {
        isLoading = true
        
        do {
            async let routines = getRoutineTasks(for: building.id)
            async let workers = getWorkersToday(for: building.id)
            async let stats = getBuildingStats(for: building.id)
            async let insights = getBuildingInsights(for: building.id)
            
            self.routineTasks = await routines
            self.workersToday = await workers
            self.buildingStats = await stats
            self.buildingInsights = await insights
            
        } catch {
            print("Error loading building data: \(error)")
        }
        
        isLoading = false
    }
    
    private func getRoutineTasks(for buildingId: String) async -> [ContextualTask] {
        return []
    }
    
    private func getWorkersToday(for buildingId: String) async -> [DetailedWorker] {
        return []
    }
    
    private func getBuildingStats(for buildingId: String) async -> FrancoSphere.BuildingStatistics {
        return FrancoSphere.BuildingStatistics(
            completionRate: 0.85,
            tasksCompleted: 12,
            tasksRemaining: 3,
            averageCompletionTime: 45.0
        )
    }
    
    private func getBuildingInsights(for buildingId: String) async -> [FrancoSphere.BuildingInsight] {
        return [
            FrancoSphere.BuildingInsight(
                title: "Good Progress",
                description: "Tasks are being completed on schedule",
                type: .positive
            )
        ]
    }
}
