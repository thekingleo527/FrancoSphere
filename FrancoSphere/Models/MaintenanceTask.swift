//
//  MaintenanceTask.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/30/25.
//

import Foundation
import SwiftUI

/// Renamed to FSLegacyTask to avoid conflicts with FrancoSphere.MaintenanceTask
struct FSLegacyTask: Identifiable {
    let id: String
    let name: String
    let buildingID: String
    let description: String
    let dueDate: Date
    let startTime: Date?
    let endTime: Date?
    let category: FrancoSphere.TaskCategory
    let urgency: FrancoSphere.TaskUrgency
    let recurrence: FrancoSphere.TaskRecurrence
    var assignedWorkers: [String]
    var isComplete: Bool = false
    
    /// Returns true if the task is past its due date
    var isPastDue: Bool {
        if isComplete {
            return false
        }
        return Date() > dueDate
    }
    
    /// The color to use when displaying the task's status
    var statusColor: Color {
        if isComplete {
            return .green
        } else if isPastDue {
            return .red
        } else if urgency == .urgent || urgency == .high {
            return .orange
        } else {
            return .blue
        }
    }
    
    /// The text to display for the task's status
    var statusText: String {
        if isComplete {
            return "Completed"
        } else if isPastDue {
            return "Overdue"
        } else if Date().addingTimeInterval(3600) > dueDate {
            return "Due Soon"
        } else {
            return "Scheduled"
        }
    }
    
    /// Convert to FrancoSphere.MaintenanceTask
    func toFrancoSphereTask() -> FrancoSphere.MaintenanceTask {
        return FrancoSphere.MaintenanceTask(
            id: id,
            name: name,
            buildingID: buildingID,
            description: description,
            dueDate: dueDate,
            startTime: startTime,
            endTime: endTime,
            category: category,
            urgency: urgency,
            recurrence: recurrence,
            isComplete: isComplete,
            assignedWorkers: assignedWorkers,
            requiredSkillLevel: "Basic" // Default value
        )
    }
    
    /// Create from FrancoSphere.MaintenanceTask
    static func fromFrancoSphereTask(_ task: FrancoSphere.MaintenanceTask) -> FSLegacyTask {
        return FSLegacyTask(
            id: task.id,
            name: task.name,
            buildingID: task.buildingID,
            description: task.description,
            dueDate: task.dueDate,
            startTime: task.startTime,
            endTime: task.endTime,
            category: task.category,
            urgency: task.urgency,
            recurrence: task.recurrence,
            assignedWorkers: task.assignedWorkers,
            isComplete: task.isComplete
        )
    }
}

// MARK: - Helper Extensions

extension FSLegacyTask {
    /// Creates a sample task for preview purposes
    static func sampleTask() -> FSLegacyTask {
        return FSLegacyTask(
            id: "T1001",
            name: "Inspect HVAC System",
            buildingID: "B101",
            description: "Regular maintenance inspection of HVAC units including filter replacement and checking refrigerant levels.",
            dueDate: Date(),
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(7200),
            category: .maintenance,
            urgency: .medium,
            recurrence: .monthly,
            assignedWorkers: ["W101"]
        )
    }
    
    /// Creates an array of sample tasks for preview purposes
    static func sampleTasks() -> [FSLegacyTask] {
        return [
            FSLegacyTask(
                id: "T1001",
                name: "Inspect HVAC System",
                buildingID: "B101",
                description: "Regular maintenance inspection of HVAC units including filter replacement and checking refrigerant levels.",
                dueDate: Date(),
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(7200),
                category: .maintenance,
                urgency: .medium,
                recurrence: .monthly,
                assignedWorkers: ["W101"]
            ),
            FSLegacyTask(
                id: "T1002",
                name: "Clean Lobby",
                buildingID: "B101",
                description: "Vacuum, dust, and empty trash bins in the lobby area.",
                dueDate: Date(),
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date().addingTimeInterval(1800),
                category: .cleaning,
                urgency: .high,
                recurrence: .daily,
                assignedWorkers: ["W102"],
                isComplete: true
            ),
            FSLegacyTask(
                id: "T1003",
                name: "Fix Leaking Sink",
                buildingID: "B102",
                description: "Repair leaking sink in 3rd floor bathroom.",
                dueDate: Date().addingTimeInterval(-86400),
                startTime: nil,
                endTime: nil,
                category: .repair,
                urgency: .urgent,
                recurrence: .oneTime,
                assignedWorkers: ["W103"]
            )
        ]
    }
}

// MARK: - Extension for FrancoSphere.TaskRecurrence
extension FrancoSphere.TaskRecurrence {
    /// Determines if a task should be scheduled on a particular date
    func shouldSchedule(lastDone: Date?, targetDate: Date) -> Bool {
        guard let lastDone = lastDone else {
            // If never done before, then yes
            return true
        }
        
        let calendar = Calendar.current
        
        switch self {
        case .daily:
            // Not if already done today
            return !calendar.isDate(lastDone, inSameDayAs: targetDate)
            
        case .weekly:
            // If at least 7 days since last done
            let nextDate = calendar.date(byAdding: .day, value: 7, to: lastDone)!
            return targetDate >= nextDate
            
        case .biweekly:
            // If at least 14 days since last done
            let nextDate = calendar.date(byAdding: .day, value: 14, to: lastDone)!
            return targetDate >= nextDate
            
        case .monthly:
            // If in a different month than last done
            let nextDate = calendar.date(byAdding: .month, value: 1, to: lastDone)!
            return targetDate >= nextDate
            
        case .quarterly:
            // If at least 3 months since last done
            let nextDate = calendar.date(byAdding: .month, value: 3, to: lastDone)!
            return targetDate >= nextDate
            
        case .semiannual:
            // If at least 6 months since last done
            let nextDate = calendar.date(byAdding: .month, value: 6, to: lastDone)!
            return targetDate >= nextDate
            
        case .annual:
            // If at least 1 year since last done
            let nextDate = calendar.date(byAdding: .year, value: 1, to: lastDone)!
            return targetDate >= nextDate
            
        case .oneTime:
            // One-time tasks should not recur
            return false
        }
    }
}

// Type aliases for backward compatibility
typealias MaintenanceTaskLegacy = FSLegacyTask
