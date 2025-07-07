//
//  WorkerActionType.swift
//  FrancoSphere
//
//  ✅ V6.0: Foundational Type Definition
//  ✅ Creates a single source of truth for all worker actions.
//  ✅ Resolves 'Cannot find type' errors in WorkerEventOutbox and WorkerFeedbackManager.
//

import Foundation

/// An enumeration of all possible actions a worker can perform and sync.
/// This provides a single, authoritative source for action types across the app.
public enum WorkerActionType: String, Codable, CaseIterable {
    case taskCompletion = "task_completion"
    case clockIn = "clock_in"
    case clockOut = "clock_out"
    case photoUpload = "photo_upload"
    case commentUpdate = "comment_update"
    case routineInspection = "routine_inspection"
    case buildingStatusUpdate = "building_status_update"
    case emergencyReport = "emergency_report"
    
    /// A user-friendly name for displaying the action in the UI.
    public var displayName: String {
        return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
