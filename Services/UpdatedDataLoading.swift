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

// MARK: - Updated WorkerDashboardView Properties
extension WorkerDashboardView {
    
    // Replace individual state properties with WorkerContextEngine
    /*
    OLD:
    @State private var assignedBuildings: [NamedCoordinate] = []
    @State private var todaysTasks: [MaintenanceTask] = []
    
    NEW:
    @StateObject private var contextEngine = WorkerContextEngine.shared
    */
}

// MARK: - Replace Data Loading Methods
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
        // Use existing TodaysTasksGlassCard with mapped tasks
        TodaysTasksGlassCard(
            tasks: mapToMaintenanceTasks(contextEngine.todaysTasks),
            onTaskTap: { task in
                if let contextualTask = findContextualTask(for: task) {
                    onTaskTap(contextualTask)
                }
            }
        )
    }
    
    private func mapToMaintenanceTasks(_ contextualTasks: [ContextualTask]) -> [MaintenanceTask] {
        contextualTasks.map { task in
            MaintenanceTask(
                id: task.id,
                name: task.name,
                buildingID: task.buildingId,
                description: "Task from \(task.category)",
                dueDate: Date(),
                startTime: parseTimeString(task.startTime),
                endTime: parseTimeString(task.endTime),
                category: TaskCategory(rawValue: task.category) ?? .maintenance,
                urgency: TaskUrgency(rawValue: task.urgencyLevel) ?? .medium,
                recurrence: TaskRecurrence(rawValue: task.recurrence) ?? .oneTime,
                isComplete: task.status == "completed",
                assignedWorkers: [contextEngine.currentWorker?.workerId ?? ""]
            )
        }
    }
    
    private func parseTimeString(_ timeStr: String?) -> Date? {
        guard let timeStr = timeStr else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeStr) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: components.hour ?? 0,
                               minute: components.minute ?? 0,
                               second: 0,
                               of: Date())
        }
        
        return nil
    }
    
    private func findContextualTask(for maintenanceTask: MaintenanceTask) -> ContextualTask? {
        contextEngine.todaysTasks.first { $0.id == maintenanceTask.id }
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
                
                // Replace placeholder with NovaAvatar
                NovaAvatar(
                    size: 60,
                    showStatus: hasNotifications,
                    hasUrgentInsight: hasUrgentTasks,
                    onTap: {
                        // Show AI insights
                        if let scenario = getAIScenario() {
                            aiScenario = scenario
                        }
                    },
                    onLongPress: {
                        showQuickActions = true
                    }
                )
                .padding(.trailing, 20)
                .padding(.top, 120)
            }
            Spacer()
        }
        .overlay(
            Group {
                if showQuickActions {
                    QuickActionMenu(
                        isPresented: $showQuickActions,
                        onActionSelected: handleQuickAction
                    )
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
    
    private func handleQuickAction(_ action: QuickActionType) {
        switch action {
        case .scanQR:
            print("Open QR scanner")
        case .reportIssue:
            print("Open issue reporter")
        case .showMap:
            print("Show building map")
        case .askNova:
            print("Open Nova chat")
        case .viewInsights:
            print("Show AI insights")
        }
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
                }
                
                HStack(spacing: 20) {
                    // In Progress
                    TaskSummaryItem(
                        count: categorizedTasks.current.count,
                        label: "Active",
                        color: .green,
                        icon: "play.circle.fill"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.3))
                    
                    // Upcoming
                    TaskSummaryItem(
                        count: categorizedTasks.upcoming.count,
                        label: "Upcoming",
                        color: .blue,
                        icon: "clock.arrow.circlepath"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.3))
                    
                    // Overdue
                    TaskSummaryItem(
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

// Enhanced TaskSummaryItem with icon
struct TaskSummaryItem: View {
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
    }
}