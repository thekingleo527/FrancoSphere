//
//  WorkerContextEngine.swift
//  FrancoSphere v6.0 — ACTOR conversion
//

import Foundation
import CoreLocation
import Combine

public actor WorkerContextEngine {
    public static let shared = WorkerContextEngine()
    private var currentWorker: WorkerProfile?
    private var assignedBuildings: [NamedCoordinate] = []
    private var todaysTasks: [ContextualTask] = []
    private var taskProgress: TaskProgress?
    private var clockInStatus: (Bool, NamedCoordinate?) = (false, nil)
    private var isLoading = false
    private var lastError: Error?

    private init() {}

    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true; lastError = nil
        do {
            let ws = WorkerService.shared
            let bs = BuildingService.shared
            let ts = TaskService.shared
            async let p = ws.getWorkerProfile(for: workerId)
            async let b = bs.getBuildingsForWorker(workerId)
            async let t = ts.getTasks(for: workerId, date: Date())
            async let pr = ts.getTaskProgress(for: workerId)
            self.currentWorker = try await p
            self.assignedBuildings = try await b
            self.todaysTasks = try await t
            self.taskProgress = try await pr
            let status = await ClockInManager.shared.getClockInStatus(for: workerId)
            self.clockInStatus = (status.isClockedIn, status.session?.building)
            echo "✅ Context loaded."
        } catch {
            lastError = error
            echo "❌ loadContext failed: $error"
            throw error
        }
        isLoading = false
    }

    // ... other methods omitted for brevity; insert your full actor definition here ...

    // Self-delete at end of script
}
