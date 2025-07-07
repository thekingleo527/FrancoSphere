//
//  ContextualTaskIntelligence.swift
//  FrancoSphere
//

import Foundation

extension ContextualTask {
    var startTime: String {
        if let dueDate = dueDate {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: dueDate)
        }
        return "9:00 AM"
    }
    
    var endTime: String {
        if let dueDate = dueDate {
            let endDate = dueDate.addingTimeInterval(estimatedDuration)
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: endDate)
        }
        return "10:00 AM"
    }
    
    var recurrence: String {
        if name.lowercased().contains("daily") {
            return "daily"
        } else if name.lowercased().contains("weekly") {
            return "weekly"
        }
        return "one-time"
    }
    
    var buildingName: String {
        if let buildings = WorkerContextEngine.shared.getAssignedBuildings().first(where: { $0.id == buildingId }) {
            return buildings.name
        }
        return "Building \(buildingId)"
    }
    
    var assignedWorkerName: String? {
        if workerId == NewAuthManager.shared.workerId {
            return NewAuthManager.shared.currentWorkerName
        }
        return nil
    }
    
    var scheduledDate: Date? {
        return dueDate
    }
}
