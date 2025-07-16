//
//  AIAssistantManager.swift
//  FrancoSphere
//
//  ✅ FIXED: Updated to match actual simple model definitions
//  ✅ All constructors corrected to use simple parameters
//  ✅ Properties updated to match actual model structure
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()
    
    // MARK: - Published Properties
    @Published var activeScenarios: [AIScenario] = []
    @Published var hasActiveScenarios: Bool = false
    @Published var suggestions: [AISuggestion] = []
    @Published var currentScenario: AIScenario?
    @Published var currentScenarioData: AIScenarioData?
    @Published var isProcessing: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        $activeScenarios
            .map { !$0.isEmpty }
            .sink { [weak self] hasScenarios in
                self?.hasActiveScenarios = hasScenarios
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Scenario Management
    func addScenario(_ scenarioType: String) {
        let scenario = AIScenario(scenario: scenarioType)
        activeScenarios.append(scenario)
        hasActiveScenarios = !activeScenarios.isEmpty
        print("📱 Added AI scenario: \(scenarioType)")
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
    
    // MARK: - Suggestion Generation
    private func generateSuggestions(for scenarioType: String) -> [AISuggestion] {
        switch scenarioType {
        case "routineIncomplete":
            return [
                AISuggestion(suggestion: "review"),
                AISuggestion(suggestion: "update")
            ]
        case "taskCompletion":
            return [
                AISuggestion(suggestion: "complete"),
                AISuggestion(suggestion: "notes")
            ]
        case "pendingTasks":
            return [
                AISuggestion(suggestion: "prioritize"),
                AISuggestion(suggestion: "reschedule")
            ]
        case "buildingArrival":
            return [
                AISuggestion(suggestion: "checkin"),
                AISuggestion(suggestion: "schedule")
            ]
        case "weatherAlert":
            return [
                AISuggestion(suggestion: "weather"),
                AISuggestion(suggestion: "adjust")
            ]
        case "maintenanceRequired":
            return [
                AISuggestion(suggestion: "schedule"),
                AISuggestion(suggestion: "order")
            ]
        case "scheduleConflict":
            return [
                AISuggestion(suggestion: "resolve"),
                AISuggestion(suggestion: "notify")
            ]
        case "emergencyResponse":
            return [
                AISuggestion(suggestion: "emergency"),
                AISuggestion(suggestion: "contact")
            ]
        default:
            return [
                AISuggestion(suggestion: "general")
            ]
        }
    }
    
    // MARK: - Scenario Processing
    func processScenario(_ scenario: AIScenario) {
        isProcessing = true
        currentScenario = scenario
        suggestions = generateSuggestions(for: scenario.scenario)
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isProcessing = false
        }
    }
    
    func processScenarioData(_ data: AIScenarioData) {
        currentScenarioData = data
        
        // Generate contextual suggestions based on scenario data
        if let context = currentScenarioData?.data {
            suggestions = generateContextualSuggestions(for: context)
        }
    }
    
    private func generateContextualSuggestions(for context: String) -> [AISuggestion] {
        // Simple context-based suggestion generation
        switch context.lowercased() {
        case let ctx where ctx.contains("weather"):
            return [
                AISuggestion(suggestion: "weather"),
                AISuggestion(suggestion: "reschedule")
            ]
        case let ctx where ctx.contains("maintenance"):
            return [
                AISuggestion(suggestion: "review"),
                AISuggestion(suggestion: "check")
            ]
        case let ctx where ctx.contains("task"):
            return [
                AISuggestion(suggestion: "update"),
                AISuggestion(suggestion: "complete")
            ]
        default:
            return [
                AISuggestion(suggestion: "review")
            ]
        }
    }
    
    // MARK: - Action Handling
    func performAction(_ actionType: String) {
        print("🤖 AI Assistant performing action: \(actionType)")
        
        switch actionType {
        case "review":
            print("📋 Reviewing current status...")
        case "update":
            print("🔄 Updating information...")
        case "complete":
            print("✅ Marking as complete...")
        case "schedule":
            print("📅 Scheduling task...")
        case "weather":
            print("🌤️ Checking weather conditions...")
        case "emergency":
            print("🚨 Following emergency protocol...")
        case "checkin":
            print("🏢 Checking in at building...")
        case "notes":
            print("📝 Adding notes...")
        case "prioritize":
            print("⚡ Prioritizing tasks...")
        case "reschedule":
            print("📅 Rescheduling tasks...")
        case "adjust":
            print("🔧 Adjusting tasks...")
        case "order":
            print("📦 Ordering supplies...")
        case "resolve":
            print("⚖️ Resolving conflicts...")
        case "notify":
            print("📢 Sending notifications...")
        case "contact":
            print("📞 Contacting support...")
        case "check":
            print("🔍 Performing check...")
        default:
            print("🔧 Performing general action...")
        }
    }
    
    // MARK: - Utility Methods
    func dismissCurrentScenario() {
        currentScenario = nil
        currentScenarioData = nil
        suggestions.removeAll()
    }
    
    func hasActiveScenario(ofType type: String) -> Bool {
        return activeScenarios.contains { $0.scenario == type }
    }
    
    func getActiveScenarios(ofType type: String) -> [AIScenario] {
        return activeScenarios.filter { $0.scenario == type }
    }
    
    // MARK: - Debug Methods
    func debugPrintStatus() {
        print("🤖 AI Assistant Status:")
        print("  Active scenarios: \(activeScenarios.count)")
        print("  Current scenario: \(currentScenario?.scenario ?? "None")")
        print("  Suggestions: \(suggestions.count)")
        print("  Processing: \(isProcessing)")
    }
}

// MARK: - Scenario Types Extension
extension AIAssistantManager {
    enum ScenarioType {
        static let routineIncomplete = "routineIncomplete"
        static let taskCompletion = "taskCompletion"
        static let pendingTasks = "pendingTasks"
        static let buildingArrival = "buildingArrival"
        static let weatherAlert = "weatherAlert"
        static let maintenanceRequired = "maintenanceRequired"
        static let scheduleConflict = "scheduleConflict"
        static let emergencyResponse = "emergencyResponse"
    }
}
