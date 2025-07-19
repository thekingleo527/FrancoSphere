//
//  ModelExtensions.swift
//  FrancoSphere
//
//  ✅ V6.0: Adds UI-specific properties to core data models.
//

import SwiftUI

// Type aliases for CoreTypes
typealias MaintenanceTask = CoreTypes.MaintenanceTask
typealias TaskCategory = CoreTypes.TaskCategory
typealias TaskUrgency = CoreTypes.TaskUrgency
typealias BuildingType = CoreTypes.BuildingType
typealias BuildingTab = CoreTypes.BuildingTab
typealias WeatherCondition = CoreTypes.WeatherCondition
typealias BuildingMetrics = CoreTypes.BuildingMetrics
typealias TaskProgress = CoreTypes.TaskProgress
typealias FrancoWorkerAssignment = CoreTypes.FrancoWorkerAssignment
typealias InventoryItem = CoreTypes.InventoryItem
typealias InventoryCategory = CoreTypes.InventoryCategory
typealias RestockStatus = CoreTypes.RestockStatus
typealias ComplianceStatus = CoreTypes.ComplianceStatus
typealias BuildingStatistics = CoreTypes.BuildingStatistics
typealias WorkerSkill = CoreTypes.WorkerSkill
typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
typealias ComplianceIssue = CoreTypes.ComplianceIssue


extension TaskCategory {
    var color: Color {
        switch self {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .sanitation: return .green
        case .inspection: return .purple
        default: return .gray
        }
    }
}

extension TaskUrgency {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high, .urgent, .critical, .emergency: return .red
        default: return .gray
        }
    }
}
