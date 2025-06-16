//
//  AIAssistantManager.swift
//  FrancoSphere
//
//  Complete AI Assistant integration for Nova
//  Created by Shawn Magloire on 6/8/25.
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - AI Scenario Data
// Since AIScenario is already defined in FrancoSphereModels, we'll create a data structure for scenario details
struct AIScenarioData {
    let scenario: AIScenario
    let buildingName: String?
    let taskCount: Int?
    let taskName: String?
    let hoursWorked: Double?
    let condition: String?
    let item: String?
    
    var title: String {
        scenario.title
    }
    
    var message: String {
        switch scenario {
        case .routineIncomplete:
            return "You have \(taskCount ?? 0) routine tasks pending at \(buildingName ?? "the building"). Would you like to review them?"
        case .pendingTasks:
            return "You have \(taskCount ?? 0) tasks scheduled for today. Let's prioritize the urgent ones."
        case .missingPhoto:
            return "The task '\(taskName ?? "")' requires photo verification. Please upload a photo to complete."
        case .clockOutReminder:
            return "You've been clocked in for \(Int(hoursWorked ?? 0)) hours. Don't forget to clock out!"
        case .weatherAlert:
            return "\(condition ?? "Weather event") expected at \(buildingName ?? "the building"). Some outdoor tasks may need rescheduling."
        case .buildingArrival:
            return "Welcome to \(buildingName ?? "this building")! You have tasks here. Would you like to clock in?"
        case .taskCompletion:
            return "Great job completing '\(taskName ?? "that task")'! Keep up the excellent work."
        case .inventoryLow:
            return "Low inventory alert: \(item ?? "Some items") at \(buildingName ?? "the building") needs restocking."
        }
    }
    
    var actionText: String {
        switch scenario {
        case .routineIncomplete: return "View Tasks"
        case .pendingTasks: return "Show Tasks"
        case .missingPhoto: return "Upload Photo"
        case .clockOutReminder: return "Clock Out Now"
        case .weatherAlert: return "View Weather"
        case .buildingArrival: return "Clock In"
        case .taskCompletion: return "Next Task"
        case .inventoryLow: return "Order Supplies"
        }
    }
    
    var icon: String {
        scenario.icon
    }
}

@MainActor
class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()
    
    // MARK: - Published Properties
    @Published var hasUrgentInsight = false
    @Published var isProcessing = false
    @Published var isOffline = false
    @Published var unreadNotifications = 0
    @Published var currentSuggestion: String?
    @Published var insights: [AIInsight] = []
    @Published var currentScenarioData: AIScenarioData?
    @Published var scenarioQueue: [AIScenarioData] = []
    
    // MARK: - Computed Properties
    var hasActiveScenarios: Bool {
        currentScenarioData != nil || !scenarioQueue.isEmpty
    }
    
    var currentScenario: AIScenario? {
        currentScenarioData?.scenario
    }
    
    // MARK: - Private Properties
    private var contextEngine: WorkerContextEngine?
    private var analysisTimer: Timer?
    
    private init() {
        setupAnalysisTimer()
    }
    
    // MARK: - Public Methods
    
    func analyzeWorkerContext(_ context: AIWorkerContext) {
        Task {
            await performAnalysis(context)
        }
    }
    
    func dismissInsight(_ insight: AIInsight) {
        insights.removeAll { $0.id == insight.id }
        updateUrgentStatus()
    }
    
    func markAllInsightsAsRead() {
        for index in insights.indices {
            insights[index].isRead = true
        }
        unreadNotifications = 0
    }
    
    func dismissCurrentScenario() {
        currentScenarioData = nil
        processNextScenario()
    }
    
    func performAction() {
        guard let scenarioData = currentScenarioData else { return }
        
        // Handle the action based on scenario type
        switch scenarioData.scenario {
        case .routineIncomplete, .pendingTasks:
            NotificationCenter.default.post(name: .showTasks, object: nil)
        case .missingPhoto:
            NotificationCenter.default.post(name: .openCamera, object: nil)
        case .clockOutReminder:
            NotificationCenter.default.post(name: .performClockOut, object: nil)
        case .weatherAlert:
            NotificationCenter.default.post(name: .showWeather, object: nil)
        case .buildingArrival:
            NotificationCenter.default.post(name: .performClockIn, object: nil)
        case .taskCompletion:
            NotificationCenter.default.post(name: .showNextTask, object: nil)
        case .inventoryLow:
            NotificationCenter.default.post(name: .showInventory, object: nil)
        }
        
        dismissCurrentScenario()
    }
    
    func addScenario(_ scenario: AIScenario, buildingName: String? = nil, taskCount: Int? = nil,
                     taskName: String? = nil, hoursWorked: Double? = nil, condition: String? = nil,
                     item: String? = nil) {
        let scenarioData = AIScenarioData(
            scenario: scenario,
            buildingName: buildingName,
            taskCount: taskCount,
            taskName: taskName,
            hoursWorked: hoursWorked,
            condition: condition,
            item: item
        )
        
        if currentScenarioData == nil {
            currentScenarioData = scenarioData
        } else {
            scenarioQueue.append(scenarioData)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAnalysisTimer() {
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { _ in
            Task {
                await self.periodicAnalysis()
            }
        }
    }
    
    private func performAnalysis(_ context: AIWorkerContext) async {
        isProcessing = true
        
        // Simulate AI processing
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Clear existing scenarios
        scenarioQueue.removeAll()
        
        // Analyze tasks
        let urgentTasks = context.todaysTasks.filter {
            $0.urgencyLevel.lowercased() == "urgent" || $0.isOverdue
        }
        
        // Generate scenarios based on context
        if urgentTasks.count > 0 {
            addScenario(.pendingTasks, taskCount: urgentTasks.count)
        }
        
        // Check for incomplete routines
        let incompleteTasks = context.todaysTasks.filter {
            $0.recurrence == "daily" && $0.status != "completed"
        }
        if incompleteTasks.count > 0, let building = context.assignedBuildings.first {
            addScenario(.routineIncomplete,
                       buildingName: building.name,
                       taskCount: incompleteTasks.count)
        }
        
        // Check for weather-related tasks
        if context.todaysTasks.contains(where: { $0.name.lowercased().contains("rain") || $0.name.lowercased().contains("weather") }) {
            if let building = context.assignedBuildings.first {
                addScenario(.weatherAlert,
                           buildingName: building.name,
                           condition: "Rain")
            }
        }
        
        // Check if worker just arrived at a building (when GPS is implemented)
        if !context.clockedIn, let building = context.assignedBuildings.first {
            // This would check if user is near the building
            addScenario(.buildingArrival, buildingName: building.name)
        }
        
        // Generate insights
        var newInsights: [AIInsight] = []
        
        if urgentTasks.count > 0 {
            newInsights.append(
                AIInsight(
                    type: .urgent,
                    title: "Urgent Tasks Require Attention",
                    message: "You have \(urgentTasks.count) urgent or overdue tasks that need immediate attention.",
                    priority: .high
                )
            )
        }
        
        // Update state
        insights = newInsights
        unreadNotifications = newInsights.filter { !$0.isRead }.count
        updateUrgentStatus()
        
        isProcessing = false
    }
    
    private func periodicAnalysis() async {
        let contextEngine = WorkerContextEngine.shared
        
        // Get latest context
        await contextEngine.refreshContext()
        
        // Analyze if we have context
        if let context = await contextEngine.getCurrentContext() {
            await performAnalysis(context)
        }
    }
    
    private func updateUrgentStatus() {
        hasUrgentInsight = insights.contains { $0.priority == .high && !$0.isRead }
    }
    
    private func processNextScenario() {
        if !scenarioQueue.isEmpty {
            currentScenarioData = scenarioQueue.removeFirst()
        }
    }
}

// MARK: - AI Insight Model

struct AIInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let priority: InsightPriority
    var isRead: Bool = false
    let timestamp = Date()
    
    enum InsightType {
        case urgent
        case weather
        case efficiency
        case reminder
        case suggestion
    }
    
    enum InsightPriority {
        case low
        case medium
        case high
    }
}

// MARK: - AI Worker Context

struct AIWorkerContext {
    let workerId: String
    let workerName: String
    let todaysTasks: [ContextualTask]
    let assignedBuildings: [FrancoSphere.NamedCoordinate]
    let currentLocation: CLLocationCoordinate2D?
    let clockedIn: Bool
    let currentBuildingId: String?
}

// MARK: - Notification Names

extension Notification.Name {
    static let showTasks = Notification.Name("showTasks")
    static let openCamera = Notification.Name("openCamera")
    static let performClockOut = Notification.Name("performClockOut")
    static let showWeather = Notification.Name("showWeather")
    static let performClockIn = Notification.Name("performClockIn")
    static let showNextTask = Notification.Name("showNextTask")
    static let showInventory = Notification.Name("showInventory")
}

// MARK: - Extensions

extension WorkerContextEngine {
    func getCurrentContext() async -> AIWorkerContext? {
        guard let worker = currentWorker else { return nil }
        
        return AIWorkerContext(
            workerId: worker.workerId,
            workerName: worker.workerName,
            todaysTasks: todaysTasks,
            assignedBuildings: assignedBuildings.map { building in
                FrancoSphere.NamedCoordinate(
                    id: building.id,
                    name: building.name,
                    latitude: building.latitude,
                    longitude: building.longitude,
                    imageAssetName: building.imageAssetName
                )
            },
            currentLocation: nil, // Would come from LocationManager
            clockedIn: false, // Would come from ClockInManager
            currentBuildingId: nil
        )
    }
}
// MARK: - WorkerDashboardView Integration

extension AIAssistantManager {
    
    /// Generate contextual scenario based on worker context - called by WorkerDashboardView
    func generateContextualScenario(
        workerId: String,
        workerName: String,
        todaysTasks: [ContextualTask],
        assignedBuildings: [Building],
        clockedIn: Bool,
        overdueCount: Int
    ) {
        // Determine the most relevant scenario based on context
        if let scenario = determineContextualScenario(
            workerId: workerId,
            workerName: workerName,
            todaysTasks: todaysTasks,
            assignedBuildings: assignedBuildings,
            clockedIn: clockedIn,
            overdueCount: overdueCount
        ) {
            // Add the scenario with relevant context data
            addScenarioFromBuildings(scenario,
                                   workerId: workerId,
                                   todaysTasks: todaysTasks,
                                   assignedBuildings: assignedBuildings,
                                   clockedIn: clockedIn,
                                   overdueCount: overdueCount)
        }
    }
    
    private func determineContextualScenario(
        workerId: String,
        workerName: String,
        todaysTasks: [ContextualTask],
        assignedBuildings: [Building],
        clockedIn: Bool,
        overdueCount: Int
    ) -> AIScenario? {
        
        // Priority 1: Overdue tasks
        if overdueCount > 0 {
            return .pendingTasks
        }
        
        // Priority 2: Incomplete routines
        let incompleteTasks = todaysTasks.filter { $0.status != "completed" }
        if incompleteTasks.count > 0 && clockedIn {
            return .routineIncomplete
        }
        
        // Priority 3: Clock out reminder (if clocked in and near end of day)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        if clockedIn && hour >= 17 { // After 5 PM
            return .clockOutReminder
        }
        
        // Priority 4: Weather alerts for outdoor tasks
        let weatherDependentTasks = todaysTasks.filter { $0.weatherDependent }
        if !weatherDependentTasks.isEmpty {
            return .weatherAlert
        }
        
        // Priority 5: Building arrival (if not clocked in and has tasks)
        if !clockedIn && !todaysTasks.isEmpty {
            return .buildingArrival
        }
        
        // No immediate scenario needed
        return nil
    }
    
    private func addScenarioFromBuildings(_ scenario: AIScenario,
                                        workerId: String,
                                        todaysTasks: [ContextualTask],
                                        assignedBuildings: [Building],
                                        clockedIn: Bool,
                                        overdueCount: Int) {
        let buildingName = assignedBuildings.first?.name
        let taskCount = todaysTasks.count
        let incompleteTasks = todaysTasks.filter { $0.status != "completed" }
        let weatherTasks = todaysTasks.filter { $0.weatherDependent }
        
        switch scenario {
        case .pendingTasks:
            addScenario(.pendingTasks,
                       buildingName: buildingName,
                       taskCount: overdueCount)
            
        case .routineIncomplete:
            addScenario(.routineIncomplete,
                       buildingName: buildingName,
                       taskCount: incompleteTasks.count)
            
        case .clockOutReminder:
            // Calculate hours worked (simplified)
            let hoursWorked = 8.0 // Would calculate from actual clock-in time
            addScenario(.clockOutReminder,
                       buildingName: buildingName,
                       hoursWorked: hoursWorked)
            
        case .weatherAlert:
            addScenario(.weatherAlert,
                       buildingName: buildingName,
                       taskCount: weatherTasks.count,
                       condition: "Weather conditions may affect outdoor tasks")
            
        case .buildingArrival:
            addScenario(.buildingArrival,
                       buildingName: buildingName,
                       taskCount: taskCount)
            
        default:
            break
        }
    }
}
extension AIAssistantManager {
    
    /// Reset Nova's glow state - fixes "resetGlow() not found" error
    func resetGlow() {
        DispatchQueue.main.async {
            self.isProcessing = false
            // Reset to default purple glow state
            print("🟣 Nova glow reset to default state")
        }
    }
}
