import Foundation
import SwiftUI

class EmergencyTaskManager {
    
    /// Creates an emergency weather task for the specified building
    static func createEmergencyWeatherTask(for building: FrancoSphere.NamedCoordinate) -> FrancoSphere.MaintenanceTask {
        // Create a task due immediately with the highest urgency
        let task = FrancoSphere.MaintenanceTask(
            id: UUID().uuidString,
            name: "WEATHER EMERGENCY: Building Check",
            buildingID: building.id,
            description: "Urgent inspection required due to extreme weather conditions. Check all critical systems and areas including: roof, basement, windows, doors, HVAC systems, and drainage.",
            dueDate: Date(),
            startTime: Date(),
            endTime: Date(timeIntervalSinceNow: 3600), // 1 hour duration
            category: .inspection,
            urgency: .urgent,
            recurrence: .oneTime,
            isComplete: false
        )
        
        // Save the task to the database
        let _ = TaskManager.shared.createTask(task)
        
        // Return the created task
        return task
    }
    
    /// Creates a flooding response task
    static func createFloodingTask(for building: FrancoSphere.NamedCoordinate) -> FrancoSphere.MaintenanceTask {
        let task = FrancoSphere.MaintenanceTask(
            id: UUID().uuidString,
            name: "URGENT: Flooding Response",
            buildingID: building.id,
            description: "Flooding reported or high risk of flooding. Check basement, drainage systems, and deploy water pumps if necessary.",
            dueDate: Date(),
            startTime: Date(),
            endTime: Date(timeIntervalSinceNow: 7200), // 2 hour duration
            category: .maintenance,
            urgency: .urgent,
            recurrence: .oneTime,
            isComplete: false
        )
        
        let _ = TaskManager.shared.createTask(task)
        return task
    }
    
    /// Creates an HVAC emergency task
    static func createHVACEmergencyTask(for building: FrancoSphere.NamedCoordinate, highTemperature: Bool) -> FrancoSphere.MaintenanceTask {
        let description = highTemperature ?
            "HVAC system failure during high temperatures. Immediate repair needed to prevent heat-related issues." :
            "Heating system failure during cold temperatures. Immediate repair needed to prevent freezing and pipe damage."
        
        let task = FrancoSphere.MaintenanceTask(
            id: UUID().uuidString,
            name: "URGENT: HVAC System Failure",
            buildingID: building.id,
            description: description,
            dueDate: Date(),
            startTime: Date(),
            endTime: Date(timeIntervalSinceNow: 5400), // 1.5 hour duration
            category: .repair,
            urgency: .urgent,
            recurrence: .oneTime,
            isComplete: false
        )
        
        let _ = TaskManager.shared.createTask(task)
        return task
    }
    
    /// Creates a structural damage assessment task
    static func createStormDamageTask(for building: FrancoSphere.NamedCoordinate) -> FrancoSphere.MaintenanceTask {
        let task = FrancoSphere.MaintenanceTask(
            id: UUID().uuidString,
            name: "URGENT: Storm Damage Assessment",
            buildingID: building.id,
            description: "Assess and document storm damage to the building. Check roof, windows, exterior walls, and surrounding area. Take photos and note any immediate safety concerns.",
            dueDate: Date(),
            startTime: Date(),
            endTime: Date(timeIntervalSinceNow: 3600), // 1 hour duration
            category: .inspection,
            urgency: .urgent,
            recurrence: .oneTime,
            isComplete: false
        )
        
        let _ = TaskManager.shared.createTask(task)
        return task
    }
    
    /// Creates a power outage response task
    static func createPowerOutageTask(for building: FrancoSphere.NamedCoordinate) -> FrancoSphere.MaintenanceTask {
        let task = FrancoSphere.MaintenanceTask(
            id: UUID().uuidString,
            name: "URGENT: Power Outage Response",
            buildingID: building.id,
            description: "Respond to power outage. Check backup generators, emergency lighting, and ensure critical systems are functioning. Assist residents as needed.",
            dueDate: Date(),
            startTime: Date(),
            endTime: Date(timeIntervalSinceNow: 3600), // 1 hour duration
            category: .maintenance,
            urgency: .urgent,
            recurrence: .oneTime,
            isComplete: false
        )
        
        let _ = TaskManager.shared.createTask(task)
        return task
    }
    
    /// Notifies all relevant workers about an emergency task
    static func notifyWorkersAboutEmergencyTask(_ task: FrancoSphere.MaintenanceTask) {
        // This would integrate with the app's notification system
        // For now, we'll print to the console
        print("🚨 EMERGENCY NOTIFICATION: \(task.name) created for Building ID: \(task.buildingID)")
        
        // In a real implementation, we would:
        // 1. Find workers assigned to this building
        // 2. Send push notifications
        // 3. Perhaps even send SMS or make phone calls for urgent situations
    }
}
