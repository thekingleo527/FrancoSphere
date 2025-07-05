//
//  AIModels.swift
//  FrancoSphere
//
//  AI Assistant type definitions
//

import Foundation

// MARK: - AI Scenario Types
public struct AIScenario: Identifiable, Codable {
    public let id: String
    public let type: String
    public let title: String
    public let description: String
    public let timestamp: Date
    
    public init(id: String = UUID().uuidString, type: String = "general", title: String = "AI Scenario", description: String = "AI-generated scenario", timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.timestamp = timestamp
    }
}

public struct AISuggestion: Identifiable, Codable {
    public let id: String
    public let text: String
    public let actionType: String
    public let confidence: Double
    
    public init(id: String = UUID().uuidString, text: String, actionType: String = "general", confidence: Double = 0.8) {
        self.id = id
        self.text = text
        self.actionType = actionType
        self.confidence = confidence
    }
}

public struct AIScenarioData: Identifiable, Codable {
    public let id: String
    public let context: String
    public let workerId: String?
    public let buildingId: String?
    public let taskId: String?
    public let timestamp: Date
    
    public init(id: String = UUID().uuidString, context: String, workerId: String? = nil, buildingId: String? = nil, taskId: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.context = context
        self.workerId = workerId
        self.buildingId = buildingId
        self.taskId = taskId
        self.timestamp = timestamp
    }
}
