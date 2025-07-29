//
//  NovaTypes.swift
//  FrancoSphere v6.0
//
//  ✅ SIMPLIFIED: Uses CoreTypes for all shared concepts
//  ✅ NO DUPLICATES: Only Nova-specific types defined here
//  ✅ CLEAN: No type conversion needed
//  ✅ ENHANCED: Added scenario support types
//

import Foundation
import SwiftUI

// MARK: - Nova-Specific Types Only

/// Nova context for AI operations
public struct NovaContext: Codable, Hashable, Identifiable, Sendable {
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
public struct NovaPrompt: Identifiable, Codable, Sendable {
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
public struct NovaResponse: Codable, Identifiable, Sendable {
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
public struct NovaAction: Identifiable, Codable, Sendable {
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

// MARK: - Scenario Support Types

/// Nova scenario data for AI-driven scenarios
public struct NovaScenarioData: Identifiable, Codable, Sendable {
    public let id: UUID
    public let scenario: CoreTypes.AIScenarioType
    public let message: String
    public let actionText: String
    public let createdAt: Date
    public let priority: CoreTypes.AIPriority
    public let context: [String: String]
    
    public init(
        id: UUID = UUID(),
        scenario: CoreTypes.AIScenarioType,
        message: String,
        actionText: String,
        createdAt: Date = Date(),
        priority: CoreTypes.AIPriority? = nil,
        context: [String: String] = [:]
    ) {
        self.id = id
        self.scenario = scenario
        self.message = message
        self.actionText = actionText
        self.createdAt = createdAt
        self.priority = priority ?? scenario.priority
        self.context = context
    }
}

/// Emergency repair state for tracking repair progress
public struct NovaEmergencyRepairState: Sendable {
    public var isActive: Bool = false
    public var progress: Double = 0.0
    public var message: String = ""
    public var workerId: String?
    
    public init(
        isActive: Bool = false,
        progress: Double = 0.0,
        message: String = "",
        workerId: String? = nil
    ) {
        self.isActive = isActive
        self.progress = progress
        self.message = message
        self.workerId = workerId
    }
}

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

extension NovaScenarioData {
    /// Check if scenario is high priority
    public var isHighPriority: Bool {
        return priority == .high || priority == .critical
    }
    
    /// Get scenario icon
    public var icon: String {
        return scenario.icon
    }
    
    /// Get scenario display title
    public var displayTitle: String {
        return scenario.displayTitle
    }
    
    /// Get scenario color
    public var color: Color {
        return scenario.color
    }
}

// MARK: - Type Aliases for Clarity

public typealias NovaInsight = CoreTypes.IntelligenceInsight
public typealias NovaSuggestion = CoreTypes.AISuggestion
public typealias NovaPriority = CoreTypes.AIPriority
public typealias NovaInsightType = CoreTypes.InsightCategory
public typealias NovaScenarioType = CoreTypes.AIScenarioType

// MARK: - Extension to AIScenarioType for UI Support

extension CoreTypes.AIScenarioType {
    public var icon: String {
        switch self {
        case .clockOutReminder: return "clock.arrow.circlepath"
        case .weatherAlert: return "cloud.rain.fill"
        case .inventoryLow: return "shippingbox.fill"
        case .routineIncomplete: return "exclamationmark.circle.fill"
        case .pendingTasks: return "list.bullet.clipboard.fill"
        case .emergencyRepair: return "wrench.and.screwdriver.fill"
        case .taskOverdue: return "clock.badge.exclamationmark"
        case .buildingAlert: return "building.2.fill"
        }
    }
    
    public var displayTitle: String {
        switch self {
        case .clockOutReminder: return "Clock Out Reminder"
        case .weatherAlert: return "Weather Alert"
        case .inventoryLow: return "Inventory Low"
        case .routineIncomplete: return "Routine Incomplete"
        case .pendingTasks: return "Pending Tasks"
        case .emergencyRepair: return "Emergency Repair"
        case .taskOverdue: return "Task Overdue"
        case .buildingAlert: return "Building Alert"
        }
    }
    
    public var color: Color {
        switch self {
        case .clockOutReminder: return .red
        case .weatherAlert: return .yellow
        case .inventoryLow: return .orange
        case .routineIncomplete: return .orange
        case .pendingTasks: return .blue
        case .emergencyRepair: return .red
        case .taskOverdue: return .red
        case .buildingAlert: return .orange
        }
    }
}
