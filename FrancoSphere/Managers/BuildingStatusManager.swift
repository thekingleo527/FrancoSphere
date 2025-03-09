import Foundation
import SwiftUI

/// Manages building status based on task completion
class BuildingStatusManager {
    static let shared = BuildingStatusManager()
    
    /// Task-based statuses for buildings
    enum TaskStatus: String {
        case complete = "Complete"
        case partial = "Partial"
        case pending = "Pending"
        case overdue = "Overdue"
        
        var color: Color {
            switch self {
            case .complete: return .green
            case .partial: return .yellow
            case .pending: return .blue
            case .overdue: return .red
            }
        }
        
        var buildingStatus: FSBuildingStatus {
            switch self {
            case .complete: return .operational // Fully operational
            case .partial: return .underMaintenance // Partially maintained
            case .pending: return .underMaintenance // Pending maintenance
            case .overdue: return .closed // Requires immediate attention
            }
        }
    }
    
    /// UI component for displaying task status
    struct StatusChipView: View {
        let status: TaskStatus
        
        var body: some View {
            Text(status.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(status.color)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    
    // Cache for building statuses
    private var buildingStatusCache: [String: TaskStatus] = [:]
    
    private init() {
        // Subscribe to task completion notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskStatusChange),
            name: NSNotification.Name("TaskCompletionStatusChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Evaluates the status of a building based on task completion
    func evaluateStatus(for buildingID: String) -> TaskStatus {
        // If cached, return from cache
        if let cachedStatus = buildingStatusCache[buildingID] {
            return cachedStatus
        }
        
        // Get all tasks for this building today
        let tasks = getAllTasks(for: buildingID)
        
        if tasks.isEmpty {
            let status = TaskStatus.pending
            buildingStatusCache[buildingID] = status
            return status
        }
        
        let completedTasks = tasks.filter { $0.isComplete }
        
        if completedTasks.count == tasks.count {
            let status = TaskStatus.complete
            buildingStatusCache[buildingID] = status
            return status
        } else if completedTasks.isEmpty {
            // Check if end of day
            if Calendar.current.component(.hour, from: Date()) >= 17 {
                let status = TaskStatus.overdue
                buildingStatusCache[buildingID] = status
                return status
            } else {
                let status = TaskStatus.pending
                buildingStatusCache[buildingID] = status
                return status
            }
        } else {
            let status = TaskStatus.partial
            buildingStatusCache[buildingID] = status
            return status
        }
    }
    
    /// Gets the color associated with a building's status
    func getStatusColor(for buildingID: String) -> Color {
        return evaluateStatus(for: buildingID).color
    }
    
    /// Gets the text label for a building's status
    func getStatusText(for buildingID: String) -> String {
        return evaluateStatus(for: buildingID).rawValue
    }
    
    /// Recalculates status for a building after task status changes
    func recalculateStatus(for buildingID: String) {
        // Remove from cache to force recalculation next time
        buildingStatusCache.removeValue(forKey: buildingID)
        
        // Notify any subscribers that the status has changed
        NotificationCenter.default.post(
            name: NSNotification.Name("BuildingStatusChanged"),
            object: nil,
            userInfo: ["buildingID": buildingID]
        )
    }
    
    /// Gets a StatusChipView for displaying a building's status
    func getStatusChip(for buildingID: String) -> StatusChipView {
        let status = evaluateStatus(for: buildingID)
        return StatusChipView(status: status)
    }
    
    // MARK: - Private Methods
    
    /// Handles task status change notifications
    @objc private func handleTaskStatusChange(notification: Notification) {
        if let taskID = notification.userInfo?["taskID"] as? String,
           let buildingID = getBuildingIDForTask(taskID) {
            recalculateStatus(for: buildingID)
        }
    }
    
    /// Gets building ID for a task
    private func getBuildingIDForTask(_ taskID: String) -> String? {
        // This would normally query your database
        // For now, just return a placeholder
        return "1"
    }
    
    /// Gets all tasks for a building - using FSLegacyTask
    private func getAllTasks(for buildingID: String) -> [FSLegacyTask] {
        // Convert from FrancoSphere.MaintenanceTask to FSLegacyTask
        let francoSphereTasks = getAllFrancoSphereTasks(for: buildingID)
        return francoSphereTasks.map { FSLegacyTask.fromFrancoSphereTask($0) }
    }
    
    /// Gets all tasks for a building in FrancoSphere namespace format
    private func getAllFrancoSphereTasks(for buildingID: String) -> [FrancoSphere.MaintenanceTask] {
        // This would normally query your database
        // For now, return a hardcoded list based on the building ID
        
        // For testing purposes, create different statuses for different buildings
        switch buildingID {
        case "1":
            return [
                FrancoSphere.MaintenanceTask(
                    id: UUID().uuidString,
                    name: "Daily Cleaning",
                    buildingID: buildingID,
                    description: "Regular daily cleaning",
                    dueDate: Date(),
                    category: .cleaning,
                    urgency: .medium,
                    recurrence: .daily,
                    isComplete: true
                )
            ]
        case "2":
            return [
                FrancoSphere.MaintenanceTask(
                    id: UUID().uuidString,
                    name: "Inspect HVAC",
                    buildingID: buildingID,
                    description: "Routine HVAC inspection",
                    dueDate: Date(),
                    category: .inspection,
                    urgency: .medium,
                    recurrence: .monthly,
                    isComplete: false
                ),
                FrancoSphere.MaintenanceTask(
                    id: UUID().uuidString,
                    name: "Clean Lobby",
                    buildingID: buildingID,
                    description: "Lobby cleaning",
                    dueDate: Date(),
                    category: .cleaning,
                    urgency: .low,
                    recurrence: .daily,
                    isComplete: true
                )
            ]
        default:
            return []
        }
    }
}
