//
//  BuildingTaskDetailView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All property access aligned with actual CoreTypes definitions
//  ✅ FIXED: Proper optional unwrapping throughout
//  ✅ FIXED: Switch statements made exhaustive
//  ✅ FIXED: Correct InventoryItem initializers
//  ✅ FIXED: WorkerSkill handling without hardcoded cases
//

import SwiftUI
// MARK: - BuildingTaskDetailView

struct BuildingTaskDetailView: View {
    let task: ContextualTask
    @State private var isComplete: Bool
    @State private var completionNotes: String = ""
    @State private var assignedWorkers: [CoreTypes.WorkerAssignment] = []
    @State private var showAssignWorker = false
    @State private var selectedWorkers: [String] = []
    @State private var showingCompletionDialog = false
    @State private var isEditingTask = false
    @State private var requiredSkills: [String] = []  // Using String instead of WorkerSkill enum
    @State private var availableInventory: [InventoryItem] = []
    @State private var selectedInventoryItems: [String: Int] = [:]
    @State private var showInventoryPicker = false

    init(task: ContextualTask) {
        self.task = task
        _isComplete = State(initialValue: task.isCompleted)
        _selectedWorkers = State(initialValue: task.worker?.id != nil ? [task.worker!.id] : [])
    }
    
    private func statusColor(for item: InventoryItem) -> Color {
        if item.currentStock <= 0 {
            return .red
        } else if item.currentStock <= item.minimumStock {
            return .orange
        } else {
            return .green
        }
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
            WorkerAssignmentView(buildingId: task.buildingId ?? "",
                                 selectedWorkers: $selectedWorkers)
        }
        .sheet(isPresented: $isEditingTask) {
            EditTaskView(task: task) { updatedTask in
                isEditingTask = false
                // In a real app, refresh the task from the database.
            }
        }
        .sheet(isPresented: $showInventoryPicker) {
            BuildingTaskInventorySelectionView(buildingId: task.buildingId ?? "",
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
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                statusBadge
            }
            HStack {
                Label(getBuildingName(for: task.buildingId ?? ""), systemImage: "building.2.fill")
                    .font(.subheadline)
                Spacer()
                Label(getRecurrenceText(), systemImage: "repeat")
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
                .fill(taskStatusColor)
                .frame(width: 8, height: 8)
            Text(taskStatusText)
                .font(.caption)
                .foregroundColor(taskStatusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(taskStatusColor.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var taskStatusColor: Color {
        return task.isCompleted ? .green : .orange
    }
    
    private var taskStatusText: String {
        return task.isCompleted ? "Complete" : "Pending"
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
                Text(task.description ?? "No description provided")
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
    
    private var scheduleContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let dueDate = task.dueDate {
                    Label("Due: \(dueDate, formatter: dateFormatter)", systemImage: "calendar")
                        .font(.subheadline)
                }
                // ✅ FIXED: Removed references to non-existent startDate and endDate
                Label("Status: \(task.isCompleted ? "Completed" : "Active")", systemImage: "clock")
                    .font(.subheadline)
            }
            Spacer()
            if !task.isCompleted {
                VStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var skillsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(requiredSkills, id: \.self) { skill in
                HStack {
                    Text(skill)
                        .font(.subheadline)
                    Spacer()
                    Text("★★★")  // Default skill level
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var categoryBadge: some View {
        // ✅ FIXED: Proper optional unwrapping
        let category = task.category ?? .maintenance
        return HStack {
            Image(systemName: categoryIcon(category))
                .foregroundColor(.white)
            Text(category.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(categoryColor(category))
        .cornerRadius(20)
    }
    
    private var urgencyBadge: some View {
        // ✅ FIXED: Proper optional unwrapping
        let urgency = task.urgency ?? .medium
        return HStack {
            Image(systemName: urgencyIcon(urgency))
                .foregroundColor(.white)
            Text(urgency.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(getUrgencyColor(urgency))
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
    
    private var workersListView: some View {
        ForEach(assignedWorkers) { worker in
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(getWorkerName(for: worker))
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
    
    private var emptyInventoryView: some View {
        Text("No inventory items selected for this task")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
    
    private var inventoryItemsView: some View {
        ForEach(Array(selectedInventoryItems.keys.sorted()), id: \.self) { itemId in
            if let item = availableInventory.first(where: { $0.id == itemId }),
               let quantity = selectedInventoryItems[itemId] {
                HStack {
                    Image(systemName: categoryIcon(for: item.category))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.subheadline)
                        // ✅ FIXED: Proper string interpolation
                        Text("Location: \(item.location ?? "Unknown")")
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
                    Text("Task marked as complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                
                if isPastDue() {
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
    
    private func getBuildingName(for buildingId: String) -> String {
        if buildingId == "14" {
            return "Rubin Museum"
        }
        return "Building \(buildingId)"
    }
    
    private func getRecurrenceText() -> String {
        // Simple implementation for recurrence display
        return "One-time"
    }
    
    private func isPastDue() -> Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }
    
    // ✅ FIXED: Made switch exhaustive with all cases
    private func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .inspection: return .purple
        case .security: return .red
        case .landscaping: return .green
        case .utilities: return .yellow
        case .emergency: return .red
        case .installation: return .orange
        case .renovation: return .purple
        case .sanitation: return .green
        case .administrative: return .gray
        }
    }
    
    // ✅ FIXED: Made switch exhaustive with all cases
    private func categoryIcon(_ category: TaskCategory) -> String {
        switch category {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.and.screwdriver"
        case .repair: return "hammer"
        case .inspection: return "magnifyingglass"
        case .security: return "shield"
        case .landscaping: return "leaf"
        case .utilities: return "bolt"
        case .emergency: return "exclamationmark.triangle.fill"
        case .installation: return "plus.square"
        case .renovation: return "building.2"
        case .sanitation: return "trash"
        case .administrative: return "folder"
        }
    }
    
    // ✅ FIXED: Made switch exhaustive with all cases
    private func getUrgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .emergency: return .red
        case .urgent: return .red
        }
    }
    
    // ✅ FIXED: Made switch exhaustive with all cases
    private func urgencyIcon(_ urgency: TaskUrgency) -> String {
        switch urgency {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "arrow.right.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        case .emergency: return "exclamationmark.triangle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    // ✅ FIXED: Made switch exhaustive with all cases
    private func categoryIcon(for category: InventoryCategory) -> String {
        switch category {
        case .tools: return "wrench.and.screwdriver"
        case .supplies: return "box"
        case .equipment: return "gear"
        case .materials: return "cube.box"
        case .safety: return "shield"
        case .cleaning: return "spray.bottle"
        case .electrical: return "bolt"
        case .plumbing: return "wrench"
        case .general: return "shippingbox"
        case .office: return "folder"
        case .maintenance: return "wrench.and.screwdriver"
        case .other: return "questionmark.circle"
        }
    }
    
    private func canManageWorkers() -> Bool {
        return true // Allow all users to manage workers for now
    }
    
    // ✅ FIXED: WorkerAssignment doesn't have role property
    private func workerRoleDisplay(for assignment: CoreTypes.WorkerAssignment) -> String {
        return "Maintenance Worker"  // Default role since WorkerAssignment doesn't have role
    }
    
    private func getWorkerName(for assignment: CoreTypes.WorkerAssignment) -> String {
        return "Worker \(assignment.workerId)"
    }
    
    // MARK: - Data Operations
    
    private func loadTaskData() {
        loadAssignedWorkers()
        loadRequiredSkills()
        loadInventory()
        checkClockInStatus()
    }
    
    private func loadAssignedWorkers() {
        if let worker = task.worker {
            // ✅ FIXED: WorkerAssignment initializer parameters
            assignedWorkers = [
                CoreTypes.WorkerAssignment(
                    id: worker.id,
                    workerId: worker.id,
                    buildingId: task.buildingId ?? ""
                )
            ]
        } else {
            assignedWorkers = []
        }
    }
    
    // ✅ FIXED: Using string skills instead of WorkerSkill enum
    private func loadRequiredSkills() {
        let skillForCategory: String
        switch task.category ?? .maintenance {
        case .cleaning: skillForCategory = "Cleaning"
        case .maintenance: skillForCategory = "General Maintenance"
        case .repair: skillForCategory = "Repair Work"
        case .inspection: skillForCategory = "Safety Inspection"
        case .sanitation: skillForCategory = "Sanitation"
        case .security: skillForCategory = "Security"
        case .landscaping: skillForCategory = "Landscaping"
        case .utilities: skillForCategory = "Utilities Management"
        case .emergency: skillForCategory = "Emergency Response"
        case .installation: skillForCategory = "Installation"
        case .renovation: skillForCategory = "Renovation"
        case .administrative: skillForCategory = "Administrative"
        }
        
        requiredSkills = [skillForCategory]
    }
    
    private func loadInventory() {
        // ✅ FIXED: Correct InventoryItem initializer
        availableInventory = [
            CoreTypes.InventoryItem(
                id: "item1",
                name: "All-Purpose Cleaner",
                category: .supplies,
                currentStock: 10,
                minimumStock: 2,
                maxStock: 50,
                unit: "bottles",
                cost: 5.99
            ),
            CoreTypes.InventoryItem(
                id: "item2",
                name: "Screwdriver Set",
                category: .tools,
                currentStock: 5,
                minimumStock: 1,
                maxStock: 10,
                unit: "sets",
                cost: 29.99
            )
        ]
    }
    
    private func checkClockInStatus() {
        print("Checking clock-in status for task in building: \(task.buildingId ?? "unknown")")
    }
    
    private func autoAssignWorker() {
        let newWorkerId = String(Int.random(in: 1000...9999))
        selectedWorkers.append(newWorkerId)
        loadAssignedWorkers()
    }
    
    private func toggleWorkerSelection(_ workerId: String) {
        if selectedWorkers.contains(workerId) {
            selectedWorkers.removeAll { $0 == workerId }
        } else {
            selectedWorkers.append(workerId)
        }
    }
    
    private func removeWorker(_ workerId: String) {
        selectedWorkers.removeAll { $0 == workerId }
        loadAssignedWorkers()
    }
    
    private func removeInventoryItem(_ itemId: String) {
        selectedInventoryItems.removeValue(forKey: itemId)
    }
    
    private func completeTask() {
        // ✅ FIXED: Removed unnecessary do-catch since no throwing code
        for (itemId, quantity) in selectedInventoryItems {
            if let item = availableInventory.first(where: { $0.id == itemId }) {
                print("Used \(quantity) of \(item.name)")
            }
        }
        
        Task {
            await MainActor.run {
                isComplete = true
            }
            print("Task completed: \(task.title)")
        }
    }
}

// MARK: - Supporting Views

struct WorkerAssignmentView: View {
    let buildingId: String
    @Binding var selectedWorkers: [String]
    @Environment(\.presentationMode) var presentationMode
    @State private var availableWorkers: [CoreTypes.WorkerAssignment] = []
    
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
                                    Text("Worker \(worker.workerId)")
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .onAppear { loadBuildingWorkers() }
        }
    }
    
    private func loadBuildingWorkers() {
        // ✅ FIXED: Correct WorkerAssignment initializer
        let placeholderWorkers = (1...5).map { i -> CoreTypes.WorkerAssignment in
            let workerId = "100\(i)"
            return CoreTypes.WorkerAssignment(
                id: workerId,
                workerId: workerId,
                buildingId: buildingId
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

struct EditTaskView: View {
    let task: ContextualTask
    let onSave: (ContextualTask) -> Void
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var category: TaskCategory
    @State private var urgency: TaskUrgency
    @Environment(\.presentationMode) var presentationMode
    
    init(task: ContextualTask, onSave: @escaping (ContextualTask) -> Void) {
        self.task = task
        self.onSave = onSave
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        // ✅ FIXED: Proper optional unwrapping with defaults
        _category = State(initialValue: task.category ?? .maintenance)
        _urgency = State(initialValue: task.urgency ?? .medium)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $title)
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                    // ✅ FIXED: Proper Picker with CoreTypes prefix
                    Picker("Category", selection: $category) {
                        ForEach(CoreTypes.TaskCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized)
                                .tag(cat)
                        }
                    }
                    Picker("Urgency", selection: $urgency) {
                        ForEach(CoreTypes.TaskUrgency.allCases, id: \.self) { urgency in
                            Text(urgency.rawValue.capitalized)
                                .tag(urgency)
                        }
                    }
                }
                Section(header: Text("Schedule")) {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveTask() }
                }
            }
        }
    }
    
    private func saveTask() {
        // Create updated task - in real app would use proper TaskService
        print("Task updated: \(title)")
        presentationMode.wrappedValue.dismiss()
    }
}

struct BuildingTaskInventorySelectionView: View {
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
                            Text("Available: \(item.currentStock) \(item.unit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Stepper(
                            value: Binding(
                                get: { quantities[item.id] ?? 0 },
                                set: { quantities[item.id] = $0 }
                            ),
                            in: 0...item.currentStock
                        ) {
                            Text("\(quantities[item.id] ?? 0)")
                                .frame(minWidth: 40, alignment: .trailing)
                        }
                    }
                }
            }
            .navigationTitle("Select Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        updateSelectedItems()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                loadInventoryItems()
                for (itemId, quantity) in selectedItems {
                    quantities[itemId] = quantity
                }
            }
        }
    }
    
    private func loadInventoryItems() {
        // ✅ FIXED: Correct InventoryItem initializer
        availableItems = [
            CoreTypes.InventoryItem(
                id: "item1",
                name: "All-Purpose Cleaner",
                category: .supplies,
                currentStock: 10,
                minimumStock: 2,
                maxStock: 50,
                unit: "bottles",
                cost: 5.99
            ),
            CoreTypes.InventoryItem(
                id: "item2",
                name: "Screwdriver Set",
                category: .tools,
                currentStock: 5,
                minimumStock: 1,
                maxStock: 10,
                unit: "sets",
                cost: 29.99
            )
        ]
    }
    
    private func updateSelectedItems() {
        selectedItems = quantities.filter { $0.value > 0 }
    }
}

// MARK: - Preview

struct BuildingTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // ✅ FIXED: Correct ContextualTask initializer
        let sampleTask = CoreTypes.ContextualTask(
            id: "task1",
            title: "HVAC Maintenance",
            description: "Monthly HVAC system inspection and filter replacement",
            isCompleted: false,
            completedDate: nil,
            dueDate: Date(),
            category: .maintenance,
            urgency: .medium,
            building: CoreTypes.NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "142-148 West 17th Street",
                latitude: 40.7402,
                longitude: -73.9980
            ),
            worker: nil,
            buildingId: "14",
            priority: .medium
        )
        
        NavigationView {
            BuildingTaskDetailView(task: sampleTask)
        }
        .preferredColorScheme(.dark)
    }
}
