//
//  WorkerDashboardIntegration.swift
//  FrancoSphere
//
//  🔧 FIXED: Removed non-existent recordTaskCompletion method call
//  ✅ All compilation errors resolved
//  ✅ Corrected TaskEvidence initialization
//  ✅ Updated to match current project structure
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class WorkerDashboardIntegration: ObservableObject {

    static let shared = WorkerDashboardIntegration()

    // Service Dependencies
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    private let contextEngine = WorkerContextEngine.shared
    private let operationalManager = OperationalDataManager.shared

    // Published Properties
    @Published var dashboardData: DashboardData?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var csvImportProgress: Double = 0.0
    @Published var lastRefresh: Date?

    // Private Properties
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupReactiveBindings()
    }

    func loadDashboardData(for workerId: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let buildings = try await loadBuildingsForWorker(workerId)
            let tasks = try await loadTasksForWorker(workerId)
            let progress = await calculateTaskProgress(for: workerId)

            await MainActor.run {
                self.dashboardData = DashboardData(
                    workerId: workerId,
                    assignedBuildings: buildings,
                    todaysTasks: tasks,
                    taskProgress: progress,
                    lastUpdated: Date()
                )

                self.lastRefresh = Date()
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }

    func refreshDashboard() async {
        guard let currentData = dashboardData else { return }
        await loadDashboardData(for: currentData.workerId)
    }

    func updateTaskCompletion(_ taskId: String, buildingId: String) async {
        guard let workerId = dashboardData?.workerId else { return }

        do {
            // ✅ FIXED: Use correct TaskEvidence initializer with proper parameters
            let evidence = TaskEvidence(
                photos: [Data](),
                timestamp: Date(),
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "Task completed via WorkerDashboardIntegration"
            )

            // Complete the task through TaskService
            try await taskService.completeTask(
                taskId,
                workerId: workerId,
                buildingId: buildingId,
                evidence: evidence
            )

            // ✅ REMOVED: contextEngine.recordTaskCompletion call since this method doesn't exist
            // Task completion is handled entirely by TaskService.completeTask above
            
            // Refresh dashboard to reflect changes
            await refreshDashboard()

        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }

    private func loadBuildingsForWorker(_ workerId: String) async throws -> [NamedCoordinate] {
        return try await workerService.getAssignedBuildings(workerId)
    }

    private func loadTasksForWorker(_ workerId: String) async throws -> [ContextualTask] {
        return try await taskService.getTasks(for: workerId, date: Date())
    }

    private func calculateTaskProgress(for workerId: String) async -> WDITaskProgress {
        do {
            let progress = try await taskService.getTaskProgress(for: workerId)
            return WDITaskProgress(
                completed: progress.completed,
                total: progress.total,
                remaining: progress.remaining,
                percentage: progress.percentage,
                overdueTasks: progress.overdueTasks
            )
        } catch {
            return WDITaskProgress(
                completed: 0,
                total: 0,
                remaining: 0,
                percentage: 0,
                overdueTasks: 0
            )
        }
    }

    func ensureOperationalDataLoaded() async {
        do {
            let hasImported = await checkIfDataImported()
            if hasImported {
                print("✅ Operational data already loaded")
                return
            }

            print("🔄 Loading operational data...")
            await MainActor.run {
                csvImportProgress = 0.1
            }

            let (imported, errors) = try await operationalManager.importRealWorldTasks()

            await MainActor.run {
                csvImportProgress = 1.0
            }

            print("✅ Loaded \(imported) real tasks from operational data")

            // ✅ FIXED: Correct optional chaining and boolean logic
            if !errors.isEmpty {
                print("⚠️ Import errors: \(errors)")
            }

        } catch {
            print("❌ Failed to load operational data: \(error)")
            await MainActor.run {
                self.error = error
            }
        }
    }

    private func checkIfDataImported() async -> Bool {
        do {
            let workerId = NewAuthManager.shared.workerId
            // ✅ FIXED: Correct optional check using isEmpty for String
            guard !workerId.isEmpty else {
                return false
            }

            let allTasks = try await loadTasksForWorker(workerId)

            // ✅ FIXED: Proper filtering logic for assigned worker names
            let operationalTasks = allTasks.filter { task in
                // Check if task has an assigned worker name (through extension or direct property)
                if let assignedWorkerName = task.assignedWorkerName,
                   !assignedWorkerName.isEmpty {
                    return true
                }
                // Also check workerId as fallback
                return !task.workerId.isEmpty
            }

            let hasMinimumTasks = allTasks.count >= 20
            let hasOperationalPattern = operationalTasks.count > 0

            return hasMinimumTasks || hasOperationalPattern

        } catch {
            print("❌ Error checking operational data status: \(error)")
            return false
        }
    }

    private func setupReactiveBindings() {
        contextEngine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshDashboard()
                }
            }
            .store(in: &cancellables)
    }

    func startBackgroundUpdates() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.refreshDashboard()
            }
        }
    }

    func stopBackgroundUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    deinit {
        refreshTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types (Unique names to avoid conflicts)

struct DashboardData {
    let workerId: String
    let assignedBuildings: [NamedCoordinate]
    let todaysTasks: [ContextualTask]
    let taskProgress: WDITaskProgress
    let lastUpdated: Date
}

struct WDITaskProgress {
    let completed: Int
    let total: Int
    let remaining: Int
    let percentage: Double
    let overdueTasks: Int
}

// MARK: - Extensions

extension WorkerDashboardIntegration {

    static func initialize() async {
        await shared.ensureOperationalDataLoaded()
    }

    static func loadForWorker(_ workerId: String) async -> WorkerDashboardIntegration {
        await shared.loadDashboardData(for: workerId)
        shared.startBackgroundUpdates()
        return shared
    }

    // MARK: - Helper Methods

    /// Get task completion rate for worker
    func getTaskCompletionRate(for workerId: String) async -> Double {
        guard let data = dashboardData, data.workerId == workerId else { return 0.0 }

        let total = data.taskProgress.total
        let completed = data.taskProgress.completed

        return total > 0 ? Double(completed) / Double(total) : 0.0
    }

    /// Check if worker has overdue tasks
    func hasOverdueTasks(for workerId: String) -> Bool {
        guard let data = dashboardData, data.workerId == workerId else { return false }
        return data.taskProgress.overdueTasks > 0
    }

    /// Get building names for assigned buildings
    func getBuildingNames(for workerId: String) -> [String] {
        guard let data = dashboardData, data.workerId == workerId else { return [] }
        return data.assignedBuildings.map { $0.name }
    }

    /// Get tasks by category
    func getTasksByCategory(for workerId: String) -> [String: [ContextualTask]] {
        guard let data = dashboardData, data.workerId == workerId else { return [:] }

        return Dictionary(grouping: data.todaysTasks) { task in
            task.category.rawValue.capitalized
        }
    }

    /// Get urgent tasks only
    func getUrgentTasks(for workerId: String) -> [ContextualTask] {
        guard let data = dashboardData, data.workerId == workerId else { return [] }

        return data.todaysTasks.filter { task in
            task.urgency == .high || task.urgency == .urgent
        }
    }
}

// MARK: - Error Handling

extension WorkerDashboardIntegration {

    enum DashboardError: LocalizedError {
        case noWorkerData
        case dataLoadingFailed(String)
        case taskCompletionFailed(String)
        case operationalDataMissing

        var errorDescription: String? {
            switch self {
            case .noWorkerData:
                return "No worker data available"
            case .dataLoadingFailed(let message):
                return "Failed to load dashboard data: \(message)"
            case .taskCompletionFailed(let message):
                return "Failed to complete task: \(message)"
            case .operationalDataMissing:
                return "Operational data not loaded"
            }
        }
    }

    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            print("❌ WorkerDashboardIntegration Error: \(error.localizedDescription)")
        }
    }
}
