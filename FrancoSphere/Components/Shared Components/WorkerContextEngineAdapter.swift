//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed incorrect BuildingType usage
//  ✅ FIXED: Added proper BuildingAssignmentType enum
//  ✅ ALIGNED: With actual CoreTypes definitions
//  ✅ ENHANCED: Clean separation of concerns
//

import Foundation
import SwiftUI
import Combine

// MARK: - Building Assignment Type
public enum BuildingAssignmentType {
    case assigned     // Worker is directly assigned to this building
    case coverage     // Worker provides coverage for this building
    case unknown      // No assignment relationship
}

// MARK: - Worker Context Engine Adapter
@MainActor
public class WorkerContextEngineAdapter: ObservableObject {
    public static let shared = WorkerContextEngineAdapter()
    
    // MARK: - Published Properties
    @Published public var currentWorker: WorkerProfile?
    @Published public var currentBuilding: NamedCoordinate?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var portfolioBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: CoreTypes.TaskProgress?
    @Published public var isLoading = false
    @Published public var hasPendingScenario = false
    @Published public var lastRefreshTime: Date?
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    private init() {
        setupPeriodicUpdates()
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    /// Load context for a specific worker
    public func loadContext(for workerId: CoreTypes.WorkerID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await contextEngine.loadContext(for: workerId)
            await refreshPublishedState()
            lastRefreshTime = Date()
        } catch {
            print("❌ Failed to load context: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Refresh the current context
    public func refreshContext() async {
        guard let workerId = currentWorker?.id else { return }
        await loadContext(for: workerId)
    }
    
    /// Check if a building is assigned to the current worker
    public func isBuildingAssigned(_ buildingId: String) -> Bool {
        return assignedBuildings.contains { $0.id == buildingId }
    }
    
    /// Get the assignment type for a building
    public func getBuildingAssignmentType(_ buildingId: String) -> BuildingAssignmentType {
        if assignedBuildings.contains(where: { $0.id == buildingId }) {
            return .assigned
        } else if portfolioBuildings.contains(where: { $0.id == buildingId }) {
            return .coverage
        }
        return .unknown
    }
    
    /// Get the actual building type (office, residential, etc.)
    public func getBuildingType(_ buildingId: String) -> CoreTypes.BuildingType? {
        // This would typically fetch from the building service
        // For now, return a default
        return .office
    }
    
    /// Update task completion status
    public func updateTaskCompletion(_ taskId: String, isCompleted: Bool) {
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = isCompleted
            updateTaskProgress()
            
            // Notify the context engine
            Task {
                await notifyTaskStatusChange(taskId: taskId, isCompleted: isCompleted)
            }
        }
    }
    
    /// Get tasks for a specific building
    public func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return todaysTasks.filter { $0.buildingId == buildingId }
    }
    
    /// Get the current worker's active building (where they're clocked in)
    public func getActiveBuilding() -> NamedCoordinate? {
        return currentBuilding
    }
    
    /// Check if worker has any pending high-priority tasks
    public func hasPendingHighPriorityTasks() -> Bool {
        return todaysTasks.contains { task in
            !task.isCompleted &&
            (task.urgency == .high || task.urgency == .critical || task.urgency == .urgent)
        }
    }
    
    /// Get completion percentage for today's tasks
    public func getCompletionPercentage() -> Double {
        guard !todaysTasks.isEmpty else { return 0.0 }
        let completedCount = todaysTasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(todaysTasks.count) * 100.0
    }
    
    // MARK: - Private Methods
    
    private func refreshPublishedState() async {
        self.currentWorker = contextEngine.getCurrentWorker()
        self.currentBuilding = contextEngine.getCurrentBuilding()
        self.assignedBuildings = contextEngine.getAssignedBuildings()
        self.portfolioBuildings = contextEngine.getPortfolioBuildings()
        self.todaysTasks = contextEngine.getTodaysTasks()
        self.taskProgress = contextEngine.getTaskProgress()
        
        // Update pending scenario status
        updatePendingScenarioStatus()
    }
    
    private func updateTaskProgress() {
        let completed = todaysTasks.filter { $0.isCompleted }.count
        taskProgress = CoreTypes.TaskProgress(
            totalTasks: todaysTasks.count,
            completedTasks: completed
        )
    }
    
    private func updatePendingScenarioStatus() {
        // Check for scenarios that need attention
        hasPendingScenario = hasPendingHighPriorityTasks() ||
                           todaysTasks.contains { $0.urgency == .emergency }
    }
    
    private func notifyTaskStatusChange(taskId: String, isCompleted: Bool) async {
        // Notify other services about task status change
        await DataSynchronizationService.shared.broadcastSyncCompletion(
            for: WorkerEvent(
                buildingId: currentBuilding?.id ?? "",
                workerId: currentWorker?.id ?? "",
                type: isCompleted ? .taskCompletion : .taskStart
            )
        )
    }
    
    private func setupPeriodicUpdates() {
        // Set up periodic refresh
        Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshPublishedState()
                    self?.lastRefreshTime = Date()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        // Listen for app becoming active to refresh data
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { await self?.refreshContext() }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Convenience Extensions

extension WorkerContextEngineAdapter {
    
    /// Get a summary of today's progress
    public func getTodaysSummary() -> (total: Int, completed: Int, percentage: Double) {
        let total = todaysTasks.count
        let completed = todaysTasks.filter { $0.isCompleted }.count
        let percentage = total > 0 ? Double(completed) / Double(total) * 100.0 : 0.0
        return (total, completed, percentage)
    }
    
    /// Get buildings that need attention
    public func getBuildingsNeedingAttention() -> [NamedCoordinate] {
        let buildingIds = todaysTasks
            .filter { !$0.isCompleted && ($0.urgency == .high || $0.urgency == .critical) }
            .compactMap { $0.buildingId }
            .unique()
        
        return assignedBuildings.filter { building in
            buildingIds.contains(building.id)
        }
    }
    
    /// Check if worker should clock out (all tasks done)
    public func shouldSuggestClockOut() -> Bool {
        guard let _ = currentBuilding else { return false }
        let buildingTasks = todaysTasks.filter { $0.buildingId == currentBuilding?.id }
        return !buildingTasks.isEmpty && buildingTasks.allSatisfy { $0.isCompleted }
    }
}

// MARK: - Helper Extensions

private extension Array where Element: Hashable {
    func unique() -> [Element] {
        return Array(Set(self))
    }
}
