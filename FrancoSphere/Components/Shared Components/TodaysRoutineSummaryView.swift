//
//  TodaysRoutineSummaryView.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With CoreTypes.ContextualTask structure
//  ✅ UPDATED: Proper enum comparisons and property access
//  ✅ GLASS: Uses glass morphism design system
//  ✅ FIXED: Handle optional category and urgency properties
//

import SwiftUI

struct TodaysRoutineSummaryView: View {
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
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
                // Use dueDate for time filtering since startTime doesn't exist
                guard let dueDate = task.dueDate else { return true }
                let hour = Calendar.current.component(.hour, from: dueDate)
                return hour >= timeRange.start && hour < timeRange.end
            }
        }
        
        // Sort by due date
        return tasks.sorted { task1, task2 in
            let date1 = task1.dueDate ?? Date.distantFuture
            let date2 = task2.dueDate ?? Date.distantFuture
            return date1 < date2
        }
    }
    
    private var tasksByBuilding: [String: [ContextualTask]] {
        Dictionary(grouping: filteredTasks) { task in
            task.buildingId ?? "Unassigned"
        }
    }
    
    private var completionStats: (completed: Int, total: Int, percentage: Double) {
        let total = filteredTasks.count
        let completed = filteredTasks.filter { $0.status == .completed }.count
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
            ForEach(Array(tasksByBuilding.keys.sorted()), id: \.self) { buildingId in
                buildingTaskSection(buildingId: buildingId, tasks: tasksByBuilding[buildingId] ?? [])
            }
        }
    }
    
    private func buildingTaskSection(buildingId: String, tasks: [ContextualTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Building header
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.blue)
                
                Text(getBuildingName(for: buildingId))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(tasks.filter { $0.status == .completed }.count)/\(tasks.count)")
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
        isLoading = true
        
        // Get today's tasks from context adapter - getTodaysTasks() is not async
        let todaysTasks = contextAdapter.getTodaysTasks()
        
        await MainActor.run {
            routineTasks = todaysTasks
            isLoading = false
        }
    }
    
    private func toggleTaskCompletion(taskId: String, completed: Bool) {
        // Update task completion via service
        Task {
            do {
                if let task = routineTasks.first(where: { $0.id == taskId }) {
                    // Create updated task with new completion status
                    let updatedTask = ContextualTask(
                        id: task.id,
                        title: task.title,
                        description: task.description,
                        isCompleted: completed,
                        dueDate: task.dueDate,
                        category: task.category ?? .cleaning,  // Provide default if nil
                        urgency: task.urgency ?? .low,  // Provide default if nil
                        buildingId: task.buildingId
                    )
                    
                    try await TaskService.shared.updateTask(updatedTask)
                    
                    // Update local state
                    if let index = routineTasks.firstIndex(where: { $0.id == taskId }) {
                        routineTasks[index] = updatedTask
                    }
                }
            } catch {
                print("Error updating task: \(error)")
            }
        }
        
        HapticManager.impact(.light)
    }
    
    // MARK: - Helper Methods
    
    private func getBuildingName(for buildingId: String) -> String {
        // In a real app, this would look up the building name from a service
        // For now, return a formatted version of the ID
        switch buildingId {
        case "14": return "Rubin Museum"
        case "1": return "12 West 18th Street"
        case "2": return "29-31 East 20th Street"
        case "Unassigned": return "Unassigned Tasks"
        default: return "Building \(buildingId)"
        }
    }
}

// MARK: - Routine Task Row Component

struct RoutineTaskRow: View {
    let task: ContextualTask
    let onToggleCompletion: (String, Bool) -> Void
    
    private var isCompleted: Bool {
        task.status == .completed
    }
    
    private var priorityColor: Color {
        switch task.urgency {
        case .emergency: return .red
        case .critical: return .red
        case .urgent: return .orange
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case nil: return .gray  // Handle optional case
        }
    }
    
    private var timeString: String {
        if let dueDate = task.dueDate {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: dueDate)
        }
        return "09:00"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(spacing: 2) {
                Text(timeString)
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
                Text(task.title)
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
                    // Category tag
                    if let category = task.category {
                        tagView(category.rawValue.capitalized, color: .purple)
                    }
                    
                    // Urgency tag
                    if let urgency = task.urgency, urgency != .low {
                        tagView(urgency.rawValue.capitalized, color: priorityColor)
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

// MARK: - Preview

struct TodaysRoutineSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TodaysRoutineSummaryView()
        }
        .preferredColorScheme(.dark)
    }
}
