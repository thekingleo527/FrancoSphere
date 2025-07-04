//
//  WorkerManager.swift
//  FrancoSphere
//

import Foundation
import Combine

@MainActor
public class WorkerManager: ObservableObject {
    public static let shared = WorkerService()
    
    @Published public var currentWorker: FrancoSphere.WorkerProfile?
    @Published public var allWorkers: [FrancoSphere.WorkerProfile] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    
    private let workerService = WorkerService.shared
    
    private init() {
        loadWorkers()
    }
    
    private func loadWorkers() {
        allWorkers = FrancoSphere.WorkerProfile.allWorkers
    }
    
    public func getWorker(by id: String) -> FrancoSphere.WorkerProfile? {
        return allWorkers.first { $0.id == id }
    }
    
    public func setCurrentWorker(_ workerId: String) {
        currentWorker = getWorker(by: workerId)
    }
    
    public func getAllActiveWorkers() -> [FrancoSphere.WorkerProfile] {
        return allWorkers.filter { $0.isActive }
    }
    
    public func loadWorkerBuildings(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        return try await workerService.getAssignedBuildings(workerId)
    }
    
    public func getWorkerTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        return try await TaskService.shared.getTasks(for: workerId, date: date)
    }
}
