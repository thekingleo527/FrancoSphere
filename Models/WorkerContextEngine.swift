//
//  WorkerContextEngine.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Complete architectural overhaul.
//  ✅ FIXED: Correctly and safely interacts with the NewAuthManager actor.
//  ✅ DELEGATED: Fetches all data from authoritative services, removing all hardcoded logic.
//

import Foundation
import Combine

@MainActor
public class WorkerContextEngine: ObservableObject {
    // MARK: - Singleton
    public static let shared = WorkerContextEngine()

    // MARK: - Published Properties for UI
    @Published public var isLoading = false
    @Published public var error: Error?
    
    // The context for the currently logged-in worker
    @Published public var workerProfile: WorkerProfile?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: TaskProgress?

    // MARK: - Services (The New Source of Truth)
    private let authManager = NewAuthManager.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared

    private init() {
        print("⚙️ WorkerContextEngine (v6.0) initialized.")
    }

    // MARK: - Core Methods

    /// Loads the entire context for a given worker ID. This is the primary entry point
    /// for populating the dashboard after a successful login.
    public func loadContext(for workerId: CoreTypes.WorkerID) async {
        guard !isLoading else { return }
        
        print("🔄 Loading context for worker ID: \(workerId)...")
        self.isLoading = true
        self.error = nil

        do {
            // Fetch all necessary data concurrently using our new services
            async let profile = workerService.getWorkerProfile(workerId)
            // ✅ FIXED: Corrected method call - removed extraneous label 'for:'
            async let buildings = buildingService.getBuildingsForWorker(workerId)
            async let tasks = taskService.getTasks(for: workerId, date: Date())
            async let progress = taskService.getTaskProgress(for: workerId)

            // Await and assign the results
            self.workerProfile = try await profile
            self.assignedBuildings = try await buildings
            self.todaysTasks = try await tasks
            self.taskProgress = try await progress
            
            print("✅ Context loaded successfully for \(self.workerProfile?.name ?? "worker").")
            
        } catch {
            let errorMessage = "Failed to load worker context: \(error.localizedDescription)"
            print("🚨 \(errorMessage)")
            self.error = error
        }
        
        self.isLoading = false
    }

    /// Refreshes the context for the currently loaded worker.
    public func refreshContext() async {
        // ✅ FIXED: Correctly awaits the result from the actor's method.
        if let workerId = await authManager.getCurrentUser()?.workerId {
            await loadContext(for: workerId)
        } else {
            print("⚠️ Cannot refresh context, no user is logged in.")
        }
    }

    /// Clears all context data, typically on logout.
    public func clearContext() {
        print("🧹 Clearing worker context.")
        workerProfile = nil
        assignedBuildings = []
        todaysTasks = []
        taskProgress = nil
        error = nil
    }
}
