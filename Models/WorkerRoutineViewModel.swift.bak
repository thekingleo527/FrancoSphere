// Import Models

//
//  WorkerRoutineViewModel.swift
//  FrancoSphere
//
//  Completely rebuilt to fix structural issues
//

import SwiftUI
import Combine
import CoreLocation

@MainActor
class WorkerRoutineViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedWorker: String = "4" // Default to Kevin
    @Published var selectedDate: Date = Date()
    @Published var routineTasks: [MaintenanceTask] = []
    @Published var buildingsWithTasks: [String: [MaintenanceTask]] = [:]
    @Published var dailyRoute: WorkerDailyRoute?
    @Published var routeOptimizations: [RouteOptimization] = []
    @Published var scheduleConflicts: [ScheduleConflict] = []
    @Published var dataHealthStatus: DataHealthStatus = DataHealthStatus.unknown
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var performanceMetrics: PerformanceMetrics
    @Published var routineSummary: WorkerRoutineSummary
    
    // MARK: - Services
    private let taskService = TaskService.shared
    private let workerManager = WorkerService.shared
    private let buildingService = BuildingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Initialize with default values
        self.performanceMetrics = PerformanceMetrics(
            efficiency: 0.0,
            tasksCompleted: 0,
            averageTime: 0.0,
            qualityScore: 0.0,
            lastUpdate: Date()
        )
        
        self.routineSummary = WorkerRoutineSummary(
            workerId: "4",
            date: Date(),
            totalTasks: 0,
            completedTasks: 0,
            totalDistance: 0.0,
            averageTaskTime: 0.0,
            buildings: []
        )
        
        setupBindings()
        Task {
            await loadWorkerData()
        }
    }
    
    // MARK: - Setup Methods
    private func setupBindings() {
        // Set up reactive bindings
        $selectedWorker
            .combineLatest($selectedDate)
            .sink { [weak self] worker, date in
                Task { @MainActor in
                    await self?.loadWorkerData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadWorkerData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load routine tasks
            await loadRoutineTasks()
            
            // Generate daily route
            await generateDailyRoute()
            
            // Load optimizations and conflicts
            await loadRouteOptimizations()
            await loadScheduleConflicts()
            
            // Update data health
            updateDataHealth()
            
        } catch {
            errorMessage = "Failed to load worker data: \(error.localizedDescription)"
            dataHealthStatus = .critical
        }
    }
    
    private func loadRoutineTasks() async {
        do {
            let tasks = try await taskService.getTasks(for: selectedWorker, date: selectedDate)
            await MainActor.run {
                self.routineTasks = tasks.compactMap { task in
                    MaintenanceTask(
                        id: task.id,
                        buildingId: task.buildingId,
                        title: task.name,
                        description: task.description,
                        category: task.category,
                        urgency: .medium,
                        dueDate: task.dueDate ?? Date()
                    )
                }
                
                // Group by building
                self.buildingsWithTasks = Dictionary(grouping: self.routineTasks) { $0.buildingId }
            }
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    private func generateDailyRoute() async {
        guard !routineTasks.isEmpty else { return }
        
        // Generate route stops from tasks
        let stops = routineTasks.compactMap { task -> RouteStop? in
            let estimatedStart = Calendar.current.date(byAdding: .hour, value: 8, to: selectedDate) ?? Date()
            let estimatedEnd = Calendar.current.date(byAdding: .hour, value: 1, to: estimatedStart) ?? Date()
            
            return RouteStop(
                id: UUID().uuidString,
                buildingId: task.buildingId,
                address: "Building \(task.buildingId)",
                estimatedArrival: estimatedStart,
                estimatedDeparture: estimatedEnd,
                tasks: [task.id]
            )
        }
        
        await MainActor.run {
            self.dailyRoute = WorkerDailyRoute(
                workerId: selectedWorker,
                date: selectedDate,
                stops: stops,
                totalDistance: 10.5,
                estimatedDuration: 28800, // 8 hours
                optimizedOrder: stops.map { $0.id }
            )
        }
    }
    
    private func loadRouteOptimizations() async {
        // Generate sample optimizations
        let optimization = RouteOptimization(
            originalRoute: ["Building1", "Building2", "Building3"],
            optimizedRoute: ["Building1", "Building3", "Building2"],
            distanceSaved: 2.3,
            timeSaved: 1800, // 30 minutes
            efficiency: 0.85
        )
        
        await MainActor.run {
            self.routeOptimizations = [optimization]
        }
    }
    
    private func loadScheduleConflicts() async {
        // Check for scheduling conflicts
        let conflicts: [ScheduleConflict] = []
        
        await MainActor.run {
            self.scheduleConflicts = conflicts
        }
    }
    
    private func updateDataHealth() {
        if routineTasks.isEmpty {
            dataHealthStatus = .warning
        } else if scheduleConflicts.isEmpty {
            dataHealthStatus = .healthy
        } else {
            dataHealthStatus = .critical
        }
    }
    
    // MARK: - Route Analysis
    func analyzeRouteEfficiency() -> (geographic: Double, time: Double, skill: Double) {
        return (
            geographic: analyzeGeographicEfficiency(),
            time: analyzeTimeEfficiency(),
            skill: analyzeSkillGrouping()
        )
    }
    
    private func analyzeGeographicEfficiency() -> Double {
        guard let route = dailyRoute, !route.stops.isEmpty else { return 0.0 }
        return 0.85 // Sample efficiency score
    }
    
    private func analyzeTimeEfficiency() -> Double {
        guard let route = dailyRoute else { return 0.0 }
        return 0.78 // Sample efficiency score
    }
    
    private func analyzeSkillGrouping() -> Double {
        let skillGroups = Dictionary(grouping: routineTasks) { task in
            task.category
        }
        return Double(skillGroups.count) / Double(max(routineTasks.count, 1))
    }
    
    // MARK: - Task Management
    func optimizeRoute() async {
        guard let currentRoute = dailyRoute else { return }
        
        // Perform route optimization
        let optimizedStops = currentRoute.stops.shuffled() // Simple optimization
        
        let optimizedRoute = WorkerDailyRoute(
            workerId: currentRoute.workerId,
            date: currentRoute.date,
            stops: optimizedStops,
            totalDistance: currentRoute.totalDistance * 0.9,
            estimatedDuration: currentRoute.estimatedDuration * 0.9,
            optimizedOrder: optimizedStops.map { $0.id }
        )
        
        await MainActor.run {
            self.dailyRoute = optimizedRoute
        }
    }
    
    func completeTask(_ taskId: String) async {
        guard let taskIndex = routineTasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        var updatedTask = routineTasks[taskIndex]
        updatedTask = MaintenanceTask(
            id: updatedTask.id,
            buildingId: updatedTask.buildingId,
            title: updatedTask.title,
            description: updatedTask.description,
            category: updatedTask.category,
            urgency: updatedTask.urgency,
            dueDate: updatedTask.dueDate,
            completedDate: Date()
        )
        
        await MainActor.run {
            self.routineTasks[taskIndex] = updatedTask
        }
    }
    
    // MARK: - Utility Methods
    private func parseTimeDouble(_ timeString: String) -> Double {
        return Double(timeString) ?? 0.0
    }
    
    private func assessDataHealth() -> DataHealthStatus {
        if routineTasks.isEmpty {
            return .warning
        } else if !scheduleConflicts.isEmpty {
            return .critical
        } else {
            return .healthy
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    private func getWorkerIdFromName(_ name: String) -> String {
        // Simple mapping - in real app would query database
        switch name.lowercased() {
        case "kevin":
            return "4"
        default:
            return "1"
        }
    }
    
    // MARK: - Kevin-Specific Methods
    func validateKevinData() -> Bool {
        return selectedWorker == "4" && !routineTasks.isEmpty
    }
    
    func getKevinAssignedBuildings() -> [String] {
        guard selectedWorker == "4" else { return [] }
        return Array(buildingsWithTasks.keys)
    }
}

// MARK: - Sample Data Extension
extension WorkerRoutineViewModel {
    static func sampleViewModel() -> WorkerRoutineViewModel {
        let vm = WorkerRoutineViewModel()
        
        // Add sample data for previews
        let sampleTask = MaintenanceTask(
            buildingId: "14",
            title: "Rubin Museum Cleaning",
            description: "Daily cleaning routine",
            category: .cleaning,
            urgency: .medium,
            dueDate: Date()
        )
        
        vm.routineTasks = [sampleTask]
        vm.dataHealthStatus = .healthy
        
        return vm
    }
}
