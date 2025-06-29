//
//  TodaysRoutineSummaryView.swift
//  FrancoSphere
//
//  ✅ F5: Navigation destination for "Today's Timeline" taps
//  Shows detailed routine from WorkerRoutineEngine.getTodaysRoutine()
//  Includes task completion toggles and building context
//

import SwiftUI

struct TodaysRoutineSummaryView: View {
    @EnvironmentObject private var contextEngine: WorkerContextEngine
    @Environment(\.dismiss) private var dismiss
    
    @State private var routineTasks: [ContextualTask] = []
    @State private var isLoading = true
    @State private var currentBuilding: String = "All Buildings"
    @State private var selectedTimeFilter: TimeFilter = .all
    
    enum TimeFilter: String, CaseIterable {
        case all = "All"
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        
        var timeRange: (start: Int, end: Int)? {
            switch self {
            case .all: return nil
            case .morning: return (start: 6, end: 12)
            case .afternoon: return (start: 12, end: 17)
            case .evening: return (start: 17, end: 22)
            }
        }
    }
    
    private var filteredTasks: [ContextualTask] {
        var tasks = routineTasks
        
        // Filter by time if selected
        if let timeRange = selectedTimeFilter.timeRange {
            tasks = tasks.filter { task in
                guard let startTime = task.startTime else { return true }
                let components = startTime.split(separator: ":")
                guard let hour = Int(components.first ?? "0") else { return true }
                return hour >= timeRange.start && hour < timeRange.end
            }
        }
        
        return tasks.sorted { task1, task2 in
            let time1 = task1.startTime ?? "00:00"
            let time2 = task2.startTime ?? "00:00"
            return time1 < time2
        }
    }
    
    private var tasksByBuilding: [String: [ContextualTask]] {
        Dictionary(grouping: filteredTasks) { $0.buildingName }
    }
    
    private var completionStats: (completed: Int, total: Int, percentage: Double) {
        let total = filteredTasks.count
        let completed = filteredTasks.filter { $0.status == "completed" }.count
        let percentage = total > 0 ? Double(completed) / Double(total) * 100 : 0
        return (completed, total, percentage)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                filterSection
                
                if isLoading {
                    loadingSection
                } else if filteredTasks.isEmpty {
                    emptyStateSection
                } else {
                    taskSections
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.black)
        .navigationTitle("Today's Routine")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .task {
            await loadRoutineData()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Progress overview
            HStack(spacing: 20) {
                progressCircle
                statsGrid
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var progressCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: completionStats.percentage / 100)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: completionStats.percentage)
            
            Text("\(Int(completionStats.percentage))%")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Completed: \(completionStats.completed)")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: "clock.circle.fill")
                    .foregroundColor(.orange)
                Text("Remaining: \(completionStats.total - completionStats.completed)")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: "list.bullet.circle.fill")
                    .foregroundColor(.blue)
                Text("Total: \(completionStats.total)")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Filter by Time")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                        filterChip(filter)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
    
    private func filterChip(_ filter: TimeFilter) -> some View {
        Button(action: {
            selectedTimeFilter = filter
            HapticManager.impact(.light)
        }) {
            Text(filter.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedTimeFilter == filter ?
                        Color.blue : Color.white.opacity(0.1)
                )
                .foregroundColor(
                    selectedTimeFilter == filter ?
                        .white : .white.opacity(0.8)
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Task Sections
    
    private var taskSections: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(tasksByBuilding.keys.sorted()), id: \.self) { buildingName in
                buildingTaskSection(buildingName: buildingName, tasks: tasksByBuilding[buildingName] ?? [])
            }
        }
    }
    
    private func buildingTaskSection(buildingName: String, tasks: [ContextualTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Building header
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.blue)
                
                Text(buildingName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(tasks.filter { $0.status == "completed" }.count)/\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Tasks for this building
            LazyVStack(spacing: 8) {
                ForEach(tasks, id: \.id) { task in
                    RoutineTaskRow(
                        task: task,
                        onToggleCompletion: { taskId, completed in
                            toggleTaskCompletion(taskId: taskId, completed: completed)
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Loading & Empty States
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.blue)
                .scaleEffect(1.2)
            
            Text("Loading today's routine...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(40)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Routine Tasks")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("No routine tasks found for the selected time period. Check back later or try a different filter.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(40)
    }
    
    // MARK: - Data Loading
    
    private func loadRoutineData() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Get today's routine from WorkerRoutineEngine
        let workerId = contextEngine.getWorkerId()
        
        // For now, use today's tasks as routine data
        // TODO: Replace with actual WorkerRoutineEngine.getTodaysRoutine(for: workerId)
        let todaysTasks = contextEngine.getTodaysTasks()
        
        await MainActor.run {
            routineTasks = todaysTasks
            isLoading = false
        }
    }
    
    private func toggleTaskCompletion(taskId: String, completed: Bool) {
        // Update task completion
        contextEngine.markTask(taskId, completed: completed)
        
        // Update local state
        if let index = routineTasks.firstIndex(where: { $0.id == taskId }) {
            routineTasks[index].status = completed ? "completed" : "pending"
        }
        
        HapticManager.impact(.light)
        
        // Refresh context engine
        Task {
            await contextEngine.refreshContext()
        }
    }
}

// MARK: - Routine Task Row Component

struct RoutineTaskRow: View {
    let task: ContextualTask
    let onToggleCompletion: (String, Bool) -> Void
    
    private var isCompleted: Bool {
        task.status == "completed"
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(spacing: 2) {
                Text(task.startTime ?? "09:00")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Circle()
                    .fill(priorityColor)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 50)
            
            // Task details
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .strikethrough(isCompleted)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                // Tags
                HStack(spacing: 6) {
                    if !task.recurrence.isEmpty {
                        tagView(task.recurrence, color: .purple)
                    }
                    
                    if !task.priority.isEmpty && task.priority != "low" {
                        tagView(task.priority.capitalized, color: priorityColor)
                    }
                }
            }
            
            Spacer()
            
            // Completion toggle
            Button(action: {
                onToggleCompletion(task.id, !isCompleted)
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : .white.opacity(0.4))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            isCompleted ?
                Color.green.opacity(0.1) :
                Color.white.opacity(0.03)
        )
        .cornerRadius(10)
    }
    
    private func tagView(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}