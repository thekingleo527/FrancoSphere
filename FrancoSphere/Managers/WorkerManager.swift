//
//  WorkerManager.swift
//  FrancoSphere
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import Combine
// FrancoSphere Types Import
// (This comment helps identify our import)

@MainActor
public class WorkerManager: ObservableObject {
    public static let shared = WorkerService.shared
    
    @Published public var currentWorker: WorkerProfile?
    @Published public var allWorkers: [WorkerProfile] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    
    private let workerService = WorkerService.shared
    
    private init() {
        loadWorkers()
    }
    
    private func loadWorkers() {
        allWorkers = WorkerProfile.allWorkers
    }
    
    public func getWorker(by id: String) -> WorkerProfile? {
        return allWorkers.first { $0.id == id }
    }
    
    public func setCurrentWorker(_ workerId: String) {
        currentWorker = getWorker(by: workerId)
    }
    
    public func getAllActiveWorkers() -> [WorkerProfile] {
        return allWorkers.filter { $0.isActive }
    }
    
    public func loadWorkerBuildings(_ workerId: String) async throws -> [NamedCoordinate] {
        return try await workerService.getAssignedBuildings(workerId)
    }
    
    public func getWorkerTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        return try await TaskService.shared.getTasks(for: workerId, date: date)
    }
}
