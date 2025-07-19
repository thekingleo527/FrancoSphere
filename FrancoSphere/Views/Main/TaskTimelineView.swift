//
//  TaskTimelineView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Proper ContextualTask property access
//  ✅ FIXED: Correct MaintenanceTask constructor calls
//  ✅ FIXED: Optional unwrapping and type conversions
//

import SwiftUI

// MARK: - Task Timeline View

struct TaskTimelineView: View {
    let workerId: String
    
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
                datePickerHeader
                
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
                TaskFilterView(filterOptions: viewModel.filterOptions) { updatedOptions in
                    viewModel.filterOptions = updatedOptions
                }
            }
            .sheet(item: $showingTaskDetail) { task in
                TaskDetailView(task: convertToContextualTask(task))
            }
            .onAppear {
                Task {
                    await viewModel.loadTasks(for: workerId, date: selectedDate)
                }
            }
            .onChange(of: selectedDate) { newDate in
                Task {
                    await viewModel.loadTasks(for: workerId, date: newDate)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var datePickerHeader: some View {
        VStack(spacing: 12) {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)
            
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
            
            Text("There are no tasks scheduled for \(dateFormatter.string(from: selectedDate))")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private func taskTimelineRow(task: MaintenanceTask, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            timelineIndicator(for: task, isLast: isLast)
            TaskTimelineCard(task: task) {
                showingTaskDetail = task
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timelineIndicator(for task: MaintenanceTask, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 2, height: 20)
            
            Circle()
                .fill(task.isCompleted ? Color.green : urgencyColor(task.urgency))
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            
            if !isLast {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
            }
        }
    }
    
    private func urgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        case .critical: return .red
        case .emergency: return .red
        }
    }
    
    // ✅ FIXED: Simple ContextualTask conversion with correct parameter order
    private func convertToContextualTask(_ task: MaintenanceTask) -> ContextualTask {
        return ContextualTask(
            id: task.id,
            title: task.title,
            isCompleted: task.isCompleted,
            buildingId: task.buildingId
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
                        Text(statusText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor)
                            .cornerRadius(8)
                    }
                }
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    categoryBadge
                    Spacer()
                    if !task.buildingId.isEmpty {
                        Label("Building \(task.buildingId)", systemImage: "building.2")
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
        
        if let start = task.startTime, let end = task.endTime {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let start = task.startTime {
            return "Starting \(formatter.string(from: start))"
        } else {
            return "All day"
        }
    }
    
    private var statusText: String {
        if task.isCompleted {
            return "Completed"
        } else if task.isPastDue {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return .green
        } else if task.isPastDue {
            return .red
        } else {
            return urgencyColor(task.urgency)
        }
    }
    
    private var categoryBadge: some View {
        Text(task.category.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor(task.category))
            .cornerRadius(6)
    }
    
    private func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .sanitation: return .green
        case .inspection: return .purple
        case .landscaping: return .green
        case .security: return .red
        case .emergency: return .red
        case .installation: return .blue
        case .utilities: return .yellow
        case .renovation: return .brown
        }
    }
    
    private func urgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        case .critical: return .red
        case .emergency: return .red
        }
    }
}

// MARK: - View Model

@MainActor
class TaskTimelineViewModel: ObservableObject {
    @Published var tasksByDate: [String: [MaintenanceTask]] = [:]
    @Published var isLoading = false
    @Published var filterOptions = TaskFilterOptions()
    
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared
    
    func loadTasks(for workerId: String, date: Date) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let contextualTasks = try await taskService.getAllTasks()
            
            // Filter tasks for the specific worker and date
            let filteredTasks = contextualTasks.filter { task in
                let isAssignedToWorker = task.assignedWorkerId == workerId
                
                let isForDate: Bool
                if let dueDate = task.dueDate {
                    isForDate = Calendar.current.isDate(dueDate, inSameDayAs: date)
                } else {
                    // ✅ FIXED: If no due date, include task for today only
                    isForDate = Calendar.current.isDate(Date(), inSameDayAs: date)
                }
                
                return isAssignedToWorker && isForDate
            }
            
            let maintenanceTasks = filteredTasks.compactMap { contextualTask -> MaintenanceTask? in
                // ✅ FIXED: Correct MaintenanceTask constructor with proper parameter order
                return MaintenanceTask(
                    id: contextualTask.id,
                    title: contextualTask.title ?? "Untitled Task",
                    description: contextualTask.description ?? "",
                    category: contextualTask.category ?? .maintenance,
                    urgency: contextualTask.urgency ?? .medium,
                    buildingId: contextualTask.buildingId ?? "",
                    assignedWorkerId: contextualTask.assignedWorkerId,
                    isCompleted: contextualTask.isCompleted,
                    dueDate: contextualTask.dueDate,
                    estimatedDuration: 3600,
                    recurrence: .none,
                    status: contextualTask.isCompleted ? .verified : .pending
                )
            }
            
            let dateKey = formatDateForKey(date)
            tasksByDate[dateKey] = maintenanceTasks.sorted { task1, task2 in
                let time1 = task1.startTime ?? task1.dueDate ?? Date.distantPast
                let time2 = task2.startTime ?? task2.dueDate ?? Date.distantPast
                return time1 < time2
            }
            
        } catch {
            print("❌ Failed to load tasks: \(error)")
            tasksByDate[formatDateForKey(date)] = []
        }
    }
    
    func tasksForDate(_ date: Date) -> [MaintenanceTask] {
        let dateKey = formatDateForKey(date)
        let tasks = tasksByDate[dateKey] ?? []
        
        return tasks.filter { task in
            if !filterOptions.showCompleted && task.isCompleted { return false }
            if !filterOptions.categories.contains(task.category) { return false }
            if !filterOptions.urgencies.contains(task.urgency) { return false }
            return true
        }
    }
    
    func totalTasksForDate(_ date: Date) -> Int {
        tasksByDate[formatDateForKey(date)]?.count ?? 0
    }
    
    func completedTasksForDate(_ date: Date) -> Int {
        tasksByDate[formatDateForKey(date)]?.filter { $0.isCompleted }.count ?? 0
    }
    
    func overdueTasksForDate(_ date: Date) -> Int {
        tasksByDate[formatDateForKey(date)]?.filter { $0.isPastDue && !$0.isCompleted }.count ?? 0
    }
    
    private func formatDateForKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct TaskFilterOptions {
    var showCompleted = true
    var categories: Set<TaskCategory> = Set(TaskCategory.allCases)
    var urgencies: Set<TaskUrgency> = Set(TaskUrgency.allCases)
}

struct TaskFilterView: View {
    let filterOptions: TaskFilterOptions
    let onUpdate: (TaskFilterOptions) -> Void
    
    @State private var localOptions: TaskFilterOptions
    @Environment(\.dismiss) private var dismiss
    
    init(filterOptions: TaskFilterOptions, onUpdate: @escaping (TaskFilterOptions) -> Void) {
        self.filterOptions = filterOptions
        self.onUpdate = onUpdate
        self._localOptions = State(initialValue: filterOptions)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display Options") {
                    Toggle("Show Completed Tasks", isOn: $localOptions.showCompleted)
                }
                
                Section("Categories") {
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        Toggle(category.rawValue, isOn: Binding(
                            get: { localOptions.categories.contains(category) },
                            set: { isOn in
                                if isOn {
                                    localOptions.categories.insert(category)
                                } else if localOptions.categories.count > 1 {
                                    localOptions.categories.remove(category)
                                }
                            }
                        ))
                    }
                }
                
                Section("Urgency Levels") {
                    ForEach(TaskUrgency.allCases, id: \.self) { urgency in
                        Toggle(urgency.rawValue, isOn: Binding(
                            get: { localOptions.urgencies.contains(urgency) },
                            set: { isOn in
                                if isOn {
                                    localOptions.urgencies.insert(urgency)
                                } else if localOptions.urgencies.count > 1 {
                                    localOptions.urgencies.remove(urgency)
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
                        onUpdate(localOptions)
                        dismiss()
                    }
                }
            }
        }
    }
}
