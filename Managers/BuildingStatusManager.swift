import Foundation
import SwiftUI

/// Manages building status based on task completion
class BuildingStatusManager {
    static let shared = BuildingStatusManager()
    
    /// Task‐based statuses for buildings
    enum TaskStatus: String {
        case complete = "Complete"
        case partial  = "Partial"
        case pending  = "Pending"
        case overdue  = "Overdue"
        
        var color: Color {
            switch self {
            case .complete: return .green
            case .partial:  return .yellow
            case .pending:  return .blue
            case .overdue:  return .red
            }
        }
        
        /// Map each TaskStatus into the single FrancoSphere.BuildingStatus enum
        var buildingStatus: FrancoSphere.BuildingStatus {
            switch self {
            case .complete:
                return .operational             // fully operational
            case .partial:
                return .underMaintenance       // partially maintained
            case .pending:
                return .underMaintenance       // pending maintenance
            case .overdue:
                return .closed                 // needs immediate attention
            }
        }
    }
    
    /// A small “chip” view that displays TaskStatus in UI
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
    
    private var buildingStatusCache: [String: TaskStatus] = [:]
    
    private init() {
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
    
    /// Evaluates a TaskStatus for this building ID (caches result)
    func evaluateStatus(for buildingID: String) -> TaskStatus {
        if let cached = buildingStatusCache[buildingID] {
            return cached
        }
        
        let tasks = getAllTasks(for: buildingID)
        let status: TaskStatus
        
        if tasks.isEmpty {
            status = .pending
        } else {
            let completedCount = tasks.filter { $0.isComplete }.count
            
            if completedCount == tasks.count {
                status = .complete
            } else if completedCount == 0 {
                // after 5 PM, mark as overdue; else still pending
                if Calendar.current.component(.hour, from: Date()) >= 17 {
                    status = .overdue
                } else {
                    status = .pending
                }
            } else {
                status = .partial
            }
        }
        
        buildingStatusCache[buildingID] = status
        return status
    }
    
    /// Returns the actual FrancoSphere.BuildingStatus enum for UI logic
    func buildingStatus(for buildingID: String) -> FrancoSphere.BuildingStatus {
        return evaluateStatus(for: buildingID).buildingStatus
    }
    
    /// Returns the color for a building’s status
    func getStatusColor(for buildingID: String) -> Color {
        return evaluateStatus(for: buildingID).color
    }
    
    /// Returns the raw text label for a building’s status
    func getStatusText(for buildingID: String) -> String {
        return evaluateStatus(for: buildingID).rawValue
    }
    
    /// Forces recalculation (removes cache) and emits a notification
    func recalculateStatus(for buildingID: String) {
        buildingStatusCache.removeValue(forKey: buildingID)
        NotificationCenter.default.post(
            name: NSNotification.Name("BuildingStatusChanged"),
            object: nil,
            userInfo: ["buildingID": buildingID]
        )
    }
    
    /// Provides a small chip view (SwiftUI) for the building’s TaskStatus
    func getStatusChip(for buildingID: String) -> StatusChipView {
        let ts = evaluateStatus(for: buildingID)
        return StatusChipView(status: ts)
    }
    
    // MARK: – Private Helpers
    
    /// Called when any task’s “completion status” changes
    @objc private func handleTaskStatusChange(notification: Notification) {
        if let taskID = notification.userInfo?["taskID"] as? String,
           let buildingID = getBuildingIDForTask(taskID) {
            recalculateStatus(for: buildingID)
        }
    }
    
    /// Stub: map a task ID to its building ID
    private func getBuildingIDForTask(_ taskID: String) -> String? {
        // In a real app, query your database. For now, return placeholder.
        return "1"
    }
    
    /// Fetches all tasks (FrancoSphere.MaintenanceTask) for a given building
    private func getAllFrancoSphereTasks(for buildingID: String) -> [FrancoSphere.MaintenanceTask] {
        // Replace with your real data‐fetch. Here, we stub two examples:
        switch buildingID {
        case "1":
            return [
                .init(
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
                .init(
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
                .init(
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
    
    /// Wraps each FrancoSphere.MaintenanceTask into a legacy FSLegacyTask
    private func getAllTasks(for buildingID: String) -> [FSLegacyTask] {
        let fsTasks = getAllFrancoSphereTasks(for: buildingID)
        return fsTasks.map { FSLegacyTask.fromFrancoSphereTask($0) }
    }
}
