//
//  AIScenario.swift
//  FrancoSphere v6.0
//
//  ✅ GENERATED: By comprehensive fix script
//  ✅ NOVA AI: Core type for scenario management
//

import Foundation

public struct AIScenario: Codable, Identifiable, Hashable {
    public let id: String
    public let scenario: String
    public let description: String
    public let context: [String: String]
    public let priority: AIPriority
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        scenario: String,
        description: String,
        context: [String: String] = [:],
        priority: AIPriority = .medium,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scenario = scenario
        self.description = description
        self.context = context
        self.priority = priority
        self.createdAt = createdAt
    }
}

public enum AIPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"  
    case high = "High"
    case critical = "Critical"
    
    public var priorityValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}
