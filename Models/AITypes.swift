import Foundation
import SwiftUI

public struct AIScenario: Identifiable, Codable, Hashable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let type: String
    public let priority: String
    public let suggestions: [AISuggestion]
    public let createdAt: Date
    
    public init(title: String, description: String, type: String, priority: String, suggestions: [AISuggestion] = [], createdAt: Date = Date()) {
        self.title = title
        self.description = description
        self.type = type
        self.priority = priority
        self.suggestions = suggestions
        self.createdAt = createdAt
    }
}

public struct AISuggestion: Identifiable, Codable, Hashable {
    public let id = UUID()
    public let text: String
    public let actionType: String
    public let confidence: Double
    
    public init(text: String, actionType: String, confidence: Double) {
        self.text = text
        self.actionType = actionType
        self.confidence = confidence
    }
}

// ✅ FIXED: Use simple AIScenarioData (non-generic) to avoid conflicts
public struct AIScenarioData: Codable, Hashable {
    public let scenarios: [AIScenario]
    public let hasPendingScenarios: Bool
    public let lastUpdated: Date
    
    public init(scenarios: [AIScenario] = [], lastUpdated: Date = Date()) {
        self.scenarios = scenarios
        self.hasPendingScenarios = !scenarios.isEmpty
        self.lastUpdated = lastUpdated
    }
    
    public static let empty = AIScenarioData()
}

public struct IntelligenceInsight: Identifiable, Codable, Hashable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let actionable: Bool
    public let timestamp: Date
    
    public init(title: String, description: String, type: InsightType, priority: InsightPriority, actionable: Bool, timestamp: Date = Date()) {
        self.title = title
        self.description = description
        self.type = type
        self.priority = priority
        self.actionable = actionable
        self.timestamp = timestamp
    }
}

public enum InsightType: String, Codable, CaseIterable {
    case performance, maintenance, compliance, efficiency, cost, safety
}

public enum InsightPriority: String, Codable, CaseIterable {
    case low, medium, high, critical
    
    public var priorityValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

public struct BuildingInsight: Identifiable, Codable, Hashable {
    public let id = UUID()
    public let buildingId: String
    public let type: InsightType
    public let title: String
    public let description: String
    public let actionRequired: Bool
    public let generatedAt: Date
    
    public init(buildingId: String, type: InsightType, title: String, description: String, actionRequired: Bool, generatedAt: Date = Date()) {
        self.buildingId = buildingId
        self.type = type
        self.title = title
        self.description = description
        self.actionRequired = actionRequired
        self.generatedAt = generatedAt
    }
}

public enum BuildingStatus: String, Codable, CaseIterable {
    case operational, maintenance, emergency, offline
}

public enum BuildingTab: String, CaseIterable {
    case overview, tasks, maintenance, compliance, workers
}

public typealias ScheduleConflict = BuildingInsight
