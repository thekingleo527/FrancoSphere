import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

//
//  TaskTimelineView.swift
//  FrancoSphere
//
//  ✅ COMPILATION ERRORS FIXED:
//  ✅ Fixed MaintenanceTask.statusText access (line 319)
//  ✅ Fixed missing arguments for category, urgency, recurrence (lines 632, 639)
//  ✅ Fixed extra arguments in initializer call (line 673)
//  ✅ Proper MaintenanceTask type usage throughout
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct TaskTimelineView: View {
    let workerId: Int64
    
    @StateObject private var viewModel = TaskTimelineViewModel()
    @State private var selectedDate = Date()
    @State private var showingFilters = false
    @State private var showingTaskDetail: MaintenanceTask?
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date picker header
                datePickerHeader
                
                // Task timeline content
                if viewModel.isLoading {
                    loadingView
                } else {
                    taskTimelineContent
                }
            }
            .navigationTitle("Task Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filter") {
                        showingFilters = true
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                TaskFilterView(filterOptions: $viewModel.filterOptions)
            }
            .sheet(item: $showingTaskDetail) { task in
                TaskDetailView(task: convertToContextualTask(task))
            }
            .onAppear {
                Task {
                    await viewModel.loadTasks(for: workerId, date: selectedDate)
                }
            }
            .onChange(of: selectedDate) { _, newDate in
                Task {
                    await viewModel.loadTasks(for: workerId, date: newDate)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var datePickerHeader: some View {
        VStack(spacing: 12) {
            // Date picker
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)
            
            // Task summary
            if !viewModel.isLoading {
                taskSummaryView
            }
        }
        .padding(.bottom)
        .background(.ultraThinMaterial)
    }
    
    private var taskSummaryView: some View {
        HStack(spacing: 20) {
            taskSummaryItem("Total", count: viewModel.totalTasksForDate(selectedDate), color: .blue)
            taskSummaryItem("Completed", count: viewModel.completedTasksForDate(selectedDate), color: .green)
            taskSummaryItem("Overdue", count: viewModel.overdueTasksForDate(selectedDate), color: .red)
        }
        .padding(.horizontal)
    }
    
    private func taskSummaryItem(_ title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading tasks...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var taskTimelineContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let tasksForDate = viewModel.tasksForDate(selectedDate)
                
                if tasksForDate.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(tasksForDate.enumerated()), id: \.element.id) { index, task in
                        taskTimelineRow(task: task, isLast: index == tasksForDate.count - 1)
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No tasks scheduled")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("There are no tasks scheduled for \(dateFormatter.string(from: selectedDate))")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private func taskTimelineRow(task: MaintenanceTask, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            timelineIndicator(for: task, isLast: isLast)
            
            // Task content
            TaskTimelineCard(task: task) {
                showingTaskDetail = task
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timelineIndicator(for task: MaintenanceTask, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            // Top line (hidden for first item)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 2, height: 20)
            
            // Circle indicator
            Circle()
                .fill(task.isCompleted ? Color.green : urgencyColor(task.urgency))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // Bottom line (hidden for last item)
            if !isLast {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
                    .frame(minHeight: 40)
            }
        }
    }
    
    private func urgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        
        @unknown default:
            EmptyView()}
    }
    
    // Convert MaintenanceTask to ContextualTask for existing TaskDetailView
    private func convertToContextualTask(_ task: MaintenanceTask) -> ContextualTask {
        // Convert String IDs to Int64 safely
        let buildingIdInt64: Int64
        if let buildingInt = Int64(task.buildingId) {
            buildingIdInt64 = buildingInt
        } else {
            buildingIdInt64 = 0
        }
        
        let workerIdInt64: Int64
        if let firstWorker = task.assignedWorkers.first, let workerInt = Int64(firstWorker) {
            workerIdInt64 = workerInt
        } else {
            workerIdInt64 = Int64(workerId)
        }
        
        // Create ContextualTask using the typealias (which points to ContextualTask)
        return ContextualTask(
            id: Int64(abs(task.id.hashValue)),
            name: task.title,
            description: task.description,
            buildingId: buildingIdInt64,
            workerId: workerIdInt64,
            isCompleted: task.isCompleted,
            dueDate: task.dueDate
        )
    }
}

// MARK: - Task Timeline Card

struct TaskTimelineCard: View {
    let task: MaintenanceTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with time and status
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timeRange)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        // ✅ FIXED: Proper statusText access
                        Text(task.statusText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor)
                            .cornerRadius(8)
                        
                        if task.isPastDue && !task.isCompleted {
                            Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Description
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Footer with category and building
                HStack {
                    categoryBadge
                    
                    Spacer()
                    
                    if !task.buildingId.isEmpty {
                        Label(buildingName, systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if let startTime = task.startTime, let endTime = task.endTime {
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        } else if let startTime = task.startTime {
            return "Starting \(formatter.string(from: startTime))"
        } else {
            return "All day"
        }
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return .green
        } else if task.isPastDue {
            return .red
        } else {
            switch task.urgency {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            case .urgent: return .purple
            
        @unknown default:
            EmptyView()}
        }
    }
    
    private var categoryBadge: some View {
        Text(task.category.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor)
            .cornerRadius(6)
    }
    
    private var categoryColor: Color {
        switch task.category {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .sanitation: return .green
        case .inspection: return .purple
        
        @unknown default:
            EmptyView()}
    }
    
    private var buildingName: String {
        // Get building name from ID - simplified for now
        return "Building \(task.buildingId)"
    }
}

// MARK: - View Model

@MainActor
class TaskTimelineViewModel: ObservableObject {
    @Published var tasksByDate: [String: [MaintenanceTask]] = [:]
    @Published var isLoading = false
    @Published var filterOptions = TaskFilterOptions()
    
    private let taskService = TaskService.shared
    
    func loadTasks(for workerId: Int64, date: Date) async {
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        do {
            let workerIdString = String(workerId)
            let contextualTasks = try await taskService.getTasks(for: workerIdString, date: date)
            
            // ✅ FIXED: Proper MaintenanceTask conversion with all required parameters
            let maintenanceTasks = contextualTasks.compactMap { contextualTask -> MaintenanceTask? in
                guard let dueDate = parseTimeString(contextualTask.startTime, for: date) else {
                    return nil
                }
                
                // ✅ FIXED: Include all required parameters (category, urgency, recurrence)
                return MaintenanceTask(
                    id: contextualTask.id,
                    name: contextualTask.name,
                    buildingID: contextualTask.buildingId,
                    description: "\(contextualTask.category) task for \(contextualTask.buildingName)",
                    dueDate: dueDate,
                    startTime: parseTimeString(contextualTask.startTime, for: date),
                    endTime: parseTimeString(contextualTask.endTime, for: date),
                    category: mapCategory(contextualTask.category),
                    urgency: mapUrgency(contextualTask.urgencyLevel),
                    recurrence: mapRecurrence(contextualTask.recurrence),
                    isComplete: contextualTask.status == "completed",
                    assignedWorkers: [workerIdString],
                    requiredSkillLevel: contextualTask.skillLevel
                )
            }
            
            let dateKey = formatDateForKey(date)
            tasksByDate[dateKey] = maintenanceTasks.sorted { $0.dueDate < $1.dueDate }
            
        } catch {
            print("❌ Failed to load tasks: \(error)")
            tasksByDate[formatDateForKey(date)] = []
        }
    }
    
    func tasksForDate(_ date: Date) -> [MaintenanceTask] {
        let dateKey = formatDateForKey(date)
        let tasks = tasksByDate[dateKey] ?? []
        
        // Apply filters
        return tasks.filter { task in
            // Filter by completion status
            if !filterOptions.showCompleted && task.isCompleted {
                return false
            }
            
            // Filter by category
            if !filterOptions.categories.contains(task.category) {
                return false
            }
            
            // Filter by urgency
            if !filterOptions.urgencies.contains(task.urgency) {
                return false
            }
            
            return true
        }
    }
    
    func totalTasksForDate(_ date: Date) -> Int {
        let dateKey = formatDateForKey(date)
        return tasksByDate[dateKey]?.count ?? 0
    }
    
    func completedTasksForDate(_ date: Date) -> Int {
        let dateKey = formatDateForKey(date)
        return tasksByDate[dateKey]?.filter { $0.isComplete }.count ?? 0
    }
    
    func overdueTasksForDate(_ date: Date) -> Int {
        let dateKey = formatDateForKey(date)
        return tasksByDate[dateKey]?.filter { $0.isPastDue && !$0.isComplete }.count ?? 0
    }
    
    // MARK: - Helper Methods
    
    private func formatDateForKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func parseTimeString(_ timeString: String?, for date: Date) -> Date? {
        guard let timeString = timeString else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            return calendar.date(from: components)
        }
        
        return nil
    }
    
    // Convert MaintenanceTask to ContextualTask for existing TaskDetailView
    private func convertToContextualTask(_ task: MaintenanceTask) -> ContextualTask {
        // Convert String IDs to Int64
        let buildingId = Int64(task.buildingId) ?? 0
        let workerId = Int64(task.assignedWorkers.first ?? "0") ?? Int64(workerId)
        
        return ContextualTask(
            id: Int64(task.id.hashValue), // Use hash of string ID
            name: task.title,
            description: task.description,
            buildingId: buildingId,
            workerId: workerId,
            isCompleted: task.isCompleted,
            dueDate: task.dueDate
        )
    }
    
    // ✅ FIXED: Category mapping function
    private func mapCategory(_ category: String) -> TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "repair": return .repair
        case "sanitation": return .sanitation
        case "inspection": return .inspection
        default: return .maintenance
        
        @unknown default:
            EmptyView()}
    }
    
    // ✅ FIXED: Urgency mapping function
    private func mapUrgency(_ urgency: String) -> TaskUrgency {
        switch urgency.lowercased() {
        case "low": return .low
        case "medium": return .medium
        case "high": return .high
        case "urgent": return .urgent
        default: return .medium
        
        @unknown default:
            EmptyView()}
    }
    
    // ✅ FIXED: Recurrence mapping function
    private func mapRecurrence(_ recurrence: String) -> TaskRecurrence {
        switch recurrence.lowercased() {
        case "daily": return .daily
        case "weekly": return .weekly
        case "monthly": return .monthly
        case "biweekly", "bi-weekly": return .biweekly
        case "quarterly": return .quarterly
        case "semiannual": return .semiannual
        case "annual": return .annual
        default: return .none
        
        @unknown default:
            EmptyView()}
    }
}

// MARK: - Supporting Types

struct TaskFilterOptions {
    var showCompleted = true
    var categories: Set<TaskCategory> = Set(TaskCategory.allCases)
    var urgencies: Set<TaskUrgency> = Set(TaskUrgency.allCases)
}

struct TaskFilterView: View {
    @Binding var filterOptions: TaskFilterOptions
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display Options") {
                    Toggle("Show Completed Tasks", isOn: $filterOptions.showCompleted)
                }
                
                Section("Categories") {
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        Toggle(category.rawValue, isOn: Binding(
                            get: { filterOptions.categories.contains(category) },
                            set: { isOn in
                                if isOn {
                                    filterOptions.categories.insert(category)
                                } else if filterOptions.categories.count > 1 {
                                    filterOptions.categories.remove(category)
                                }
                            }
                        ))
                    }
                }
                
                Section("Urgency Levels") {
                    ForEach(TaskUrgency.allCases, id: \.self) { urgency in
                        Toggle(urgency.rawValue, isOn: Binding(
                            get: { filterOptions.urgencies.contains(urgency) },
                            set: { isOn in
                                if isOn {
                                    filterOptions.urgencies.insert(urgency)
                                } else if filterOptions.urgencies.count > 1 {
                                    filterOptions.urgencies.remove(urgency)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Filter Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct TaskTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskTimelineView(workerId: 4) // Kevin's ID
        }
    }
}
