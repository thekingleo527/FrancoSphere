//
//  WorkerDashboardIntegration.swift
//  FrancoSphere
//
//  ✅ FINAL VERSION - All compilation errors fixed
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Combine
// FrancoSphere Types Import
// (This comment helps identify our import)

import CoreLocation
// FrancoSphere Types Import
// (This comment helps identify our import)


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
            let evidence = WDITaskEvidence(
                photos: [Data](),
                timestamp: Date(),
                location: CLLocation(latitude: 0, longitude: 0),
                notes: String?.none
            )
            
            try await taskService.completeTask(
                taskId,
                workerId: workerId,
                buildingId: buildingId,
                evidence: evidence
            )
            
            await contextEngine.updateTaskCompletion(
                workerId: workerId,
                buildingId: buildingId,
                taskName: ""
            )
            
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
            guard let workerId = NewAuthManager.shared.workerId, !workerId.isEmpty else {
                return false
            }
            
            let allTasks = try await loadTasksForWorker(workerId)
            
            let operationalTasks = allTasks.filter { task in
                !task.assignedWorkerName.isEmpty
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


extension WorkerDashboardIntegration {
    
    static func initialize() async {
        await shared.ensureOperationalDataLoaded()
    }
    
    static func loadForWorker(_ workerId: String) async -> WorkerDashboardIntegration {
        await shared.loadDashboardData(for: workerId)
        shared.startBackgroundUpdates()
        return shared
    }
}
