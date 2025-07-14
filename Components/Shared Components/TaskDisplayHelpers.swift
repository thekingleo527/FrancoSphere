//
//  TaskDisplayHelpers.swift
//  FrancoSphere
//
//  Fixed version with proper Optional handling and no redeclarations
//

import SwiftUI
import Foundation

struct TaskDisplayHelpers {
    
    // MARK: - Task Status Helpers
    static func getStatusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "completed":
            return .green
        case "in_progress", "in progress":
            return .blue
        case "pending":
            return .orange
        case "overdue":
            return .red
        case "cancelled":
            return .gray
        default:
            return .secondary
        }
    }
    
    static func getStatusIcon(for status: String) -> String {
        switch status.lowercased() {
        case "completed":
            return "checkmark.circle.fill"
        case "in_progress", "in progress":
            return "clock.circle.fill"
        case "pending":
            return "clock.circle"
        case "overdue":
            return "exclamationmark.triangle.fill"
        case "cancelled":
            return "xmark.circle.fill"
        default:
            return "circle"
        }
    }
    
    // MARK: - Category Helpers
    static func getCategoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "maintenance":
            return .orange
        case "cleaning":
            return .blue
        case "inspection":
            return .green
        case "sanitation":
            return .purple
        case "repair":
            return .red
        case "security":
            return .indigo
        default:
            return .gray
        }
    }
    
    static func getCategoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "maintenance":
            return "wrench.and.screwdriver"
        case "cleaning":
            return "spray.and.wipe"
        case "inspection":
            return "checklist"
        case "sanitation":
            return "trash"
        case "repair":
            return "hammer"
        case "security":
            return "shield"
        default:
            return "square.grid.2x2"
        }
    }
    
    // MARK: - Urgency Helpers
    static func getUrgencyColor(for urgency: String) -> Color {
        switch urgency.lowercased() {
        case "urgent":
            return .red
        case "high":
            return .orange
        case "medium":
            return .yellow
        case "low":
            return .green
        default:
            return .gray
        }
    }
    
    static func getUrgencyPriority(for urgency: String) -> Int {
        switch urgency.lowercased() {
        case "urgent":
            return 4
        case "high":
            return 3
        case "medium":
            return 2
        case "low":
            return 1
        default:
            return 2
        }
    }
    
    // MARK: - Time Helpers
    static func formatTimeString(_ timeString: String) -> String {
        // Handle various time formats
        if timeString.contains(":") {
            return timeString // Already formatted
        }
        
        // Convert 24-hour to 12-hour format if needed
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let date = formatter.date(from: timeString) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        
        return timeString
    }
    
    static func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        
        // Try different formats
        let formats = ["HH:mm", "h:mm a", "h:mm:ss a", "HH:mm:ss"]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString) {
                return date
            }
        }
        
        return nil
    }
    
    static func timeUntilTask(_ task: ContextualTask) -> String {
        guard let scheduledDate = task.scheduledDate else {
            return "No time set"
        }
        
        let timeInterval = scheduledDate.timeIntervalSinceNow
        return formatTimeInterval(timeInterval)
    }
    
    private static func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        if timeInterval < 0 {
            return "Overdue"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Task Filtering
    static func filterTasksByStatus(_ tasks: [ContextualTask], status: String) -> [ContextualTask] {
        return tasks.filter { $0.status.lowercased() == status.lowercased() }
    }
    
    static func filterTasksByCategory(_ tasks: [ContextualTask], category: String) -> [ContextualTask] {
        return tasks.filter { $0.category?.rawValue.lowercased() ?? "" == category.lowercased() }
    }
    
    static func filterTasksByUrgency(_ tasks: [ContextualTask], urgency: String) -> [ContextualTask] {
        return tasks.filter { $0.urgency?.rawValue.lowercased() ?? "" == urgency.lowercased() }
    }
    
    // MARK: - Task Sorting
    static func sortTasksByPriority(_ tasks: [ContextualTask]) -> [ContextualTask] {
        return tasks.sorted { task1, task2 in
            let priority1 = getUrgencyPriority(for: task1.urgency?.rawValue ?? "")
            let priority2 = getUrgencyPriority(for: task2.urgency?.rawValue ?? "")
            return priority1 > priority2
        }
    }
    
    static func sortTasksByTime(_ tasks: [ContextualTask]) -> [ContextualTask] {
        return tasks.sorted { task1, task2 in
            guard let time1 = task1.startTime, let time2 = task2.startTime,
                  let date1 = parseTimeString(time1), let date2 = parseTimeString(time2) else {
                return false
            }
            return date1 < date2
        }
    }
    
    // MARK: - Progress Calculation
    static func calculateCompletionPercentage(for tasks: [ContextualTask]) -> Double {
        guard !tasks.isEmpty else { return 0.0 }
        
        let completedTasks = tasks.filter { $0.status.lowercased() == "completed" }
        return Double(completedTasks.count) / Double(tasks.count) * 100.0
    }
    
    static func getTaskStats(for tasks: [ContextualTask]) -> TaskStats {
        let completed = tasks.filter { $0.status.lowercased() == "completed" }.count
        let pending = tasks.filter { $0.status.lowercased() == "pending" }.count
        let inProgress = tasks.filter { $0.status.lowercased().contains("progress") }.count
        let overdue = tasks.filter { $0.isOverdue }.count
        
        return TaskStats(
            total: tasks.count,
            completed: completed,
            pending: pending,
            inProgress: inProgress,
            overdue: overdue,
            completionPercentage: calculateCompletionPercentage(for: tasks)
        )
    }
}

// MARK: - Supporting Types
struct TaskStats {
    let total: Int
    let completed: Int
    let pending: Int
    let inProgress: Int
    let overdue: Int
    let completionPercentage: Double
}

// MARK: - View Extensions
extension View {
    func taskStatusModifier(for task: ContextualTask) -> some View {
        self.modifier(TaskStatusModifier(task: task))
    }
}

struct TaskStatusModifier: ViewModifier {
    let task: ContextualTask
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TaskDisplayHelpers.getStatusColor(for: task.status), lineWidth: 2)
            )
            .background(
                TaskDisplayHelpers.getStatusColor(for: task.status)
                    .opacity(0.1)
                    .cornerRadius(8)
            )
    }
}
