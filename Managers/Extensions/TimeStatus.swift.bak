//
//  TimeStatus.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//


//
//  TaskStatusExtension.swift
//  FrancoSphere
//
//  Extensions to add real-time status to existing MaintenanceTask model
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Task Time Status
extension MaintenanceTask {
    
    enum TimeStatus {
        case upcoming(minutesUntil: Int)
        case inProgress(percentComplete: Double)
        case overdue(minutesLate: Int)
        case completed
        case notToday
        
        var displayColor: Color {
            switch self {
            case .upcoming(let minutes):
                return minutes <= 30 ? .orange : .blue
            case .inProgress:
                return .green
            case .overdue:
                return .red
            case .completed:
                return .gray
            case .notToday:
                return .gray.opacity(0.5)
            }
        }
        
        var statusText: String {
            switch self {
            case .upcoming(let minutes):
                if minutes <= 0 { return "Starting now" }
                if minutes < 60 { return "In \(minutes) min" }
                let hours = minutes / 60
                return "In \(hours)h \(minutes % 60)m"
            case .inProgress(let percent):
                return "\(Int(percent * 100))% complete"
            case .overdue(let minutes):
                if minutes < 60 { return "\(minutes) min late" }
                let hours = minutes / 60
                return "\(hours)h \(minutes % 60)m late"
            case .completed:
                return "Completed"
            case .notToday:
                return "Not scheduled today"
            }
        }
        
        var actionIcon: String {
            switch self {
            case .upcoming:
                return "clock.arrow.circlepath"
            case .inProgress:
                return "play.circle.fill"
            case .overdue:
                return "exclamationmark.circle.fill"
            case .completed:
                return "checkmark.circle.fill"
            case .notToday:
                return "calendar.circle"
            }
        }
    }
    
    // Computed time status
    var timeStatus: TimeStatus {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if task is for today
        if !calendar.isDateInToday(dueDate) {
            return .notToday
        }
        
        if isComplete {
            return .completed
        }
        
        // If no start/end times, use due date
        guard let start = startTime, let end = endTime else {
            if isPastDue {
                let minutes = calendar.dateComponents([.minute], from: dueDate, to: now).minute ?? 0
                return .overdue(minutesLate: minutes)
            } else {
                let minutes = calendar.dateComponents([.minute], from: now, to: dueDate).minute ?? 0
                return .upcoming(minutesUntil: minutes)
            }
        }
        
        // Calculate based on start/end times
        if now < start {
            let minutes = calendar.dateComponents([.minute], from: now, to: start).minute ?? 0
            return .upcoming(minutesUntil: minutes)
        } else if now >= start && now <= end {
            let totalDuration = end.timeIntervalSince(start)
            let elapsed = now.timeIntervalSince(start)
            let percent = elapsed / totalDuration
            return .inProgress(percentComplete: percent)
        } else {
            let minutes = calendar.dateComponents([.minute], from: end, to: now).minute ?? 0
            return .overdue(minutesLate: minutes)
        }
    }
    
    // Time slot display
    var timeSlot: String {
        guard let start = startTime, let end = endTime else { 
            return "All day" 
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    // Duration display
    var durationText: String {
        guard let start = startTime, let end = endTime else { return "" }
        let minutes = Int(end.timeIntervalSince(start) / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}

// MARK: - Task Manager Extensions for Real-Time Features
extension TaskManager {
    
    /// Fetch today's tasks for a worker with real-time status
    func fetchTodaysTasks(forWorker workerId: String) async -> (current: [MaintenanceTask], upcoming: [MaintenanceTask], completed: [MaintenanceTask]) {
        
        let todaysTasks = await fetchTasksAsync(forWorker: workerId, date: Date())
        
        var current: [MaintenanceTask] = []
        var upcoming: [MaintenanceTask] = []
        var completed: [MaintenanceTask] = []
        
        for task in todaysTasks {
            switch task.timeStatus {
            case .inProgress, .overdue:
                current.append(task)
            case .upcoming:
                upcoming.append(task)
            case .completed:
                completed.append(task)
            case .notToday:
                break // Skip
            }
        }
        
        // Sort by time
        current.sort { ($0.startTime ?? $0.dueDate) < ($1.startTime ?? $1.dueDate) }
        upcoming.sort { ($0.startTime ?? $0.dueDate) < ($1.startTime ?? $1.dueDate) }
        completed.sort { ($0.startTime ?? $0.dueDate) > ($1.startTime ?? $1.dueDate) }
        
        return (current, upcoming, completed)
    }
    
    /// Get next task for worker
    func getNextTask(forWorker workerId: String) async -> MaintenanceTask? {
        let (current, upcoming, _) = await fetchTodaysTasks(forWorker: workerId)
        
        // First check current tasks (in progress or overdue)
        if let currentTask = current.first {
            return currentTask
        }
        
        // Then check upcoming
        return upcoming.first
    }
    
    /// Get time until next task
    func getTimeUntilNextTask(forWorker workerId: String) async -> String? {
        guard let nextTask = await getNextTask(forWorker: workerId) else { return nil }
        
        switch nextTask.timeStatus {
        case .upcoming(let minutes):
            if minutes <= 0 { return "Starting now" }
            if minutes < 60 { return "\(minutes) minutes" }
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        case .inProgress:
            return "In progress"
        case .overdue:
            return "Overdue"
        default:
            return nil
        }
    }
}

// MARK: - Observable Task State Manager
@MainActor
class TaskStateManager: ObservableObject {
    @Published var currentTasks: [MaintenanceTask] = []
    @Published var upcomingTasks: [MaintenanceTask] = []
    @Published var completedTasks: [MaintenanceTask] = []
    @Published var isLoading = false
    
    private var refreshTimer: Timer?
    private let taskManager = TaskService.shared
    
    init() {
        startAutoRefresh()
    }
    
    func loadTasks(forWorker workerId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        let (current, upcoming, completed) = await taskManager.fetchTodaysTasks(forWorker: workerId)
        
        self.currentTasks = current
        self.upcomingTasks = upcoming
        self.completedTasks = completed
    }
    
    func markTaskComplete(_ taskId: String) async {
        await taskManager.toggleTaskCompletionAsync(taskID: taskId, completedBy: "Worker")
        
        // Reload tasks
        if let workerId = currentTasks.first?.assignedWorkers.first {
            await loadTasks(forWorker: workerId)
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Re-categorize tasks based on current time
                let allTasks = self.currentTasks + self.upcomingTasks
                
                var newCurrent: [MaintenanceTask] = []
                var newUpcoming: [MaintenanceTask] = []
                
                for task in allTasks {
                    switch task.timeStatus {
                    case .inProgress, .overdue:
                        newCurrent.append(task)
                    case .upcoming:
                        newUpcoming.append(task)
                    default:
                        break
                    }
                }
                
                self.currentTasks = newCurrent.sorted { ($0.startTime ?? $0.dueDate) < ($1.startTime ?? $1.dueDate) }
                self.upcomingTasks = newUpcoming.sorted { ($0.startTime ?? $0.dueDate) < ($1.startTime ?? $1.dueDate) }
            }
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    var taskSummary: (total: Int, completed: Int, remaining: Int) {
        let total = currentTasks.count + upcomingTasks.count + completedTasks.count
        let completed = completedTasks.count
        let remaining = currentTasks.count + upcomingTasks.count
        
        return (total, completed, remaining)
    }
    
    var timeUntilNextTask: String? {
        let nextTask = currentTasks.first ?? upcomingTasks.first
        guard let next = nextTask else { return nil }
        
        switch next.timeStatus {
        case .upcoming(let minutes):
            if minutes <= 0 { return "Starting now" }
            if minutes < 60 { return "\(minutes) minutes" }
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        case .inProgress:
            return "In progress"
        case .overdue:
            return "Overdue"
        default:
            return nil
        }
    }
}