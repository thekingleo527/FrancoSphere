//
//  ClientDashboardTypes.swift
//  FrancoSphere
//
//  Missing type definitions for compilation fixes
//

import Foundation
import SwiftUI

// MARK: - Portfolio Intelligence Types

public struct PortfolioIntelligence: Codable {
    public let totalBuildings: Int
    public let totalTasks: Int
    public let completedTasks: Int
    public let overdueTasks: Int
    public let averageEfficiency: Double
    public let topPerformingBuildings: [NamedCoordinate]
    public let alertBuildings: [NamedCoordinate]
    public let lastUpdated: Date
    
    public var completionRate: Double {
        totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
    }
    
    public init(
        totalBuildings: Int,
        totalTasks: Int,
        completedTasks: Int,
        overdueTasks: Int,
        averageEfficiency: Double,
        topPerformingBuildings: [NamedCoordinate] = [],
        alertBuildings: [NamedCoordinate] = [],
        lastUpdated: Date = Date()
    ) {
        self.totalBuildings = totalBuildings
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.overdueTasks = overdueTasks
        self.averageEfficiency = averageEfficiency
        self.topPerformingBuildings = topPerformingBuildings
        self.alertBuildings = alertBuildings
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Intelligence Insight Types

public struct IntelligenceInsight: Identifiable, Codable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let actionable: Bool
    public let timestamp: Date
    
    public init(
        title: String,
        description: String,
        type: InsightType,
        priority: InsightPriority,
        actionable: Bool,
        timestamp: Date = Date()
    ) {
        self.title = title
        self.description = description
        self.type = type
        self.priority = priority
        self.actionable = actionable
        self.timestamp = timestamp
    }
}

public enum InsightType: String, CaseIterable, Codable {
    case performance = "Performance"
    case maintenance = "Maintenance"
    case compliance = "Compliance"
    case efficiency = "Efficiency"
    case safety = "Safety"
    case cost = "Cost"
    
    public var icon: String {
        switch self {
        case .performance: return "chart.line.uptrend.xyaxis"
        case .maintenance: return "wrench.and.screwdriver"
        case .compliance: return "checkmark.shield"
        case .efficiency: return "speedometer"
        case .safety: return "shield.lefthalf.filled"
        case .cost: return "dollarsign.circle"
        }
    }
    
    public var color: Color {
        switch self {
        case .performance: return .blue
        case .maintenance: return .orange
        case .compliance: return .green
        case .efficiency: return .purple
        case .safety: return .red
        case .cost: return .yellow
        }
    }
}

public enum InsightPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    public var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Compliance Types

public struct ComplianceIssue: Identifiable, Codable {
    public let id = UUID()
    public let building: NamedCoordinate
    public let issueType: ComplianceIssueType
    public let severity: ComplianceSeverity
    public let description: String
    public let dueDate: Date?
    public let resolvedDate: Date?
    
    public var isResolved: Bool { resolvedDate != nil }
    
    public init(
        building: NamedCoordinate,
        issueType: ComplianceIssueType,
        severity: ComplianceSeverity,
        description: String,
        dueDate: Date? = nil,
        resolvedDate: Date? = nil
    ) {
        self.building = building
        self.issueType = issueType
        self.severity = severity
        self.description = description
        self.dueDate = dueDate
        self.resolvedDate = resolvedDate
    }
}

public enum ComplianceIssueType: String, CaseIterable, Codable {
    case maintenanceOverdue = "Maintenance Overdue"
    case safetyViolation = "Safety Violation"
    case documentationMissing = "Documentation Missing"
    case inspectionRequired = "Inspection Required"
    case certificationExpired = "Certification Expired"
    
    public var icon: String {
        switch self {
        case .maintenanceOverdue: return "wrench.and.screwdriver"
        case .safetyViolation: return "exclamationmark.triangle"
        case .documentationMissing: return "doc.text"
        case .inspectionRequired: return "magnifyingglass"
        case .certificationExpired: return "calendar.badge.exclamationmark"
        }
    }
}

public enum ComplianceSeverity: String, CaseIterable, Codabe {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Building Analytics Types

public struct BuildingAnalytics: Codable {
    public let buildingId: String
    public let completionRate: Double
    public let overdueTasks: Int
    public let efficiency: Double
    public let lastUpdated: Date
    
    public init(
        buildingId: String,
        completionRate: Double,
        overdueTasks: Int,
        efficiency: Double,
        lastUpdated: Date = Date()
    ) {
        self.buildingId = buildingId
        self.completionRate = completionRate
        self.overdueTasks = overdueTasks
        self.efficiency = efficiency
        self.lastUpdated = lastUpdated
    }
}

public struct BuildingOperationalInsights: Codable {
    public let predictiveMaintenanceAlerts: [String]
    public let efficiencyTrends: [Double]
    public let costOptimizations: [String]
    
    public init(
        predictiveMaintenanceAlerts: [String] = [],
        efficiencyTrends: [Double] = [],
        costOptimizations: [String] = []
    ) {
        self.predictiveMaintenanceAlerts = predictiveMaintenanceAlerts
        self.efficiencyTrends = efficiencyTrends
        self.costOptimizations = costOptimizations
    }
}
