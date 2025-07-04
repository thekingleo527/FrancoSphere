// Extensions/ContextualTaskExtensions.swift
// 🔧 Extensions for immutable ContextualTask updates

import Foundation

extension ContextualTask {
    
    /// Create a new ContextualTask with updated status
    func withUpdatedStatus(_ newStatus: String) -> ContextualTask {
        return ContextualTask(
            id: self.id,
            name: self.name,
            buildingId: self.buildingId,
            buildingName: self.buildingName,
            category: self.category,
            startTime: self.startTime,
            endTime: self.endTime,
            recurrence: self.recurrence,
            skillLevel: self.skillLevel,
            status: newStatus, // Only this changes
            urgencyLevel: self.urgencyLevel,
            assignedWorkerName: self.assignedWorkerName,
            scheduledDate: self.scheduledDate
        )
    }
    
    /// Create a new ContextualTask with updated urgency level
    func withUpdatedUrgency(_ newUrgency: String) -> ContextualTask {
        return ContextualTask(
            id: self.id,
            name: self.name,
            buildingId: self.buildingId,
            buildingName: self.buildingName,
            category: self.category,
            startTime: self.startTime,
            endTime: self.endTime,
            recurrence: self.recurrence,
            skillLevel: self.skillLevel,
            status: self.status,
            urgencyLevel: newUrgency, // Only this changes
            assignedWorkerName: self.assignedWorkerName,
            scheduledDate: self.scheduledDate
        )
    }
    
    /// Create a new ContextualTask with both status and urgency updated
    func withUpdatedStatusAndUrgency(status: String, urgency: String) -> ContextualTask {
        return ContextualTask(
            id: self.id,
            name: self.name,
            buildingId: self.buildingId,
            buildingName: self.buildingName,
            category: self.category,
            startTime: self.startTime,
            endTime: self.endTime,
            recurrence: self.recurrence,
            skillLevel: self.skillLevel,
            status: status,
            urgencyLevel: urgency,
            assignedWorkerName: self.assignedWorkerName,
            scheduledDate: self.scheduledDate
        )
    }
}
