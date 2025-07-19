//
//  TodaysTasksGlassCard.swift
//  FrancoSphere
//
//  ✅ FIXED: All property access and method issues resolved
//  ✅ ALIGNED: With current MaintenanceTask structure (not CoreTypes)
//  ✅ CORRECTED: Animation typos and building name lookup
//  ✅ USES: Correct MaintenanceTask type via TypeAliases
//

import SwiftUI

// Type aliases for CoreTypes

struct TodaysTasksGlassCard: View {
    let tasks: [MaintenanceTask]  // ✅ FIXED: Use MaintenanceTask from TypeAliases
    let onTaskTap: (MaintenanceTask) -> Void  // ✅ FIXED: Use MaintenanceTask from TypeAliases
    
    @State private var showCompleted = false
    
    private var pendingTasks: [MaintenanceTask] {
        // ✅ FIXED: Use .isCompleted instead of .isComplete
        tasks.filter { !$0.isCompleted }.sorted { task1, task2 in
            // Sort by urgency then time
            if task1.urgency != task2.urgency {
                return task1.urgency.sortOrder > task2.urgency.sortOrder
            }
            return (task1.dueDate ?? Date.distantFuture) < (task2.dueDate ?? Date.distantFuture)
        }
    }
    
    private var completedTasks: [MaintenanceTask] {
        // ✅ FIXED: Use .isCompleted instead of .isComplete
        tasks.filter { $0.isCompleted }
    }
    
    var body: some View {
        GlassCard(intensity: GlassIntensity.regular) {
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
                        // Pending tasks - ✅ FIXED: Very explicit type to prevent Task confusion
                        ForEach(pendingTasks, id: \.id) { (maintenanceTask: MaintenanceTask) in
                            TaskGlassRow(task: maintenanceTask) {
                                onTaskTap(maintenanceTask)
                            }
                        }
                        
                        // Completed section
                        if completedTasks.count > 0 {
                            Button(action: {
                                // ✅ FIXED: Animation instead of Animation
                                withAnimation(.easeInOut(duration: 0.2)) {
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
                                // ✅ FIXED: Very explicit type to prevent Task confusion
                                ForEach(completedTasks, id: \.id) { (maintenanceTask: MaintenanceTask) in
                                    TaskGlassRow(task: maintenanceTask, isCompleted: true) {
                                        onTaskTap(maintenanceTask)
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

// Task urgency extension for sorting - ✅ FIXED: Use TaskUrgency from TypeAliases
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
    let task: MaintenanceTask  // ✅ FIXED: Use MaintenanceTask from TypeAliases
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
                    // ✅ FIXED: Use .title property from MaintenanceTask
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .strikethrough(isCompleted)
                    
                    HStack(spacing: 8) {
                        // Building
                        Label(buildingName, systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Time
                        if let dueDate = task.dueDate {
                            Label(timeString(dueDate), systemImage: "clock")
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
        // ✅ FIXED: Use simple building name lookup with fallback
        getBuildingName(for: task.buildingId)
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // ✅ FIXED: Simple building name lookup function
    private func getBuildingName(for buildingId: String) -> String {
        // Try to find building in allBuildings static data
        if let building = NamedCoordinate.allBuildings.first(where: { $0.id == buildingId }) {
            return building.displayName
        }
        
        // Fallback for common building IDs
        switch buildingId {
        case "1": return "12 West 18th"
        case "14": return "Rubin Museum"
        case "16": return "Stuyvesant Park"
        case "17": return "178 Spring St"
        default: return "Building \(buildingId)"
        }
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
        .padding(.vertical, 4)
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
    let task: MaintenanceTask  // ✅ FIXED: Use MaintenanceTask from TypeAliases
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
                            // ✅ FIXED: Use .title property from MaintenanceTask
                            Text(task.title)
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
                            if let dueDate = task.dueDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                    Text(timeString(dueDate))
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
        // ✅ FIXED: Animation instead of Animation
        .animation(.easeInOut(duration: 0.1), value: isPressed)
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
        // ✅ FIXED: Use simple building name lookup with fallback
        getBuildingName(for: task.buildingId)
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // ✅ FIXED: Simple building name lookup function
    private func getBuildingName(for buildingId: String) -> String {
        if let building = NamedCoordinate.allBuildings.first(where: { $0.id == buildingId }) {
            return building.displayName
        }
        
        switch buildingId {
        case "1": return "12 West 18th"
        case "14": return "Rubin Museum"
        case "16": return "Stuyvesant Park"
        case "17": return "178 Spring St"
        default: return "Building \(buildingId)"
        }
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
                    // Sample tasks - ✅ FIXED: Use MaintenanceTask from TypeAliases
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
                        // ✅ FIXED: Use .title property
                        print("Task tapped: \(task.title)")
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
