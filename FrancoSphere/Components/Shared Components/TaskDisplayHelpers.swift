//
//
//  TaskDisplayHelpers.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Invalid redeclaration errors resolved
//  ✅ CLEANED: Removed duplicate property declarations
//  ✅ ORGANIZED: Single implementation of each helper function
//

import SwiftUI
import Foundation

// MARK: - Task Display Helpers

/// Helper functions for displaying tasks in various UI components
public struct TaskDisplayHelpers {
    
    // MARK: - Status Display
    
    /// Get appropriate color for task status
    public static func statusColor(for task: ContextualTask) -> Color {
        if task.isCompleted {
            return .green
        } else if let dueDate = task.dueDate, dueDate < Date() {
            return .red // Overdue
        } else {
            return task.priority.color
        }
    }
    
    /// Get status icon for task
    public static func statusIcon(for task: ContextualTask) -> String {
        if task.isCompleted {
            return "checkmark.circle.fill"
        } else if let dueDate = task.dueDate, dueDate < Date() {
            return "exclamationmark.triangle.fill"
        } else {
            return "circle"
        }
    }
    
    /// Get status text for task
    public static func statusText(for task: ContextualTask) -> String {
        if task.isCompleted {
            return "Completed"
        } else if let dueDate = task.dueDate, dueDate < Date() {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    // MARK: - Time Display
    
    /// Get formatted start time for task
    public static func startTimeText(for task: ContextualTask) -> String {
        guard let scheduledDate = task.scheduledDate else {
            return "No scheduled time"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }
    
    /// Get relative time description
    public static func relativeTimeText(for task: ContextualTask) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        if let dueDate = task.dueDate {
            return formatter.localizedString(for: dueDate, relativeTo: Date())
        } else if let scheduledDate = task.scheduledDate {
            return formatter.localizedString(for: scheduledDate, relativeTo: Date())
        } else {
            return "No time set"
        }
    }
    
    // MARK: - Worker Assignment
    
    /// Get assigned worker ID for display
    public static func assignedWorkerIdText(for task: ContextualTask) -> String {
        return task.assignedWorkerId ?? task.worker?.id ?? "Unassigned"
    }
    
    /// Get assigned worker name for display
    public static func assignedWorkerName(for task: ContextualTask) -> String {
        if let worker = task.worker {
            return worker.name
        } else if let workerId = task.assignedWorkerId {
            return "Worker \(workerId)"
        } else {
            return "Unassigned"
        }
    }
    
    // MARK: - Priority Display
    
    /// Get priority badge view
    public static func priorityBadge(for task: ContextualTask) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
            
            Text(task.priority.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Duration Calculations
    
    /// Calculate estimated duration for task
    public static func estimatedDurationText(for task: ContextualTask) -> String {
        // If task has explicit estimated duration, use it
        if let duration = task.estimatedDuration {
            return formatDuration(duration)
        }
        
        // Otherwise, estimate based on category and urgency
        let baseDuration: TimeInterval
        switch task.priority {
        case .critical:
            baseDuration = 3600 // 1 hour
        case .high:
            baseDuration = 2700 // 45 minutes
        case .medium:
            baseDuration = 1800 // 30 minutes
        case .low:
            baseDuration = 900  // 15 minutes
        }
        
        return formatDuration(baseDuration)
    }
    
    private static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Progress Indicators
    
    /// Get progress indicator for task
    public static func progressIndicator(for task: ContextualTask) -> some View {
        Group {
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if let dueDate = task.dueDate, dueDate < Date() {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Category Display
    
    /// Get category badge for task
    public static func categoryBadge(for task: ContextualTask) -> some View {
        let categoryText = task.title.lowercased().contains("clean") ? "Cleaning" :
                          task.title.lowercased().contains("maintenance") ? "Maintenance" :
                          task.title.lowercased().contains("repair") ? "Repair" : "General"
        
        let categoryColor: Color = {
            switch categoryText {
            case "Cleaning": return .blue
            case "Maintenance": return .orange
            case "Repair": return .red
            default: return .gray
            }
        }()
        
        return Text(categoryText)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor)
            .cornerRadius(8)
    }
    
    // MARK: - Building Display
    
    /// Get building name for task
    public static func buildingName(for task: ContextualTask) -> String {
        return task.buildingId ?? "Unknown Building"
    }
    
    /// Get building short name for compact display
    public static func buildingShortName(for task: ContextualTask) -> String {
        guard let buildingId = task.buildingId else { return "N/A" }
        
        // Extract short name from building ID or full name
        if buildingId.contains("Street") {
            let components = buildingId.components(separatedBy: " ")
            return components.prefix(2).joined(separator: " ")
        } else {
            return buildingId
        }
    }
    
    // MARK: - Completion Display
    
    /// Get completion status view
    public static func completionStatusView(for task: ContextualTask) -> some View {
        HStack(spacing: 4) {
            progressIndicator(for: task)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(statusText(for: task))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor(for: task))
                
                if let completedDate = task.completedDate {
                    Text("Completed \(RelativeDateTimeFormatter().localizedString(for: completedDate, relativeTo: Date()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Apply task status styling
    func taskStatusStyle(for task: ContextualTask) -> some View {
        self
            .foregroundColor(TaskDisplayHelpers.statusColor(for: task))
            .opacity(task.isCompleted ? 0.7 : 1.0)
    }
    
    /// Apply task priority styling
    func taskPriorityStyle(for task: ContextualTask) -> some View {
        self
            .overlay(
                Rectangle()
                    .fill(task.priority.color)
                    .frame(width: 3)
                    .cornerRadius(1.5),
                alignment: .leading
            )
    }
}

// MARK: - Preview Support

#if DEBUG
struct TaskDisplayHelpers_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Sample task for preview
            let sampleTask = ContextualTask(
                id: "preview-task",
                title: "Clean Lobby",
                description: "Daily lobby cleaning",
                buildingId: "123 Main Street",
                assignedWorkerId: "worker-001",
                priority: .high,
                scheduledDate: Date(),
                dueDate: Date().addingTimeInterval(3600),
                estimatedDuration: 1800
            )
            
            VStack(alignment: .leading, spacing: 8) {
                TaskDisplayHelpers.priorityBadge(for: sampleTask)
                TaskDisplayHelpers.categoryBadge(for: sampleTask)
                TaskDisplayHelpers.completionStatusView(for: sampleTask)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}
#endif
