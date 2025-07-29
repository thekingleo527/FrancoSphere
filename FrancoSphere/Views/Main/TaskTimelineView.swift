//
//  TaskTimelineView.swift
//  FrancoSphere v6.0
//
//  ✅ REFACTORED: Uses CoreTypes.ContextualTask consistently
//  ✅ OPTIMIZED: Efficient data loading for specific worker
//  ✅ INTEGRATED: Cross-dashboard sync support
//  ✅ ENHANCED: Nova AI insights integration
//

import SwiftUI
import Combine

// MARK: - Task Timeline View

struct TaskTimelineView: View {
    let workerId: String
    let workerName: String?
    
    @StateObject private var viewModel = TaskTimelineViewModel()
    @State private var selectedDate = Date()
    @State private var showingFilters = false
    @State private var showingTaskDetail: CoreTypes.ContextualTask?
    @State private var showingNovaInsights = false
    
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
                    Menu {
                        Button(action: { showingFilters = true }) {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button(action: { showingNovaInsights = true }) {
                            Label("AI Insights", systemImage: "brain")
                        }
                        
                        Button(action: { refreshTasks() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                TaskFilterView(filterOptions: $viewModel.filterOptions)
            }
            .sheet(item: $showingTaskDetail) { task in
                NavigationView {
                    TaskDetailView(task: task)
                }
            }
            .sheet(isPresented: $showingNovaInsights) {
                NovaTaskInsightsView(workerId: workerId, date: selectedDate)
            }
            .onAppear {
                viewModel.initialize(workerId: workerId, workerName: workerName)
                loadTasksForSelectedDate()
            }
            .onChange(of: selectedDate) { _, newDate in
                loadTasksForSelectedDate()
            }
            .onReceive(viewModel.dashboardUpdatePublisher) { _ in
                // Refresh when cross-dashboard updates occur
                loadTasksForSelectedDate()
            }
        }
    }
    
    // MARK: - UI Components
    
    private var datePickerHeader: some View {
        VStack(spacing: 12) {
            // Date navigation
            HStack {
                Button(action: { moveDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                
                Button(action: { moveDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button("Today") {
                    selectedDate = Date()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            
            if !viewModel.isLoading {
                taskSummaryView
            }
        }
        .padding(.bottom)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 2)
    }
    
    private var taskSummaryView: some View {
        HStack(spacing: 20) {
            taskSummaryItem("Total", count: viewModel.taskStats.total, color: .blue)
            taskSummaryItem("Completed", count: viewModel.taskStats.completed, color: .green)
            taskSummaryItem("Pending", count: viewModel.taskStats.pending, color: .orange)
            taskSummaryItem("Overdue", count: viewModel.taskStats.overdue, color: .red)
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
        .frame(maxWidth: .infinity)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading timeline...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var taskTimelineContent: some View {
        ScrollView {
            if viewModel.filteredTasks.isEmpty {
                emptyStateView
                    .padding(.top, 60)
            } else {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    // Group tasks by time
                    ForEach(viewModel.taskGroups, id: \.0) { timeGroup, tasks in
                        Section {
                            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                                taskTimelineRow(
                                    task: task,
                                    isFirst: index == 0,
                                    isLast: index == tasks.count - 1,
                                    isLastGroup: timeGroup == viewModel.taskGroups.last?.0
                                )
                            }
                        } header: {
                            timeGroupHeader(timeGroup)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func timeGroupHeader(_ timeGroup: String) -> some View {
        Text(timeGroup)
            .font(.headline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground).opacity(0.95))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.hasActiveTasks ? "line.3.horizontal.decrease.circle" : "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(viewModel.hasActiveTasks ? "No tasks match filters" : "No tasks scheduled")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if viewModel.hasActiveTasks {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var emptyStateMessage: String {
        if viewModel.hasActiveTasks {
            return "Try adjusting your filters to see more tasks"
        } else {
            return "There are no tasks scheduled for \(dateFormatter.string(from: selectedDate))"
        }
    }
    
    private func taskTimelineRow(task: CoreTypes.ContextualTask, isFirst: Bool, isLast: Bool, isLastGroup: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            timelineIndicator(for: task, isFirst: isFirst, isLast: isLast && isLastGroup)
            
            TaskTimelineCard(task: task) {
                showingTaskDetail = task
            }
            .transition(.scale.combined(with: .opacity))
        }
        .padding(.vertical, 8)
    }
    
    private func timelineIndicator(for task: CoreTypes.ContextualTask, isFirst: Bool, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            if !isFirst {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2, height: 20)
            }
            
            ZStack {
                Circle()
                    .fill(indicatorColor(for: task))
                    .frame(width: 16, height: 16)
                
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .shadow(color: indicatorColor(for: task).opacity(0.3), radius: 3)
            
            if !isLast {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
            }
        }
        .frame(width: 20)
    }
    
    private func indicatorColor(for task: CoreTypes.ContextualTask) -> Color {
        if task.isCompleted {
            return .green
        } else if isOverdue(task) {
            return .red
        } else {
            return FrancoSphereDesign.EnumColors.taskUrgency(task.urgency ?? .medium)
        }
    }
    
    private func isOverdue(_ task: CoreTypes.ContextualTask) -> Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
    
    // MARK: - Helper Methods
    
    private func moveDate(by days: Int) {
        if let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func loadTasksForSelectedDate() {
        Task {
            await viewModel.loadTasks(for: selectedDate)
        }
    }
    
    private func refreshTasks() {
        Task {
            await viewModel.refreshTasks(for: selectedDate)
        }
    }
}

// MARK: - Task Timeline Card

struct TaskTimelineCard: View {
    let task: CoreTypes.ContextualTask
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if let building = task.building {
                            Label(building.name, systemImage: "building.2")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    statusBadge
                }
                
                // Description
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Footer badges
                HStack(spacing: 8) {
                    categoryBadge
                    urgencyBadge
                    
                    Spacer()
                    
                    if let dueDate = task.dueDate {
                        timeDisplay(for: dueDate)
                    }
                }
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: shadowColor, radius: isPressed ? 2 : 4, y: isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.1) {
            // Action handled by button
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    
    private var borderColor: Color {
        if task.isCompleted {
            return .green.opacity(0.3)
        } else if isOverdue {
            return .red.opacity(0.3)
        } else {
            return Color(.separator).opacity(0.5)
        }
    }
    
    private var shadowColor: Color {
        if task.isCompleted {
            return .green.opacity(0.1)
        } else if isOverdue {
            return .red.opacity(0.1)
        } else {
            return .black.opacity(0.1)
        }
    }
    
    private var statusBadge: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }
    
    private var statusText: String {
        if task.isCompleted {
            return "Completed"
        } else if isOverdue {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return .green
        } else if isOverdue {
            return .red
        } else {
            return .orange
        }
    }
    
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
    
    private var categoryBadge: some View {
        Group {
            if let category = task.category {
                Label(category.rawValue.capitalized, systemImage: categoryIcon(category))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.EnumColors.taskCategory(category))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FrancoSphereDesign.EnumColors.taskCategory(category).opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
    
    private var urgencyBadge: some View {
        Group {
            if let urgency = task.urgency {
                Text(urgency.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FrancoSphereDesign.EnumColors.taskUrgency(urgency))
                    .cornerRadius(6)
            }
        }
    }
    
    private func timeDisplay(for date: Date) -> some View {
        Label(timeFormatter.string(from: date), systemImage: "clock")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func categoryIcon(_ category: CoreTypes.TaskCategory) -> String {
        switch category {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.and.screwdriver"
        case .repair: return "hammer"
        case .sanitation: return "trash"
        case .inspection: return "magnifyingglass"
        case .landscaping: return "leaf"
        case .security: return "shield"
        case .emergency: return "exclamationmark.triangle.fill"
        case .installation: return "plus.square"
        case .utilities: return "bolt"
        case .renovation: return "building.2"
        case .administrative: return "folder"
        }
    }
}

// MARK: - View Model

@MainActor
class TaskTimelineViewModel: ObservableObject {
    @Published var tasks: [CoreTypes.ContextualTask] = []
    @Published var isLoading = false
    @Published var filterOptions = TaskFilterOptions()
    @Published var taskStats = TaskStats()
    
    private var workerId: String = ""
    private var workerName: String?
    private let taskService = TaskService.shared
    private let dashboardSyncService = DashboardSyncService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var filteredTasks: [CoreTypes.ContextualTask] {
        tasks.filter { task in
            if !filterOptions.showCompleted && task.isCompleted { return false }
            if let category = task.category, !filterOptions.categories.contains(category) { return false }
            if let urgency = task.urgency, !filterOptions.urgencies.contains(urgency) { return false }
            return true
        }
    }
    
    var taskGroups: [(String, [CoreTypes.ContextualTask])] {
        let groups = Dictionary(grouping: filteredTasks) { task -> String in
            if task.isCompleted {
                return "Completed"
            } else if isOverdue(task) {
                return "Overdue"
            } else if let dueDate = task.dueDate, Calendar.current.isDateInToday(dueDate) {
                return "Today"
            } else {
                return "Upcoming"
            }
        }
        
        let order = ["Overdue", "Today", "Upcoming", "Completed"]
        return order.compactMap { key in
            if let tasks = groups[key] {
                return (key, tasks.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) })
            }
            return nil
        }
    }
    
    var hasActiveTasks: Bool {
        !tasks.isEmpty
    }
    
    var dashboardUpdatePublisher: AnyPublisher<CoreTypes.DashboardUpdate, Never> {
        dashboardSyncService.crossDashboardUpdates
            .filter { [weak self] update in
                guard let self = self else { return false }
                // Listen for task-related updates for this worker
                return update.workerId == self.workerId &&
                       (update.type == .taskCompleted || update.type == .taskStarted)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    func initialize(workerId: String, workerName: String?) {
        self.workerId = workerId
        self.workerName = workerName
    }
    
    // MARK: - Data Loading
    
    func loadTasks(for date: Date) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load tasks for specific worker
            let allTasks = try await taskService.getTasksForWorker(workerId)
            
            // Filter for selected date
            let calendar = Calendar.current
            tasks = allTasks.filter { task in
                if let dueDate = task.dueDate {
                    return calendar.isDate(dueDate, inSameDayAs: date)
                }
                return false
            }
            
            updateTaskStats()
            
        } catch {
            print("❌ Failed to load timeline tasks: \(error)")
            tasks = []
        }
    }
    
    func refreshTasks(for date: Date) async {
        // Broadcast refresh request
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .buildingMetricsChanged,
            buildingId: "",
            workerId: workerId,
            data: ["action": "refresh", "date": ISO8601DateFormatter().string(from: date)]
        )
        dashboardSyncService.broadcastWorkerUpdate(update)
        
        // Reload tasks
        await loadTasks(for: date)
    }
    
    func clearFilters() {
        filterOptions = TaskFilterOptions()
    }
    
    // MARK: - Private Methods
    
    private func updateTaskStats() {
        taskStats = TaskStats(
            total: tasks.count,
            completed: tasks.filter { $0.isCompleted }.count,
            pending: tasks.filter { !$0.isCompleted && !isOverdue($0) }.count,
            overdue: tasks.filter { isOverdue($0) }.count
        )
    }
    
    private func isOverdue(_ task: CoreTypes.ContextualTask) -> Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
}

// MARK: - Supporting Types

struct TaskStats {
    var total: Int = 0
    var completed: Int = 0
    var pending: Int = 0
    var overdue: Int = 0
}

struct TaskFilterOptions {
    var showCompleted = true
    var categories: Set<CoreTypes.TaskCategory> = Set(CoreTypes.TaskCategory.allCases)
    var urgencies: Set<CoreTypes.TaskUrgency> = Set(CoreTypes.TaskUrgency.allCases)
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
                    ForEach(CoreTypes.TaskCategory.allCases, id: \.self) { category in
                        Toggle(category.rawValue.capitalized, isOn: Binding(
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
                    ForEach(CoreTypes.TaskUrgency.allCases, id: \.self) { urgency in
                        Toggle(urgency.rawValue.capitalized, isOn: Binding(
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

// MARK: - Nova AI Insights View

struct NovaTaskInsightsView: View {
    let workerId: String
    let date: Date
    
    @State private var insights: [CoreTypes.IntelligenceInsight] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Analyzing tasks...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if insights.isEmpty {
                    ContentUnavailableView(
                        "No Insights Available",
                        systemImage: "brain",
                        description: Text("Nova AI couldn't generate insights for this date")
                    )
                } else {
                    List(insights) { insight in
                        NovaInsightRow(insight: insight)
                    }
                }
            }
            .navigationTitle("AI Task Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadInsights()
            }
        }
    }
    
    private func loadInsights() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let novaInsights = try await NovaIntelligenceEngine.shared.generateTaskTimelineInsights(
                workerId: workerId,
                date: date
            )
            insights = novaInsights
        } catch {
            print("Failed to load Nova insights: \(error)")
            insights = []
        }
    }
}

struct NovaInsightRow: View {
    let insight: CoreTypes.IntelligenceInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForCategory(insight.category))
                    .foregroundColor(colorForPriority(insight.priority))
                
                Text(insight.title)
                    .font(.headline)
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            if insight.actionRequired {
                Label("Action Required", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForCategory(_ category: CoreTypes.InsightCategory) -> String {
        switch category {
        case .efficiency: return "speedometer"
        case .cost: return "dollarsign.circle"
        case .safety: return "shield"
        case .compliance: return "checkmark.shield"
        case .quality: return "star"
        case .operations: return "gearshape.2"
        case .maintenance: return "wrench.and.screwdriver"
        }
    }
    
    private func colorForPriority(_ priority: CoreTypes.AIPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
}
