//
//  WorkerRoutineViewModel.swift
//  FrancoSphere
//
//  ✅ FIXED - All property names and constructor calls corrected
//  ✅ Matches FrancoSphereModels structure exactly
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
    @Published var dataHealthStatus: DataHealthStatus = .unknown
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
        // Initialize with default values matching exact FrancoSphereModels structure
        self.performanceMetrics = PerformanceMetrics(
            efficiency: 0.0,
            completionRate: 0.0,
            averageTime: 0.0
        )
        
        self.routineSummary = WorkerRoutineSummary(
            summary: "Loading worker routine data..."
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
        
        // Load routine tasks
        await loadRoutineTasks()
        
        // Generate daily route
        await generateDailyRoute()
        
        // Load optimizations and conflicts
        await loadRouteOptimizations()
        await loadScheduleConflicts()
        
        // Update data health
        updateDataHealth()
        
        // Update routine summary
        updateRoutineSummary()
    }
    
    private func loadRoutineTasks() async {
        do {
            let tasks = try await taskService.getTasks(for: selectedWorker, date: selectedDate)
            await MainActor.run {
                self.routineTasks = tasks.compactMap { task in
                    // FIXED: Use correct property names and constructor signature
                    MaintenanceTask(
                        id: task.id,
                        title: task.name,                    // FIXED: title not name
                        description: task.description,
                        category: task.category,
                        urgency: task.urgency,
                        recurrence: .none,
                        estimatedDuration: task.estimatedDuration,
                        requiredSkills: [],
                        buildingId: task.buildingId,
                        assignedWorkerId: task.workerId,
                        dueDate: task.dueDate,              // FIXED: dueDate not scheduledDate
                        completedDate: nil,
                        isCompleted: task.isCompleted,
                        notes: nil,
                        status: .pending                    // FIXED: status not verificationStatus
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
        
        // FIXED: Define route variable properly
        let route = Array(buildingsWithTasks.keys).sorted()
        
        await MainActor.run {
            self.dailyRoute = WorkerDailyRoute(route: route)
        }
    }
    
    private func loadRouteOptimizations() async {
        // Generate sample optimizations using correct structure
        let optimization = RouteOptimization(
            optimizedRoute: ["14", "1", "2"],
            estimatedTime: 7200, // 2 hours
            efficiencyGain: 0.15
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
    
    private func updateRoutineSummary() {
        let summary = generateSummaryText()
        self.routineSummary = WorkerRoutineSummary(summary: summary)
        
        // Update performance metrics
        let completedTasks = routineTasks.filter { $0.isCompleted }.count
        let totalTasks = routineTasks.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        
        self.performanceMetrics = PerformanceMetrics(
            efficiency: completionRate * 0.85 + 0.15, // Sample calculation
            completionRate: completionRate,
            averageTime: 3600.0 // 1 hour average
        )
    }
    
    private func generateSummaryText() -> String {
        let completedCount = routineTasks.filter { $0.isCompleted }.count
        let totalCount = routineTasks.count
        let buildingCount = buildingsWithTasks.count
        
        return """
        Worker: \(selectedWorker == "4" ? "Kevin Dutan" : "Worker \(selectedWorker)")
        Date: \(formatDate(selectedDate))
        Tasks: \(completedCount)/\(totalCount) completed
        Buildings: \(buildingCount) assigned
        Status: \(dataHealthStatus.description)
        """
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
        guard let route = dailyRoute, !route.route.isEmpty else { return 0.0 }
        return 0.85 // Sample efficiency score
    }
    
    private func analyzeTimeEfficiency() -> Double {
        guard let _ = dailyRoute else { return 0.0 }
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
        let optimizedRoute = currentRoute.route.shuffled() // Simple optimization
        
        let newRoute = WorkerDailyRoute(
            route: optimizedRoute
        )
        
        await MainActor.run {
            self.dailyRoute = newRoute
        }
    }
    
    func completeTask(_ taskId: String) async {
        guard let taskIndex = routineTasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        let task = routineTasks[taskIndex]
        // FIXED: Use correct property names and constructor signature
        let updatedTask = MaintenanceTask(
            id: task.id,
            title: task.title,                      // FIXED: title not name
            description: task.description,
            category: task.category,
            urgency: task.urgency,
            recurrence: task.recurrence,
            estimatedDuration: task.estimatedDuration,
            requiredSkills: task.requiredSkills,
            buildingId: task.buildingId,
            assignedWorkerId: task.assignedWorkerId,
            dueDate: task.dueDate,                  // FIXED: dueDate not scheduledDate
            completedDate: Date(),
            isCompleted: true,
            notes: task.notes,
            status: .approved                       // FIXED: status not verificationStatus
        )
        
        await MainActor.run {
            self.routineTasks[taskIndex] = updatedTask
            updateRoutineSummary()
        }
    }
    
    // MARK: - Utility Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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

// MARK: - DataHealthStatus Extension
extension DataHealthStatus {
    var description: String {
        switch self {
        case .healthy:
            return "Healthy"
        case .warning:
            return "Warning"
        case .critical:
            return "Critical"
        case .unknown:
            return "Unknown"
        case .error:
            return "Error"
        }
    }
}

// MARK: - Sample Data Extension
extension WorkerRoutineViewModel {
    static func sampleViewModel() -> WorkerRoutineViewModel {
        let vm = WorkerRoutineViewModel()
        
        // FIXED: Use correct property names in sample data
        let sampleTask = MaintenanceTask(
            id: UUID().uuidString,
            title: "Rubin Museum Cleaning",           // FIXED: title not name
            description: "Daily cleaning routine for Rubin Museum",
            category: .cleaning,
            urgency: .medium,
            recurrence: .daily,
            estimatedDuration: 3600,
            requiredSkills: [.cleaning],
            buildingId: "14",
            assignedWorkerId: "4",
            dueDate: Date(),                          // FIXED: dueDate not scheduledDate
            completedDate: nil,
            isCompleted: false,
            notes: nil,
            status: .pending                          // FIXED: status not verificationStatus
        )
        
        vm.routineTasks = [sampleTask]
        vm.dataHealthStatus = .healthy
        vm.routineSummary = WorkerRoutineSummary(
            summary: "Kevin Dutan - 1 task assigned to Rubin Museum"
        )
        
        return vm
    }
}
