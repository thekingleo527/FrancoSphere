// AI Types Import
//  Import AI types for proper enum resolution

//
//  AIAssistantManager.swift
//  FrancoSphere
//
//  Fixed version with proper type handling
//

import Foundation

// MARK: - Scenario Types
public enum AIScenarioType: String, CaseIterable {
    case routineIncomplete = "routine_incomplete"
    case taskCompletion = "task_completion"
    case pendingTasks = "pending_tasks"
    case buildingArrival = "building_arrival"
    case weatherAlert = "weather_alert"
    case maintenanceRequired = "maintenance_required"
    case scheduleConflict = "schedule_conflict"
    case emergencyResponse = "emergency_response"
    
    // MARK: - Scenario Management
        func addScenario(_ scenarioType: AIScenarioType) {
        let scenario = AIScenario()
        activeScenarios.append(scenario)
        hasActiveScenarios = !activeScenarios.isEmpty
        print("📱 Added AI scenario: \(scenarioType.rawValue)")
    }
    
    func dismissScenario(_ scenarioId: String) {
        activeScenarios.removeAll { $0.id == scenarioId }
        hasActiveScenarios = !activeScenarios.isEmpty
    }
    
    func clearAllScenarios() {
        activeScenarios.removeAll()
        suggestions.removeAll()
        hasActiveScenarios = false
        currentScenario = nil
        currentScenarioData = nil
    }
    
    private func generateSuggestions(for scenarioType: AIScenarioType) -> [AISuggestion] {
        switch scenarioType {
        case .routineIncomplete:
            return [
                AISuggestion(id: "check_tasks", text: "Review incomplete tasks", priority: .high),
                AISuggestion(id: "update_status", text: "Update task status", priority: .medium)
            ]
        case .taskCompletion:
            return [
                AISuggestion(id: "mark_complete", text: "Mark task as complete", priority: .high),
                AISuggestion(id: "add_notes", text: "Add completion notes", priority: .low)
            ]
        case .pendingTasks:
            return [
                AISuggestion(id: "prioritize", text: "Prioritize pending tasks", priority: .high),
                AISuggestion(id: "reschedule", text: "Reschedule if needed", priority: .medium)
            ]
        case .buildingArrival:
            return [
                AISuggestion(id: "clock_in", text: "Clock in at building", priority: .high),
                AISuggestion(id: "check_schedule", text: "Review today's schedule", priority: .medium)
            ]
        default:
            return [
                AISuggestion(id: "generic_action", text: "Take appropriate action", priority: .medium)
            ]
        }
    }
}

import Combine

@MainActor
class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()
    
    @Published var activeScenarios: [AIScenario] = []

    @Published var aiSuggestions: [AISuggestion] = []
    @Published var currentScenarioData: AIScenarioData? = nil
    @Published var hasActiveScenarios: Bool = false
    @Published var isProcessing: Bool = false
    @Published var contextualMessage: String = ""
    @Published var currentScenario: AIScenario? = nil
    @Published var avatarImage: String = "person.circle"
    @Published var suggestions: [AISuggestion] = []
    @Published var isAnalyzing = false
    
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    func analyzeWorkerContext() async {
        isAnalyzing = true
        
        // Get current worker context
        let workerId = contextEngine.getWorkerId()
        
        // Check if we have a valid worker ID
        if !workerId.isEmpty {
            let workerSummary = getWorkerSummary(workerId)
            await generateScenarios(from: workerSummary)
        }
        
        isAnalyzing = false
    }
    
    func refreshAnalysis() async {
        await analyzeWorkerContext()
    }
    
    private func setupBindings() {
        contextEngine.objectWillChange
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.analyzeWorkerContext()
                }
            }
            .store(in: &cancellables)
    }
    
    private func getWorkerSummary(_ workerId: String) -> WorkerSummary {
        let tasks = contextEngine.getTodaysTasks()
        let buildings = contextEngine.getAssignedBuildings()
        let completedTasks = tasks.filter { $0.status == "completed" }
        
        return WorkerSummary(
            workerId: workerId,
            totalTasks: tasks.count,
            completedTasks: completedTasks.count,
            assignedBuildings: buildings.count,
            dataHealth: assessDataHealth()
        )
    }
    
    private func assessDataHealth() -> DataHealthLevel {
        let tasks = contextEngine.getTodaysTasks()
        let buildings = contextEngine.getAssignedBuildings()
        
        if tasks.isEmpty || buildings.isEmpty {
            return .critical
        } else if tasks.count < 5 {
            return .warning
        } else {
            return .healthy
        }
    }
    
    private func generateScenarios(from summary: WorkerSummary) async {
        var scenarios: [AIScenario] = []
        
        // Scenario 1: Task completion guidance
        if summary.completedTasks < summary.totalTasks / 2 {
            let suggestions = [
                AISuggestion(
                    id: "suggest_priority",
                    text: "Focus on high-priority tasks first",
                    priority: .high
                ),
                AISuggestion(
                    id: "suggest_schedule",
                    text: "Review your schedule for today",
                    priority: .medium
                )
            ]
            
            scenarios.append(AIScenario(
                id: "incomplete_tasks",
                title: "Task Completion Guidance",
                description: "You have several tasks remaining today",
                suggestions: suggestions
            ))
        }
        
        // Scenario 2: Data health issues
        if summary.dataHealth == .critical {
            let suggestions = [
                AISuggestion(
                    id: "refresh_data",
                    text: "Refresh your task data",
                    priority: .urgent
                ),
                AISuggestion(
                    id: "check_assignments",
                    text: "Verify your building assignments",
                    priority: .high
                )
            ]
            
            scenarios.append(AIScenario(
                id: "data_issues",
                title: "Data Sync Issue",
                description: "Your task data may need refreshing",
                suggestions: suggestions
            ))
        }
        
        // Scenario 3: Productivity optimization
        if summary.completedTasks > 0 {
            let suggestions = [
                AISuggestion(
                    id: "route_optimize",
                    text: "Optimize your route between buildings",
                    priority: .medium
                ),
                AISuggestion(
                    id: "time_tracking",
                    text: "Track time for similar tasks",
                    priority: .low
                )
            ]
            
            scenarios.append(AIScenario(
                id: "productivity_tips",
                title: "Productivity Optimization",
                description: "Tips to improve your workflow",
                suggestions: suggestions
            ))
        }
        
        await MainActor.run {
            self.activeScenarios = scenarios
            self.suggestions = scenarios.flatMap { $0.suggestions }
        }
    }
    
    // MARK: - Scenario Management
        func addScenario(_ scenarioType: AIScenarioType) {
        let scenario = AIScenario()
        activeScenarios.append(scenario)
        hasActiveScenarios = !activeScenarios.isEmpty
        print("📱 Added AI scenario: \(scenarioType.rawValue)")
    }
    
    func dismissScenario(_ scenarioId: String) {
        activeScenarios.removeAll { $0.id == scenarioId }
        hasActiveScenarios = !activeScenarios.isEmpty
    }
    
    func clearAllScenarios() {
        activeScenarios.removeAll()
        suggestions.removeAll()
        hasActiveScenarios = false
        currentScenario = nil
        currentScenarioData = nil
    }
    
    private func generateSuggestions(for scenarioType: AIScenarioType) -> [AISuggestion] {
        switch scenarioType {
        case .routineIncomplete:
            return [
                AISuggestion(id: "check_tasks", text: "Review incomplete tasks", priority: .high),
                AISuggestion(id: "update_status", text: "Update task status", priority: .medium)
            ]
        case .taskCompletion:
            return [
                AISuggestion(id: "mark_complete", text: "Mark task as complete", priority: .high),
                AISuggestion(id: "add_notes", text: "Add completion notes", priority: .low)
            ]
        case .pendingTasks:
            return [
                AISuggestion(id: "prioritize", text: "Prioritize pending tasks", priority: .high),
                AISuggestion(id: "reschedule", text: "Reschedule if needed", priority: .medium)
            ]
        case .buildingArrival:
            return [
                AISuggestion(id: "clock_in", text: "Clock in at building", priority: .high),
                AISuggestion(id: "check_schedule", text: "Review today's schedule", priority: .medium)
            ]
        default:
            return [
                AISuggestion(id: "generic_action", text: "Take appropriate action", priority: .medium)
            ]
        }
    }
}

// MARK: - Supporting Types
private struct WorkerSummary {
    let workerId: String
    let totalTasks: Int
    let completedTasks: Int
    let assignedBuildings: Int
    let dataHealth: DataHealthLevel
    
    // MARK: - Scenario Management
        func addScenario(_ scenarioType: AIScenarioType) {
        let scenario = AIScenario()
        activeScenarios.append(scenario)
        hasActiveScenarios = !activeScenarios.isEmpty
        print("📱 Added AI scenario: \(scenarioType.rawValue)")
    }
    
    func dismissScenario(_ scenarioId: String) {
        activeScenarios.removeAll { $0.id == scenarioId }
        hasActiveScenarios = !activeScenarios.isEmpty
    }
    
    func clearAllScenarios() {
        activeScenarios.removeAll()
        suggestions.removeAll()
        hasActiveScenarios = false
        currentScenario = nil
        currentScenarioData = nil
    }
    
    private func generateSuggestions(for scenarioType: AIScenarioType) -> [AISuggestion] {
        switch scenarioType {
        case .routineIncomplete:
            return [
                AISuggestion(id: "check_tasks", text: "Review incomplete tasks", priority: .high),
                AISuggestion(id: "update_status", text: "Update task status", priority: .medium)
            ]
        case .taskCompletion:
            return [
                AISuggestion(id: "mark_complete", text: "Mark task as complete", priority: .high),
                AISuggestion(id: "add_notes", text: "Add completion notes", priority: .low)
            ]
        case .pendingTasks:
            return [
                AISuggestion(id: "prioritize", text: "Prioritize pending tasks", priority: .high),
                AISuggestion(id: "reschedule", text: "Reschedule if needed", priority: .medium)
            ]
        case .buildingArrival:
            return [
                AISuggestion(id: "clock_in", text: "Clock in at building", priority: .high),
                AISuggestion(id: "check_schedule", text: "Review today's schedule", priority: .medium)
            ]
        default:
            return [
                AISuggestion(id: "generic_action", text: "Take appropriate action", priority: .medium)
            ]
        }
    }
}

private enum DataHealthLevel {
    case healthy, warning, critical
    
    // MARK: - Scenario Management
        func addScenario(_ scenarioType: AIScenarioType) {
        let scenario = AIScenario()
        activeScenarios.append(scenario)
        hasActiveScenarios = !activeScenarios.isEmpty
        print("📱 Added AI scenario: \(scenarioType.rawValue)")
    }
    
    func dismissScenario(_ scenarioId: String) {
        activeScenarios.removeAll { $0.id == scenarioId }
        hasActiveScenarios = !activeScenarios.isEmpty
    }
    
    func clearAllScenarios() {
        activeScenarios.removeAll()
        suggestions.removeAll()
        hasActiveScenarios = false
        currentScenario = nil
        currentScenarioData = nil
    }
    
    private func generateSuggestions(for scenarioType: AIScenarioType) -> [AISuggestion] {
        switch scenarioType {
        case .routineIncomplete:
            return [
                AISuggestion(id: "check_tasks", text: "Review incomplete tasks", priority: .high),
                AISuggestion(id: "update_status", text: "Update task status", priority: .medium)
            ]
        case .taskCompletion:
            return [
                AISuggestion(id: "mark_complete", text: "Mark task as complete", priority: .high),
                AISuggestion(id: "add_notes", text: "Add completion notes", priority: .low)
            ]
        case .pendingTasks:
            return [
                AISuggestion(id: "prioritize", text: "Prioritize pending tasks", priority: .high),
                AISuggestion(id: "reschedule", text: "Reschedule if needed", priority: .medium)
            ]
        case .buildingArrival:
            return [
                AISuggestion(id: "clock_in", text: "Clock in at building", priority: .high),
                AISuggestion(id: "check_schedule", text: "Review today's schedule", priority: .medium)
            ]
        default:
            return [
                AISuggestion(id: "generic_action", text: "Take appropriate action", priority: .medium)
            ]
        }
    }
}

    
        func addScenario(_ scenarioType: AIScenarioType) {
        let scenario = AIScenario()
        activeScenarios.append(scenario)
        hasActiveScenarios = !activeScenarios.isEmpty
        print("📱 Added AI scenario: \(scenarioType.rawValue)")
    }
    
    func dismissCurrentScenario() {
        currentScenario = nil
        currentScenarioData = nil
    }
    
    func performAction(_ action: String) {
        print("Performing AI action: \(action)")
    }
