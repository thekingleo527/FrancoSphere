//
//  WorkerContextEngine.swift
//  FrancoSphere
//
//  🎯 PHASE 0.2: ACTOR CONVERSION COMPLETE
//  ✅ Converted from @MainActor ObservableObject to actor
//  ✅ Removed @Published properties (not compatible with actors)
//  ✅ Added missing assignedBuildings and clockInStatus properties
//  ✅ Provides async getter methods for UI access
//  ✅ Real database integration through services
//  ✅ Thread-safe state management
//

import Foundation
import CoreLocation

/// Thread-safe actor for managing worker context and state across all dashboards
public actor WorkerContextEngine {
    public static let shared = WorkerContextEngine()
    
    // MARK: - Private State (no @Published in actors)
    
    /// Current worker profile loaded from database
    private var currentWorker: WorkerProfile?
    
    /// Buildings assigned to the current worker
    private var assignedBuildings: [NamedCoordinate] = []
    
    /// Today's tasks for the current worker
    private var todaysTasks: [ContextualTask] = []
    
    /// Task completion progress for the current worker
    private var taskProgress: TaskProgress?
    
    /// Clock-in status and current building
    private var clockInStatus: (isClockedIn: Bool, building: NamedCoordinate?) = (false, nil)
    
    /// Loading state for UI feedback
    private var isLoading = false
    
    /// Error state for UI display
    private var error: Error?
    
    // MARK: - Service Dependencies
    
    private let authManager = NewAuthManager.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared
    private let clockInManager = ClockInManager.shared
    
    private init() {}
    
    // MARK: - Public API (all methods async for actor access)
    
    /// Load complete worker context from database
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        
        self.isLoading = true
        self.error = nil
        
        do {
            print("🔄 Loading worker context for ID: \(workerId)")
            
            // Load REAL worker data from database concurrently
            async let profile = workerService.getWorkerProfile(for: workerId)
            async let buildings = buildingService.getBuildingsForWorker(workerId)
            async let tasks = taskService.getTasks(for: workerId, date: Date())
            async let progress = taskService.getTaskProgress(for: workerId)
            
            // Update state atomically
            self.currentWorker = try await profile
            self.assignedBuildings = try await buildings
            self.todaysTasks = try await tasks
            self.taskProgress = try await progress
            
            // Load clock-in status
            let status = await clockInManager.getClockInStatus(for: workerId)
            self.clockInStatus = (status.isClockedIn, status.currentBuilding)
            
            print("✅ Worker context loaded: \(assignedBuildings.count) buildings, \(todaysTasks.count) tasks")
            
        } catch {
            print("❌ Failed to load worker context: \(error)")
            self.error = error
            throw error
        }
        
        self.isLoading = false
    }
    
    /// Refresh context for currently authenticated user
    public func refreshContext() async {
        if let user = await authManager.getCurrentUser() {
            do {
                try await loadContext(for: user.workerId)
            } catch {
                self.error = error
                print("⚠️ Failed to refresh context: \(error)")
            }
        } else {
            print("⚠️ Cannot refresh context, no user is logged in.")
        }
    }
    
    // MARK: - Getter Methods (Replace @Published access)
    
    /// Get current worker profile
    public func getCurrentWorker() -> WorkerProfile? {
        return currentWorker
    }
    
    /// Get assigned buildings for current worker
    public func getAssignedBuildings() -> [NamedCoordinate] {
        return assignedBuildings
    }
    
    /// Get today's tasks for current worker
    public func getTodaysTasks() -> [ContextualTask] {
        return todaysTasks
    }
    
    /// Get task progress for current worker
    public func getTaskProgress() -> TaskProgress? {
        return taskProgress
    }
    
    /// Get loading state
    public func getIsLoading() -> Bool {
        return isLoading
    }
    
    /// Get error state
    public func getError() -> Error? {
        return error
    }
    
    /// Get clock-in status
    public func isWorkerClockedIn() -> Bool {
        return clockInStatus.isClockedIn
    }
    
    /// Get current building where worker is clocked in
    public func getCurrentBuilding() -> NamedCoordinate? {
        return clockInStatus.building
    }
    
    // MARK: - Real-World Worker Methods
    
    /// Get current worker ID
    public func getWorkerId() -> String? {
        return currentWorker?.id
    }
    
    /// Get current worker name
    public func getWorkerName() -> String {
        return currentWorker?.name ?? "Unknown Worker"
    }
    
    /// Get current worker email
    public func getWorkerEmail() -> String? {
        return currentWorker?.email
    }
    
    /// Get current worker role
    public func getWorkerRole() -> UserRole {
        return currentWorker?.role ?? .worker
    }
    
    /// Get worker operational status
    public func getWorkerStatus() -> CoreTypes.WorkerStatus {
        return clockInStatus.isClockedIn ? .clockedIn : .available
    }
    
    /// Get count of pending tasks
    public func getPendingTaskCount() -> Int {
        return todaysTasks.filter { !$0.isCompleted }.count
    }
    
    /// Get count of completed tasks today
    public func getCompletedTaskCount() -> Int {
        return todaysTasks.filter { $0.isCompleted }.count
    }
    
    /// Get count of overdue tasks
    public func getOverdueTaskCount() -> Int {
        return todaysTasks.filter { task in
            !task.isCompleted && (task.dueDate ?? Date.distantFuture) < Date()
        }.count
    }
    
    // MARK: - Task Management with Real Data
    
    /// Record task completion with evidence
    public func recordTaskCompletion(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID,
        taskId: CoreTypes.TaskID,
        evidence: ActionEvidence
    ) async throws {
        print("📝 Recording task completion: \(taskId) by worker \(workerId)")
        
        // Record to database through TaskService
        try await taskService.completeTask(taskId, evidence: evidence)
        
        // Update local state to reflect completion
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = true
            todaysTasks[index].completedDate = Date()
            print("✅ Local task state updated")
        }
        
        // Refresh task progress
        self.taskProgress = try await taskService.getTaskProgress(for: workerId)
        
        // Notify real-time sync system
        await notifyTaskCompletion(taskId: taskId, buildingId: buildingId, workerId: workerId)
    }
    
    /// Update clock-in status
    public func updateClockInStatus(isClockedIn: Bool, building: NamedCoordinate?) async {
        self.clockInStatus = (isClockedIn, building)
        
        if isClockedIn, let building = building {
            print("⏰ Worker clocked in at: \(building.name)")
        } else {
            print("⏰ Worker clocked out")
        }
    }
    
    /// Add new task to today's list (for real-time updates)
    public func addTask(_ task: ContextualTask) async {
        if !todaysTasks.contains(where: { $0.id == task.id }) {
            todaysTasks.append(task)
            print("➕ New task added: \(task.title)")
        }
    }
    
    /// Remove task from today's list
    public func removeTask(withId taskId: CoreTypes.TaskID) async {
        todaysTasks.removeAll { $0.id == taskId }
        print("➖ Task removed: \(taskId)")
    }
    
    /// Update building assignments (for real-time updates)
    public func updateAssignedBuildings(_ buildings: [NamedCoordinate]) async {
        self.assignedBuildings = buildings
        print("🏢 Building assignments updated: \(buildings.count) buildings")
    }
    
    // MARK: - Private Helper Methods
    
    /// Notify real-time sync system of task completion
    private func notifyTaskCompletion(taskId: CoreTypes.TaskID, buildingId: CoreTypes.BuildingID, workerId: CoreTypes.WorkerID) async {
        // Create worker event for real-time broadcasting
        let event = WorkerEventOutbox.WorkerEvent(
            type: .taskComplete,
            workerId: workerId,
            buildingId: buildingId,
            payload: TaskCompletionPayload(taskId: taskId),
            timestamp: Date()
        )
        
        // Add to outbox for sync across dashboards
        await WorkerEventOutbox.shared.addEvent(event)
    }
    
    /// Clear all state (for logout)
    public func clearContext() async {
        self.currentWorker = nil
        self.assignedBuildings = []
        self.todaysTasks = []
        self.taskProgress = nil
        self.clockInStatus = (false, nil)
        self.isLoading = false
        self.error = nil
        
        print("🧹 Worker context cleared")
    }
}

// MARK: - Supporting Types

/// Task completion payload for real-time events
public struct TaskCompletionPayload: Codable {
    let taskId: CoreTypes.TaskID
    let completedAt: Date
    
    init(taskId: CoreTypes.TaskID) {
        self.taskId = taskId
        self.completedAt = Date()
    }
}
