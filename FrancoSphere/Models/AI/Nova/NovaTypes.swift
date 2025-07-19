//
//  NovaTypes.swift
//  FrancoSphere v6.0
//
//  ✅ GENERATED: By comprehensive fix script
//  ✅ NOVA AI: All core types for AI integration
//  ✅ UNIFIED: Single source of truth for Nova types
//

import Foundation

// MARK: - Nova Core Types

public struct NovaContext: Codable {
    public let data: String
    public let insights: [String]
    public let metadata: [String: String]
    
    public init(data: String, insights: [String] = [], metadata: [String: String] = [:]) {
        self.data = data
        self.insights = insights
        self.metadata = metadata
    }
}

public struct NovaPrompt: Codable {
    public let text: String
    public let context: NovaContext?
    public let priority: AIPriority
    public let createdAt: Date
    
    public init(text: String, context: NovaContext? = nil, priority: AIPriority = .medium, createdAt: Date = Date()) {
        self.text = text
        self.context = context
        self.priority = priority
        self.createdAt = createdAt
    }
}

public struct NovaResponse: Codable {
    public let text: String
    public let suggestions: [String]
    public let confidence: Double
    public let sources: [String]
    public let generatedAt: Date
    
    public init(text: String, suggestions: [String] = [], confidence: Double = 0.8, sources: [String] = [], generatedAt: Date = Date()) {
        self.text = text
        self.suggestions = suggestions
        self.confidence = confidence
        self.sources = sources
        self.generatedAt = generatedAt
    }
}

public enum NovaProcessingState: String, Codable, CaseIterable {
    case idle = "Idle"
    case processing = "Processing"
    case responding = "Responding"
    case error = "Error"
}

public struct NovaInsight: Codable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let category: InsightCategory
    public let priority: AIPriority
    public let confidence: Double
    public let actionable: Bool
    public let relatedBuildings: [String]
    public let generatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        category: InsightCategory,
        priority: AIPriority,
        confidence: Double = 0.8,
        actionable: Bool = false,
        relatedBuildings: [String] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.confidence = confidence
        self.actionable = actionable
        self.relatedBuildings = relatedBuildings
        self.generatedAt = generatedAt
    }
}
