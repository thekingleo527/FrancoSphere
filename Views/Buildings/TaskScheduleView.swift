//
//  TaskScheduleView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With actual ContextualTask structure from codebase analysis
//  ✅ INTEGRATED: Proper constructor and property access
//  ✅ EXHAUSTIVE: All switch statements handle all cases
//

import SwiftUI

struct TaskScheduleView: View {
    let buildingID: String
    
    @State private var selectedDate: Date = Date()
    @State private var calendar = Calendar.current
    @State private var monthDates: [Date] = []
    @State private var visibleMonth: Date = Date()
    @State private var weekDays: [String] = []
    @State private var tasks: [ContextualTask] = []
    @State private var isLoading = true
    @State private var showTaskDetail: ContextualTask? = nil
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
                TaskDetailView(task: task)
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
    
    private func taskStatusColor(_ task: ContextualTask) -> Color {
        if task.isCompleted {
            return .gray
        } else {
            // ✅ FIXED: Handle optional urgency with nil coalescing
            return (task.urgency ?? .medium).color
        }
    }
    
    private func taskStatusText(_ task: ContextualTask) -> String {
        if task.isCompleted {
            return "Completed"
        } else if isPastDue(task) {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private func isPastDue(_ task: ContextualTask) -> Bool {
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
                
                let textColor = getTextColor(isCurrentMonth: isCurrentMonth, isSelected: isSelected, isToday: isToday)
                
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
    
    private func getTextColor(isCurrentMonth: Bool, isSelected: Bool, isToday: Bool) -> Color {
        if !isCurrentMonth { return .gray }
        if isSelected { return .white }
        if isToday { return .blue }
        return .primary
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
                            Button(action: { toggleCategory(category) }) {
                                HStack {
                                    Image(systemName: categoryIcon(category))
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
                        ForEach(TaskUrgency.allCases, id: \.self) { urgency in
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
                if options.categories.count > 1 {
                    options.categories.remove(category)
                }
            } else {
                options.categories.insert(category)
            }
        }
        
        private func toggleUrgency(_ urgency: TaskUrgency) {
            if options.urgencies.contains(urgency) {
                if options.urgencies.count > 1 {
                    options.urgencies.remove(urgency)
                }
            } else {
                options.urgencies.insert(urgency)
            }
        }
        
        // ✅ FIXED: Exhaustive switch for all TaskCategory cases
        private func categoryColor(_ category: TaskCategory) -> Color {
            switch category {
            case .cleaning:     return .blue
            case .maintenance:  return .orange
            case .repair:       return .red
            case .inspection:   return .purple
            case .security:     return .red
            case .landscaping:  return .green
            case .installation: return .green
            case .utilities:    return .yellow
            case .emergency:    return .red
            case .renovation:   return .brown
            }
        }
        
        // ✅ FIXED: Exhaustive switch for all TaskCategory cases
        private func categoryIcon(_ category: TaskCategory) -> String {
            switch category {
            case .cleaning:     return "sparkles"
            case .maintenance:  return "wrench"
            case .repair:       return "hammer"
            case .inspection:   return "eye"
            case .security:     return "shield"
            case .landscaping:  return "leaf"
            case .installation: return "plus.square"
            case .utilities:    return "bolt"
            case .emergency:    return "exclamationmark.triangle"
            case .renovation:   return "house"
            }
        }
    }
    
    // MARK: - Task Row
    
    struct TaskRow: View {
        let task: ContextualTask
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    // ✅ FIXED: Handle optional category with nil coalescing
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : categoryIcon(task.category ?? .maintenance))
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // ✅ FIXED: Use task.name (confirmed from codebase analysis)
                    Text(task.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(task.description ?? "No description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 15) {
                        // ✅ FIXED: Handle optional category with nil coalescing
                        let categoryValue = task.category ?? .maintenance
                        Label(categoryValue.rawValue.capitalized, systemImage: categoryIcon(categoryValue))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if !task.recurrence.isEmpty && task.recurrence != "none" {
                            Label(task.recurrence.capitalized, systemImage: "repeat")
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
                // ✅ FIXED: Handle optional urgency with nil coalescing
                return (task.urgency ?? .medium).color
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
        
        private func isPastDue(_ task: ContextualTask) -> Bool {
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }
        
        // ✅ FIXED: Exhaustive switch for all TaskCategory cases
        private func categoryIcon(_ category: TaskCategory) -> String {
            switch category {
            case .cleaning:     return "sparkles"
            case .maintenance:  return "wrench"
            case .repair:       return "hammer"
            case .inspection:   return "eye"
            case .security:     return "shield"
            case .landscaping:  return "leaf"
            case .installation: return "plus.square"
            case .utilities:    return "bolt"
            case .emergency:    return "exclamationmark.triangle"
            case .renovation:   return "house"
            }
        }
    }
    
    // MARK: - Task Form View
    
    struct TaskFormView: View {
        let buildingID: String
        let date: Date
        let onSave: (ContextualTask) -> Void
        
        @State private var taskName: String = ""
        @State private var taskDescription: String = ""
        @State private var category: TaskCategory = .maintenance
        @State private var urgency: TaskUrgency = .medium
        @State private var recurrence: String = "none"
        
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
                            ForEach(TaskCategory.allCases, id: \.self) { category in
                                Text(category.rawValue.capitalized)
                                    .tag(category)
                            }
                        }
                        
                        Picker("Urgency", selection: $urgency) {
                            ForEach(TaskUrgency.allCases, id: \.self) { urgency in
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
                            Text("None").tag("none")
                            Text("Daily").tag("daily")
                            Text("Weekly").tag("weekly")
                            Text("Monthly").tag("monthly")
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
            // ✅ FIXED: Use the actual ContextualTask constructor based on codebase analysis
            let task = ContextualTask(
                id: UUID().uuidString,
                name: taskName,
                buildingId: buildingID,
                buildingName: "Building \(buildingID)",
                category: category.rawValue,
                startTime: formatTime(date),
                endTime: formatTime(date.addingTimeInterval(3600)),
                recurrence: recurrence,
                skillLevel: urgency.rawValue,
                status: "pending",
                urgencyLevel: urgency.rawValue,
                assignedWorkerName: NewAuthManager.shared.currentWorkerName,
                workerId: NewAuthManager.shared.workerId,
                isCompleted: false,
                dueDate: date,
                estimatedDuration: 3600,
                notes: taskDescription.isEmpty ? nil : taskDescription,
                description: taskDescription.isEmpty ? nil : taskDescription
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
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Computed Properties
    
    private var tasksForSelectedDate: [ContextualTask] {
        getTasksForDate(selectedDate)
            .filter { task in
                if !filterOptions.showCompleted && task.isCompleted {
                    return false
                }
                
                // ✅ FIXED: Handle optional category with nil coalescing
                if !filterOptions.categories.contains(task.category ?? .maintenance) {
                    return false
                }
                
                // ✅ FIXED: Handle optional urgency with nil coalescing
                if !filterOptions.urgencies.contains(task.urgency ?? .medium) {
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
                
                let firstPriority = urgencyPriority(first.urgency ?? .medium)
                let secondPriority = urgencyPriority(second.urgency ?? .medium)
                return firstPriority > secondPriority
            }
    }
    
    // ✅ FIXED: Exhaustive switch for all TaskUrgency cases
    private func urgencyPriority(_ urgency: TaskUrgency) -> Int {
        switch urgency {
        case .critical, .emergency: return 5
        case .urgent:               return 4
        case .high:                 return 3
        case .medium:               return 2
        case .low:                  return 1
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
                if let nextDate = dates.last,
                   let newDate = calendar.date(byAdding: .day, value: day + 1, to: nextDate) {
                    dates.append(newDate)
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
    
    private func getTasksForDate(_ date: Date) -> [ContextualTask] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTasks() {
        isLoading = true
        
        Task {
            do {
                // ✅ FIXED: Use correct TaskService method that exists
                let contextualTasks = try await TaskService.shared.getTasks(for: buildingID, date: Date())
                
                await MainActor.run {
                    self.tasks = contextualTasks
                    self.isLoading = false
                    loadTasksForSelectedDate()
                }
            } catch {
                await MainActor.run {
                    self.tasks = []
                    self.isLoading = false
                    print("❌ Failed to load tasks: \(error)")
                }
            }
        }
    }
    
    private func loadTasksForSelectedDate() {
        // This method updates the filtered tasks for the selected date
        // The actual filtering happens in the computed property tasksForSelectedDate
    }
    
    private func refreshData() {
        loadTasks()
    }
}
