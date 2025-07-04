//
//  WorkerDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ FIXED: All type conflicts resolved
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Combine
// FrancoSphere Types Import
// (This comment helps identify our import)


@MainActor
class WorkerDashboardViewModel: ObservableObject {
    
    // Published Properties
    @Published var assignedBuildings: [FrancoSphere.NamedCoordinate] = []
    @Published var todaysTasks: [ContextualTask] = []
    @Published var taskProgress: TaskProgress = TaskProgress(completed: 0, total: 0, remaining: 0, percentage: 0, overdueTasks: 0)
    @Published var isDataLoaded = false
    @Published var dataHealthStatus: DataHealthStatus = .unknown
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    @Published var weatherImpact: WeatherImpact?
    
    // Dependencies
    private let workerService: WorkerService
    private let taskService: TaskService
    private let contextEngine: WorkerContextEngine
    private var cancellables = Set<AnyCancellable>()
    
    init(workerService: WorkerService = WorkerService.shared,
         taskService: TaskService = TaskService.shared,
         contextEngine: WorkerContextEngine = WorkerContextEngine.shared) {
        
        self.workerService = workerService
        self.taskService = taskService
        self.contextEngine = contextEngine
        
        setupReactiveBindings()
    }
    
    func loadDashboardData() async {
        guard let workerId = NewAuthManager.shared.workerId else {
            errorMessage = "No worker ID available"
            return
        }
        
        isDataLoaded = false
        errorMessage = nil
        
        do {
            let buildings = try await workerService.getAssignedBuildings(workerId)
            let tasks = try await taskService.getTasks(for: workerId, date: Date())
            let progress = try await taskService.getTaskProgress(for: workerId)
            
            assignedBuildings = buildings
            todaysTasks = tasks
            taskProgress = progress
            
            dataHealthStatus = assessDataHealth()
            isDataLoaded = true
            
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
        }
    }
    
    func completeTask(_ task: ContextualTask, evidence: TaskEvidence?) async {
        guard let workerId = NewAuthManager.shared.workerId else { return }
        
        do {
            try await taskService.completeTask(task.id, workerId: workerId, buildingId: task.buildingId, evidence: evidence)
            
            if let index = todaysTasks.firstIndex(where: { $0.id == task.id }) {
                todaysTasks[index].status = "completed"
            }
            
            let updatedProgress = try await taskService.getTaskProgress(for: workerId)
            taskProgress = updatedProgress
            
        } catch {
            errorMessage = "Failed to complete task: \(error.localizedDescription)"
        }
    }
    
    func refreshData() async {
        isRefreshing = true
        await loadDashboardData()
        isRefreshing = false
    }
    
    private func assessDataHealth() -> DataHealthStatus {
        var issues: [String] = []
        
        if assignedBuildings.isEmpty { issues.append("No buildings assigned") }
        if todaysTasks.isEmpty { issues.append("No tasks scheduled") }
        
        if issues.isEmpty { return .healthy }
        else if issues.count <= 2 { return .warning(issues) }
        else { return .critical(issues) }
    }
    
    private func setupReactiveBindings() {
        WeatherManager.shared.$currentWeather
            .receive(on: DispatchQueue.main)
            .sink { [weak self] weather in
                // Update weather impact
            }
            .store(in: &cancellables)
    }
}


