//
//
//  UpdatedDataLoading.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//

//
//  WorkerDashboardContextIntegration.swift
//  FrancoSphere
//
//  Integrates WorkerContextEngine with WorkerDashboardView
//

import SwiftUI
import Foundation

// MARK: - TimeBasedTaskFilter (Simplified for compatibility)
struct TimeBasedTaskFilter {
    static func categorizeByTimeStatus(tasks: [ContextualTask]) -> (current: [ContextualTask], upcoming: [ContextualTask], overdue: [ContextualTask]) {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let currentMinute = calendar.component(.minute, from: Date())
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        var upcoming: [ContextualTask] = []
        var current: [ContextualTask] = []
        var overdue: [ContextualTask] = []
        
        for task in tasks {
            guard let startTime = task.startTime else {
                current.append(task)
                continue
            }
            
            let components = startTime.split(separator: ":")
            guard components.count == 2,
                  let hour = Int(components[0]),
                  let minute = Int(components[1]) else {
                current.append(task)
                continue
            }
            
            let taskTotalMinutes = hour * 60 + minute
            
            if task.status == "completed" {
                continue
            } else if taskTotalMinutes < currentTotalMinutes - 30 {
                overdue.append(task)
            } else if taskTotalMinutes <= currentTotalMinutes + 30 {
                current.append(task)
            } else {
                upcoming.append(task)
            }
        }
        
        return (current, upcoming, overdue)
    }
    
    static func nextSuggestedTask(from tasks: [ContextualTask]) -> ContextualTask? {
        let categorized = categorizeByTimeStatus(tasks: tasks)
        
        if let urgentOverdue = categorized.overdue.first(where: {
            $0.urgencyLevel.lowercased() == "urgent" || $0.urgencyLevel.lowercased() == "high"
        }) {
            return urgentOverdue
        }
        
        if let urgentCurrent = categorized.current.first(where: {
            $0.urgencyLevel.lowercased() == "urgent" || $0.urgencyLevel.lowercased() == "high"
        }) {
            return urgentCurrent
        }
        
        return categorized.current.first ?? categorized.upcoming.first
    }
    
    static func timeUntilTask(_ task: ContextualTask) -> String? {
        guard let startTime = task.startTime else { return nil }
        
        let components = startTime.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let taskMinutes = hour * 60 + minute
        let currentMinutes = currentHour * 60 + currentMinute
        let difference = taskMinutes - currentMinutes
        
        if difference < 0 {
            let overdue = abs(difference)
            if overdue < 60 {
                return "\(overdue) min overdue"
            } else {
                return "\(overdue / 60) hr overdue"
            }
        } else if difference == 0 {
            return "Now"
        } else if difference < 60 {
            return "In \(difference) min"
        } else {
            return "In \(difference / 60) hr"
        }
    }
    
    static func formatTimeString(_ time: String?) -> String {
        guard let time = time else { return "No time set" }
        
        let components = time.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return time }
        
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

// MARK: - Updated Data Loading Methods
@MainActor
struct UpdatedDataLoading {
    
    // Replace initializeWorkerDashboard() with:
    static func initializeWorkerDashboard(workerId: String) async {
        // Single call to load everything
        await WorkerContextEngine.shared.loadWorkerContext(workerId: workerId)
        
        // Start auto-refresh
        WorkerContextEngine.shared.startAutoRefresh()
    }
    
    // Replace individual loading methods with computed properties:
    static var assignedBuildings: [Building] {
        WorkerContextEngine.shared.assignedBuildings
    }
    
    static var todaysTasks: [ContextualTask] {
        WorkerContextEngine.shared.todaysTasks
    }
    
    static var categorizedTasks: (current: [ContextualTask], upcoming: [ContextualTask], overdue: [ContextualTask]) {
        TimeBasedTaskFilter.categorizeByTimeStatus(
            tasks: WorkerContextEngine.shared.todaysTasks
        )
    }
}

// MARK: - Replace Today's Tasks Card
struct UpdatedTodaysTasksCard: View {
    @ObservedObject var contextEngine = WorkerContextEngine.shared
    let onTaskTap: (ContextualTask) -> Void
    
    var body: some View {
        // Create a simplified glass card for tasks since TodaysTasksGlassCard may not be available
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
                    
                    Text("\(contextEngine.todaysTasks.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Task list
                if contextEngine.todaysTasks.isEmpty {
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
                } else {
                    VStack(spacing: 8) {
                        ForEach(contextEngine.todaysTasks.prefix(5), id: \.id) { task in
                            RealTimeTaskRow(task: task) {
                                onTaskTap(task)
                            }
                        }
                        
                        if contextEngine.todaysTasks.count > 5 {
                            Text("+ \(contextEngine.todaysTasks.count - 5) more tasks")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 8)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Real-Time Task Status Display
struct RealTimeTaskRow: View {
    let task: ContextualTask
    let onTap: () -> Void
    
    private var timeStatus: String {
        TimeBasedTaskFilter.timeUntilTask(task) ?? ""
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator with real-time color
                ZStack {
                    Circle()
                        .fill(task.urgencyColor.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(task.urgencyColor, lineWidth: 2))
                    
                    if task.isOverdue {
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: categoryIcon(for: task.category))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(task.urgencyColor)
                    }
                }
                
                // Task details
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Building name
                        Text(task.buildingName)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        // Time status
                        if !timeStatus.isEmpty {
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            Text(timeStatus)
                                .font(.caption2)
                                .foregroundColor(task.isOverdue ? .red : .white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                // Time slot
                if let startTime = task.startTime {
                    Text(TimeBasedTaskFilter.formatTimeString(startTime))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "cleaning": return "sparkles"
        case "sanitation": return "trash.fill"
        case "maintenance": return "wrench.and.screwdriver.fill"
        case "inspection": return "magnifyingglass.circle.fill"
        case "operations": return "gearshape.2.fill"
        case "repair": return "hammer.fill"
        default: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Nova AI Integration
struct UpdatedAIOverlay: View {
    @State private var showQuickActions = false
    @State private var aiScenario: AIScenario?
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                // Simplified NovaAvatar replacement since it may not be available
                Button(action: {
                    if let scenario = getAIScenario() {
                        aiScenario = scenario
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: hasUrgentTasks ? "exclamationmark.circle.fill" : "brain.head.profile")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        
                        if hasNotifications {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                                .offset(x: 20, y: -20)
                        }
                    }
                }
                .onLongPressGesture {
                    showQuickActions = true
                }
                .padding(.trailing, 20)
                .padding(.top, 120)
            }
            Spacer()
        }
        .overlay(
            Group {
                if showQuickActions {
                    // Simplified quick actions overlay
                    VStack {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                        
                        Button("Close") {
                            showQuickActions = false
                        }
                        .foregroundColor(.blue)
                        .padding()
                    }
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .padding()
                }
            }
        )
    }
    
    private var hasNotifications: Bool {
        let engine = WorkerContextEngine.shared
        return engine.getUrgentTaskCount() > 0 ||
               engine.todaysTasks.contains { $0.isOverdue }
    }
    
    private var hasUrgentTasks: Bool {
        WorkerContextEngine.shared.getUrgentTaskCount() > 0
    }
    
    private func getAIScenario() -> AIScenario? {
        let engine = WorkerContextEngine.shared
        let categorized = TimeBasedTaskFilter.categorizeByTimeStatus(tasks: engine.todaysTasks)
        
        if !categorized.overdue.isEmpty {
            return .overdueTasks(count: categorized.overdue.count)
        } else if let next = TimeBasedTaskFilter.nextSuggestedTask(from: engine.todaysTasks) {
            return .upcomingTask(task: next)
        }
        
        return nil
    }
}

// MARK: - AI Scenarios
enum AIScenario {
    case overdueTasks(count: Int)
    case upcomingTask(task: ContextualTask)
    case weatherAlert(condition: String)
    case endOfDaySummary
}

// MARK: - Update Summary Section
struct UpdatedTaskSummary: View {
    @ObservedObject var contextEngine = WorkerContextEngine.shared
    
    private var categorizedTasks: (current: [ContextualTask], upcoming: [ContextualTask], overdue: [ContextualTask]) {
        TimeBasedTaskFilter.categorizeByTimeStatus(tasks: contextEngine.todaysTasks)
    }
    
    var body: some View {
        GlassCard(intensity: .regular) {
            VStack(spacing: 16) {
                HStack {
                    Text("Real-Time Status")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    
                    if let refreshTime = contextEngine.lastRefreshTime {
                        Text("Updated \(refreshTime, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                HStack(spacing: 20) {
                    // In Progress
                    UpdatedTaskSummaryItem(
                        count: categorizedTasks.current.count,
                        label: "Active",
                        color: .green,
                        icon: "play.circle.fill"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.3))
                    
                    // Upcoming
                    UpdatedTaskSummaryItem(
                        count: categorizedTasks.upcoming.count,
                        label: "Upcoming",
                        color: .blue,
                        icon: "clock.arrow.circlepath"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.3))
                    
                    // Overdue
                    UpdatedTaskSummaryItem(
                        count: categorizedTasks.overdue.count,
                        label: "Overdue",
                        color: .red,
                        icon: "exclamationmark.circle.fill"
                    )
                }
                
                // Next task suggestion
                if let nextTask = TimeBasedTaskFilter.nextSuggestedTask(from: contextEngine.todaysTasks) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Next: \(nextTask.name)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        Spacer()
                        if let time = TimeBasedTaskFilter.timeUntilTask(nextTask) {
                            Text(time)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
    }
}

// Enhanced TaskSummaryItem with icon (renamed to avoid conflicts)
struct UpdatedTaskSummaryItem: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String?
    
    init(count: Int, label: String, color: Color, icon: String? = nil) {
        self.count = count
        self.label = label
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Integration Helper Methods
@MainActor
extension UpdatedDataLoading {
    
    // Helper method to refresh context from any view
    static func refreshWorkerContext() async {
        await WorkerContextEngine.shared.refreshContext()
    }
    
    // Helper method to get tasks for a specific building
    static func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        WorkerContextEngine.shared.getTasksForBuilding(buildingId)
    }
    
    // Helper method to get urgent task count
    static func getUrgentTaskCount() -> Int {
        WorkerContextEngine.shared.getUrgentTaskCount()
    }
    
    // Helper method to check if worker has overdue tasks
    static func hasOverdueTasks() -> Bool {
        let categorized = categorizedTasks
        return !categorized.overdue.isEmpty
    }
    
    // Helper method to get next suggested task
    static func getNextSuggestedTask() -> ContextualTask? {
        TimeBasedTaskFilter.nextSuggestedTask(from: WorkerContextEngine.shared.todaysTasks)
    }
}
