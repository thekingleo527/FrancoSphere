//
//  AIAssistantManager.swift
//  FrancoSphere
//
//  ✅ FIXED: Proper structure with shared instance
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


@MainActor
class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()
    
    @Published var activeScenarios: [AIScenario] = []
    @Published var currentSuggestions: [FrancoSphere.AISuggestion] = []
    @Published var isProcessing = false
    @Published var dataHealthStatus: FrancoSphere.DataHealthStatus = .unknown
    
    private var contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var lastKevinBuildingCheck = Date.distantPast
    private var lastTaskPipelineCheck = Date.distantPast
    
    private init() {
        setupReactiveListening()
    }
    
    func generateIntelligentScenarios() async {
        guard let workerId = NewAuthManager.shared.workerId else { return }
        
        isProcessing = true
        
        // Get current worker context
        let healthReport = contextEngine.getWorkerContextSummary()
        await processHealthReport(healthReport, workerId: workerId)
        
        isProcessing = false
    }
    
    private func setupReactiveListening() {
        contextEngine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.generateIntelligentScenarios()
                }
            }
            .store(in: &cancellables)
    }
    
    private func processHealthReport(_ healthReport: [String: Any], workerId: String) async {
        let workerName = healthReport["workerName"] as? String ?? ""
        let buildingsAssigned = healthReport["buildingCount"] as? Int ?? 0
        let tasksLoaded = healthReport["taskCount"] as? Int ?? 0
        let hasError = healthReport["hasError"] as? Bool ?? false
        
        let newHealthStatus = determineHealthStatus(
            workerId: workerId,
            buildings: buildingsAssigned,
            tasks: tasksLoaded,
            hasError: hasError
        )
        
        self.dataHealthStatus = newHealthStatus
        
        if newHealthStatus == .critical {
            await generateIntelligentDataScenario(
                workerId: workerId,
                workerName: workerName,
                buildings: buildingsAssigned,
                tasks: tasksLoaded,
                hasError: hasError
            )
        }
    }
    
    private func determineHealthStatus(workerId: String, buildings: Int, tasks: Int, hasError: Bool) -> FrancoSphere.DataHealthStatus {
        if workerId == "4" && buildings == 0 {
            return .critical(["Kevin missing building assignments"])
        }
        if buildings > 0 && tasks == 0 {
            return .critical(["No tasks loaded"])
        }
        if hasError {
            return .critical(["System error detected"])
        }
        if buildings == 0 {
            return .warning(["No buildings assigned"])
        }
        if tasks < 2 && buildings > 2 {
            return .warning(["Low task count"])
        }
        if buildings > 0 && tasks > 0 {
            return .healthy
        }
        return .unknown
    }
    
    private func generateIntelligentDataScenario(workerId: String, workerName: String, buildings: Int, tasks: Int, hasError: Bool) async {
        // Kevin's critical building assignment failure
        if workerId == "4" && buildings == 0 {
            let currentTime = Date()
            if currentTime.timeIntervalSince(lastKevinBuildingCheck) > 300 {
                lastKevinBuildingCheck = currentTime
                await generateKevinCriticalScenario()
            }
            return
        }
        
        // Task pipeline failure
        if buildings > 0 && tasks == 0 {
            let currentTime = Date()
            if currentTime.timeIntervalSince(lastTaskPipelineCheck) > 180 {
                lastTaskPipelineCheck = currentTime
                await generateTaskPipelineFailureScenario(workerName: workerName, buildingCount: buildings)
            }
            return
        }
    }
    
    private func generateKevinCriticalScenario() async {
        let suggestion = FrancoSphere.AISuggestion(
            title: "Kevin's Building Assignments Missing",
            message: "Critical: Kevin should have 6+ buildings including Rubin Museum. System data issue detected.",
            actionType: "refresh_data",
            priority: 1
        )
        
        currentSuggestions.append(suggestion)
        activeScenarios.append(.routineIncomplete)
    }
    
    private func generateTaskPipelineFailureScenario(workerName: String, buildingCount: Int) async {
        let suggestion = FrancoSphere.AISuggestion(
            title: "Task Pipeline Issue",
            message: "\(workerName) has \(buildingCount) buildings but no tasks loaded. Check task generation.",
            actionType: "reload_tasks",
            priority: 2
        )
        
        currentSuggestions.append(suggestion)
        activeScenarios.append(.pendingTasks)
    }
}

// MARK: - QuickBooks Integration Support
