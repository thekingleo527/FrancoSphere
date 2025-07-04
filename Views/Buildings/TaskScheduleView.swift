
//
//  TaskScheduleView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/4/25.
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
        var categories: Set<TaskCategory> = Set(TaskCategory.allCases)
        var urgencies: Set<TaskUrgency> = Set(TaskUrgency.allCases)
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
                    Button(action: {
                        showAddTask = true
                    }) {
                        Label("Add Task", systemImage: "plus")
                    }
                    
                    Button(action: {
                        showFilterOptions = true
                    }) {
                        Label("Filter Tasks", systemImage: "line.horizontal.3.decrease.circle")
                    }
                    
                    Button(action: {
                        refreshData()
                    }) {
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
        if task.isComplete {
            return .gray
        } else {
            switch task.urgency {
            case .low:    return .green
            case .medium: return .yellow
            case .high:   return .orange
            case .urgent: return .red
            }
        }
    }
    
    private func taskStatusText(_ task: MaintenanceTask) -> String {
        if task.isComplete {
            return "Completed"
        } else if task.isPastDue {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    // MARK: - Calendar Header
    
    private var calendarHeader: some View {
        HStack {
            // Month and year display
            Text(monthYearString(from: visibleMonth))
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // Navigation buttons
            HStack {
                Button(action: {
                    navigateMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .padding(8)
                }
                
                Button(action: {
                    // Reset to today
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
                
                Button(action: {
                    navigateMonth(by: 1)
                }) {
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
                    // Date cell
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
                // Date cell (larger for week view)
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
            
            // If the selected date is in a different month, update the visible month
            if !isCurrentMonth {
                visibleMonth = date
                updateMonthDates()
            }
        }) {
            VStack(spacing: 4) {
                // Date number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: selectedView == .week ? 20 : 16))
                    .fontWeight(isSelected || isToday ? .bold : .regular)
                    .foregroundColor(isCurrentMonth ? (isSelected ? .white : (isToday ? .blue : .primary)) : .gray)
                
                if selectedView == .week {
                    // Show more details in week view
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
                    // Just show task indicators in month view
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
                
                Button(action: {
                    showAddTask = true
                }) {
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
            
            Button(action: {
                showAddTask = true
            }) {
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
        @Binding var options: FilterOptions
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Status")) {
                        Toggle("Show Completed Tasks", isOn: $options.showCompleted)
                    }
                    
                    Section(header: Text("Categories")) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Button(action: {
                                toggleCategory(category)
                            }) {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(categoryColor(category))
                                    
                                    Text(category.rawValue)
                                    
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
                        ForEach(TaskUrgency.allCases, id: \.self) { urgency in
                            Button(action: {
                                toggleUrgency(urgency)
                            }) {
                                HStack {
                                    Circle()
                                        .fill(urgencyColor(urgency))
                                        .frame(width: 10, height: 10)
                                    
                                    Text(urgency.rawValue)
                                    
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
                            // Reset filters
                            options.showCompleted = true
                            options.categories = Set(TaskCategory.allCases)
                            options.urgencies = Set(TaskUrgency.allCases)
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
        
        private func toggleCategory(_ category: TaskCategory) {
            if options.categories.contains(category) {
                // Don't allow deselecting all categories
                if options.categories.count > 1 {
                    options.categories.remove(category)
                }
            } else {
                options.categories.insert(category)
            }
        }
        
        private func toggleUrgency(_ urgency: TaskUrgency) {
            if options.urgencies.contains(urgency) {
                // Don't allow deselecting all urgencies
                if options.urgencies.count > 1 {
                    options.urgencies.remove(urgency)
                }
            } else {
                options.urgencies.insert(urgency)
            }
        }
        
        private func categoryColor(_ category: TaskCategory) -> Color {
            switch category {
            case .cleaning: return .blue
            case .maintenance: return .orange
            case .repair: return .red
            case .sanitation: return .green
            case .inspection: return .purple
            }
        }
        
        private func urgencyColor(_ urgency: TaskUrgency) -> Color {
            switch urgency {
            case .low:    return .green
            case .medium: return .yellow
            case .high:   return .orange
            case .urgent: return .red
            }
        }
    }
    
    // MARK: - Task Row
    
    struct TaskRow: View {
        let task: MaintenanceTask
        
        var body: some View {
            HStack(spacing: 12) {
                // Task status indicator
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: task.isComplete ? "checkmark.circle.fill" : task.category.icon)
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 15) {
                        if let startTime = task.startTime {
                            Label(formatTime(startTime), systemImage: "clock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Label(task.category.rawValue, systemImage: task.category.icon)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if task.recurrence != .oneTime {
                            Label(task.recurrence.rawValue, systemImage: "repeat")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Task status badge
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
            if task.isComplete {
                return .gray
            } else {
                switch task.urgency {
                case .low:    return .green
                case .medium: return .yellow
                case .high:   return .orange
                case .urgent: return .red
                }
            }
        }
        
        private var statusText: String {
            if task.isComplete {
                return "Completed"
            } else if task.isPastDue {
                return "Overdue"
            } else {
                return "Pending"
            }
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Task Form View
    
    struct TaskFormView: View {
        let buildingID: String
        let date: Date
        let onSave: (MaintenanceTask) -> Void
        
        @State private var taskName: String = ""
        @State private var taskDescription: String = ""
        @State private var category: TaskCategory = .maintenance
        @State private var urgency: TaskUrgency = .medium
        @State private var recurrence: TaskRecurrence = .oneTime
        @State private var addStartTime = false
        @State private var startTime: Date
        @State private var addEndTime = false
        @State private var endTime: Date
        
        @Environment(\.presentationMode) var presentationMode
        
        init(buildingID: String, date: Date, onSave: @escaping (MaintenanceTask) -> Void) {
            self.buildingID = buildingID
            self.date = date
            self.onSave = onSave
            
            // Initialize times to 9 AM and 5 PM on the selected date
            let calendar = Calendar.current
            let startComponents = calendar.dateComponents([.year, .month, .day], from: date)
            var modifiedComponents = startComponents
            modifiedComponents.hour = 9
            modifiedComponents.minute = 0
            _startTime = State(initialValue: calendar.date(from: modifiedComponents) ?? date)
            
            modifiedComponents.hour = 17
            modifiedComponents.minute = 0
            _endTime = State(initialValue: calendar.date(from: modifiedComponents) ?? date)
        }
        
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
                            ForEach(TaskCategory.allCases, id: \.self) { category in
                                Label(category.rawValue, systemImage: category.icon)
                                    .tag(category)
                            }
                        }
                        
                        Picker("Urgency", selection: $urgency) {
                            ForEach(TaskUrgency.allCases, id: \.self) { urgency in
                                HStack {
                                    Circle()
                                        .fill(urgencyColor(urgency))
                                        .frame(width: 10, height: 10)
                                    
                                    Text(urgency.rawValue)
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
                            ForEach(TaskRecurrence.allCases, id: \.self) { recurrence in
                                Text(recurrence.rawValue).tag(recurrence)
                            }
                        }
                        
                        Toggle("Add Start Time", isOn: $addStartTime)
                        
                        if addStartTime {
                            DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                        }
                        
                        Toggle("Add End Time", isOn: $addEndTime)
                        
                        if addEndTime && addStartTime {
                            DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
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
            // Prepare the start time and end time
            var calculatedStartTime: Date? = nil
            var calculatedEndTime: Date? = nil
            
            if addStartTime {
                // Combine the date part from the selected date with the time part from startTime
                let calendar = Calendar.current
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                
                calculatedStartTime = calendar.date(from: dateComponents)
                
                if addEndTime {
                    // Similarly for end time
                    var endDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                    
                    endDateComponents.hour = endTimeComponents.hour
                    endDateComponents.minute = endTimeComponents.minute
                    
                    calculatedEndTime = calendar.date(from: endDateComponents)
                }
            }
            
            // Create the task with all properties set at initialization
            let task = MaintenanceTask(
                name: taskName,
                buildingID: buildingID,
                description: taskDescription,
                dueDate: date,
                startTime: calculatedStartTime,
                endTime: calculatedEndTime,
                category: category,
                urgency: urgency,
                recurrence: recurrence
            )
            
            // Save the task
            onSave(task)
            presentationMode.wrappedValue.dismiss()
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        private func urgencyColor(_ urgency: TaskUrgency) -> Color {
            switch urgency {
            case .low:    return .green
            case .medium: return .yellow
            case .high:   return .orange
            case .urgent: return .red
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var tasksForSelectedDate: [MaintenanceTask] {
        // Apply filters
        return getTasksForDate(selectedDate)
            .filter { task in
                // Filter by completion status
                if !filterOptions.showCompleted && task.isComplete {
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
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    // MARK: - Helper Methods
    
    private func setupCalendar() {
        // Set up weekday symbols
        weekDays = calendar.veryShortWeekdaySymbols
        
        // Set first day of week to Sunday (index 1)
        calendar.firstWeekday = 1
        
        // Update month dates
        updateMonthDates()
    }
    
    private func updateMonthDates() {
        monthDates = getDaysInMonth(for: visibleMonth)
    }
    
    private func getDaysInMonth(for date: Date) -> [Date] {
        var dates: [Date] = []
        
        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }
        
        // Get the first weekday of the month (0-based index)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        // Add days from the previous month to fill the first week
        if offsetDays > 0 {
            for day in (1...offsetDays).reversed() {
                if let prevDate = calendar.date(byAdding: .day, value: -day, to: firstDayOfMonth) {
                    dates.append(prevDate)
                }
            }
        }
        
        // Add all days in the current month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                dates.append(date)
            }
        }
        
        // Add days from the next month to complete the last week if needed
        let totalDays = dates.count
        let remainingDays = 42 - totalDays // 6 weeks total for consistent grid
        
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
        
        // Get start of week (Sunday)
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7
        
        if let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: date) {
            // Generate the 7 days of the week
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
            calendar.isDate(task.dueDate, inSameDayAs: date)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTasks() {
        isLoading = true
        
        Task {
            // Make it async
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
        // This would be a separate fetch in a real app for efficiency
        // Here we're just filtering the already loaded tasks
    }
    
    private func refreshData() {
        loadTasks()
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
