//
//  NovaTypes.swift
//  FrancoSphere v6.0 - Nova AI Core Types
//
//  ✅ AUTHORITATIVE: Single source of truth for all Nova types
//  ✅ FIXED: Resolves NovaContext redeclaration ambiguity
//  ✅ COMPREHENSIVE: All Nova AI types in one place
//

import Foundation
import SwiftUI

// MARK: - Core Nova Context (AUTHORITATIVE DEFINITION)
public struct NovaContext: Codable, Hashable, Identifiable {
    public let id: UUID
    public let data: String
    public let timestamp: Date
    public let insights: [String]
    public let metadata: [String: String]
    
    public init(
        id: UUID = UUID(),
        data: String,
        timestamp: Date = Date(),
        insights: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.data = data
        self.timestamp = timestamp
        self.insights = insights
        self.metadata = metadata
    }
    
    public static let empty = NovaContext(data: "")
}

// MARK: - Nova Prompt System
public struct NovaPrompt: Identifiable, Codable, Hashable {
    public let id: UUID
    public let text: String
    public let priority: NovaPriority
    public let context: NovaContext?
    public let createdAt: Date
    public let expiresAt: Date?
    
    public init(
        id: UUID = UUID(),
        text: String,
        priority: NovaPriority = .medium,
        context: NovaContext? = nil,
        createdAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.priority = priority
        self.context = context
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

// MARK: - Nova Priority System
public enum NovaPriority: String, Codable, CaseIterable, Hashable {
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

// MARK: - Nova Action System
public struct NovaAction: Identifiable, Codable, Hashable {
    public let id: UUID
    public let title: String
    public let description: String
    public let actionType: NovaActionType
    public let priority: NovaPriority
    public let estimatedDuration: TimeInterval
    public let requiredSkills: [String]
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        actionType: NovaActionType,
        priority: NovaPriority = .medium,
        estimatedDuration: TimeInterval = 300, // 5 minutes default
        requiredSkills: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.actionType = actionType
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.requiredSkills = requiredSkills
    }
}

// MARK: - Nova Action Types
public enum NovaActionType: String, Codable, CaseIterable, Hashable {
    case navigate = "Navigate"
    case complete = "Complete"
    case review = "Review"
    case schedule = "Schedule"
    case contact = "Contact"
    case emergency = "Emergency"
    case maintenance = "Maintenance"
    case inspection = "Inspection"
    case documentation = "Documentation"
    case analysis = "Analysis"
    
    public var icon: String {
        switch self {
        case .navigate: return "arrow.right.circle"
        case .complete: return "checkmark.circle"
        case .review: return "magnifyingglass.circle"
        case .schedule: return "calendar.circle"
        case .contact: return "person.circle"
        case .emergency: return "exclamationmark.triangle"
        case .maintenance: return "wrench.and.screwdriver"
        case .inspection: return "list.bullet.clipboard"
        case .documentation: return "doc.circle"
        case .analysis: return "chart.line.uptrend.xyaxis.circle"
        }
    }
}

// MARK: - Nova Intelligence Types
public struct NovaInsight: Identifiable, Codable, Hashable {
    public let id: UUID
    public let title: String
    public let description: String
    public let category: NovaInsightCategory
    public let priority: NovaPriority
    public let confidence: Double
    public let actionable: Bool
    public let suggestedActions: [NovaAction]
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: NovaInsightCategory,
        priority: NovaPriority = .medium,
        confidence: Double = 0.8,
        actionable: Bool = true,
        suggestedActions: [NovaAction] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.confidence = confidence
        self.actionable = actionable
        self.suggestedActions = suggestedActions
        self.createdAt = createdAt
    }
}

// MARK: - Nova Insight Categories
public enum NovaInsightCategory: String, Codable, CaseIterable, Hashable {
    case performance = "Performance"
    case maintenance = "Maintenance"
    case efficiency = "Efficiency"
    case compliance = "Compliance"
    case safety = "Safety"
    case cost = "Cost"
    case quality = "Quality"
    case prediction = "Prediction"
    
    public var color: Color {
        switch self {
        case .performance: return .blue
        case .maintenance: return .orange
        case .efficiency: return .green
        case .compliance: return .purple
        case .safety: return .red
        case .cost: return .yellow
        case .quality: return .indigo
        case .prediction: return .mint
        }
    }
    
    public var icon: String {
        switch self {
        case .performance: return "speedometer"
        case .maintenance: return "wrench.and.screwdriver"
        case .efficiency: return "gauge.badge.plus"
        case .compliance: return "checkmark.shield"
        case .safety: return "shield"
        case .cost: return "dollarsign.circle"
        case .quality: return "star.circle"
        case .prediction: return "crystal.ball"
        }
    }
}

// MARK: - Nova Response Types
public struct NovaResponse: Codable, Hashable {
    public let success: Bool
    public let message: String
    public let actions: [NovaAction]
    public let insights: [NovaInsight]
    public let context: NovaContext?
    public let timestamp: Date
    
    public init(
        success: Bool,
        message: String,
        actions: [NovaAction] = [],
        insights: [NovaInsight] = [],
        context: NovaContext? = nil,
        timestamp: Date = Date()
    ) {
        self.success = success
        self.message = message
        self.actions = actions
        self.insights = insights
        self.context = context
        self.timestamp = timestamp
    }
    
    public static let empty = NovaResponse(success: false, message: "No response")
}

// MARK: - Nova Data Structures
public struct NovaDataPoint: Codable, Hashable {
    public let timestamp: Date
    public let value: Double
    public let category: String
    public let metadata: [String: String]
    
    public init(timestamp: Date = Date(), value: Double, category: String, metadata: [String: String] = [:]) {
        self.timestamp = timestamp
        self.value = value
        self.category = category
        self.metadata = metadata
    }
}

public struct NovaPattern: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let description: String
    public let confidence: Double
    public let frequency: NovaPatternFrequency
    public let dataPoints: [NovaDataPoint]
    public let discoveredAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        confidence: Double,
        frequency: NovaPatternFrequency,
        dataPoints: [NovaDataPoint] = [],
        discoveredAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.confidence = confidence
        self.frequency = frequency
        self.dataPoints = dataPoints
        self.discoveredAt = discoveredAt
    }
}

public enum NovaPatternFrequency: String, Codable, CaseIterable, Hashable {
    case hourly = "Hourly"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case seasonal = "Seasonal"
    case irregular = "Irregular"
}

// MARK: - Convenience Extensions
extension NovaContext {
    public func withAdditionalInsight(_ insight: String) -> NovaContext {
        var newInsights = self.insights
        newInsights.append(insight)
        return NovaContext(
            id: self.id,
            data: self.data,
            timestamp: self.timestamp,
            insights: newInsights,
            metadata: self.metadata
        )
    }
    
    public func withMetadata(key: String, value: String) -> NovaContext {
        var newMetadata = self.metadata
        newMetadata[key] = value
        return NovaContext(
            id: self.id,
            data: self.data,
            timestamp: self.timestamp,
            insights: self.insights,
            metadata: newMetadata
        )
    }
}

extension NovaPrompt {
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    public var isUrgent: Bool {
        return priority.numericValue >= 4
    }
}

extension NovaInsight {
    public var isHighPriority: Bool {
        return priority.numericValue >= 3
    }
    
    public var hasActions: Bool {
        return !suggestedActions.isEmpty
    }
}

// MARK: - Nova Processing State
public enum NovaProcessingState: String, Codable {
    case idle = "idle"
    case processing = "processing"
    case completed = "completed"
    case error = "error"
}
