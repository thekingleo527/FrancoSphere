//
//  WorkerContextEngine.swift
//  FrancoSphere
//
//  ✅ V6.0: ObservableObject for SwiftUI compatibility
//

import Foundation
import CoreLocation
import Combine

@MainActor
public class WorkerContextEngine: ObservableObject {
    public static let shared = WorkerContextEngine()
    
    // MARK: - Published State for UI
    @Published public var currentWorker: WorkerProfile?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: TaskProgress?
    @Published public var clockInStatus: (isClockedIn: Bool, building: NamedCoordinate?) = (false, nil)
    @Published public var isLoading = false
    @Published public var error: Error?
    
    // Service Dependencies
    private let authManager = NewAuthManager.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared
    private let clockInManager = ClockInManager.shared
    
    private init() {}
    
    // MARK: - Public API
    
    func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            print("🔄 Loading worker context for ID: \(workerId)")
            
            async let profile = workerService.getWorkerProfile(for: workerId)
            async let buildings = buildingService.getBuildingsForWorker(workerId)
            async let tasks = taskService.getTasks(for: workerId, date: Date())
            async let progress = taskService.getTaskProgress(for: workerId)
            
            self.currentWorker = try await profile
            self.assignedBuildings = try await buildings
            self.todaysTasks = try await tasks
            self.taskProgress = try await progress
            
            let status = await clockInManager.getClockInStatus(for: workerId)
            self.clockInStatus = (status.isClockedIn, status.currentBuilding)
            
            print("✅ Worker context loaded: \(assignedBuildings.count) buildings, \(todaysTasks.count) tasks")
            
        } catch {
            print("❌ Failed to load worker context: \(error)")
            self.error = error
            throw error
        }
        
        isLoading = false
    }
    
    func refreshContext() async {
        if let user = await authManager.getCurrentUser() {
            do {
                try await loadContext(for: user.workerId)
            } catch {
                self.error = error
            }
        }
    }
    
    // MARK: - Getter Methods for Compatibility
    func getCurrentWorker() -> WorkerProfile? { currentWorker }
    func getAssignedBuildings() -> [NamedCoordinate] { assignedBuildings }
    func getTodaysTasks() -> [ContextualTask] { todaysTasks }
    func getTaskProgress() -> TaskProgress? { taskProgress }
    func isWorkerClockedIn() -> Bool { clockInStatus.isClockedIn }
    func getCurrentBuilding() -> NamedCoordinate? { clockInStatus.building }
    func getWorkerId() -> String? { currentWorker?.id }
    func getWorkerName() -> String { currentWorker?.name ?? "Unknown Worker" }
    func getWorkerEmail() -> String? { currentWorker?.email }
    func getWorkerRole() -> UserRole { currentWorker?.role ?? .worker }
    func getPendingTaskCount() -> Int { todaysTasks.filter { !$0.isCompleted }.count }
    func getCompletedTaskCount() -> Int { todaysTasks.filter { $0.isCompleted }.count }
    func getOverdueTaskCount() -> Int {
        todaysTasks.filter { task in
            !task.isCompleted && (task.dueDate ?? Date.distantFuture) < Date()
        }.count
    }
    
    // For backwards compatibility
    func todayWorkers() -> [WorkerProfile] {
        return currentWorker != nil ? [currentWorker!] : []
    }
    
    func recordTaskCompletion(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID,
        taskId: CoreTypes.TaskID,
        evidence: ActionEvidence
    ) async throws {
        try await taskService.completeTask(taskId, evidence: evidence)
        
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index] = ContextualTask(
                id: todaysTasks[index].id,
                title: todaysTasks[index].title,
                description: todaysTasks[index].description,
                category: todaysTasks[index].category,
                urgency: todaysTasks[index].urgency,
                buildingId: todaysTasks[index].buildingId,
                buildingName: todaysTasks[index].buildingName,
                assignedWorkerId: todaysTasks[index].assignedWorkerId,
                assignedWorkerName: todaysTasks[index].assignedWorkerName,
                isCompleted: true,
                completedDate: Date(),
                dueDate: todaysTasks[index].dueDate,
                estimatedDuration: todaysTasks[index].estimatedDuration,
                recurrence: todaysTasks[index].recurrence,
                notes: todaysTasks[index].notes
            )
        }
        
        self.taskProgress = try await taskService.getTaskProgress(for: workerId)
    }
}

    // MARK: - Helper Methods for UI Components
    
    /// Get building name synchronously from cached data
    public func getBuildingNameSync(buildingId: String) -> String {
        return assignedBuildings.first { $0.id == buildingId }?.name ?? "Building \(buildingId)"
    }
    
    /// Get worker shift for profile
    public func getWorkerShiftForProfile(_ worker: WorkerProfile) -> String {
        // Map based on worker ID - from WorkerConstants
        switch worker.id {
        case "1": return "9:00-15:00"   // Greg
        case "2": return "6:00-15:00"   // Edwin  
        case "4": return "7:00-15:00"   // Kevin
        case "5": return "6:30-11:00"   // Mercedes
        case "6": return "7:00-16:00"   // Luis
        case "7": return "18:00-22:00"  // Angel
        default: return "Flexible"
        }
    }
    
    /// Check if worker is currently on site
    public func isWorkerOnSiteForProfile(_ worker: WorkerProfile) -> Bool {
        return clockInStatus.isClockedIn && currentWorker?.id == worker.id
    }
