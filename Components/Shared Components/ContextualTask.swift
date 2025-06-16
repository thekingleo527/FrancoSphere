//
//  ContextualTask.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/14/25.
//


//
//  ContextualTask.swift
//  FrancoSphere
//
//  🚨 STANDALONE CONTEXTUAL TASK TYPE
//  ✅ Fixes "Cannot find type 'ContextualTask'" compilation errors
//  ✅ Extracted from WorkerContextEngine.swift for better accessibility
//

import Foundation
import SwiftUI

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
    
    // MARK: - Computed Properties
    
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
    
    /// Determines if task is weather-dependent
    var weatherDependent: Bool {
        let weatherKeywords = ["outdoor", "exterior", "roof", "gutter", "window", "clean", "sweep", "park"]
        return weatherKeywords.contains { keyword in
            name.lowercased().contains(keyword) || category.lowercased().contains(keyword)
        }
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
            urgencyLevel: row["urgencyLevel"] as? String ?? "medium"
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
    
    /// Create empty/placeholder task
    static var empty: ContextualTask {
        return ContextualTask(
            id: "",
            name: "",
            buildingId: "",
            buildingName: "",
            category: "",
            startTime: nil,
            endTime: nil,
            recurrence: "",
            skillLevel: "",
            status: "",
            urgencyLevel: ""
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
        return self.filter { $0.weatherDependent }.count
    }
}

// MARK: - Supporting Types

/// Task progress calculation result
struct TaskProgress {
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let urgentTasks: Int
    
    var completionPercentage: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var isOnTrack: Bool {
        return overdueTasks == 0
    }
    
    var hasUrgentWork: Bool {
        return urgentTasks > 0 || overdueTasks > 0
    }
}

/// Weather adaptation for tasks
struct WeatherTaskAdaptation {
    let task: ContextualTask
    let status: AdaptationStatus
    let reason: String?
    
    enum AdaptationStatus {
        case normal
        case weatherDependent
        case postponed
        case rescheduled
    }
    
    var shouldDelay: Bool {
        return status == .postponed || status == .rescheduled
    }
    
    var warningMessage: String? {
        guard status != .normal else { return nil }
        return reason ?? "Weather conditions may affect this task"
    }
}

// MARK: - Task Time Utilities

extension ContextualTask {
    
    /// Get task start time as Date (today)
    var startTimeAsDate: Date? {
        guard let startTime = startTime else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let time = formatter.date(from: startTime) else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                            minute: timeComponents.minute ?? 0,
                            second: 0,
                            of: now)
    }
    
    /// Check if task is scheduled for current hour
    var isCurrentHour: Bool {
        guard let taskDate = startTimeAsDate else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        
        return calendar.component(.hour, from: taskDate) == calendar.component(.hour, from: now)
    }
    
    /// Check if task is upcoming (within next 2 hours)
    var isUpcoming: Bool {
        guard let taskDate = startTimeAsDate else { return false }
        
        let now = Date()
        let twoHoursFromNow = now.addingTimeInterval(2 * 60 * 60)
        
        return taskDate > now && taskDate <= twoHoursFromNow
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ContextualTask {
    
    /// Sample tasks for previews and testing
    static var previewTasks: [ContextualTask] {
        return [
            ContextualTask(
                id: "1",
                name: "Boiler Check",
                buildingId: "17",
                buildingName: "Stuyvesant Cove Park",
                category: "maintenance",
                startTime: "07:30",
                endTime: "08:00",
                recurrence: "daily",
                skillLevel: "Advanced",
                status: "pending",
                urgencyLevel: "high"
            ),
            ContextualTask(
                id: "2",
                name: "Clean Common Areas",
                buildingId: "16",
                buildingName: "133 East 15th Street",
                category: "cleaning",
                startTime: "08:00",
                endTime: "09:00",
                recurrence: "daily",
                skillLevel: "Basic",
                status: "pending",
                urgencyLevel: "medium"
            ),
            ContextualTask(
                id: "3",
                name: "Sweep Front of Building",
                buildingId: "4",
                buildingName: "131 Perry Street",
                category: "cleaning",
                startTime: "10:00",
                endTime: "10:30",
                recurrence: "daily",
                skillLevel: "Basic",
                status: "completed",
                urgencyLevel: "low"
            )
        ]
    }
}
#endif

