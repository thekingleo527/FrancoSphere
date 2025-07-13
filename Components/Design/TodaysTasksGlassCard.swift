import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

//
//  TodaysTasksGlassCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//

// TodaysTasksGlassCard.swift
// Today's tasks in glass card format

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct TodaysTasksGlassCard: View {
    let tasks: [MaintenanceTask]
    let onTaskTap: (MaintenanceTask) -> Void
    
    @State private var showCompleted = false
    
    private var pendingTasks: [MaintenanceTask] {
        tasks.filter { !$0.isComplete }.sorted { task1, task2 in
            // Sort by urgency then time
            if task1.urgency != task2.urgency {
                return task1.urgency.sortOrder > task2.urgency.sortOrder
            }
            if let time1 = task1.startTime, let time2 = task2.startTime {
                return time1 < time2
            }
            return (task1.dueDate ?? Date.distantFuture) < (task2.dueDate ?? Date.distantFuture)
        }
    }
    
    private var completedTasks: [MaintenanceTask] {
        tasks.filter { $0.isComplete }
    }
    
    var body: some View {
        GlassCard(intensity: .regular) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "checklist")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Today's Tasks")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Task counts
                    HStack(spacing: 12) {
                        TaskCountBadge(
                            count: pendingTasks.count,
                            label: "Pending",
                            color: .orange
                        )
                        
                        if completedTasks.count > 0 {
                            TaskCountBadge(
                                count: completedTasks.count,
                                label: "Done",
                                color: .green
                            )
                        }
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Task list
                if tasks.isEmpty {
                    EmptyTasksView()
                } else {
                    VStack(spacing: 8) {
                        // Pending tasks
                        ForEach(pendingTasks) { task in
                            TaskGlassRow(task: task) {
                                onTaskTap(task)
                            }
                        }
                        
                        // Completed section
                        if completedTasks.count > 0 {
                            Button(action: {
                                withAnimation(AnimationAnimation.easeInOut(duration: 0.2)) {
                                    showCompleted.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                                        .font(.caption)
                                    
                                    Text("Completed (\(completedTasks.count))")
                                        .font(.caption)
                                    
                                    Spacer()
                                }
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.vertical, 8)
                            }
                            
                            if showCompleted {
                                ForEach(completedTasks) { task in
                                    TaskGlassRow(task: task, isCompleted: true) {
                                        onTaskTap(task)
                                    }
                                    .opacity(0.6)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Task urgency extension for sorting
extension TaskUrgency {
    var sortOrder: Int {
        switch self {
        case .urgent: return 6
        case .critical: return 5
        case .emergency: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

struct TaskGlassRow: View {
    let task: MaintenanceTask
    var isCompleted: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion indicator
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color.green : taskUrgencyColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
                
                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .strikethrough(isCompleted)
                    
                    HStack(spacing: 8) {
                        // Building
                        Label(buildingName, systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Time
                        if let startTime = task.startTime {
                            Label(timeString(startTime), systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                // Category icon with urgency indicator
                VStack(spacing: 4) {
                    Image(systemName: task.category.icon)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    // Urgency indicator
                    if !isCompleted {
                        Circle()
                            .fill(taskUrgencyColor)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // FIXED: Created computed property for urgency color
    private var taskUrgencyColor: Color {
        switch task.urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        case .urgent: return .purple
        case .critical: return .red
        case .emergency: return .red
        }
    }
    
    private var buildingName: String {
        getBuildingNameSync(buildingId: task.buildingID)
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct TaskCountBadge: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.caption.bold())
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)  // FIXED: Removed extra comma
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.green.opacity(0.6))
            
            Text("No tasks scheduled")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Enjoy your day!")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Enhanced Task Row with Priority Indicator
struct EnhancedTaskGlassRow: View {
    let task: MaintenanceTask
    var isCompleted: Bool = false
    let onTap: () -> Void
    let onComplete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color.green : taskUrgencyColor, lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(isCompleted ? Color.green.opacity(0.2) : Color.clear)
                        )
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task content
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Task info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(task.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .strikethrough(isCompleted)
                            
                            Spacer()
                            
                            // Urgency badge
                            if !isCompleted {
                                Text(task.urgency.rawValue.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(taskUrgencyColor.opacity(0.3))
                                            .overlay(
                                                Capsule()
                                                    .stroke(taskUrgencyColor, lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        
                        HStack(spacing: 12) {
                            // Building
                            HStack(spacing: 4) {
                                Image(systemName: "building.2")
                                    .font(.caption2)
                                Text(buildingName)
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.7))
                            
                            // Time
                            if let startTime = task.startTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                    Text(timeString(startTime))
                                        .font(.caption)
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            // Category
                            HStack(spacing: 4) {
                                Image(systemName: task.category.icon)
                                    .font(.caption2)
                                Text(task.category.rawValue)
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(isCompleted ? 0.7 : 1.0)
        .animation(AnimationAnimation.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var taskUrgencyColor: Color {
        switch task.urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        case .urgent: return .purple
        case .critical: return .red
        case .emergency: return .red
        }
    }
    
    private var buildingName: String {
        getBuildingNameSync(buildingId: task.buildingID)
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct TodaysTasksGlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Sample tasks
                    let sampleTasks = [
                        MaintenanceTask(
                            title: "HVAC Filter Replacement",
                            description: "Replace air filters",
                            category: .maintenance,
                            urgency: .high,
                            buildingId: "1",
                            dueDate: Date()
                        ),
                        MaintenanceTask(
                            title: "Lobby Cleaning",
                            description: "Clean lobby area",
                            category: .cleaning,
                            urgency: .medium,
                            buildingId: "2",
                            dueDate: Date()
                        ),
                        MaintenanceTask(
                            title: "Emergency Repair",
                            description: "Fix urgent issue",
                            category: .repair,
                            urgency: .urgent,
                            buildingId: "3",
                            dueDate: Date()
                        )
                    ]
                    
                    TodaysTasksGlassCard(tasks: sampleTasks) { task in
                        print("Task tapped: \(task.name)")
                    }
                    
                    // Empty state
                    TodaysTasksGlassCard(tasks: []) { _ in }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
