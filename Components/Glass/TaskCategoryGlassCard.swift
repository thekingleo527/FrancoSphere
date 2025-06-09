//
//  TaskCategoryGlassCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


//
//  TaskCategoryGlassCard.swift
//  FrancoSphere
//
//  Glass card for displaying categorized tasks with expand/collapse functionality
//

import SwiftUI

struct TaskCategoryGlassCard: View {
    let title: String
    let icon: String
    let tasks: [FrancoSphere.MaintenanceTask]
    let categoryColor: Color
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onTaskTap: (FrancoSphere.MaintenanceTask) -> Void
    let onTaskComplete: (FrancoSphere.MaintenanceTask) -> Void
    
    @State private var expandedTasks: Set<String> = []
    
    var pendingTasks: [FrancoSphere.MaintenanceTask] {
        tasks.filter { !$0.isComplete }
    }
    
    var body: some View {
        GlassCard(intensity: .thin) {
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
            onTaskTap(pendingTasks.first!)
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
    
    private func toggleTaskExpanded(_ task: FrancoSphere.MaintenanceTask) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedTasks.contains(task.id) {
                expandedTasks.remove(task.id)
            } else {
                expandedTasks.insert(task.id)
            }
        }
    }
    
    private func isScheduledForToday(_ task: FrancoSphere.MaintenanceTask) -> Bool {
        Calendar.current.isDateInToday(task.dueDate)
    }
    
    private func getTodayTasksCount() -> Int {
        pendingTasks.filter { isScheduledForToday($0) }.count
    }
    
    private func getOverdueTasksCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return pendingTasks.filter { $0.dueDate < today }.count
    }
}

// MARK: - TaskRowGlassView

struct TaskRowGlassView: View {
    let task: FrancoSphere.MaintenanceTask
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
                    
                    // Task content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            // Time or recurrence
                            if let startTime = task.startTime {
                                Text(formatTime(startTime))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                Text(task.recurrence.rawValue)
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
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // Expanded content
            if isExpanded {
                expandedContent
            }
        }
    }
    
    // MARK: - Sub-components
    
    private var taskStatusIndicator: some View {
        ZStack {
            Circle()
                .stroke(urgencyColor, lineWidth: 2)
                .frame(width: 20, height: 20)
            
            if task.isComplete {
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
        switch task.urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
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
    static var sampleTasks: [FrancoSphere.MaintenanceTask] {
        [
            FrancoSphere.MaintenanceTask(
                id: "1",
                name: "Clean Lobby Windows",
                buildingID: "15",
                description: "Clean all glass surfaces in the main lobby area",
                dueDate: Date(),
                startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
                endTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()),
                category: .cleaning,
                urgency: .medium,
                recurrence: .weekly,
                isComplete: false,
                assignedWorkers: ["2"]
            ),
            FrancoSphere.MaintenanceTask(
                id: "2",
                name: "Vacuum Common Areas",
                buildingID: "15",
                description: "Vacuum all carpeted areas including hallways and lobby",
                dueDate: Date(),
                category: .cleaning,
                urgency: .low,
                recurrence: .daily,
                isComplete: false,
                assignedWorkers: ["2"]
            ),
            FrancoSphere.MaintenanceTask(
                id: "3",
                name: "Emergency Light Check",
                buildingID: "15",
                description: "Test all emergency lighting systems",
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                category: .inspection,
                urgency: .urgent,
                recurrence: .monthly,
                isComplete: false,
                assignedWorkers: ["1"]
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