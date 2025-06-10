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

// MARK: - Updated Data Loading Methods
@MainActor
struct UpdatedDataLoading {
    
    // Replace initializeWorkerDashboard() with:
    static func initializeWorkerDashboard(workerId: String) async {
        // Single call to load everything
        await WorkerContextEngine.shared.loadWorkerContext(workerId: workerId)
        
        // Start auto-refresh (available via extensions)
        // WorkerContextEngine.shared.startAutoRefresh()
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

// MARK: - Simplified Task Display Components
struct SimplifiedTaskCard: View {
    let task: ContextualTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(task.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Circle()
                        .fill(task.urgencyColor)
                        .frame(width: 8, height: 8)
                }
                
                HStack {
                    Text(task.buildingName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    if let startTime = task.startTime {
                        Text(TimeBasedTaskFilter.formatTimeString(startTime))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Simplified Task List
struct SimplifiedTasksList: View {
    @ObservedObject var contextEngine = WorkerContextEngine.shared
    let onTaskTap: (ContextualTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Today's Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(contextEngine.todaysTasks.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
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
                        SimplifiedTaskCard(task: task) {
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.15)
        )
    }
}

// MARK: - Simplified AI Overlay
struct SimplifiedAIOverlay: View {
    @State private var showQuickActions = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button(action: {
                    // Handle AI tap
                    print("AI Assistant tapped")
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
}

// MARK: - Simplified Task Summary
struct SimplifiedTaskSummary: View {
    @ObservedObject var contextEngine = WorkerContextEngine.shared
    
    private var categorizedTasks: (current: [ContextualTask], upcoming: [ContextualTask], overdue: [ContextualTask]) {
        TimeBasedTaskFilter.categorizeByTimeStatus(tasks: contextEngine.todaysTasks)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Real-Time Status")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // Active tasks
                SimplifiedTaskSummaryItem(
                    count: categorizedTasks.current.count,
                    label: "Active",
                    color: .green,
                    icon: "play.circle.fill"
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))
                
                // Upcoming
                SimplifiedTaskSummaryItem(
                    count: categorizedTasks.upcoming.count,
                    label: "Upcoming",
                    color: .blue,
                    icon: "clock.arrow.circlepath"
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))
                
                // Overdue
                SimplifiedTaskSummaryItem(
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.15)
        )
    }
}

// MARK: - Simplified Task Summary Item
struct SimplifiedTaskSummaryItem: View {
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
