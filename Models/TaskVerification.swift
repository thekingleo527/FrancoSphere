// TaskVerification.swift
// Handles task verification and status tracking

import Foundation
import SwiftUI

// MARK: - Maintenance Task Extensions

extension MaintenanceTask {  // Remove FrancoSphere.
    /// Converts a maintenance task to a legacy task item format
    func toVerificationTaskItem() -> FSTaskItem {
        let intId = Int64(self.id) ?? 0
        let buildingIntId = Int64(self.buildingID) ?? 0
        let workerIntId = self.assignedWorkers.first.flatMap { Int64($0) } ?? 0

        return FSTaskItem(
            id: intId,
            name: self.name,
            description: self.description,
            buildingId: buildingIntId,
            workerId: workerIntId,
            isCompleted: self.isComplete,
            scheduledDate: self.dueDate
        )
    }

    /// Returns true if the task needs verification
    var needsVerification: Bool {
        return isComplete && (verificationStatus == nil || verificationStatus == .pending)
    }

    /// Returns the formatted completion date if available
    var formattedCompletionDate: String? {
        guard let date = completionInfo?.date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Building Status Functions

/// Determines a building's operational status based on task completion percentage
func getVerificationStatusForBuilding(_ buildingId: String) -> BuildingStatus {  // Remove FrancoSphere.
    let completionPercentage = computeCompletionPercentage(for: buildingId)

    if completionPercentage >= 0.9 {
        return .operational
    } else if completionPercentage >= 0.6 {
        return .underMaintenance
    } else if completionPercentage >= 0.3 {
        return .underMaintenance
    } else {
        return .closed
    }
}

/// Calculates the percentage of completed tasks for a building
private func computeCompletionPercentage(for buildingId: String) -> Double {
    // This would typically query your data store to get actual task completion data
    // For now, return a sample value
    #if DEBUG
    // Return different values for different buildings in debug mode for testing
    switch buildingId {
    case "1": return 0.95 // Fully operational
    case "2": return 0.75 // Routine partial
    case "3": return 0.45 // Under maintenance
    case "4": return 0.15 // Closed
    default: return 0.75   // Default value
    }
    #else
    // In production, this would calculate based on actual database values
    // Placeholder implementation
    return 0.75
    #endif
}

// MARK: - Task Verification Helper

/// Provides utility methods for task verification operations
struct TaskVerificationHelper {
    /// Marks a task as verified
    static func verifyTask(_ task: MaintenanceTask, verifierId: String) -> MaintenanceTask {  // Remove FrancoSphere.
        var updatedTask = task
        updatedTask.verificationStatus = VerificationStatus.verified  // Remove FrancoSphere.
        return updatedTask
    }

    /// Marks a task as rejected with a reason
    static func rejectTask(
        _ task: MaintenanceTask,  // Remove FrancoSphere.
        verifierId: String,
        reason: String
    ) -> MaintenanceTask {  // Remove FrancoSphere.
        var updatedTask = task
        updatedTask.verificationStatus = VerificationStatus.rejected  // Remove FrancoSphere.
        return updatedTask
    }

    /// Marks a task as pending verification
    static func pendingVerification(_ task: MaintenanceTask) -> MaintenanceTask {  // Remove FrancoSphere.
        var updatedTask = task
        updatedTask.verificationStatus = VerificationStatus.pending  // Remove FrancoSphere.
        return updatedTask
    }

    /// Creates a verification record for a task
    static func createVerificationRecord(
        task: MaintenanceTask,  // Remove FrancoSphere.
        verifierId: String,
        status: VerificationStatus  // Remove FrancoSphere.
    ) -> TaskCompletionRecord {  // Remove FrancoSphere.
        return TaskCompletionRecord(
            taskId: task.id,
            buildingID: task.buildingID,
            workerId: task.assignedWorkers.first ?? "",
            completionDate: Date(),
            notes: "Verification by \(verifierId)",
            photoPath: task.completionInfo?.photoPath,
            verificationStatus: status,
            verifierID: verifierId,
            verificationDate: Date()
        )
    }

    /// Returns tasks that need verification for a specific building
    static func tasksNeedingVerification(
        for buildingId: String,
        from tasks: [MaintenanceTask]  // Remove FrancoSphere.
    ) -> [MaintenanceTask] {  // Remove FrancoSphere.
        return tasks.filter { task in
            task.buildingID == buildingId && task.needsVerification
        }
    }

    /// Returns tasks that were recently verified
    static func recentlyVerifiedTasks(
        from tasks: [MaintenanceTask],  // Remove FrancoSphere.
        days: Int = 7
    ) -> [MaintenanceTask] {  // Remove FrancoSphere.
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return tasks.filter { task in
            if let status = task.verificationStatus, status == .verified {
                if let completionDate = task.completionInfo?.date {
                    return completionDate >= cutoffDate
                }
            }
            return false
        }
    }
}

// MARK: - Color Helper Functions

/// Returns the appropriate color for a verification status
private func getVerificationStatusColor(_ status: VerificationStatus) -> Color {  // Remove FrancoSphere.
    switch status {
    case .pending:  return .orange
    case .verified: return .green
    case .rejected: return .red
    }
}

// MARK: - Building Status Extensions

extension BuildingStatus {  // Remove FrancoSphere.
    /// Returns a user‐friendly status text
    func getStatusText() -> String {
        return self.rawValue
    }
    
    /// Returns an appropriate icon name for the status
    func getIconName() -> String {  // FIX: Changed 'unc' to 'func'
        switch self {
        case .operational:
            return "checkmark.circle.fill"
        case .underMaintenance:
            return "wrench.fill"
        case .closed:
            return "xmark.circle.fill"
        case .routineComplete:
            return "checkmark.seal.fill"
        case .routinePartial:
            return "clock.badge.checkmark.fill"
        case .routinePending:
            return "clock.fill"
        case .routineOverdue:
            return "exclamationmark.clock.fill"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    /// Returns a "color" to use for this status badge
    var color: Color {
        switch self {
        case .operational:
            return .green
        case .underMaintenance:
            return .orange
        case .closed:
            return .red
        case .routineComplete:
            return .green
        case .routinePartial:
            return .yellow
        case .routinePending:
            return .orange
        case .routineOverdue:
            return .red
        @unknown default:
            return .gray
        }
    }
}

// MARK: - SwiftUI Components

/// A view component for displaying verification status
struct VerificationStatusBadge: View {
    let status: VerificationStatus?  // Remove FrancoSphere.
    
    var body: some View {
        if let status = status {
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.caption)
                Text(status.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(getVerificationStatusColor(status).opacity(0.2))
            .foregroundColor(getVerificationStatusColor(status))
            .cornerRadius(8)
        } else {
            EmptyView()
        }
    }
}

/// A view component for displaying building status
struct BuildingStatusBadge: View {
    let status: BuildingStatus  // Remove FrancoSphere.
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.getIconName())
                .font(.caption)
            Text(status.getStatusText())
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.2))
        .foregroundColor(status.color)
        .cornerRadius(8)
    }
}
