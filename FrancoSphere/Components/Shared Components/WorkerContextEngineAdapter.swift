//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere v6.0 - FIXED VERSION
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class WorkerContextEngineAdapter: ObservableObject {
    public static let shared = WorkerContextEngineAdapter()
    
    @Published public var currentWorker: WorkerProfile?
    @Published public var currentBuilding: NamedCoordinate?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var portfolioBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: CoreTypes.TaskProgress?
    @Published public var isLoading = false
    @Published public var hasPendingScenario = false
    
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPeriodicUpdates()
    }
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async {
        isLoading = true
        do {
            try await contextEngine.loadContext(for: workerId)
            await refreshPublishedState()
        } catch {
            print("❌ Failed to load context:", error)
        }
        isLoading = false
    }
    
    private func refreshPublishedState() async {
        self.currentWorker = contextEngine.getCurrentWorker()
        self.currentBuilding = contextEngine.getCurrentBuilding()
        self.assignedBuildings = contextEngine.getAssignedBuildings()
        self.portfolioBuildings = contextEngine.getPortfolioBuildings()
        self.todaysTasks = contextEngine.getTodaysTasks()
        self.taskProgress = contextEngine.getTaskProgress()
    }
    
    public func isBuildingAssigned(_ buildingId: String) -> Bool {
        return assignedBuildings.contains { $0.id == buildingId }
    }
    
    public func getBuildingType(_ buildingId: String) -> BuildingType {
        if assignedBuildings.contains(where: { $0.id == buildingId }) {
            return .assigned
        } else if portfolioBuildings.contains(where: { $0.id == buildingId }) {
            return .coverage
        }
        return .unknown
    }
    
    public func updateTaskCompletion(_ taskId: String, isCompleted: Bool) {
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = isCompleted
            updateTaskProgress()
        }
    }
    
    private func updateTaskProgress() {
        let completed = todaysTasks.filter { $0.isCompleted }.count
        taskProgress = CoreTypes.TaskProgress(
            totalTasks: todaysTasks.count,
            completedTasks: completed
        )
    }
    
    private func setupPeriodicUpdates() {
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task { await self.refreshPublishedState() }
            }
            .store(in: &cancellables)
    }
}

