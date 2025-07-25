//
//
//  AIAssistantManager.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Aligned with actual CoreTypes.AISuggestion constructor
//  ✅ FIXED: Corrected AIScenario property access (using .scenario not missing properties)
//  ✅ FIXED: Corrected AIScenarioData property access (no .data property exists)
//  ✅ FIXED: Updated ScenarioType to match actual AIScenarioType enum cases
//  ✅ FIXED: Removed duplicate method declarations
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
    @Published var suggestions: [CoreTypes.AISuggestion] = []
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
        // ✅ FIXED: Use correct AIScenario constructor
        let scenario = AIScenario(
            scenario: scenarioType,
            description: "AI scenario: \(scenarioType)",
            priority: .medium
        )
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
    private func generateSuggestions(for scenarioType: String) -> [CoreTypes.AISuggestion] {
        switch scenarioType {
        case ScenarioType.routineIncomplete:
            return [
                CoreTypes.AISuggestion(
                    title: "Review Incomplete Tasks",
                    description: "Check which routine tasks need attention",
                    priority: .medium,
                    category: .operations
                ),
                CoreTypes.AISuggestion(
                    title: "Update Status",
                    description: "Mark completed tasks as done",
                    priority: .low,
                    category: .operations
                )
            ]
        
        case ScenarioType.pendingTasks:
            return [
                CoreTypes.AISuggestion(
                    title: "Prioritize Tasks",
                    description: "Organize tasks by urgency and importance",
                    priority: .high,
                    category: .operations
                ),
                CoreTypes.AISuggestion(
                    title: "Reschedule Tasks",
                    description: "Adjust timeline for pending work",
                    priority: .medium,
                    category: .operations
                )
            ]
        
        case ScenarioType.weatherAlert:
            return [
                CoreTypes.AISuggestion(
                    title: "Check Weather Impact",
                    description: "Review how weather affects scheduled tasks",
                    priority: .high,
                    category: .safety
                ),
                CoreTypes.AISuggestion(
                    title: "Adjust Schedule",
                    description: "Move outdoor tasks to indoor alternatives",
                    priority: .medium,
                    category: .operations
                )
            ]
        
        case ScenarioType.clockOutReminder:
            return [
                CoreTypes.AISuggestion(
                    title: "Clock Out",
                    description: "Remember to clock out when finished",
                    priority: .medium,
                    category: .operations
                )
            ]
        
        case ScenarioType.inventoryLow:
            return [
                CoreTypes.AISuggestion(
                    title: "Order Supplies",
                    description: "Restock low inventory items",
                    priority: .medium,
                    category: .operations
                ),
                CoreTypes.AISuggestion(
                    title: "Check Alternatives",
                    description: "Find substitute materials if available",
                    priority: .low,
                    category: .operations
                )
            ]
        
        case ScenarioType.emergencyRepair:
            return [
                CoreTypes.AISuggestion(
                    title: "Emergency Protocol",
                    description: "Follow emergency repair procedures",
                    priority: .critical,
                    category: .safety
                ),
                CoreTypes.AISuggestion(
                    title: "Contact Support",
                    description: "Get immediate assistance for emergency",
                    priority: .critical,
                    category: .safety
                )
            ]
        
        case ScenarioType.taskOverdue:
            return [
                CoreTypes.AISuggestion(
                    title: "Immediate Action",
                    description: "Address overdue tasks immediately",
                    priority: .high,
                    category: .operations
                ),
                CoreTypes.AISuggestion(
                    title: "Notify Supervisor",
                    description: "Inform about overdue status",
                    priority: .medium,
                    category: .operations
                )
            ]
        
        case ScenarioType.buildingAlert:
            return [
                CoreTypes.AISuggestion(
                    title: "Investigate Alert",
                    description: "Check building status and resolve issues",
                    priority: .high,
                    category: .operations
                ),
                CoreTypes.AISuggestion(
                    title: "Document Findings",
                    description: "Record any issues discovered",
                    priority: .medium,
                    category: .operations
                )
            ]
        
        default:
            return [
                CoreTypes.AISuggestion(
                    title: "General Assistance",
                    description: "Nova AI is here to help",
                    priority: .low,
                    category: .operations
                )
            ]
        }
    }
    
    // MARK: - Scenario Processing
    func processScenario(_ scenario: AIScenario) {
        isProcessing = true
        currentScenario = scenario
        // ✅ FIXED: Use .scenario property (exists in AIScenario)
        suggestions = generateSuggestions(for: scenario.scenario)
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isProcessing = false
        }
    }
    
    func processScenarioData(_ data: AIScenarioData) {
        currentScenarioData = data
        
        // ✅ FIXED: AIScenarioData has .message property, not .data
        // Generate contextual suggestions based on scenario message
        if let message = currentScenarioData?.message {
            suggestions = generateContextualSuggestions(for: message)
        }
    }
    
    private func generateContextualSuggestions(for context: String) -> [CoreTypes.AISuggestion] {
        // Simple context-based suggestion generation
        switch context.lowercased() {
        case let ctx where ctx.contains("weather"):
            return [
                CoreTypes.AISuggestion(
                    title: "Weather Check",
                    description: "Review weather conditions for work planning",
                    priority: .medium,
                    category: .safety
                ),
                CoreTypes.AISuggestion(
                    title: "Reschedule",
                    description: "Adjust schedule based on weather",
                    priority: .low,
                    category: .operations
                )
            ]
        case let ctx where ctx.contains("maintenance"):
            return [
                CoreTypes.AISuggestion(
                    title: "Review",
                    description: "Review maintenance requirements",
                    priority: .medium,
                    category: .maintenance
                ),
                CoreTypes.AISuggestion(
                    title: "Check",
                    description: "Perform maintenance check",
                    priority: .high,
                    category: .maintenance
                )
            ]
        case let ctx where ctx.contains("task"):
            return [
                CoreTypes.AISuggestion(
                    title: "Update",
                    description: "Update task information",
                    priority: .medium,
                    category: .operations
                ),
                CoreTypes.AISuggestion(
                    title: "Complete",
                    description: "Mark task as complete",
                    priority: .high,
                    category: .operations
                )
            ]
        default:
            return [
                CoreTypes.AISuggestion(
                    title: "Review",
                    description: "Review current situation",
                    priority: .low,
                    category: .operations
                )
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
        // ✅ FIXED: Use .scenario property
        return activeScenarios.contains { $0.scenario == type }
    }
    
    func getActiveScenarios(ofType type: String) -> [AIScenario] {
        // ✅ FIXED: Use .scenario property
        return activeScenarios.filter { $0.scenario == type }
    }
    
    // MARK: - Debug Methods
    func debugPrintStatus() {
        print("🤖 AI Assistant Status:")
        print("  Active scenarios: \(activeScenarios.count)")
        // ✅ FIXED: Use .scenario property
        print("  Current scenario: \(currentScenario?.scenario ?? "None")")
        print("  Suggestions: \(suggestions.count)")
        print("  Processing: \(isProcessing)")
    }
}

// MARK: - ✅ FIXED: Updated Scenario Types to match actual AIScenarioType enum
extension AIAssistantManager {
    enum ScenarioType {
        // ✅ FIXED: These match the actual AIScenarioType cases from AIScenarioSheetView.swift
        static let routineIncomplete = "routine_incomplete"
        static let pendingTasks = "pending_tasks"
        static let weatherAlert = "weather_alert"
        static let clockOutReminder = "clock_out_reminder"
        static let inventoryLow = "inventory_low"
        static let emergencyRepair = "emergency_repair"
        static let taskOverdue = "task_overdue"
        static let buildingAlert = "building_alert"
    }
}
