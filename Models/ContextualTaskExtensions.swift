//
//  ContextualTaskExtensions.swift
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
        return "daily"
    }
    
    var buildingName: String {
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
