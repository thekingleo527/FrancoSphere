//
//  TaskScheduleView.swift
//  FrancoSphere
//
//  ✅ FIXED: Proper imports and TaskCategory usage
//  ✅ Integration with real services (TaskService, BuildingService)
//  ✅ Actor-compatible async/await patterns
//

import SwiftUI

struct TaskScheduleView: View {
    let buildingID: String
    
    @State private var selectedDate: Date = Date()
    @State private var calendar = Calendar.current
    @State private var monthDates: [Date] = []
    @State private var visibleMonth: Date = Date()
    @State private var weekDays: [String] = []
    @State private var tasks: [MaintenanceTask] = []
    @State private var isLoading = true
    @State private var showTaskDetail: MaintenanceTask? = nil
    @State private var showAddTask = false
    @State private var selectedView: ScheduleView = .month
    @State private var showFilterOptions = false
    @State private var filterOptions = FilterOptions()
    
    enum ScheduleView {
        case week
        case month
    }
    
    struct FilterOptions {
        var showCompleted = true
        var categories: Set<FrancoSphere.TaskCategory> = Set(FrancoSphere.TaskCategory.allCases)
        var urgencies: Set<FrancoSphere.TaskUrgency> = Set(FrancoSphere.TaskUrgency.allCases)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar header with month and controls
            calendarHeader
            
            // Week or month selector
            viewSelector
            
            // Weekday header
            weekdayHeader
            
            // Calendar body (week or month view)
            if selectedView == .month {
                monthView
            } else {
                weekView
            }
            
            // Task list for selected date
            taskListSection
        }
        .navigationTitle("Task Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showAddTask = true }) {
                        Label("Add Task", systemImage: "plus")
                    }
                    
                    Button(action: { showFilterOptions = true }) {
                        Label("Filter Tasks", systemImage: "line.horizontal.3.decrease.circle")
                    }
                    
                    Button(action: { refreshData() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            setupCalendar()
            loadTasks()
        }
        .onChange(of: selectedDate) { _ in
            loadTasksForSelectedDate()
        }
        .onChange(of: visibleMonth) { _ in
            updateMonthDates()
        }
        .sheet(item: $showTaskDetail) { task in
            NavigationView {
                BuildingTaskDetailView(task: task)
            }
        }
        .sheet(isPresented: $showAddTask) {
            TaskFormView(buildingID: buildingID, date: selectedDate) { newTask in
                tasks.append(newTask)
                showAddTask = false
            }
        }
        .sheet(isPresented: $showFilterOptions) {
            FilterView(options: $filterOptions)
        }
    }
    
    // MARK: - Helper Functions
    
    private func taskStatusColor(_ task: MaintenanceTask) -> Color {
        if task.isCompleted {
            return .gray
        } else {
            return task.urgency.color
        }
    }
    
    private func taskStatusText(_ task: MaintenanceTask) -> String {
        if task.isCompleted {
            return "Completed"
        } else if isPastDue(task) {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private func isPastDue(_ task: MaintenanceTask) -> Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }
    
    // MARK: - Calendar Header
    
    private var calendarHeader: some View {
        HStack {
            Text(monthYearString(from: visibleMonth))
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            HStack {
                Button(action: { navigateMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .padding(8)
                }
                
                Button(action: {
                    selectedDate = Date()
                    visibleMonth = Date()
                    updateMonthDates()
                }) {
                    Text("Today")
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: { navigateMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .padding(8)
                }
            }
        }
        .padding()
    }
    
    // MARK: - View Selector
    
    private var viewSelector: some View {
        Picker("View", selection: $selectedView) {
            Text("Week").tag(ScheduleView.week)
            Text("Month").tag(ScheduleView.month)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Weekday Header
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Month View
    
    private var monthView: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(monthDates, id: \.self) { date in
                    dateCell(date)
                }
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Week View
    
    private var weekView: some View {
        let weekDates = getWeekDates(for: selectedDate)
        
        return HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                dateCell(date)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Date Cell
    
    private func dateCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.component(.month, from: date) == calendar.component(.month, from: visibleMonth)
        let tasksForDate = getTasksForDate(date)
        
        return Button(action: {
            selectedDate = date
            if !isCurrentMonth {
                visibleMonth = date
                updateMonthDates()
            }
        }) {
            VStack(spacing: 4) {
                let dayNumber = calendar.component(.day, from: date)
                let fontSize: CGFloat = selectedView == .week ? 20 : 16
                let fontWeight: Font.Weight = (isSelected || isToday) ? .bold : .regular
                let textColor: Color = {
                    if isCurrentMonth {
                        if isSelected { return .white }
                        else if isToday { return .blue }
                        else { return .primary }
                    } else {
                        return .gray
                    }
                }()
                
                Text("\(dayNumber)")
                    .font(.system(size: fontSize))
                    .fontWeight(fontWeight)
                    .foregroundColor(textColor)
                
                if selectedView == .week {
                    VStack(spacing: 2) {
                        ForEach(tasksForDate.prefix(3), id: \.id) { task in
                            Circle()
                                .fill(taskStatusColor(task))
                                .frame(width: 8, height: 8)
                        }
                        
                        if tasksForDate.count > 3 {
                            Text("+\(tasksForDate.count - 3)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                } else {
                    if !tasksForDate.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(0..<min(3, tasksForDate.count), id: \.self) { index in
                                Circle()
                                    .fill(taskStatusColor(tasksForDate[index]))
                                    .frame(width: 6, height: 6)
                            }
                            
                            if tasksForDate.count > 3 {
                                Text("+\(tasksForDate.count - 3)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
            }
            .frame(height: selectedView == .week ? 80 : 50)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
            .padding(2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Task List Section
    
    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(calendar.isDateInToday(selectedDate) ? "Today" : dateString(from: selectedDate)), \(tasksForSelectedDate.count) tasks")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showAddTask = true }) {
                    Label("Add", systemImage: "plus.circle")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            if isLoading {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity)
            } else if tasksForSelectedDate.isEmpty {
                emptyTasksView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tasksForSelectedDate) { task in
                            TaskRow(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showTaskDetail = task
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(maxHeight: 300)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyTasksView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No tasks scheduled for this date")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Button(action: { showAddTask = true }) {
                Text("Add Task")
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Filter View
    
    struct FilterView: View {
        @State var options: FilterOptions
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Status")) {
                        Toggle("Show Completed Tasks", isOn: $options.showCompleted)
                    }
                    
                    Section(header: Text("Categories")) {
                        ForEach(FrancoSphere.TaskCategory.allCases, id: \.self) { category in
                            Button(action: { toggleCategory(category) }) {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(categoryColor(category))
                                    
                                    Text(category.rawValue.capitalized)
                                    
                                    Spacer()
                                    
                                    if options.categories.contains(category) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Section(header: Text("Urgency")) {
                        ForEach(FrancoSphere.TaskUrgency.allCases, id: \.self) { urgency in
                            Button(action: { toggleUrgency(urgency) }) {
                                HStack {
                                    Circle()
                                        .fill(urgency.color)
                                        .frame(width: 10, height: 10)
                                    
                                    Text(urgency.rawValue.capitalized)
                                    
                                    Spacer()
                                    
                                    if options.urgencies.contains(urgency) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Section {
                        Button(action: {
                            options.showCompleted = true
                            options.categories = Set(FrancoSphere.TaskCategory.allCases)
                            options.urgencies = Set(FrancoSphere.TaskUrgency.allCases)
                        }) {
                            Text("Reset Filters")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .navigationTitle("Filter Tasks")
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
        
        private func toggleCategory(_ category: FrancoSphere.TaskCategory) {
            if options.categories.contains(category) {
                if options.categories.count > 1 {
                    options.categories.remove(category)
                }
            } else {
                options.categories.insert(category)
            }
        }
        
        private func toggleUrgency(_ urgency: FrancoSphere.TaskUrgency) {
            if options.urgencies.contains(urgency) {
                if options.urgencies.count > 1 {
                    options.urgencies.remove(urgency)
                }
            } else {
                options.urgencies.insert(urgency)
            }
        }
        
        private func categoryColor(_ category: FrancoSphere.TaskCategory) -> Color {
            // Use default colors for each category
            switch category {
            case .cleaning:     return .blue
            case .maintenance:  return .orange
            case .repair:       return .red
            case .sanitation:   return .green
            case .inspection:   return .purple
            case .security:     return .red
            case .landscaping:  return .green
            case .electrical:   return .yellow
            case .plumbing:     return .blue
            case .hvac:         return .cyan
            case .renovation:   return .brown
            case .utilities:    return .yellow
            case .installation: return .green
            case .emergency:    return .red
            }
        }
    }
    
    // MARK: - Task Row
    
    struct TaskRow: View {
        let task: MaintenanceTask
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : task.category.icon)
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 15) {
                        Label(task.category.rawValue.capitalized, systemImage: task.category.icon)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if task.recurrence != .none {
                            Label(task.recurrence.rawValue.capitalized, systemImage: "repeat")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        
        private var statusColor: Color {
            if task.isCompleted {
                return .gray
            } else {
                return task.urgency.color
            }
        }
        
        private var statusText: String {
            if task.isCompleted {
                return "Completed"
            } else if isPastDue(task) {
                return "Overdue"
            } else {
                return "Pending"
            }
        }
        
        private func isPastDue(_ task: MaintenanceTask) -> Bool {
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }
    }
    
    // MARK: - Task Form View
    
    struct TaskFormView: View {
        let buildingID: String
        let date: Date
        let onSave: (MaintenanceTask) -> Void
        
        @State private var taskName: String = ""
        @State private var taskDescription: String = ""
        @State private var category: FrancoSphere.TaskCategory = .maintenance
        @State private var urgency: FrancoSphere.TaskUrgency = .medium
        @State private var recurrence: FrancoSphere.TaskRecurrence = .oneTime
        
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Task Details")) {
                        TextField("Task Name", text: $taskName)
                        
                        ZStack(alignment: .topLeading) {
                            if taskDescription.isEmpty {
                                Text("Describe what needs to be done...")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                            
                            TextEditor(text: $taskDescription)
                                .frame(minHeight: 100)
                        }
                        
                        Picker("Category", selection: $category) {
                            ForEach(FrancoSphere.TaskCategory.allCases, id: \.self) { category in
                                Label(category.rawValue.capitalized, systemImage: category.icon)
                                    .tag(category)
                            }
                        }
                        
                        Picker("Urgency", selection: $urgency) {
                            ForEach(FrancoSphere.TaskUrgency.allCases, id: \.self) { urgency in
                                HStack {
                                    Circle()
                                        .fill(urgency.color)
                                        .frame(width: 10, height: 10)
                                    
                                    Text(urgency.rawValue.capitalized)
                                }
                                .tag(urgency)
                            }
                        }
                    }
                    
                    Section(header: Text("Timing")) {
                        HStack {
                            Text("Due Date")
                            Spacer()
                            Text(formatDate(date))
                                .foregroundColor(.secondary)
                        }
                        
                        Picker("Recurrence", selection: $recurrence) {
                            ForEach(FrancoSphere.TaskRecurrence.allCases, id: \.self) { recurrence in
                                Text(recurrence.rawValue.capitalized).tag(recurrence)
                            }
                        }
                    }
                }
                .navigationTitle("Add Task")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button("Save") {
                        saveTask()
                    }
                    .disabled(taskName.isEmpty)
                )
            }
        }
        
        private func saveTask() {
            let task = MaintenanceTask(
                title: taskName,
                description: taskDescription,
                category: category,
                urgency: urgency,
                buildingId: buildingID,
                assignedWorkerId: nil,
                isCompleted: false,
                dueDate: date,
                estimatedDuration: TimeInterval(3600),
                recurrence: recurrence,
                notes: nil
            )
            
            onSave(task)
            presentationMode.wrappedValue.dismiss()
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Computed Properties
    
    private var tasksForSelectedDate: [MaintenanceTask] {
        getTasksForDate(selectedDate)
            .filter { task in
                if !filterOptions.showCompleted && task.isCompleted {
                    return false
                }
                
                if !filterOptions.categories.contains(task.category) {
                    return false
                }
                
                if !filterOptions.urgencies.contains(task.urgency) {
                    return false
                }
                
                return true
            }
            .sorted { first, second in
                let firstDate = first.dueDate ?? Date.distantFuture
                let secondDate = second.dueDate ?? Date.distantFuture
                
                if firstDate != secondDate {
                    return firstDate < secondDate
                }
                
                let firstPriority = urgencyPriority(first.urgency)
                let secondPriority = urgencyPriority(second.urgency)
                return firstPriority > secondPriority
            }
    }
    
    private func urgencyPriority(_ urgency: FrancoSphere.TaskUrgency) -> Int {
        switch urgency {
        case .critical: return 4
        case .high:     return 3
        case .medium:   return 2
        case .low:      return 1
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupCalendar() {
        weekDays = calendar.veryShortWeekdaySymbols
        calendar.firstWeekday = 1
        updateMonthDates()
    }
    
    private func updateMonthDates() {
        monthDates = getDaysInMonth(for: visibleMonth)
    }
    
    private func getDaysInMonth(for date: Date) -> [Date] {
        var dates: [Date] = []
        
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        if offsetDays > 0 {
            for day in (1...offsetDays).reversed() {
                if let prevDate = calendar.date(byAdding: .day, value: -day, to: firstDayOfMonth) {
                    dates.append(prevDate)
                }
            }
        }
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                dates.append(date)
            }
        }
        
        let totalDays = dates.count
        let remainingDays = 42 - totalDays
        
        if remainingDays > 0 {
            for day in 0..<remainingDays {
                if let nextDate = calendar.date(byAdding: .day, value: day + 1, to: dates.last!) {
                    dates.append(nextDate)
                }
            }
        }
        
        return dates
    }
    
    private func getWeekDates(for date: Date) -> [Date] {
        var weekDates: [Date] = []
        
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7
        
        if let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: date) {
            for day in 0..<7 {
                if let weekDate = calendar.date(byAdding: .day, value: day, to: startOfWeek) {
                    weekDates.append(weekDate)
                }
            }
        }
        
        return weekDates
    }
    
    private func navigateMonth(by months: Int) {
        if let newDate = calendar.date(byAdding: .month, value: months, to: visibleMonth) {
            visibleMonth = newDate
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func getTasksForDate(_ date: Date) -> [MaintenanceTask] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTasks() {
        isLoading = true
        
        Task {
            let fetchedTasks = await TaskService.shared.fetchTasks(
                forBuilding: buildingID,
                includePastTasks: true
            )
            
            await MainActor.run {
                tasks = fetchedTasks
                isLoading = false
                loadTasksForSelectedDate()
            }
        }
    }
    
    private func loadTasksForSelectedDate() {
        // Filter already loaded tasks
    }
    
    private func refreshData() {
        loadTasks()
    }
}

// MARK: - Extensions for TaskService

extension TaskService {
    func fetchTasks(forBuilding buildingId: String, includePastTasks: Bool) async -> [MaintenanceTask] {
        do {
            // Get all tasks for the building
            let contextualTasks = try await getTasksForBuilding(buildingId, date: Date())
            
            // Convert ContextualTask to MaintenanceTask
            return contextualTasks.map { task in
                MaintenanceTask(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    category: task.category,
                    urgency: task.urgency,
                    buildingId: task.buildingId,
                    assignedWorkerId: task.assignedWorkerId,
                    isCompleted: task.isCompleted,
                    dueDate: task.dueDate,
                    estimatedDuration: task.estimatedDuration,
                    recurrence: task.recurrence,
                    notes: task.notes
                )
            }
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
}

// MARK: - Preview Support

struct TaskScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskScheduleView(buildingID: "1")
        }
    }
}
