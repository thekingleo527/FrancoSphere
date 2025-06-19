// FILE: AIAssistantManager.swift
//
//  AIAssistantManager.swift
//  FrancoSphere
//
//  🤖 AI ASSISTANT MANAGER (PHASE-2) - FIXED VERSION
//  ✅ FIXED: Interface compatibility with AIAvatarOverlayView
//  ✅ FIXED: Added missing AIScenarioData struct and properties
//  ✅ FIXED: ContextualTask property access (.status instead of .isCompleted)
//  ✅ FIXED: Added missing methods (performAction, dismissCurrentScenario)
//  ✅ FIXED: Moved addScenario method to proper class level
//  ✅ Building type references use FrancoSphere.NamedCoordinate
//  ✅ Generates contextual scenarios based on worker status, tasks, and weather
//

import Foundation
import SwiftUI
import Combine

// MARK: - AIScenarioData Struct (MISSING TYPE - ADDED)

struct AIScenarioData: Identifiable {
    let id = UUID()
    let scenario: FrancoSphere.AIScenario
    let title: String
    let message: String
    let icon: String
    let actionText: String
    let timestamp: Date
    
    init(scenario: FrancoSphere.AIScenario, message: String, actionText: String = "Take Action") {
        self.scenario = scenario
        self.title = scenario.title
        self.message = message
        self.icon = scenario.icon
        self.actionText = actionText
        self.timestamp = Date()
    }
}

@MainActor
class AIAssistantManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AIAssistantManager()
    
    // MARK: - Published Properties (FIXED: Added missing properties for AIAvatarOverlayView)
    @Published var currentScenario: FrancoSphere.AIScenario?
    @Published var currentScenarioData: AIScenarioData? // ✅ ADDED: Missing property
    @Published var scenarioQueue: [AIScenarioData] = [] // ✅ ADDED: Missing property
    @Published var isProcessingVoice = false
    @Published var isProcessing = false
    @Published var lastInteractionTime: Date?
    @Published var aiSuggestions: [AISuggestion] = []
    @Published var contextualMessage: String = ""
    
    // ✅ ADDED: Missing computed property
    var hasActiveScenarios: Bool {
        currentScenarioData != nil || !scenarioQueue.isEmpty
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let maxScenarioAge: TimeInterval = 300 // 5 minutes
    
    private init() {
        setupPeriodicContextCheck()
    }
    
    // MARK: - ✅ FIXED: Add Scenario Method (MOVED TO PROPER CLASS LEVEL)
    
    func addScenario(_ scenario: FrancoSphere.AIScenario,
                     buildingName: String? = nil,
                     taskCount: Int? = nil) {
        
        // Create appropriate message based on scenario
        let message: String
        let actionText: String
        
        switch scenario {
        case .routineIncomplete:
            message = "You have \(taskCount ?? 0) routine tasks pending at \(buildingName ?? "the building"). Would you like to review them?"
            actionText = "View Tasks"
            
        case .pendingTasks:
            message = "You have \(taskCount ?? 0) tasks scheduled for today. Let's prioritize the urgent ones."
            actionText = "Show Tasks"
            
        case .weatherAlert:
            message = "Weather conditions may affect outdoor tasks at \(buildingName ?? "the building")."
            actionText = "View Weather"
            
        case .buildingArrival:
            message = "Welcome to \(buildingName ?? "this building")! Ready to clock in?"
            actionText = "Clock In"
            
        case .clockOutReminder:
            message = "Don't forget to clock out when you're finished."
            actionText = "Clock Out"
            
        case .taskCompletion:
            message = "Great job! Keep up the excellent work."
            actionText = "Next Task"
            
        case .missingPhoto:
            message = "Some tasks require photo verification."
            actionText = "Add Photos"
            
        case .inventoryLow:
            message = "Inventory check needed at \(buildingName ?? "the building")."
            actionText = "Check Inventory"
        }
        
        // Create scenario data
        let scenarioData = AIScenarioData(
            scenario: scenario,
            message: message,
            actionText: actionText
        )
        
        // Update state
        self.currentScenario = scenario
        self.currentScenarioData = scenarioData
        self.lastInteractionTime = Date()
        
        print("🤖 AI Scenario Added: \(scenario.rawValue) - \(message)")
    }
    
    // MARK: - 🚀 MAIN CONTEXTUAL SCENARIO GENERATION
    
    /// Generates contextual AI scenario based on current worker state
    func generateContextualScenario(
        clockedIn: Bool,
        currentTasks: [ContextualTask],
        overdueCount: Int,
        currentBuilding: FrancoSphere.NamedCoordinate?,  // 🔧 FIXED: Use NamedCoordinate
        weatherRisk: String = "Low"
    ) async {
        
        // Check if we need a new scenario
        guard shouldGenerateNewScenario() else { return }
        
        var scenario: FrancoSphere.AIScenario?
        var message = ""
        var actionText = "Take Action"
        
        // Priority 1: Weather alerts for outdoor work
        if weatherRisk != "Low" {
            let hasOutdoorTasks = currentTasks.contains { task in
                task.name.lowercased().contains("sidewalk") ||
                task.name.lowercased().contains("curb") ||
                task.name.lowercased().contains("roof") ||
                task.name.lowercased().contains("trash area")
            }
            
            if hasOutdoorTasks {
                scenario = .weatherAlert
                message = "Weather conditions may affect outdoor tasks. Consider indoor work first."
                actionText = "View Indoor Tasks"
            }
        }
        
        // Priority 2: Clock out reminder for end of shift
        if clockedIn && isEndOfShift() {
            scenario = .clockOutReminder
            message = "Shift ending soon. Don't forget to clock out when you're finished."
            actionText = "Clock Out Now"
        }
        
        // Priority 3: Overdue tasks
        else if overdueCount > 0 {
            scenario = .pendingTasks
            message = "You have \(overdueCount) overdue task\(overdueCount == 1 ? "" : "s") that need attention."
            actionText = "View Overdue Tasks"
        }
        
        // Priority 4: Building arrival assistance
        else if let building = currentBuilding, !clockedIn {
            scenario = .buildingArrival
            message = "Welcome to \(building.name)! Ready to clock in and see your tasks?"
            actionText = "Clock In"
        }
        
        // Priority 5: Incomplete routine check
        else if clockedIn && hasIncompleteRoutine(tasks: currentTasks) {
            scenario = .routineIncomplete
            message = "Some routine tasks are still pending. Let me help you prioritize."
            actionText = "View Routine Tasks"
        }
        
        // Priority 6: Task completion encouragement
        else if clockedIn && currentTasks.allSatisfy({ $0.status == "completed" }) && !currentTasks.isEmpty {
            scenario = .taskCompletion
            message = "Excellent work! All tasks completed. Consider checking for additional work."
            actionText = "Find More Work"
        }
        
        // Priority 7: Missing photo reminder
        else if hasTasksNeedingPhotos(tasks: currentTasks) {
            scenario = .missingPhoto
            message = "Some completed tasks require before/after photos for verification."
            actionText = "Add Photos"
        }
        
        // Priority 8: Inventory check
        else if shouldCheckInventory() {
            scenario = .inventoryLow
            message = "Time for an inventory check. Some supplies may be running low."
            actionText = "Check Inventory"
        }
        
        // ✅ FIXED: Create AIScenarioData if we have a scenario
        if let scenario = scenario {
            let scenarioData = AIScenarioData(
                scenario: scenario,
                message: message,
                actionText: actionText
            )
            
            // Update both properties for compatibility
            self.currentScenario = scenario
            self.currentScenarioData = scenarioData
        } else {
            self.currentScenario = nil
            self.currentScenarioData = nil
        }
        
        // Generate AI suggestions based on scenario
        await generateAISuggestions(for: scenario, tasks: currentTasks, building: currentBuilding)
        
        // Update state
        self.contextualMessage = message
        self.lastInteractionTime = Date()
        
        print("🤖 AI Scenario Generated: \(scenario?.rawValue ?? "None") - \(message)")
    }
    // MARK: - AI Suggestions Generation
    
    private func generateAISuggestions(
        for scenario: FrancoSphere.AIScenario?,
        tasks: [ContextualTask],
        building: FrancoSphere.NamedCoordinate?  // 🔧 FIXED: Use NamedCoordinate
    ) async {
        
        var suggestions: [AISuggestion] = []
        
        switch scenario {
        case .weatherAlert:
            suggestions = [
                AISuggestion(
                    id: "weather_indoor",
                    title: "Prioritize Indoor Tasks",
                    description: "Start with lobby cleaning and elevator maintenance",
                    icon: "house.fill",
                    priority: .high
                ),
                AISuggestion(
                    id: "weather_check",
                    title: "Check Weather Updates",
                    description: "Monitor conditions before outdoor work",
                    icon: "cloud.sun.fill",
                    priority: .medium
                )
            ]
            
        case .routineIncomplete:
            let incompleteTasks = tasks.filter { $0.status != "completed" } // ✅ FIXED: Use .status
            suggestions = incompleteTasks.prefix(3).map { task in
                AISuggestion(
                    id: "task_\(task.id)",
                    title: "Complete \(task.name)",
                    description: "Due: \(formatTaskTime(task.startTime ?? ""))",
                    icon: task.category.lowercased().contains("clean") ? "sparkles" : "wrench.and.screwdriver",
                    priority: task.urgencyLevel.lowercased() == "high" ? .high : .medium
                )
            }
            
        case .buildingArrival:
            if let building = building {
                suggestions = [
                    AISuggestion(
                        id: "clock_in",
                        title: "Clock In",
                        description: "Start your shift at \(building.name)",
                        icon: "clock.arrow.circlepath",
                        priority: .high
                    ),
                    AISuggestion(
                        id: "view_tasks",
                        title: "View Today's Tasks",
                        description: "See what's scheduled for this building",
                        icon: "list.bullet.clipboard",
                        priority: .medium
                    )
                ]
            }
            
        case .pendingTasks:
            let urgentTasks = tasks.filter { $0.status != "completed" && $0.urgencyLevel.lowercased() == "high" } // ✅ FIXED: Use .urgencyLevel
            suggestions = urgentTasks.prefix(2).map { task in
                AISuggestion(
                    id: "urgent_\(task.id)",
                    title: "Priority: \(task.name)",
                    description: "High priority task at \(task.buildingName)",
                    icon: "exclamationmark.triangle.fill",
                    priority: .high
                )
            }
            
        case .taskCompletion:
            suggestions = [
                AISuggestion(
                    id: "next_building",
                    title: "Check Next Building",
                    description: "Look for additional work nearby",
                    icon: "building.2.crop.circle.badge.plus",
                    priority: .medium
                ),
                AISuggestion(
                    id: "early_completion",
                    title: "Report Early Completion",
                    description: "Let management know you're ahead of schedule",
                    icon: "checkmark.seal.fill",
                    priority: .low
                )
            ]
            
        case .missingPhoto:
            let tasksNeedingPhotos = tasks.filter { $0.status == "completed" && needsPhotoVerification($0) } // ✅ FIXED: Use .status
            suggestions = tasksNeedingPhotos.prefix(2).map { task in
                AISuggestion(
                    id: "photo_\(task.id)",
                    title: "Add Photo for \(task.name)",
                    description: "Upload before/after photo for verification",
                    icon: "camera.fill",
                    priority: .medium
                )
            }
            
        case .clockOutReminder:
            suggestions = [
                AISuggestion(
                    id: "clock_out",
                    title: "Clock Out",
                    description: "End your shift and log hours",
                    icon: "clock.badge.checkmark",
                    priority: .high
                ),
                AISuggestion(
                    id: "final_check",
                    title: "Final Building Check",
                    description: "Ensure all areas are secure",
                    icon: "checkmark.circle.fill",
                    priority: .medium
                )
            ]
            
        case .inventoryLow:
            suggestions = [
                AISuggestion(
                    id: "check_supplies",
                    title: "Check Supply Levels",
                    description: "Review cleaning supplies and tools",
                    icon: "shippingbox.fill",
                    priority: .medium
                ),
                AISuggestion(
                    id: "request_restock",
                    title: "Request Restocking",
                    description: "Submit supply requests if needed",
                    icon: "plus.circle.fill",
                    priority: .low
                )
            ]
            
        default:
            // Default helpful suggestions
            suggestions = generateDefaultSuggestions(tasks: tasks, building: building)
        }
        
        self.aiSuggestions = suggestions
    }
    
    // MARK: - Default Suggestions
    
    private func generateDefaultSuggestions(
        tasks: [ContextualTask],
        building: FrancoSphere.NamedCoordinate?  // 🔧 FIXED: Use NamedCoordinate
    ) -> [AISuggestion] {
        
        var suggestions: [AISuggestion] = []
        
        // Time-based suggestions
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        if currentHour < 9 {
            suggestions.append(AISuggestion(
                id: "morning_routine",
                title: "Morning Routine Check",
                description: "Review priority tasks for the morning",
                icon: "sunrise.fill",
                priority: .medium
            ))
        } else if currentHour > 16 {
            suggestions.append(AISuggestion(
                id: "end_of_day",
                title: "End of Day Review",
                description: "Complete final tasks and secure buildings",
                icon: "sunset.fill",
                priority: .medium
            ))
        }
        
        // Task-based suggestions
        if !tasks.isEmpty {
            let nextTask = tasks.first { $0.status != "completed" } // ✅ FIXED: Use .status
            if let next = nextTask {
                suggestions.append(AISuggestion(
                    id: "next_task",
                    title: "Next: \(next.name)",
                    description: "Ready to start your next task?",
                    icon: "arrow.right.circle.fill",
                    priority: .medium
                ))
            }
        }
        
        // Building-specific suggestions
        if let building = building {
            suggestions.append(AISuggestion(
                id: "building_info",
                title: "Building Information",
                description: "View details for \(building.name)",
                icon: "info.circle.fill",
                priority: .low
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Voice Processing
    
    func startVoiceProcessing() {
        isProcessingVoice = true
        
        // Simulate voice processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isProcessingVoice = false
            self.processVoiceCommand("Show me my next tasks")
        }
    }
    
    private func processVoiceCommand(_ command: String) {
        print("🎤 Processing voice command: \(command)")
        
        // Update contextual message based on voice command
        if command.lowercased().contains("task") {
            contextualMessage = "Here are your upcoming tasks. Tap any task to see details."
        } else if command.lowercased().contains("weather") {
            contextualMessage = "Current weather conditions are favorable for outdoor work."
        } else if command.lowercased().contains("building") {
            contextualMessage = "You can view building information and navigate using the map."
        } else {
            contextualMessage = "I'm here to help with tasks, navigation, and building information."
        }
        
        lastInteractionTime = Date()
    }
    
    // MARK: - Helper Methods
    
    private func shouldGenerateNewScenario() -> Bool {
        guard let lastTime = lastInteractionTime else { return true }
        return Date().timeIntervalSince(lastTime) > maxScenarioAge
    }
    
    private func isEndOfShift() -> Bool {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return currentHour >= 16 // 4 PM or later
    }
    
    private func hasIncompleteRoutine(tasks: [ContextualTask]) -> Bool {
        let routineTasks = tasks.filter { task in
            task.name.lowercased().contains("routine") ||
            task.name.lowercased().contains("daily") ||
            task.name.lowercased().contains("morning")
        }
        return routineTasks.contains { $0.status != "completed" } // ✅ FIXED: Use .status
    }
    
    private func hasTasksNeedingPhotos(tasks: [ContextualTask]) -> Bool {
        return tasks.contains { $0.status == "completed" && needsPhotoVerification($0) } // ✅ FIXED: Use .status
    }
    
    private func needsPhotoVerification(_ task: ContextualTask) -> Bool {
        let taskName = task.name.lowercased()
        return taskName.contains("repair") ||
               taskName.contains("maintenance") ||
               taskName.contains("clean") ||
               taskName.contains("inspection")
    }
    
    private func shouldCheckInventory() -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let weekday = calendar.component(.weekday, from: Date())
        
        // Suggest inventory check on Monday mornings or Friday afternoons
        return (weekday == 2 && hour < 10) || (weekday == 6 && hour > 15)
    }
    
    private func formatTaskTime(_ timeString: String) -> String {
        // Handle time string in format "HH:mm" or empty string
        guard !timeString.isEmpty else { return "No time set" }
        
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString // Return as-is if can't parse
        }
        
        // Convert to 12-hour format
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
    
    // MARK: - Periodic Context Check
    
    private func setupPeriodicContextCheck() {
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.checkForContextUpdates()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkForContextUpdates() async {
        // This would typically check with WorkerContextEngine for updates
        // For now, we'll just clear old scenarios
        if let lastTime = lastInteractionTime,
           Date().timeIntervalSince(lastTime) > maxScenarioAge {
            currentScenario = nil
            currentScenarioData = nil // ✅ FIXED: Also clear scenario data
            aiSuggestions = []
            contextualMessage = ""
        }
    }
    
    // MARK: - ✅ ADDED: Missing Public Interface Methods for AIAvatarOverlayView
    
    func dismissCurrentScenario() {
        currentScenario = nil
        currentScenarioData = nil
        aiSuggestions = []
        lastInteractionTime = Date()
    }
    
    func performAction() {
        guard let scenarioData = currentScenarioData else { return }
        
        print("🤖 Performing action for scenario: \(scenarioData.scenario.rawValue)")
        
        // Handle specific scenario actions
        switch scenarioData.scenario {
        case .clockOutReminder:
            contextualMessage = "Clocking out now..."
        case .buildingArrival:
            contextualMessage = "Opening clock-in interface..."
        case .pendingTasks:
            contextualMessage = "Showing overdue tasks..."
        case .weatherAlert:
            contextualMessage = "Filtering indoor tasks..."
        case .routineIncomplete:
            contextualMessage = "Showing routine tasks..."
        case .taskCompletion:
            contextualMessage = "Looking for additional work..."
        case .missingPhoto:
            contextualMessage = "Opening camera interface..."
        case .inventoryLow:
            contextualMessage = "Opening inventory check..."
        }
        
        // Clear the current scenario after action
        dismissCurrentScenario()
    }
    
    func handleSuggestionTap(_ suggestion: AISuggestion) {
        print("🤖 AI Suggestion tapped: \(suggestion.title)")
        
        // Update contextual message based on suggestion
        switch suggestion.id {
        case let id where id.starts(with: "task_"):
            contextualMessage = "Great choice! Focus on completing this task efficiently."
        case "clock_in":
            contextualMessage = "Perfect! Clocking in will start tracking your time."
        case "weather_indoor":
            contextualMessage = "Smart strategy. Indoor tasks are safer in bad weather."
        default:
            contextualMessage = "Good thinking! I'm here if you need more assistance."
        }
        
        lastInteractionTime = Date()
    }
    
    func getContextualGreeting(workerName: String, timeOfDay: String) -> String {
        let greetings = [
            "morning": "Good morning, \(workerName)! Ready to tackle today's tasks?",
            "afternoon": "Good afternoon, \(workerName)! How's your day going?",
            "evening": "Good evening, \(workerName)! Wrapping up for the day?"
        ]
        
        return greetings[timeOfDay] ?? "Hi \(workerName)! How can I help you today?"
    }
}

// MARK: - AI Suggestion Model

struct AISuggestion: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let priority: Priority
    
    enum Priority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

// MARK: - Real-World Worker Context Integration

extension AIAssistantManager {
    
    /// Generate Edwin-specific morning suggestions (Worker ID 2)
    func generateEdwinMorningSuggestions() -> [AISuggestion] {
        return [
            AISuggestion(
                id: "edwin_park_check",
                title: "Stuyvesant Cove Park Check",
                description: "Start with the morning park inspection",
                icon: "leaf.fill",
                priority: .high
            ),
            AISuggestion(
                id: "edwin_boiler",
                title: "Boiler Blow-Down Schedule",
                description: "Check boiler systems at 133 E 15th",
                icon: "flame.fill",
                priority: .medium
            ),
            AISuggestion(
                id: "edwin_walkthroughs",
                title: "Building Walk-Throughs",
                description: "Complete routine building inspections",
                icon: "building.2.crop.circle",
                priority: .medium
            )
        ]
    }
    
    /// Generate Kevin-specific Perry Street suggestions (Worker ID 3)
    func generateKevinPerrySuggestions() -> [AISuggestion] {
        return [
            AISuggestion(
                id: "kevin_perry_131",
                title: "131 Perry Street",
                description: "Sidewalk sweep and trash return",
                icon: "road.lanes",
                priority: .high
            ),
            AISuggestion(
                id: "kevin_perry_68",
                title: "68 Perry Street",
                description: "Full building clean and vacuum",
                icon: "bubbles.and.sparkles",
                priority: .medium
            ),
            AISuggestion(
                id: "kevin_stairwell_hose",
                title: "Stairwell Hose-Down",
                description: "Complete stairwell cleaning at 68 Perry",
                icon: "drop.fill",
                priority: .medium
            )
        ]
    }
    
    /// Generate Mercedes' glass cleaning suggestions (Worker ID 5)
    func generateMercedesGlassSuggestions() -> [AISuggestion] {
        return [
            AISuggestion(
                id: "mercedes_112_glass",
                title: "112 West 18th Glass",
                description: "Glass and lobby cleaning routine",
                icon: "sparkles",
                priority: .high
            ),
            AISuggestion(
                id: "mercedes_117_glass",
                title: "117 West 17th Glass",
                description: "Continue glass cleaning sequence",
                icon: "sparkles",
                priority: .medium
            ),
            AISuggestion(
                id: "mercedes_roof_drain",
                title: "Rubin Museum Roof Drain",
                description: "2F Terrace drain maintenance (Wednesday)",
                icon: "drop.triangle.fill",
                priority: .low
            )
        ]
    }
}
