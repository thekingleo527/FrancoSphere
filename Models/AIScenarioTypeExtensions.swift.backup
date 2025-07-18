//
//  AIScenarioTypeExtensions.swift
//  FrancoSphere
//
//  Extensions for AI scenario types
//

import Foundation

// MARK: - AIScenarioType Extensions
extension AIScenarioType {
    public var displayTitle: String {
        switch self {
        case .routineIncomplete:
            return "Routine Incomplete"
        case .taskCompletion:
            return "Task Completion"
        case .pendingTasks:
            return "Pending Tasks"
        case .buildingArrival:
            return "Building Arrival"
        case .weatherAlert:
            return "Weather Alert"
        case .maintenanceRequired:
            return "Maintenance Required"
        case .scheduleConflict:
            return "Schedule Conflict"
        case .emergencyResponse:
            return "Emergency Response"
        }
    }
    
    public var defaultDescription: String {
        switch self {
        case .routineIncomplete:
            return "Some routine tasks are incomplete"
        case .taskCompletion:
            return "Task is ready for completion"
        case .pendingTasks:
            return "You have pending tasks that need attention"
        case .buildingArrival:
            return "You've arrived at a building"
        case .weatherAlert:
            return "Weather conditions may affect your work"
        case .maintenanceRequired:
            return "Equipment or area needs maintenance"
        case .scheduleConflict:
            return "There's a conflict in your schedule"
        case .emergencyResponse:
            return "Emergency situation requires immediate attention"
        }
    }
    
    public var icon: String {
        switch self {
        case .routineIncomplete:
            return "clock"
        case .taskCompletion:
            return "checkmark.circle"
        case .pendingTasks:
            return "list.bullet"
        case .buildingArrival:
            return "building.2"
        case .weatherAlert:
            return "cloud.rain"
        case .maintenanceRequired:
            return "wrench"
        case .scheduleConflict:
            return "calendar.badge.exclamationmark"
        case .emergencyResponse:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - AIPriority Enum
public enum AIPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    case critical = "Critical"
    
    public var color: String {
        switch self {
        case .low:
            return "gray"
        case .medium:
            return "blue"
        case .high:
            return "orange"
        case .urgent:
            return "red"
        case .critical:
            return "purple"
        }
    }
}
