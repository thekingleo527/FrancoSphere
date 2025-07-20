//
//  BuildingInsight.swift
//  FrancoSphere
//

import Foundation

public struct BuildingInsight: Codable, Identifiable {
    public let id: String; public let title: String; public let description: String
    public let category: InsightCategory; public let priority: AIPriority
    public let actionable: Bool; public let timestamp: Date

    public init(
        id: String = UUID().uuidString,
        title: String, description: String,
        category: InsightCategory, priority: AIPriority,
        actionable: Bool = true, timestamp: Date = Date()
    ) {
        self.id = id; self.title = title; self.description = description
        self.category = category; self.priority = priority
        self.actionable = actionable; self.timestamp = timestamp
    }
}

public enum InsightCategory: String, CaseIterable, Codable {
    case performance, maintenance, efficiency, compliance, safety, cost
    public var color: Color {
        switch self {
        case .performance: return .blue
        case .maintenance: return .orange
        case .efficiency: return .green
        case .compliance: return .purple
        case .safety: return .red
        case .cost: return .yellow
        }
    }
}

public enum AIPriority: String, CaseIterable, Codable {
    case low, medium, high, critical
    public var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}
