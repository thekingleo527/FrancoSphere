//
//  WorkerManager.swift
//  CyntientOps
//
//  ✅ FIXED: Added proper CoreTypes references
//  ✅ FIXED: Corrected shared instance reference
//  ✅ FIXED: All type references use CoreTypes prefix
//

import Foundation
import Combine

@MainActor
public class WorkerManager: ObservableObject {
    public static let shared = WorkerManager()  // ✅ FIXED: Should be WorkerManager, not WorkerService
    
    @Published public var currentWorker: CoreTypes.WorkerProfile?  // ✅ FIXED: Added CoreTypes prefix
    @Published public var allWorkers: [CoreTypes.WorkerProfile] = []  // ✅ FIXED: Added CoreTypes prefix
    @Published public var isLoading = false
    @Published public var error: Error?
    
    private let workerService = WorkerService.shared
    
    private init() {
        loadWorkers()
    }
    
    private func loadWorkers() {
        // ✅ FIXED: Load from actual data or use empty array initially
        Task {
            do {
                self.allWorkers = try await workerService.getAllActiveWorkers()
            } catch {
                self.error = error
                self.allWorkers = []
            }
        }
    }
    
    public func getWorker(by id: String) -> CoreTypes.WorkerProfile? {  // ✅ FIXED: Added CoreTypes prefix
        return allWorkers.first { $0.id == id }
    }
    
    public func setCurrentWorker(_ workerId: String) {
        currentWorker = getWorker(by: workerId)
    }
    
    public func getAllActiveWorkers() -> [CoreTypes.WorkerProfile] {  // ✅ FIXED: Added CoreTypes prefix
        return allWorkers.filter { $0.isActive }
    }
    
    public func loadWorkerBuildings(_ workerId: String) async throws -> [CoreTypes.NamedCoordinate] {  // ✅ FIXED: Added CoreTypes prefix
        // WorkerService doesn't have getAssignedBuildings method, use BuildingService instead
        return try await BuildingService.shared.getBuildingsForWorker(workerId)
    }
    
    public func getWorkerTasks(for workerId: String, date: Date) async throws -> [CoreTypes.ContextualTask] {  // ✅ FIXED: Added CoreTypes prefix
        // TaskService.getTasks doesn't exist, use getTasksForWorker instead
        return try await TaskService.shared.getTasksForWorker(workerId)
    }
}
