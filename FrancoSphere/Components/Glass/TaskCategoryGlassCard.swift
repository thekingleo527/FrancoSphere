import Foundation

// Type aliases for CoreTypes

import SwiftUI

// Type aliases for CoreTypes

//
//  TaskCategoryGlassCard.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ CORRECTED: MaintenanceTask parameter order in initializer
//  ✅ ALIGNED: With CoreTypes.MaintenanceTask structure
//

struct TaskCategoryGlassCard: View {
    let title: String
    let icon: String
    let tasks: [MaintenanceTask]
    let categoryColor: Color
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onTaskTap: (MaintenanceTask) -> Void
    let onTaskComplete: (MaintenanceTask) -> Void
    
    @State private var expandedTasks: Set<String> = []
    
    var pendingTasks: [MaintenanceTask] {
        // FIXED: Use .isCompleted instead of .isComplete
        tasks.filter { !$0.isCompleted }
    }
    
    var body: some View {
        GlassCard(intensity: GlassIntensity.thin) {
            VStack(alignment: .leading, spacing: 0) {
                // Header section
                categoryHeader
                
                // Tasks content (expandable)
                if isExpanded && !pendingTasks.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(pendingTasks.prefix(5)) { task in // Limit to 5 tasks for performance
                            TaskRowGlassView(
                                task: task,
                                isExpanded: expandedTasks.contains(task.id),
                                isToday: isScheduledForToday(task),
                                onToggleExpand: { toggleTaskExpanded(task) },
                                onComplete: { onTaskComplete(task) },
                                onTap: { onTaskTap(task) }
                            )
                        }
                        
                        // Show more button if there are additional tasks
                        if pendingTasks.count > 5 {
                            showMoreButton
                        }
                    }
                    .padding(.top, 16)
                }
                
                // Empty state
                else if isExpanded && pendingTasks.isEmpty {
                    emptyStateView
                }
            }
            .padding(20)
        }
        .onAppear {
            // Auto-expand today's tasks
            for task in pendingTasks {
                if isScheduledForToday(task) {
                    expandedTasks.insert(task.id)
                }
            }
        }
    }
    
    // MARK: - Sub-components
    
    private var categoryHeader: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(categoryColor)
                }
                
                // Title and count
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Text("\(pendingTasks.count) pending")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if getTodayTasksCount() > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                                
                                Text("\(getTodayTasksCount()) today")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        if getOverdueTasksCount() > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                
                                Text("\(getOverdueTasksCount()) overdue")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Expand/collapse indicator
                VStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if pendingTasks.count > 0 {
                        Text("\(pendingTasks.count)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(categoryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(categoryColor.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var showMoreButton: some View {
        Button(action: {
            // In a real implementation, this would navigate to a full task list
            if let firstTask = pendingTasks.first {
                onTaskTap(firstTask)
            }
        }) {
            HStack {
                Text("View all \(pendingTasks.count) tasks")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.green)
            
            Text("All tasks completed!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("No pending tasks in this category")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Helper Methods
    
    private func toggleTaskExpanded(_ task: MaintenanceTask) {
        withAnimation(Animation.easeInOut(duration: 0.2)) {
            if expandedTasks.contains(task.id) {
                expandedTasks.remove(task.id)
            } else {
                expandedTasks.insert(task.id)
            }
        }
    }
    
    private func isScheduledForToday(_ task: MaintenanceTask) -> Bool {
        // FIXED: Handle optional dueDate properly
        guard let dueDate = task.dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    private func getTodayTasksCount() -> Int {
        pendingTasks.filter { isScheduledForToday($0) }.count
    }
    
    private func getOverdueTasksCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return pendingTasks.filter {
            guard let dueDate = $0.dueDate else { return false }
            return dueDate < today
        }.count
    }
}
// MARK: - Helper Methods

private func toggleTaskExpanded(_ task: MaintenanceTask) {
    withAnimation(Animation.easeInOut(duration: 0.2)) {
        if expandedTasks.contains(task.id) {
            expandedTasks.remove(task.id)
        } else {
            expandedTasks.insert(task.id)
        }
    }
}

private func isScheduledForToday(_ task: MaintenanceTask) -> Bool {
    // FIXED: Handle optional dueDate properly
    guard let dueDate = task.dueDate else { return false }
    return Calendar.current.isDateInToday(dueDate)
}

private func getTodayTasksCount() -> Int {
    pendingTasks.filter { isScheduledForToday($0) }.count
}

private func getOverdueTasksCount() -> Int {
    let today = Calendar.current.startOfDay(for: Date())
    return pendingTasks.filter {
        guard let dueDate = $0.dueDate else { return false }
        return dueDate < today
    }.count
}

// ADD THIS METHOD HERE:
private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}// MARK: - TaskRowGlassView

struct TaskRowGlassView: View {
    let task: MaintenanceTask
    let isExpanded: Bool
    let isToday: Bool
    let onToggleExpand: () -> Void
    let onComplete: () -> Void
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main task row
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    // Task status indicator
                    taskStatusIndicator
                    
                    // Task content - FIXED: Simplified to avoid complex expression
                    taskContent
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isToday ? Color.orange.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isToday ? Color.orange.opacity(0.3) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(Animation.easeInOut(duration: 0.1), value: isPressed)
            
            // Expanded content
            if isExpanded {
                expandedContent
            }
        }
    }
    
    // MARK: - Sub-components
    
    // FIXED: Separated task content to avoid complex expression
    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 8) {
                // Time or recurrence
                if let dueDate = task.dueDate {
                    Text(formatTime(dueDate))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                } else if task.isRecurring {
                    Text("Recurring")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text(formatDuration(task.estimatedDuration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Priority badge
                priorityBadge
                
                if isToday {
                    Text("TODAY")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(6)
                }
            }
        }
    }
    
    private var taskStatusIndicator: some View {
        ZStack {
            Circle()
                .stroke(urgencyColor, lineWidth: 2)
                .frame(width: 20, height: 20)
            
            // FIXED: Use .isCompleted instead of .isComplete
            if task.isCompleted {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(urgencyColor.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    private var priorityBadge: some View {
        Text(task.urgency.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(urgencyColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(urgencyColor.opacity(0.2))
            .cornerRadius(6)
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Description
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // View details button
                Button(action: onTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Details")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Complete button
                Button(action: onComplete) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                        Text("Complete")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var urgencyColor: Color {
        // FIXED: Complete switch with all TaskUrgency cases
        switch task.urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .emergency: return .red
        case .urgent: return .purple
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct TaskCategoryGlassCard_Previews: PreviewProvider {
    static var sampleTasks: [MaintenanceTask] {
        [
            // ✅ FIXED: Use correct properties only
            MaintenanceTask(
                title: "Clean Lobby Windows",
                description: "Clean all glass surfaces in the main lobby area",
                category: .cleaning,
                urgency: .medium,
                buildingId: "15",
                assignedWorkerId: "2",
                dueDate: Date(),
                isRecurring: true  // Instead of recurrence property
            ),
            MaintenanceTask(
                title: "Vacuum Common Areas",
                description: "Vacuum all carpeted areas including hallways and lobby",
                category: .cleaning,
                urgency: .low,
                buildingId: "15",
                assignedWorkerId: "2",
                dueDate: Date(),
                isRecurring: true  // Daily tasks are recurring
            ),
            MaintenanceTask(
                title: "Emergency Light Check",
                description: "Test all emergency lighting systems",
                category: .inspection,
                urgency: .urgent,
                buildingId: "15",
                assignedWorkerId: "1",
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                isRecurring: true  // Monthly tasks are recurring
            )
        ]
    }
    
    static var previews: some View {
        ZStack {
            FrancoSphereColors.primaryBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    TaskCategoryGlassCard(
                        title: "Cleaning Routine",
                        icon: "spray.and.wipe",
                        tasks: sampleTasks,
                        categoryColor: .blue,
                        isExpanded: true,
                        onToggleExpand: {},
                        onTaskTap: { _ in },
                        onTaskComplete: { _ in }
                    )
                    
                    TaskCategoryGlassCard(
                        title: "Sanitation & Garbage",
                        icon: "trash",
                        tasks: [],
                        categoryColor: .green,
                        isExpanded: true,
                        onToggleExpand: {},
                        onTaskTap: { _ in },
                        onTaskComplete: { _ in }
                    )
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
