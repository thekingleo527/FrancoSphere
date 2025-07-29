//
//  NovaTypes.swift
//  FrancoSphere v6.0
//
//  ✅ SIMPLIFIED: Uses CoreTypes for all shared concepts
//  ✅ NO DUPLICATES: Only Nova-specific types defined here
//  ✅ CLEAN: No type conversion needed
//

import Foundation
import SwiftUI

// MARK: - Nova-Specific Types Only

/// Nova context for AI operations
public struct NovaContext: Codable, Hashable, Identifiable {
    public let id: UUID
    public let data: String
    public let timestamp: Date
    public let insights: [String]
    public let metadata: [String: String]
    public let userRole: CoreTypes.UserRole?
    public let buildingContext: CoreTypes.BuildingID?
    public let taskContext: String?
    
    public init(
        id: UUID = UUID(),
        data: String,
        timestamp: Date = Date(),
        insights: [String] = [],
        metadata: [String: String] = [:],
        userRole: CoreTypes.UserRole? = nil,
        buildingContext: CoreTypes.BuildingID? = nil,
        taskContext: String? = nil
    ) {
        self.id = id
        self.data = data
        self.timestamp = timestamp
        self.insights = insights
        self.metadata = metadata
        self.userRole = userRole
        self.buildingContext = buildingContext
        self.taskContext = taskContext
    }
}

/// Nova prompt structure
public struct NovaPrompt: Identifiable, Codable {
    public let id: UUID
    public let text: String
    public let priority: CoreTypes.AIPriority  // Using CoreTypes!
    public let context: NovaContext?
    public let createdAt: Date
    public let expiresAt: Date?
    
    public init(
        id: UUID = UUID(),
        text: String,
        priority: CoreTypes.AIPriority = .medium,
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

/// Nova response structure
public struct NovaResponse: Codable, Identifiable {
    public let id: UUID
    public let success: Bool
    public let message: String
    public let insights: [CoreTypes.IntelligenceInsight]  // Using CoreTypes!
    public let actions: [NovaAction]
    public let confidence: Double
    public let timestamp: Date
    public let processingTime: TimeInterval?
    
    public init(
        id: UUID = UUID(),
        success: Bool,
        message: String,
        insights: [CoreTypes.IntelligenceInsight] = [],
        actions: [NovaAction] = [],
        confidence: Double = 1.0,
        timestamp: Date = Date(),
        processingTime: TimeInterval? = nil
    ) {
        self.id = id
        self.success = success
        self.message = message
        self.insights = insights
        self.actions = actions
        self.confidence = confidence
        self.timestamp = timestamp
        self.processingTime = processingTime
    }
}

/// Nova-specific action (no CoreTypes equivalent)
public struct NovaAction: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let actionType: NovaActionType
    public let parameters: [String: String]
    public let estimatedDuration: TimeInterval?
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        actionType: NovaActionType,
        parameters: [String: String] = [:],
        estimatedDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.actionType = actionType
        self.parameters = parameters
        self.estimatedDuration = estimatedDuration
    }
}

/// Nova action types (no CoreTypes equivalent)
public enum NovaActionType: String, Codable, CaseIterable {
    case navigate = "navigate"
    case schedule = "schedule"
    case assign = "assign"
    case notify = "notify"
    case analysis = "analysis"
    case report = "report"
    case review = "review"
    case complete = "complete"
    
    public var icon: String {
        switch self {
        case .navigate: return "location.fill"
        case .schedule: return "calendar"
        case .assign: return "person.badge.plus"
        case .notify: return "bell.fill"
        case .analysis: return "chart.line.uptrend.xyaxis"
        case .report: return "doc.text.fill"
        case .review: return "magnifyingglass"
        case .complete: return "checkmark.circle"
        }
    }
}

/// Nova processing state
public enum NovaProcessingState: String, Codable {
    case idle = "idle"
    case processing = "processing"
    case completed = "completed"
    case error = "error"
}

// NOTE: NovaAggregatedData is defined in NovaDataAggregator.swift
// NOTE: NovaRecommendation is defined in NovaCore.swift
// We don't redefine them here to avoid duplicates

// MARK: - Error Types

public enum NovaError: Error, LocalizedError {
    case invalidContext
    case promptTooLong(Int)
    case responseTimeout
    case rateLimitExceeded
    case serviceUnavailable
    case processingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidContext:
            return "Invalid context provided to Nova"
        case .promptTooLong(let length):
            return "Prompt too long: \(length) characters"
        case .responseTimeout:
            return "Nova response timed out"
        case .rateLimitExceeded:
            return "Nova rate limit exceeded"
        case .serviceUnavailable:
            return "Nova service temporarily unavailable"
        case .processingFailed(let reason):
            return "Nova processing failed: \(reason)"
        }
    }
}

// MARK: - Convenience Extensions

extension NovaContext {
    /// Check if context is expired (older than 5 minutes)
    public var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > 300
    }
    
    /// Add an insight to the context
    public func withInsight(_ insight: String) -> NovaContext {
        var newInsights = insights
        newInsights.append(insight)
        return NovaContext(
            id: id,
            data: data,
            timestamp: timestamp,
            insights: newInsights,
            metadata: metadata,
            userRole: userRole,
            buildingContext: buildingContext,
            taskContext: taskContext
        )
    }
}

extension NovaPrompt {
    /// Check if prompt has expired
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    /// Check if prompt is high priority
    public var isHighPriority: Bool {
        return priority == .high || priority == .critical
    }
}

extension NovaResponse {
    /// Check if response has critical insights
    public var hasCriticalInsights: Bool {
        return insights.contains { $0.priority == .critical }
    }
    
    /// Get insights by priority
    public func insights(withPriority priority: CoreTypes.AIPriority) -> [CoreTypes.IntelligenceInsight] {
        return insights.filter { $0.priority == priority }
    }
}

// MARK: - Type Aliases for Clarity

public typealias NovaInsight = CoreTypes.IntelligenceInsight
public typealias NovaSuggestion = CoreTypes.AISuggestion
public typealias NovaPriority = CoreTypes.AIPriority
public typealias NovaInsightType = CoreTypes.InsightCategory
