//
//  AITypes.swift
//  FrancoSphere
//
//  AI-related types and enums
//

import Foundation

// MARK: - AI Scenario Types
public enum AIScenarioType: String, CaseIterable {
    case routineIncomplete = "routine_incomplete"
    case taskCompletion = "task_completion" 
    case pendingTasks = "pending_tasks"
    case buildingArrival = "building_arrival"
    case weatherAlert = "weather_alert"
    case maintenanceRequired = "maintenance_required"
    case scheduleConflict = "schedule_conflict"
    case emergencyResponse = "emergency_response"
}

// MARK: - AI Priority
public enum AIPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    case critical = "Critical"
    
    public var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        case .critical: return "purple"
        }
    }
}

// MARK: - Worker Status (Consolidated)
public enum WorkerStatus: String, CaseIterable, Codable {
    case available = "Available"
    case busy = "Busy"
    case clockedIn = "Clocked In"
    case clockedOut = "Clocked Out"
    case onBreak = "On Break"
    case offline = "Offline"
}
