//
//  AITypes.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ No type redeclarations
//  ✅ Proper protocol conformance
//

import Foundation
import SwiftUI

// MARK: - AI Scenario Framework

public struct AIScenario: Codable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let category: AIScenarioCategory
    public let priority: AIPriority
    public let contextData: [String: String]
    public let suggestions: [AISuggestion]
    public let estimatedImpact: AIImpact
    public let createdAt: Date
    public let expiresAt: Date?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        category: AIScenarioCategory,
        priority: AIPriority,
        contextData: [String: String] = [:],
        suggestions: [AISuggestion] = [],
        estimatedImpact: AIImpact,
        createdAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.contextData = contextData
        self.suggestions = suggestions
        self.estimatedImpact = estimatedImpact
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

public struct AISuggestion: Codable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let actionType: AIActionType
    public let confidence: Double // 0.0 to 1.0
    public let estimatedTimeToComplete: TimeInterval
    public let requiredResources: [AIResource]
    public let potentialImpact: AIImpact
    public let isEmergency: Bool
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        actionType: AIActionType,
        confidence: Double,
        estimatedTimeToComplete: TimeInterval,
        requiredResources: [AIResource] = [],
        potentialImpact: AIImpact,
        isEmergency: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.actionType = actionType
        self.confidence = confidence
        self.estimatedTimeToComplete = estimatedTimeToComplete
        self.requiredResources = requiredResources
        self.potentialImpact = potentialImpact
        self.isEmergency = isEmergency
    }
}

// MARK: - AIScenarioData with Generic Type Parameters
// This allows it to work with any task, building, and worker types
public struct AIScenarioData<TaskType: Codable & Hashable, BuildingType: Codable & Hashable, WorkerType: Codable & Hashable>: Codable, Hashable {
    public let scenario: AIScenario
    public let contextualTasks: [TaskType]
    public let affectedBuildings: [BuildingType]
    public let availableWorkers: [WorkerType]
    public let currentMetrics: AIMetrics
    public let recommendedActions: [AIRecommendedAction]
    public let riskAssessment: AIRiskAssessment
    
    public init(
        scenario: AIScenario,
        contextualTasks: [TaskType],
        affectedBuildings: [BuildingType],
        availableWorkers: [WorkerType],
        currentMetrics: AIMetrics,
        recommendedActions: [AIRecommendedAction] = [],
        riskAssessment: AIRiskAssessment
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

public enum AIScenarioCategory: String, Codable, CaseIterable {
    case emergency = "emergency"
    case optimization = "optimization"
    case maintenance = "maintenance"
    case compliance = "compliance"
    case efficiency = "efficiency"
    case prediction = "prediction"
    
    public var icon: String {
        switch self {
        case .emergency: return "exclamationmark.triangle.fill"
        case .optimization: return "speedometer"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .compliance: return "checkmark.shield.fill"
        case .efficiency: return "chart.line.uptrend.xyaxis"
        case .prediction: return "crystal.ball.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .emergency: return .red
        case .optimization: return .blue
        case .maintenance: return .orange
        case .compliance: return .green
        case .efficiency: return .purple
        case .prediction: return .cyan
        }
    }
}

public enum AIPriority: String, Codable, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    public var numericValue: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    public var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

public enum AIActionType: String, Codable, CaseIterable {
    case immediate = "immediate"
    case scheduled = "scheduled"
    case preventive = "preventive"
    case investigative = "investigative"
    case optimizationRecommendation = "optimization_recommendation"
    
    public var icon: String {
        switch self {
        case .immediate: return "bolt.fill"
        case .scheduled: return "calendar"
        case .preventive: return "shield.checkered"
        case .investigative: return "magnifyingglass"
        case .optimizationRecommendation: return "lightbulb.fill"
        }
    }
}

public struct AIResource: Codable, Hashable {
    public let type: AIResourceType
    public let quantity: Int
    public let description: String
    public let isAvailable: Bool
    
    public init(type: AIResourceType, quantity: Int, description: String, isAvailable: Bool) {
        self.type = type
        self.quantity = quantity
        self.description = description
        self.isAvailable = isAvailable
    }
}

public enum AIResourceType: String, Codable, CaseIterable {
    case worker = "worker"
    case equipment = "equipment"
    case material = "material"
    case time = "time"
    case expertise = "expertise"
}

public struct AIImpact: Codable, Hashable {
    public let efficiencyGain: Double // Percentage
    public let costSavings: Double // Dollars
    public let timeReduction: TimeInterval // Seconds
    public let qualityImprovement: Double // Percentage
    public let riskReduction: Double // Percentage
    
    public init(
        efficiencyGain: Double,
        costSavings: Double,
        timeReduction: TimeInterval,
        qualityImprovement: Double,
        riskReduction: Double
    ) {
        self.efficiencyGain = efficiencyGain
        self.costSavings = costSavings
        self.timeReduction = timeReduction
        self.qualityImprovement = qualityImprovement
        self.riskReduction = riskReduction
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

public struct AIRecommendedAction: Codable, Hashable, Identifiable {
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
        requiredSkills: [String],
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
        riskFactors: [String],
        mitigationStrategies: [String],
        probabilityOfSuccess: Double,
        contingencyPlans: [String]
    ) {
        self.riskLevel = riskLevel
        self.riskFactors = riskFactors
        self.mitigationStrategies = mitigationStrategies
        self.probabilityOfSuccess = probabilityOfSuccess
        self.contingencyPlans = contingencyPlans
    }
}

public enum AIRiskLevel: String, Codable, CaseIterable {
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
}
