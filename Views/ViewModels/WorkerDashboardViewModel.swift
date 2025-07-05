//
//  WorkerDashboardViewModel.swift
//  FrancoSphere
//

import SwiftUI
import Combine

@MainActor
class WorkerDashboardViewModel: ObservableObject {
    @Published var assignedBuildings: [NamedCoordinate] = []
    @Published var todaysTasks: [ContextualTask] = []
    @Published var isDataLoaded = false
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    
    // Use nil initialization to avoid constructor issues
    @Published var progress: TaskProgress?
    @Published var dataHealthStatus: FrancoSphere.DataHealthStatus = .unknown
    @Published var weatherImpact: WeatherImpact?
    
    private let workerService: WorkerService
    private let taskService: TaskService
    private let contextEngine: WorkerContextEngine
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.workerService = WorkerService.shared
        self.taskService = TaskService.shared
        self.contextEngine = WorkerContextEngine.shared
        setupReactiveBindings()
    }
    
    func loadDashboardData() async {
        // Minimal implementation
        isDataLoaded = true
    }
    
    func refreshData() async {
        isRefreshing = true
        await loadDashboardData()
        isRefreshing = false
    }
    
    private func assessDataHealth() -> FrancoSphere.DataHealthStatus {
        return .healthy
    }
    
    private func setupReactiveBindings() {
        // Minimal setup
    }
}
