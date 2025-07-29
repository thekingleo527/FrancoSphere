//
//  AIAssistantManager.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: No duplicate types or conflicting definitions
//  ✅ FIXED: Proper switch statement structure
//  ✅ FIXED: Using correct CoreTypes.AIScenario properties
//  ✅ ALIGNED: Works alongside NovaAIContextManager
//
//  This manager handles simple AI scenario tracking and suggestions,
//  while NovaAIContextManager handles the more sophisticated context-aware AI features.
//

import Foundation
import SwiftUI
import Combine

/// Simple AI Assistant Manager for scenario tracking
/// Works alongside the more sophisticated NovaAIContextManager
@MainActor
class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()
    
    // MARK: - Published Properties
    @Published var activeScenarios: [CoreTypes.AIScenario] = []
    @Published var hasActiveScenarios: Bool = false
    @Published var suggestions: [CoreTypes.AISuggestion] = []
    @Published var currentScenario: CoreTypes.AIScenario?
    @Published var currentScenarioContext: [String: Any] = [:]  // Generic context storage
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
        // Convert string to AIScenarioType
        guard let type = mapStringToScenarioType(scenarioType) else {
            print("⚠️ Unknown scenario type: \(scenarioType)")
            return
        }
        
        // Use correct AIScenario constructor
        let scenario = CoreTypes.AIScenario(
            type: type,
            title: generateTitle(for: type),
            description: generateDescription(for: type)
        )
        
        activeScenarios.append(scenario)
        hasActiveScenarios = !activeScenarios.isEmpty
        print("📱 Added AI scenario: \(scenario.title)")
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
        currentScenarioContext.removeAll()
    }
    
    // MARK: - Helper Methods
    
    private func mapStringToScenarioType(_ string: String) -> CoreTypes.AIScenarioType? {
        switch string {
        case "clock_out_reminder":
            return .clockOutReminder
        case "weather_alert":
            return .weatherAlert
        case "inventory_low":
            return .inventoryLow
        case "routine_incomplete":
            return .routineIncomplete
        case "pending_tasks":
            return .pendingTasks
        case "emergency_repair":
            return .emergencyRepair
        case "task_overdue":
            return .taskOverdue
        case "building_alert":
            return .buildingAlert
        default:
            return nil
        }
    }
    
    private func generateTitle(for type: CoreTypes.AIScenarioType) -> String {
        switch type {
        case .clockOutReminder:
            return "Clock Out Reminder"
        case .weatherAlert:
            return "Weather Alert"
        case .inventoryLow:
            return "Low Inventory"
        case .routineIncomplete:
            return "Incomplete Routine"
        case .pendingTasks:
            return "Pending Tasks"
        case .emergencyRepair:
            return "Emergency Repair"
        case .taskOverdue:
            return "Overdue Task"
        case .buildingAlert:
            return "Building Alert"
        }
    }
    
    private func generateDescription(for type: CoreTypes.AIScenarioType) -> String {
        switch type {
        case .clockOutReminder:
            return "Remember to clock out when your shift ends"
        case .weatherAlert:
            return "Weather conditions may affect work schedule"
        case .inventoryLow:
            return "Supplies running low and need restocking"
        case .routineIncomplete:
            return "Some routine tasks haven't been completed"
        case .pendingTasks:
            return "You have tasks waiting for completion"
        case .emergencyRepair:
            return "Urgent repair needed immediately"
        case .taskOverdue:
            return "Task is past its due date"
        case .buildingAlert:
            return "Building requires attention"
        }
    }
    
    // MARK: - Suggestion Generation
    private func generateSuggestions(for type: CoreTypes.AIScenarioType) -> [CoreTypes.AISuggestion] {
        switch type {
        case .routineIncomplete:
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
        
        case .pendingTasks:
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
        
        case .weatherAlert:
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
        
        case .clockOutReminder:
            return [
                CoreTypes.AISuggestion(
                    title: "Clock Out",
                    description: "Remember to clock out when finished",
                    priority: .medium,
                    category: .operations
                )
            ]
        
        case .inventoryLow:
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
        
        case .emergencyRepair:
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
        
        case .taskOverdue:
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
        
        case .buildingAlert:
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
        }
    }
    
    // MARK: - Scenario Processing
    func processScenario(_ scenario: CoreTypes.AIScenario) {
        isProcessing = true
        currentScenario = scenario
        suggestions = generateSuggestions(for: scenario.type)
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isProcessing = false
        }
    }
    
    // Process additional context for scenarios
    func processScenarioContext(_ context: [String: Any]) {
        currentScenarioContext = context
        
        // Generate contextual suggestions based on context message
        if let message = context["message"] as? String {
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
        currentScenarioContext.removeAll()
        suggestions.removeAll()
    }
    
    func hasActiveScenario(ofType type: CoreTypes.AIScenarioType) -> Bool {
        return activeScenarios.contains { $0.type == type }
    }
    
    func getActiveScenarios(ofType type: CoreTypes.AIScenarioType) -> [CoreTypes.AIScenario] {
        return activeScenarios.filter { $0.type == type }
    }
    
    // MARK: - Debug Methods
    func debugPrintStatus() {
        print("🤖 AI Assistant Status:")
        print("  Active scenarios: \(activeScenarios.count)")
        print("  Current scenario: \(currentScenario?.type.rawValue ?? "None")")
        print("  Suggestions: \(suggestions.count)")
        print("  Processing: \(isProcessing)")
    }
    
    // MARK: - Context Helpers
    
    /// Get typed value from scenario context
    func getContextValue<T>(_ key: String, as type: T.Type) -> T? {
        return currentScenarioContext[key] as? T
    }
    
    /// Update scenario context
    func updateContext(key: String, value: Any) {
        currentScenarioContext[key] = value
    }
}
