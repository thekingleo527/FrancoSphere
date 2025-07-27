//
//  AIScenarioTypeExtensions.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Updated to use only existing AIScenarioType cases
//  ✅ ALIGNED: With canonical definition from AIScenarioSheetView.swift
//  ✅ REMOVED: Duplicate AIPriority enum (exists in CoreTypes.swift)
//

import Foundation

// MARK: - AIScenarioType Extensions
extension AIScenarioType {
    public var displayTitle: String {
        switch self {
        case .routineIncomplete:
            return "Routine Incomplete"
        case .pendingTasks:
            return "Pending Tasks"
        case .weatherAlert:
            return "Weather Alert"
        case .clockOutReminder:
            return "Clock Out Reminder"
        case .inventoryLow:
            return "Inventory Low"
        case .emergencyRepair:
            return "Emergency Repair"
        case .taskOverdue:
            return "Task Overdue"
        case .buildingAlert:
            return "Building Alert"
        }
    }
    
    public var defaultDescription: String {
        switch self {
        case .routineIncomplete:
            return "Some routine tasks are incomplete"
        case .pendingTasks:
            return "You have pending tasks that need attention"
        case .weatherAlert:
            return "Weather conditions may affect your work"
        case .clockOutReminder:
            return "Remember to clock out when you finish"
        case .inventoryLow:
            return "Inventory levels are running low"
        case .emergencyRepair:
            return "Emergency repair situation requires attention"
        case .taskOverdue:
            return "Tasks are overdue and need immediate attention"
        case .buildingAlert:
            return "Building alert requires your attention"
        }
    }
    
    public var icon: String {
        switch self {
        case .routineIncomplete:
            return "clock"
        case .pendingTasks:
            return "list.bullet"
        case .weatherAlert:
            return "cloud.rain"
        case .clockOutReminder:
            return "clock.badge.exclamationmark"
        case .inventoryLow:
            return "cube.box"
        case .emergencyRepair:
            return "exclamationmark.triangle"
        case .taskOverdue:
            return "clock.badge.exclamationmark"
        case .buildingAlert:
            return "building.2"
        }
    }
    
    public var priority: CoreTypes.AIPriority {
        switch self {
        case .emergencyRepair:
            return .critical
        case .taskOverdue:
            return .high
        case .weatherAlert:
            return .high
        case .buildingAlert:
            return .high
        case .clockOutReminder:
            return .medium
        case .routineIncomplete:
            return .medium
        case .pendingTasks:
            return .medium
        case .inventoryLow:
            return .low
        }
    }
}

// MARK: - REMOVED: AIPriority enum (already exists in CoreTypes.swift)
// The AIPriority enum has been removed from this file to eliminate duplication.
// Use CoreTypes.AIPriority instead.
