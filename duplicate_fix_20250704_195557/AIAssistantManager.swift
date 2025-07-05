//
//  AIAssistantManager.swift
//  FrancoSphere
//
//  Fixed version with proper type handling
//

import Foundation
import Combine

@MainActor
class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()
    
    @Published var activeScenarios: [FrancoSphere.AIScenario] = []
    @Published var suggestions: [FrancoSphere.AISuggestion] = []
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
        var scenarios: [FrancoSphere.AIScenario] = []
        
        // Scenario 1: Task completion guidance
        if summary.completedTasks < summary.totalTasks / 2 {
            let suggestions = [
                FrancoSphere.AISuggestion(
                    id: "suggest_priority",
                    text: "Focus on high-priority tasks first",
                    priority: .high
                ),
                FrancoSphere.AISuggestion(
                    id: "suggest_schedule",
                    text: "Review your schedule for today",
                    priority: .medium
                )
            ]
            
            scenarios.append(FrancoSphere.AIScenario(
                id: "incomplete_tasks",
                title: "Task Completion Guidance",
                description: "You have several tasks remaining today",
                suggestions: suggestions
            ))
        }
        
        // Scenario 2: Data health issues
        if summary.dataHealth == .critical {
            let suggestions = [
                FrancoSphere.AISuggestion(
                    id: "refresh_data",
                    text: "Refresh your task data",
                    priority: .urgent
                ),
                FrancoSphere.AISuggestion(
                    id: "check_assignments",
                    text: "Verify your building assignments",
                    priority: .high
                )
            ]
            
            scenarios.append(FrancoSphere.AIScenario(
                id: "data_issues",
                title: "Data Sync Issue",
                description: "Your task data may need refreshing",
                suggestions: suggestions
            ))
        }
        
        // Scenario 3: Productivity optimization
        if summary.completedTasks > 0 {
            let suggestions = [
                FrancoSphere.AISuggestion(
                    id: "route_optimize",
                    text: "Optimize your route between buildings",
                    priority: .medium
                ),
                FrancoSphere.AISuggestion(
                    id: "time_tracking",
                    text: "Track time for similar tasks",
                    priority: .low
                )
            ]
            
            scenarios.append(FrancoSphere.AIScenario(
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
}

// MARK: - Supporting Types
private struct WorkerSummary {
    let workerId: String
    let totalTasks: Int
    let completedTasks: Int
    let assignedBuildings: Int
    let dataHealth: DataHealthLevel
}

private enum DataHealthLevel {
    case healthy, warning, critical
}
