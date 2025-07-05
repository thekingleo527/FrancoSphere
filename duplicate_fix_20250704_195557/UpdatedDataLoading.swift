//
//  UpdatedDataLoading.swift
//  FrancoSphere
//
//  Fixed version with proper method calls and types
//

import Foundation
import CoreLocation

@MainActor
class UpdatedDataLoading: ObservableObject {
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let contextEngine = WorkerContextEngine.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    
    func loadComprehensiveData() async {
        isLoading = true
        loadingProgress = 0.0
        errorMessage = nil
        
        do {
            // Step 1: Load worker context (25%)
            await updateProgress(0.25, "Loading worker context...")
            await loadWorkerContext()
            
            // Step 2: Load building assignments (50%)
            await updateProgress(0.50, "Loading building assignments...")
            await loadBuildingAssignments()
            
            // Step 3: Load tasks (75%)
            await updateProgress(0.75, "Loading tasks...")
            await loadTasks()
            
            // Step 4: Calculate progress (100%)
            await updateProgress(1.0, "Calculating progress...")
            await calculateTaskProgress()
            
        } catch {
            errorMessage = "Data loading failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func loadWorkerContext() async {
        guard let workerId = NewAuthManager.shared.workerId else {
            throw LoadingError.noWorkerID
        }
        
        await contextEngine.loadWorkerContext(workerId: workerId)
    }
    
    private func loadBuildingAssignments() async {
        guard let workerId = NewAuthManager.shared.workerId else {
            throw LoadingError.noWorkerID
        }
        
        do {
            let buildings = try await workerService.getAssignedBuildings(workerId)
            await contextEngine.updateAssignedBuildings(buildings)
        } catch {
            throw LoadingError.buildingLoadFailed(error)
        }
    }
    
    private func loadTasks() async {
        guard let workerId = NewAuthManager.shared.workerId else {
            throw LoadingError.noWorkerID
        }
        
        do {
            let tasks = try await taskService.getTasks(for: workerId, date: Date())
            let filteredTasks = filterTasksForToday(tasks)
            await contextEngine.updateTodaysTasks(filteredTasks)
        } catch {
            throw LoadingError.taskLoadFailed(error)
        }
    }
    
    private func calculateTaskProgress() async {
        guard let workerId = NewAuthManager.shared.workerId else {
            throw LoadingError.noWorkerID
        }
        
        do {
            let progress = try await taskService.getTaskProgress(for: workerId)
            await contextEngine.updateTaskProgress(progress)
        } catch {
            throw LoadingError.progressCalculationFailed(error)
        }
    }
    
    private func filterTasksForToday(_ tasks: [ContextualTask]) -> [ContextualTask] {
        let calendar = Calendar.current
        let today = Date()
        
        return tasks.filter { task in
            if let scheduledDate = task.scheduledDate {
                return calendar.isDate(scheduledDate, inSameDayAs: today)
            }
            return true // Include tasks without specific dates
        }
    }
    
    private func updateProgress(_ progress: Double, _ message: String) async {
        await MainActor.run {
            loadingProgress = progress
        }
        
        print("Loading progress: \(Int(progress * 100))% - \(message)")
        
        // Small delay for UI responsiveness
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func refreshData() async {
        await loadComprehensiveData()
    }
    
    func validateDataIntegrity() async -> Bool {
        let tasks = contextEngine.getTodaysTasks()
        let buildings = contextEngine.getAssignedBuildings()
        
        return !tasks.isEmpty && !buildings.isEmpty
    }
}

// MARK: - Supporting Types
enum LoadingError: LocalizedError {
    case noWorkerID
    case buildingLoadFailed(Error)
    case taskLoadFailed(Error)
    case progressCalculationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noWorkerID:
            return "No worker ID available"
        case .buildingLoadFailed(let error):
            return "Failed to load buildings: \(error.localizedDescription)"
        case .taskLoadFailed(let error):
            return "Failed to load tasks: \(error.localizedDescription)"
        case .progressCalculationFailed(let error):
            return "Failed to calculate progress: \(error.localizedDescription)"
        }
    }
}

// MARK: - WorkerContextEngine Extensions
extension WorkerContextEngine {
    func updateAssignedBuildings(_ buildings: [FrancoSphere.NamedCoordinate]) async {
        await MainActor.run {
            self.assignedBuildings = buildings
        }
    }
    
    func updateTodaysTasks(_ tasks: [ContextualTask]) async {
        await MainActor.run {
            self.todaysTasks = tasks
        }
    }
    
    func updateTaskProgress(_ progress: FrancoSphere.TaskProgress) async {
        await MainActor.run {
            // Update any progress-related properties in context engine
        }
    }
}
