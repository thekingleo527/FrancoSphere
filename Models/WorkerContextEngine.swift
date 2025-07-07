//
//  WorkerContextEngine.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Corrected actor property access and method calls.
//

import Foundation
import Combine

@MainActor
public class WorkerContextEngine: ObservableObject {
    public static let shared = WorkerContextEngine()

    @Published public var isLoading = false
    @Published public var error: Error?
    @Published public var workerProfile: WorkerProfile?
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: TaskProgress?

    private let authManager = NewAuthManager.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared

    private init() {}

    public func loadContext(for workerId: CoreTypes.WorkerID) async {
        guard !isLoading else { return }
        self.isLoading = true
        self.error = nil
        do {
            async let profile = workerService.getWorkerProfile(for: workerId)
            // ✅ FIXED: Corrected method call - removed extraneous label 'for:'
            async let buildings = buildingService.getBuildingsForWorker(workerId)
            async let tasks = taskService.getTasks(for: workerId, date: Date())
            async let progress = taskService.getTaskProgress(for: workerId)

            self.workerProfile = try await profile
            self.assignedBuildings = try await buildings
            self.todaysTasks = try await tasks
            self.taskProgress = try await progress
        } catch {
            self.error = error
        }
        self.isLoading = false
    }

    public func refreshContext() async {
        // ✅ FIXED: Correctly awaits the result from the actor's method.
        if let workerId = await authManager.getCurrentUser()?.workerId {
            await loadContext(for: workerId)
        } else {
            print("⚠️ Cannot refresh context, no user is logged in.")
        }
    }
}
