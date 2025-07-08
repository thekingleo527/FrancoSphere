//
//  UpdatedDataLoading.swift
//  FrancoSphere
//
//  ✅ Fixed with correct WorkerService method names
//

import Foundation

@MainActor
class UpdatedDataLoading: ObservableObject {
    @Published var isLoading = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    
    func loadUpdatedData() async {
        isLoading = true
        statusMessage = "Loading updated data..."
        progress = 0.0
        
        do {
            // Load workers using correct method name
            progress = 0.3
            statusMessage = "Loading workers..."
            let workers = await workerService.getAllActiveWorkers() // Correct method name
            
            // Load tasks using correct method name
            progress = 0.6
            statusMessage = "Loading tasks..."
            let tasks = try await taskService.getAllTasks() // This one does throw
            
            // Validate data
            progress = 0.9
            statusMessage = "Validating data..."
            let isValid = validateWorkerData(workers) && validateTaskData(tasks)
            
            // Completion
            progress = 1.0
            statusMessage = isValid ? "Data loaded successfully" : "Data validation warnings"
            
        } catch {
            statusMessage = "Error loading data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func validateWorkerData(_ workers: [WorkerProfile]) -> Bool {
        return !workers.isEmpty
    }
    
    private func validateTaskData(_ tasks: [ContextualTask]) -> Bool {
        return !tasks.isEmpty
    }
}
