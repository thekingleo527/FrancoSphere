//
//  AITypes.swift
//  FrancoSphere v6.0 - UNIFIED AI TYPES
//
//  🚨 CRITICAL FIX: Resolves duplicate AISuggestion/AIPriority declarations
//  ✅ FIXED: Single source of truth for all AI types
//  ✅ REMOVED: Conflicting declarations from Models/AITypes.swift
//  ✅ ENHANCED: Complete protocol conformance
//

import Foundation
import SwiftUI

// MARK: - Core AI Types (Single Declarations)

public struct AIScenario: Identifiable, Codable, Hashable {
    public let id: String
    public let scenario: String
    public let createdAt: Date
    
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

public struct AISuggestion: Identifiable, Codable, Hashable {
    public let id: String
    public let suggestion: String
    public let createdAt: Date
    
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

// MARK: - AI Scenario Data Types

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
        data: String? = nil,
        createdAt: Date = Date()
    ) {
        self.scenario = scenario
        self.message = message
        self.actionText = actionText
        self.data = data
        self.createdAt = createdAt
    }
    
    public static let empty = AIScenarioData(
        scenario: .taskCompletion,
        message: "No scenarios available",
        actionText: "Refresh"
    )
}

public enum AIScenarioType: String, Codable, CaseIterable {
    case taskCompletion = "taskCompletion"
    case routineIncomplete = "routineIncomplete"
    case buildingArrival = "buildingArrival"
    case clockOutReminder = "clockOutReminder"
    case pendingTasks = "pendingTasks"
    case weatherAlert = "weatherAlert"
    case maintenanceRequired = "maintenanceRequired"
    case scheduleConflict = "scheduleConflict"
    case emergencyResponse = "emergencyResponse"
    case missingPhoto = "missingPhoto"
    case inventoryLow = "inventoryLow"
    
    public var displayName: String {
        switch self {
        case .taskCompletion: return "Task Completion"
        case .routineIncomplete: return "Routine Incomplete"
        case .buildingArrival: return "Building Arrival"
        case .clockOutReminder: return "Clock Out Reminder"
        case .pendingTasks: return "Pending Tasks"
        case .weatherAlert: return "Weather Alert"
        case .maintenanceRequired: return "Maintenance Required"
        case .scheduleConflict: return "Schedule Conflict"
        case .emergencyResponse: return "Emergency Response"
        case .missingPhoto: return "Missing Photo"
        case .inventoryLow: return "Inventory Low"
        }
    }
    
    public var color: Color {
        switch self {
        case .emergencyResponse: return .red
        case .scheduleConflict, .clockOutReminder: return .orange
        case .weatherAlert, .maintenanceRequired: return .yellow
        case .routineIncomplete, .pendingTasks, .missingPhoto: return .blue
        case .taskCompletion, .buildingArrival: return .green
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

// MARK: - Extended AI Types with Protocol Conformance

public struct AIRecommendedAction: Identifiable, Codable, Hashable, Equatable {
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
    
    // MARK: - Equatable Conformance
    public static func == (lhs: AIRecommendedAction, rhs: AIRecommendedAction) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable Conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

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

public struct AIRiskAssessment: Codable, Hashable {
    public let overallRisk: AIPriority
    public let riskFactors: [String]
    public let mitigationStrategies: [String]
    public let timeline: String
    
    public init(
        overallRisk: AIPriority,
        riskFactors: [String],
        mitigationStrategies: [String],
        timeline: String
    ) {
        self.overallRisk = overallRisk
        self.riskFactors = riskFactors
        self.mitigationStrategies = mitigationStrategies
        self.timeline = timeline
    }
}

// MARK: - Extended AI Scenario Data

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
