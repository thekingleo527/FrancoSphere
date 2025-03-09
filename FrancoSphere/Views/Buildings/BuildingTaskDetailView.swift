//
//  BuildingTaskDetailView.swift
//  FrancoSphere
//
//  Updated by Shawn Magloire on 3/3/25.
//

import SwiftUI

// Add extensions for compatibility
extension WorkerSkill {
    var levelStars: String {
        return "★★★" // Default 3 stars
    }
    
    var name: String {
        return self.rawValue
    }
}

// MARK: - BuildingTaskDetailView

struct BuildingTaskDetailView: View {
    let task: MaintenanceTask
    @State private var isComplete: Bool
    @State private var completionNotes: String = ""
    @State private var assignedWorkers: [WorkerAssignment] = []
    @State private var showAssignWorker = false
    @State private var selectedWorkers: [String] = []
    @State private var showingCompletionDialog = false
    @State private var isEditingTask = false
    @State private var requiredSkills: [WorkerSkill] = []
    @State private var availableInventory: [InventoryItem] = []
    @State private var selectedInventoryItems: [String: Int] = [:]
    @State private var showInventoryPicker = false
    @StateObject private var authManager = AuthManager.shared

    // Use a local instance of WorkerAssignmentManager (or replace with your singleton if available)
    private let workerAssignmentManager = WorkerAssignmentManager()
    
    init(task: MaintenanceTask) {
        self.task = task
        _isComplete = State(initialValue: task.isComplete)
        _selectedWorkers = State(initialValue: task.assignedWorkers)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                taskHeaderSection
                Divider()
                taskDetailsSection
                workerAssignmentSection
                inventorySection
                Divider()
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        isEditingTask = true
                    }) {
                        Label("Edit Task", systemImage: "pencil")
                    }
                    if !isComplete {
                        Button(action: {
                            autoAssignWorker()
                        }) {
                            Label("Auto-Assign Worker", systemImage: "person.badge.plus")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadTaskData()
        }
        .sheet(isPresented: $showAssignWorker) {
            WorkerAssignmentView(buildingId: task.buildingID,
                                 selectedWorkers: $selectedWorkers)
        }
        .sheet(isPresented: $isEditingTask) {
            EditTaskView(task: task) { updatedTask in
                isEditingTask = false
                // In a real app, refresh the task from the database.
            }
        }
        .sheet(isPresented: $showInventoryPicker) {
            InventorySelectionView(buildingId: task.buildingID,
                                   selectedItems: $selectedInventoryItems)
        }
        .alert("Complete Task", isPresented: $showingCompletionDialog) {
            Button("Cancel", role: .cancel) {
                showingCompletionDialog = false
            }
            Button("Complete") {
                completeTask()
            }
        } message: {
            Text("Are you sure you want to mark this task as complete?")
        }
    }
    
    // MARK: - UI Sections
    
    private var taskHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                statusBadge
            }
            HStack {
                Label(getBuildingName(for: task.buildingID), systemImage: "building.2.fill")
                    .font(.subheadline)
                Spacer()
                Label(task.recurrence.rawValue, systemImage: "repeat")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var statusBadge: some View {
        HStack {
            Circle()
                .fill(task.statusColor)
                .frame(width: 8, height: 8)
            Text(task.statusText)
                .font(.caption)
                .foregroundColor(task.statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(task.statusColor.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                categoryBadge
                urgencyBadge
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                Text(task.description)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Schedule")
                    .font(.headline)
                scheduleContent
            }
            if !requiredSkills.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Required Skills")
                        .font(.headline)
                    skillsList
                }
            }
        }
    }
    
    // Break down the complex schedule view
    private var scheduleContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Due: \(task.dueDate, formatter: dateFormatter)", systemImage: "calendar")
                    .font(.subheadline)
                if let startTime = task.startTime {
                    Label("Start: \(startTime, formatter: timeFormatter)", systemImage: "clock")
                        .font(.subheadline)
                }
                if let endTime = task.endTime {
                    Label("End: \(endTime, formatter: timeFormatter)", systemImage: "clock.badge.checkmark")
                        .font(.subheadline)
                }
            }
            Spacer()
            if task.recurrence != .oneTime && !task.isComplete {
                VStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text("Recurring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // Break down the skills list
    private var skillsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(requiredSkills, id: \.self) { skill in
                HStack {
                    Text(skill.name)
                        .font(.subheadline)
                    Spacer()
                    Text(skill.levelStars)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var categoryBadge: some View {
        HStack {
            Image(systemName: task.category.icon)
                .foregroundColor(.white)
            Text(task.category.rawValue)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(categoryColor(task.category))
        .cornerRadius(20)
    }
    
    private var urgencyBadge: some View {
        HStack {
            Image(systemName: urgencyIcon(task.urgency))
                .foregroundColor(.white)
            Text(task.urgency.rawValue)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(task.urgency.color)
        .cornerRadius(20)
    }
    
    private var workerAssignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Assigned Workers")
                    .font(.headline)
                Spacer()
                if !isComplete {
                    Button(action: { showAssignWorker = true }) {
                        Label("Assign", systemImage: "person.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
            if assignedWorkers.isEmpty {
                emptyWorkersView
            } else {
                workersListView
            }
        }
    }
    
    // Break down empty workers view
    private var emptyWorkersView: some View {
        HStack {
            Image(systemName: "person.slash")
                .foregroundColor(.orange)
            Text("No workers assigned")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            if !isComplete {
                Button("Auto-Assign") { autoAssignWorker() }
                    .font(.caption)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // Break down workers list view
    private var workersListView: some View {
        ForEach(assignedWorkers) { worker in
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(worker.workerName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(workerRoleDisplay(for: worker))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !isComplete && canManageWorkers() {
                    Button(action: { removeWorker(worker.id) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inventory Usage")
                    .font(.headline)
                Spacer()
                if !isComplete {
                    Button(action: { showInventoryPicker = true }) {
                        Label("Select Items", systemImage: "cart.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if selectedInventoryItems.isEmpty {
                emptyInventoryView
            } else {
                inventoryItemsView
            }
        }
    }
    
    // Break down empty inventory view
    private var emptyInventoryView: some View {
        Text("No inventory items selected for this task")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
    
    // Break down inventory items view
    private var inventoryItemsView: some View {
        ForEach(Array(selectedInventoryItems.keys.sorted()), id: \.self) { itemId in
            if let item = availableInventory.first(where: { $0.id == itemId }),
               let quantity = selectedInventoryItems[itemId] {
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.subheadline)
                        Text("Location: \(item.location)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(quantity) \(item.unit)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    if !isComplete {
                        Button(action: { removeInventoryItem(itemId) }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if isComplete {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("This task has been completed")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    if task.recurrence != .oneTime {
                        Text("The next occurrence has been scheduled automatically")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            } else {
                Button(action: { showingCompletionDialog = true }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("MARK AS COMPLETE")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                }
                .background(Color.green)
                .cornerRadius(10)
                if task.isPastDue {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("This task is past due")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private func getBuildingName(for buildingID: String) -> String {
        if let building = NamedCoordinate.allBuildings.first(where: { $0.id == buildingID }) {
            return building.name
        }
        return "Unknown Building"
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
    
    private func urgencyIcon(_ urgency: TaskUrgency) -> String {
        switch urgency {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "arrow.right.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    private func canManageWorkers() -> Bool {
        return authManager.userRole == "admin" || authManager.userRole == "supervisor"
    }
    
    private func workerRoleDisplay(for assignment: WorkerAssignment) -> String {
        // For demonstration, we return a fixed role.
        return "Maintenance Worker"
    }
    
    // MARK: - Data Operations
    
    private func loadTaskData() {
        loadAssignedWorkers()
        loadRequiredSkills()
        loadInventory()
        checkClockInStatus()
    }
    
    // FIXED: Proper WorkerAssignment creation
    private func loadAssignedWorkers() {
        // Create WorkerAssignment instances from assigned worker IDs
        assignedWorkers = task.assignedWorkers.map { workerId in
            return WorkerAssignment(
                id: workerId,
                workerId: workerId,
                taskId: task.id,
                assignmentDate: Date(),
                workerName: "Worker #\(workerId)"
            )
        }
    }
    
    // FIXED: Use direct mapping instead of static methods
    private func loadRequiredSkills() {
        // Map task category to corresponding skill
        let skillForCategory: WorkerSkill
        switch task.category {
        case .cleaning: skillForCategory = .cleaning
        case .maintenance: skillForCategory = .maintenance
        case .repair: skillForCategory = .repair
        case .inspection: skillForCategory = .inspection
        case .sanitation: skillForCategory = .sanitation
        }
        
        // Create a simple array of required skills
        requiredSkills = [skillForCategory]
    }
    
    private func loadInventory() {
        // Simplified implementation for demo
        availableInventory = [
            InventoryItem(
                id: "item1",
                name: "All-Purpose Cleaner",
                buildingID: task.buildingID,
                category: .cleaning,
                quantity: 10,
                unit: "bottles",
                minimumQuantity: 2, location: "Janitor Closet"
            ),
            InventoryItem(
                id: "item2",
                name: "Screwdriver Set",
                buildingID: task.buildingID,
                category: .tools,
                quantity: 5,
                unit: "sets",
                minimumQuantity: 1, location: "Tool Room"
            )
        ]
    }
    
    private func checkClockInStatus() {
        let status = SQLiteManager.shared.isWorkerClockedIn(workerId: authManager.workerId)
        if !status.isClockedIn || status.buildingId != Int64(task.buildingID) {
            // In a real app, show a warning alert.
        }
    }
    private func autoAssignWorker() {
        // Generate a random worker ID as a placeholder
        if let newWorkerId = String(Int.random(in: 1000...9999)) as String? {
            selectedWorkers.append(newWorkerId)
            // Reload workers after assignment
            loadAssignedWorkers()
        }
    }
    // FIXED: Simple implementation that doesn't depend on manager
    private func toggleWorkerSelection(_ workerId: String) {
        if selectedWorkers.contains(workerId) {
            selectedWorkers.removeAll { $0 == workerId }
        } else {
            selectedWorkers.append(workerId)
        }
    }
    
    // FIXED: Simple implementation that doesn't depend on manager
    private func removeWorker(_ workerId: String) {
        selectedWorkers.removeAll { $0 == workerId }
        // Reload workers after removal
        loadAssignedWorkers()
    }
    
    private func removeInventoryItem(_ itemId: String) {
        selectedInventoryItems.removeValue(forKey: itemId)
    }
    
    private func completeTask() {
        for (itemId, quantity) in selectedInventoryItems {
            if let item = availableInventory.first(where: { $0.id == itemId }) {
                print("Used \(quantity) of \(item.name)")
            }
        }
        TaskManager.shared.toggleTaskCompletion(taskID: task.id)
        isComplete = true
    }
}

// MARK: - Subview Stubs

// Fixed WorkerAssignmentView
struct WorkerAssignmentView: View {
    let buildingId: String
    @Binding var selectedWorkers: [String]
    @Environment(\.presentationMode) var presentationMode
    @State private var availableWorkers: [WorkerAssignment] = []
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Building Workers")) {
                    if availableWorkers.isEmpty {
                        Text("No workers assigned to this building")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availableWorkers) { worker in
                            Button(action: { toggleWorkerSelection(worker.workerId) }) {
                                HStack {
                                    Text(worker.workerName)
                                    Spacer()
                                    if selectedWorkers.contains(worker.workerId) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("Assign Workers")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Done") { presentationMode.wrappedValue.dismiss() }
            )
            .onAppear { loadBuildingWorkers() }
        }
    }
    
    // FIXED: Simple implementation that doesn't depend on specific manager method
    private func loadBuildingWorkers() {
        // Create sample workers for the view
        let placeholderWorkers = (1...5).map { i -> WorkerAssignment in
            let workerId = "100\(i)"
            return WorkerAssignment(
                id: workerId,
                workerId: workerId,
                taskId: "", // Empty string for placeholder
                assignmentDate: Date(),
                workerName: "Worker #\(workerId)"
            )
        }
        availableWorkers = placeholderWorkers
    }
    
    private func toggleWorkerSelection(_ workerId: String) {
        if selectedWorkers.contains(workerId) {
            selectedWorkers.removeAll { $0 == workerId }
        } else {
            selectedWorkers.append(workerId)
        }
    }
}

// Stub for EditTaskView - FIXED initializer parameter order
struct EditTaskView: View {
    let task: MaintenanceTask
    let onSave: (MaintenanceTask) -> Void
    @State private var name: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var category: TaskCategory
    @State private var urgency: TaskUrgency
    @State private var recurrence: TaskRecurrence
    @State private var startTime: Date?
    @State private var endTime: Date?
    @Environment(\.presentationMode) var presentationMode
    
    init(task: MaintenanceTask, onSave: @escaping (MaintenanceTask) -> Void) {
        self.task = task
        self.onSave = onSave
        _name = State(initialValue: task.name)
        _description = State(initialValue: task.description)
        _dueDate = State(initialValue: task.dueDate)
        _category = State(initialValue: task.category)
        _urgency = State(initialValue: task.urgency)
        _recurrence = State(initialValue: task.recurrence)
        _startTime = State(initialValue: task.startTime)
        _endTime = State(initialValue: task.endTime)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $name)
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    Picker("Urgency", selection: $urgency) {
                        ForEach(TaskUrgency.allCases, id: \.self) { urgency in
                            Text(urgency.rawValue)
                                .tag(urgency)
                        }
                    }
                }
                Section(header: Text("Schedule")) {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    Picker("Recurrence", selection: $recurrence) {
                        ForEach(TaskRecurrence.allCases, id: \.self) { rec in
                            Text(rec.rawValue)
                                .tag(rec)
                        }
                    }
                    Toggle("Specific Start Time", isOn: Binding(
                        get: { startTime != nil },
                        set: { newValue in startTime = newValue ? Date() : nil }
                    ))
                    if startTime != nil {
                        DatePicker("Start Time", selection: Binding(
                            get: { startTime ?? Date() },
                            set: { startTime = $0 }
                        ), displayedComponents: .hourAndMinute)
                    }
                    Toggle("Specific End Time", isOn: Binding(
                        get: { endTime != nil },
                        set: { newValue in endTime = newValue ? Date() : nil }
                    ))
                    if endTime != nil {
                        DatePicker("End Time", selection: Binding(
                            get: { endTime ?? Date() },
                            set: { endTime = $0 }
                        ), displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") { saveTask() }
            )
        }
    }
    
    // FIXED: Proper parameter order matching MaintenanceTask initializer
    private func saveTask() {
        let updatedTask = MaintenanceTask(
            id: task.id,
            name: name,
            buildingID: task.buildingID,
            description: description,
            dueDate: dueDate,
            startTime: startTime,
            endTime: endTime,
            category: category,
            urgency: urgency,
            recurrence: recurrence,
            isComplete: task.isComplete,
            assignedWorkers: task.assignedWorkers
        )
        onSave(updatedTask)
        presentationMode.wrappedValue.dismiss()
    }
}

// Simple placeholder for InventorySelectionView
struct TaskInventorySelectionView: View {
    let buildingId: String
    @Binding var selectedItems: [String: Int]
    @Environment(\.presentationMode) var presentationMode
    @State private var availableItems: [InventoryItem] = []
    @State private var quantities: [String: Int] = [:]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableItems) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            Text("Available: \(item.quantity) \(item.unit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Stepper(
                            value: Binding(
                                get: { quantities[item.id] ?? 0 },
                                set: { quantities[item.id] = $0 }
                            ),
                            in: 0...item.quantity
                        ) {
                            Text("\(quantities[item.id] ?? 0)")
                                .frame(minWidth: 40, alignment: .trailing)
                        }
                    }
                }
            }
            .navigationTitle("Select Inventory")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    updateSelectedItems()
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                loadInventoryItems()
                // Initialize quantities from selected items
                for (itemId, quantity) in selectedItems {
                    quantities[itemId] = quantity
                }
            }
        }
    }
    
    private func loadInventoryItems() {
        // Sample inventory items for demo
        availableItems = [
            InventoryItem(
                id: "item1",
                name: "All-Purpose Cleaner",
                buildingID: buildingId,
                category: .cleaning,
                quantity: 10,
                unit: "bottles",
                minimumQuantity: 2,
                location: "Janitor Closet"
            )
,
            InventoryItem(
                id: "item2",
                name: "Screwdriver Set",
                buildingID: buildingId,
                category: .tools,
                quantity: 5,
                unit: "sets",
                minimumQuantity: 1,
                location: "Tool Room"
            )
        ]
    }
    
    private func updateSelectedItems() {
        // Update selected items with non-zero quantities
        selectedItems = quantities.filter { $0.value > 0 }
    }
}
