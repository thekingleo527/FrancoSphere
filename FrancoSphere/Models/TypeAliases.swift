import Foundation
import SwiftUI
import CoreLocation

// MARK: - Legacy Type Aliases
// These type aliases ensure backward compatibility

// Define FSBuildingStatus which is referenced but missing
public enum FSBuildingStatus: String, Codable, Hashable {
    case operational = "Operational"
    case underMaintenance = "Under Maintenance"
    case closed = "Closed"
    
    public var color: Color {
        switch self {
        case .operational: return .green
        case .underMaintenance: return .orange
        case .closed: return .red
        }
    }
}

// No need to redefine VerificationStatus as it's already in FrancoSphere
// Use FrancoSphere's VerificationStatus instead
public typealias FSVerificationStatus = FrancoSphere.VerificationStatus

// Additional type aliases for legacy code support
public typealias FSNamedCoordinate = FrancoSphere.NamedCoordinate
public typealias FSTaskUrgency = FrancoSphere.TaskUrgency
public typealias FSTaskCategory = FrancoSphere.TaskCategory
public typealias FSMaintenanceTask = FrancoSphere.MaintenanceTask
public typealias FSTaskRecurrence = FrancoSphere.TaskRecurrence
public typealias FSTaskCompletionInfo = FrancoSphere.TaskCompletionInfo
public typealias FSTaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias FSMaintenanceRecord = FrancoSphere.MaintenanceRecord
public typealias FSWorkerSkill = FrancoSphere.WorkerSkill
public typealias FSSkillLevel = FrancoSphere.SkillLevel
public typealias FSUserRole = FrancoSphere.UserRole
public typealias FSWorkerProfile = FrancoSphere.WorkerProfile
public typealias FSWorkerAssignment = FrancoSphere.WorkerAssignment
public typealias FSTaskTemplate = FrancoSphere.TaskTemplate

// Use explicit FrancoSphere namespace to avoid ambiguity
extension FSVerificationStatus {
    public static func convertFromFS(_ status: FrancoSphere.VerificationStatus) -> FSVerificationStatus {
        switch status {
        case .pending: return .pending
        case .verified: return .verified
        case .rejected: return .rejected
        }
    }
}
