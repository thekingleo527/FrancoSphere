//
//
//  AITypes.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: Matches actual AIAssistantManager usage
//  ✅ SIMPLIFIED: Removed complex generic types causing errors
//  ✅ CORRECTED: Uses actual FrancoSphere types (ContextualTask, WorkerProfile, NamedCoordinate)
//

import Foundation
import SwiftUI

// MARK: - AI Scenario (Simple Implementation)
public struct AIScenario: Identifiable, Codable, Hashable {
    public let id: String
    public let scenario: String
    public let createdAt: Date
    
    // Simple constructor matching AIAssistantManager usage
    public init(scenario: String) {
        self.id = UUID().uuidString
        self.scenario = scenario
        self.createdAt = Date()
    }
    
    public init(id: String, scenario: String, createdAt: Date) {
        self.id = id
        self.scenario = scenario
        self.createdAt = createdAt
    }
}

// MARK: - AI Suggestion (Simple Implementation)
public struct AISuggestion: Identifiable, Codable, Hashable {
    public let id: String
    public let suggestion: String
    public let createdAt: Date
    
    // Simple constructor matching AIAssistantManager usage
    public init(suggestion: String) {
        self.id = UUID().uuidString
        self.suggestion = suggestion
        self.createdAt = Date()
    }
    
    public init(id: String, suggestion: String, createdAt: Date) {
        self.id = id
        self.suggestion = suggestion
        self.createdAt = createdAt
    }
}

// MARK: - AI Scenario Data (Simple, Non-Generic)
public struct AIScenarioData: Codable, Hashable {
    public let scenario: AIScenarioType
    public let message: String
    public let actionText: String
    public let data: String?
    public let createdAt: Date
    
    public init(
        scenario: AIScenarioType,
        message: String,
        actionText: String = "Handle",
        data: String? = nil
    ) {
        self.scenario = scenario
        self.message = message
        self.actionText = actionText
        self.data = data
        self.createdAt = Date()
    }
    
    // Empty state
    public static let empty = AIScenarioData(
        scenario: .routineIncomplete,
        message: "No active scenarios"
    )
}

// MARK: - AI Scenario Types
public enum AIScenarioType: String, Codable, CaseIterable, Hashable {
    case routineIncomplete = "routineIncomplete"
    case taskCompletion = "taskCompletion"
    case pendingTasks = "pendingTasks"
    case buildingArrival = "buildingArrival"
    case weatherAlert = "weatherAlert"
    case maintenanceRequired = "maintenanceRequired"
    case scheduleConflict = "scheduleConflict"
    case emergencyResponse = "emergencyResponse"
    case missingPhoto = "missingPhoto"
    case clockOutReminder = "clockOutReminder"
    case inventoryLow = "inventoryLow"
    
    public var displayTitle: String {
        switch self {
        case .routineIncomplete: return "Routine Incomplete"
        case .taskCompletion: return "Task Completion"
        case .pendingTasks: return "Pending Tasks"
        case .buildingArrival: return "Building Arrival"
        case .weatherAlert: return "Weather Alert"
        case .maintenanceRequired: return "Maintenance Required"
        case .scheduleConflict: return "Schedule Conflict"
        case .emergencyResponse: return "Emergency Response"
        case .missingPhoto: return "Missing Photo"
        case .clockOutReminder: return "Clock Out Reminder"
        case .inventoryLow: return "Inventory Low"
        }
    }
    
    public var defaultDescription: String {
        switch self {
        case .routineIncomplete: return "Some routine tasks are incomplete"
        case .taskCompletion: return "Task is ready for completion"
        case .pendingTasks: return "You have pending tasks that need attention"
        case .buildingArrival: return "You've arrived at a building"
        case .weatherAlert: return "Weather conditions may affect your work"
        case .maintenanceRequired: return "Equipment or area needs maintenance"
        case .scheduleConflict: return "There's a conflict in your schedule"
        case .emergencyResponse: return "Emergency situation requires immediate attention"
        case .missingPhoto: return "Photo evidence is missing for a task"
        case .clockOutReminder: return "Don't forget to clock out"
        case .inventoryLow: return "Inventory levels are low"
        }
    }
    
    public var icon: String {
        switch self {
        case .routineIncomplete: return "clock"
        case .taskCompletion: return "checkmark.circle"
        case .pendingTasks: return "list.bullet"
        case .buildingArrival: return "building.2"
        case .weatherAlert: return "cloud.rain"
        case .maintenanceRequired: return "wrench"
        case .scheduleConflict: return "calendar.badge.exclamationmark"
        case .emergencyResponse: return "exclamationmark.triangle"
        case .missingPhoto: return "camera"
        case .clockOutReminder: return "clock.badge.checkmark"
        case .inventoryLow: return "shippingbox"
        }
    }
    
    public var color: Color {
        switch self {
        case .routineIncomplete: return .orange
        case .taskCompletion: return .green
        case .pendingTasks: return .blue
        case .buildingArrival: return .green
        case .weatherAlert: return .yellow
        case .maintenanceRequired: return .orange
        case .scheduleConflict: return .red
        case .emergencyResponse: return .red
        case .missingPhoto: return .purple
        case .clockOutReminder: return .red
        case .inventoryLow: return .orange
        }
    }
    
    public var priority: AIPriority {
        switch self {
        case .emergencyResponse: return .critical
        case .scheduleConflict, .clockOutReminder: return .high
        case .weatherAlert, .maintenanceRequired, .inventoryLow: return .medium
        case .routineIncomplete, .pendingTasks, .missingPhoto: return .medium
        case .taskCompletion, .buildingArrival: return .low
        }
    }
}

// MARK: - AI Priority
public enum AIPriority: String, Codable, CaseIterable, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    case critical = "Critical"
    
    public var numericValue: Int {
        switch self {
        case .critical: return 5
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    public var color: Color {
        switch self {
        case .critical: return .purple
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    public var systemImageName: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .urgent: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.circle"
        case .medium: return "info.circle"
        case .low: return "info.circle"
        }
    }
}

// MARK: - Extended AI Scenario Data (For Complex Use Cases)
public struct ExtendedAIScenarioData: Codable, Hashable {
    public let scenario: AIScenario
    public let contextualTasks: [ContextualTask]
    public let affectedBuildings: [NamedCoordinate]
    public let availableWorkers: [WorkerProfile]
    public let currentMetrics: AIMetrics?
    public let recommendedActions: [AIRecommendedAction]
    public let riskAssessment: AIRiskAssessment?
    
    public init(
        scenario: AIScenario,
        contextualTasks: [ContextualTask] = [],
        affectedBuildings: [NamedCoordinate] = [],
        availableWorkers: [WorkerProfile] = [],
        currentMetrics: AIMetrics? = nil,
        recommendedActions: [AIRecommendedAction] = [],
        riskAssessment: AIRiskAssessment? = nil
    ) {
        self.scenario = scenario
        self.contextualTasks = contextualTasks
        self.affectedBuildings = affectedBuildings
        self.availableWorkers = availableWorkers
        self.currentMetrics = currentMetrics
        self.recommendedActions = recommendedActions
        self.riskAssessment = riskAssessment
    }
}

// MARK: - Supporting AI Types

public struct AIMetrics: Codable, Hashable {
    public let overallScore: Double
    public let confidenceLevel: Double
    public let dataQuality: Double
    public let predictiveAccuracy: Double
    public let lastUpdated: Date
    
    public init(
        overallScore: Double,
        confidenceLevel: Double,
        dataQuality: Double,
        predictiveAccuracy: Double,
        lastUpdated: Date = Date()
    ) {
        self.overallScore = overallScore
        self.confidenceLevel = confidenceLevel
        self.dataQuality = dataQuality
        self.predictiveAccuracy = predictiveAccuracy
        self.lastUpdated = lastUpdated
    }
}

public struct AIRecommendedAction: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let priority: AIPriority
    public let estimatedDuration: TimeInterval
    public let requiredSkills: [String]
    public let expectedOutcome: String
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        priority: AIPriority,
        estimatedDuration: TimeInterval,
        requiredSkills: [String] = [],
        expectedOutcome: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.requiredSkills = requiredSkills
        self.expectedOutcome = expectedOutcome
    }
}

public struct AIRiskAssessment: Codable, Hashable {
    public let riskLevel: AIRiskLevel
    public let riskFactors: [String]
    public let mitigationStrategies: [String]
    public let probabilityOfSuccess: Double
    public let contingencyPlans: [String]
    
    public init(
        riskLevel: AIRiskLevel,
        riskFactors: [String] = [],
        mitigationStrategies: [String] = [],
        probabilityOfSuccess: Double,
        contingencyPlans: [String] = []
    ) {
        self.riskLevel = riskLevel
        self.riskFactors = riskFactors
        self.mitigationStrategies = mitigationStrategies
        self.probabilityOfSuccess = probabilityOfSuccess
        self.contingencyPlans = contingencyPlans
    }
}

public enum AIRiskLevel: String, Codable, CaseIterable, Hashable {
    case minimal = "minimal"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case critical = "critical"
    
    public var color: Color {
        switch self {
        case .minimal: return .green
        case .low: return .yellow
        case .moderate: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    public var numericValue: Int {
        switch self {
        case .minimal: return 1
        case .low: return 2
        case .moderate: return 3
        case .high: return 4
        case .critical: return 5
        }
    }
}

// MARK: - Convenience Extensions

extension AIScenarioData {
    public var priorityColor: Color {
        scenario.priority.color
    }
    
    public var scenarioIcon: String {
        scenario.icon
    }
    
    public var isUrgent: Bool {
        scenario.priority.numericValue >= 4
    }
    
    public var isCritical: Bool {
        scenario.priority == .critical
    }
}

extension AIScenarioType {
    public func createScenarioData(message: String, actionText: String = "Handle") -> AIScenarioData {
        AIScenarioData(scenario: self, message: message, actionText: actionText)
    }
}

// MARK: - Factory Methods for Common Scenarios

extension AIScenarioData {
    public static func routineIncomplete(workerName: String, buildingName: String) -> AIScenarioData {
        AIScenarioData(
            scenario: .routineIncomplete,
            message: "\(workerName) has incomplete routine tasks at \(buildingName)",
            actionText: "Review Tasks"
        )
    }
    
    public static func taskCompletion(taskName: String, buildingName: String) -> AIScenarioData {
        AIScenarioData(
            scenario: .taskCompletion,
            message: "Task '\(taskName)' at \(buildingName) is ready for completion",
            actionText: "Complete Task"
        )
    }
    
    public static func weatherAlert(condition: String, buildingNames: [String]) -> AIScenarioData {
        let buildingList = buildingNames.prefix(2).joined(separator: ", ")
        let additionalCount = buildingNames.count > 2 ? " and \(buildingNames.count - 2) more" : ""
        
        return AIScenarioData(
            scenario: .weatherAlert,
            message: "\(condition) weather affecting operations at \(buildingList)\(additionalCount)",
            actionText: "Adjust Schedule"
        )
    }
    
    public static func buildingArrival(workerName: String, buildingName: String) -> AIScenarioData {
        AIScenarioData(
            scenario: .buildingArrival,
            message: "\(workerName) has arrived at \(buildingName)",
            actionText: "Start Tasks"
        )
    }
    
    public static func emergencyResponse(description: String, buildingName: String) -> AIScenarioData {
        AIScenarioData(
            scenario: .emergencyResponse,
            message: "Emergency: \(description) at \(buildingName)",
            actionText: "Respond"
        )
    }
}

// MARK: - Intelligence Types Reference
// Note: IntelligenceInsight, InsightType, and InsightPriority are defined in CoreTypes.swift
// This file only contains AI-specific types that don't conflict with existing definitions

// MARK: - Type Aliases for Compatibility
// These ensure the IntelligenceInsightsView can access the CoreTypes properly
public typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
public typealias InsightType = CoreTypes.InsightType
public typealias InsightPriority = CoreTypes.InsightPriority
