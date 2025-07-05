// FILE: Components/Shared Components/ContextualTask.swift
//
//  ContextualTask.swift
//  FrancoSphere
//
//  ✅ ENHANCED CONTEXTUAL TASK with computed properties
//  ✅ Added compatibility properties for existing code
//  ✅ Real data integration ready
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - ContextualTask Model

/// Core task model with building context and time information
struct ContextualTask: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let buildingId: String
    let buildingName: String
    let category: String
    let startTime: String?
    let endTime: String?
    let recurrence: String
    let skillLevel: String
    let status: String
    let urgencyLevel: String
    let assignedWorkerName: String?
    let scheduledDate: Date?
    
    // MARK: - Computed Properties
    
    /// Compatibility property for existing code
    var isCompleted: Bool {
        return status == "completed"
    }
    
    /// Check if task is weather-dependent
    var isWeatherDependent: Bool {
        let weatherKeywords = ["outdoor", "exterior", "roof", "gutter", "window", "clean", "sweep", "park", "sidewalk", "hose"]
        return weatherKeywords.contains { keyword in
            name.lowercased().contains(keyword) || category.lowercased().contains(keyword)
        }
    }
    
    /// Check if task is overdue based on current time
    var isOverdue: Bool {
        guard let startTime = startTime else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let taskTime = formatter.date(from: startTime) {
            let calendar = Calendar.current
            let now = Date()
            let taskComponents = calendar.dateComponents([.hour, .minute], from: taskTime)
            let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
            
            if let taskHour = taskComponents.hour, let taskMinute = taskComponents.minute,
               let nowHour = nowComponents.hour, let nowMinute = nowComponents.minute {
                let taskMinutes = taskHour * 60 + taskMinute
                let nowMinutes = nowHour * 60 + nowMinute
                return nowMinutes > taskMinutes && status == "pending"
            }
        }
        return false
    }
    
    /// Color coding based on urgency and overdue status
    var urgencyColor: Color {
        if isOverdue { return .red }
        switch urgencyLevel.lowercased() {
        case "urgent", "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
    
    /// Time display for UI
    var timeDisplay: String {
        if let start = startTime, let end = endTime {
            return "\(start) - \(end)"
        } else if let start = startTime {
            return start
        } else {
            return "Flexible"
        }
    }
    
    /// Formatted building name for display
    var buildingDisplayName: String {
        return buildingName.isEmpty ? "Building \(buildingId)" : buildingName
    }
    
    // MARK: - Initializers
    
    init(id: String, name: String, buildingId: String, buildingName: String, category: String, startTime: String?, endTime: String?, recurrence: String, skillLevel: String, status: String, urgencyLevel: String, assignedWorkerName: String? = nil, scheduledDate: Date? = nil) {
        self.id = id
        self.name = name
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.recurrence = recurrence
        self.skillLevel = skillLevel
        self.status = status
        self.urgencyLevel = urgencyLevel
        self.assignedWorkerName = assignedWorkerName
        self.scheduledDate = scheduledDate
    }
    
    // MARK: - Hashable & Identifiable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ContextualTask, rhs: ContextualTask) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - ContextualTask Factory Methods

extension ContextualTask {
    
    /// Create a ContextualTask from database row
    static func fromDatabaseRow(_ row: [String: Any]) -> ContextualTask {
        return ContextualTask(
            id: String(describing: row["id"] ?? ""),
            name: row["name"] as? String ?? "",
            buildingId: String(row["buildingId"] as? Int64 ?? 0),
            buildingName: row["buildingName"] as? String ?? "",
            category: row["category"] as? String ?? "general",
            startTime: row["startTime"] as? String,
            endTime: row["endTime"] as? String,
            recurrence: row["recurrence"] as? String ?? "oneTime",
            skillLevel: row["skillLevel"] as? String ?? "Basic",
            status: row["status"] as? String ?? "pending",
            urgencyLevel: row["urgencyLevel"] as? String ?? "medium",
            assignedWorkerName: row["assignedWorkerName"] as? String,
            scheduledDate: row["scheduledDate"] as? Date
        )
    }
    
    /// Create sample task for testing
    static func sampleTask(
        id: String = "sample_1",
        name: String = "Sample Task",
        buildingId: String = "1",
        buildingName: String = "Sample Building"
    ) -> ContextualTask {
        return ContextualTask(
            id: id,
            name: name,
            buildingId: buildingId,
            buildingName: buildingName,
            category: "maintenance",
            startTime: "09:00",
            endTime: "10:00",
            recurrence: "daily",
            skillLevel: "Basic",
            status: "pending",
            urgencyLevel: "medium"
        )
    }
}

// MARK: - ContextualTask Array Extensions

extension Array where Element == ContextualTask {
    
    /// Filter tasks by building ID
    func forBuilding(_ buildingId: String) -> [ContextualTask] {
        return self.filter { $0.buildingId == buildingId }
    }
    
    /// Filter tasks by status
    func withStatus(_ status: String) -> [ContextualTask] {
        return self.filter { $0.status == status }
    }
    
    /// Get only overdue tasks
    var overdue: [ContextualTask] {
        return self.filter { $0.isOverdue }
    }
    
    /// Get only urgent tasks
    var urgent: [ContextualTask] {
        return self.filter { $0.urgencyLevel.lowercased() == "urgent" }
    }
    
    /// Get only pending tasks
    var pending: [ContextualTask] {
        return self.filter { $0.status == "pending" }
    }
    
    /// Get only completed tasks
    var completed: [ContextualTask] {
        return self.filter { $0.status == "completed" }
    }
    
    /// Count of incomplete tasks
    var incompleteCount: Int {
        return self.filter { $0.status != "completed" }.count
    }
    
    /// Count of weather-dependent tasks
    var weatherDependentCount: Int {
        return self.filter { $0.isWeatherDependent }.count
    }
}
