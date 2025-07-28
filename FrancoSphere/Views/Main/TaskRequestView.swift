import Foundation
import SwiftUI
import UIKit
import Combine

//
//  TaskRequestView.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Using CoreTypes.InventoryItem with FULL initializer
//  ✅ FIXED: All type references explicitly use CoreTypes namespace
//  ✅ FIXED: .onAppear closure structure corrected
//  ✅ FIXED: Added Combine import for better type support
//

// MARK: - Supporting Models (Must be defined before use)

struct TaskSuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let category: String
    let urgency: String
    let buildingId: String
    
    static func == (lhs: TaskSuggestion, rhs: TaskSuggestion) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Main View

struct TaskRequestView: View {
    // ✅ TODO: Replace with actual AuthManager implementation when available
    // @StateObject private var authManager = NewAuthManager.shared
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedBuildingID: String = ""
    @State private var selectedCategory: TaskCategory = .maintenance
    @State private var selectedUrgency: TaskUrgency = .medium
    @State private var selectedDate: Date = Date().addingTimeInterval(86400) // Tomorrow
    @State private var showCompletionAlert = false
    @State private var addStartTime = false
    @State private var startTime: Date = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var addEndTime = false
    @State private var endTime: Date = Date().addingTimeInterval(7200) // 2 hours from now
    @State private var attachPhoto = false
    @State private var photo: UIImage?
    @State private var showPhotoSelector = false
    @State private var requiredInventory: [String: Int] = [:]
    @State private var showInventorySelector = false
    @State private var availableInventory: [CoreTypes.InventoryItem] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var suggestions: [TaskSuggestion] = []
    @State private var showSuggestions = false
    @Environment(\.presentationMode) var presentationMode
    
    // ✅ FIXED: Load buildings asynchronously
    @State private var buildingOptions: [NamedCoordinate] = []
    @State private var isLoadingBuildings = true
    
    // ✅ NEW: Worker selection state
    @State private var selectedWorkerId: String = "4" // Default to Kevin Dutan
    @State private var workerOptions: [WorkerProfile] = []
    
    // Services are accessed as singletons, not @StateObject since they're actors
    
    var body: some View {
        NavigationView {
            Form {
                if isLoadingBuildings {
                    loadingSection
                } else {
                    taskDetailsSection
                    locationSection
                    scheduleSection
                    
                    if !requiredInventory.isEmpty {
                        materialsSection
                    }
                    
                    attachmentSection
                    actionSection
                    
                    if !suggestions.isEmpty {
                        suggestionSection
                    }
                }
            }
            .navigationTitle("New Task Request")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Submit", action: submitTaskWrapper)
                    .disabled(!isFormValid || isSubmitting)
            )
            .task {
                loadBuildings()
                loadWorkers()
                loadSuggestions()
            }
            .alert(isPresented: $showCompletionAlert) {
                Alert(
                    title: Text("Task Request Submitted"),
                    message: Text("Your request has been submitted successfully."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .sheet(isPresented: $showPhotoSelector) {
                PhotoPickerView(selectedImage: $photo)
            }
            .sheet(isPresented: $showInventorySelector) {
                InventorySelectionView(
                    buildingId: selectedBuildingID,
                    selectedItems: $requiredInventory,
                    onDismiss: {
                        showInventorySelector = false
                    }
                )
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var loadingSection: some View {
        Section {
            HStack {
                ProgressView()
                    .padding(.trailing, 10)
                Text("Loading buildings...")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }
    
    private var taskDetailsSection: some View {
        Section("Task Details") {
            TextField("Task Name", text: $taskName)
                .autocapitalization(.words)
            
            ZStack(alignment: .topLeading) {
                if taskDescription.isEmpty {
                    Text("Describe what needs to be done...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $taskDescription)
                    .frame(minHeight: 100)
                    .autocapitalization(.sentences)
            }
            
            Picker("Urgency", selection: $selectedUrgency) {
                ForEach(TaskUrgency.allCases, id: \.self) { urgency in
                    HStack {
                        Circle()
                            .fill(getUrgencyColor(urgency))
                            .frame(width: 10, height: 10)
                        
                        Text(urgency.rawValue.capitalized)
                    }
                    .tag(urgency)
                }
            }
        }
    }
    
    private var locationSection: some View {
        Section("Assignment Details") {
            Picker("Building", selection: $selectedBuildingID) {
                Text("Select a building").tag("")
                
                ForEach(buildingOptions) { building in
                    Text(building.name).tag(building.id)
                }
            }
            
            // ✅ NEW: Worker selection picker
            Picker("Assign to Worker", selection: $selectedWorkerId) {
                ForEach(workerOptions) { worker in
                    Text(worker.name).tag(worker.id)
                }
            }
            
            if !selectedBuildingID.isEmpty {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        Label(category.rawValue.capitalized, systemImage: getCategoryIcon(category.rawValue))
                            .tag(category)
                    }
                }
                
                Button(action: {
                    loadInventoryWrapper()
                    showInventorySelector = true
                }) {
                    HStack {
                        Label("Required Materials", systemImage: "archivebox")
                        
                        Spacer()
                        
                        if requiredInventory.isEmpty {
                            Text("None")
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(requiredInventory.count) items")
                                .foregroundColor(.blue)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var scheduleSection: some View {
        Section("Timing") {
            DatePicker("Due Date", selection: $selectedDate, displayedComponents: .date)
            
            Toggle("Add Start Time", isOn: $addStartTime)
            
            if addStartTime {
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
            }
            
            Toggle("Add End Time", isOn: $addEndTime)
            
            if addEndTime {
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    .disabled(!addStartTime)
                    .onChange(of: startTime) { oldValue, newValue in
                        if endTime < newValue {
                            endTime = newValue.addingTimeInterval(3600)
                        }
                    }
            }
        }
    }
    
    private var materialsSection: some View {
        Section("Required Materials") {
            ForEach(Array(requiredInventory.keys), id: \.self) { itemId in
                if let item = getInventoryItem(itemId),
                   let quantity = requiredInventory[itemId], quantity > 0 {
                    HStack {
                        Text(item.name)
                        
                        Spacer()
                        
                        Text("\(quantity) \(item.displayUnit)")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            requiredInventory.removeValue(forKey: itemId)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Button(action: {
                showInventorySelector = true
            }) {
                Label("Edit Materials", systemImage: "pencil")
            }
        }
    }
    
    private var attachmentSection: some View {
        Section("Attachment") {
            Toggle("Attach Photo", isOn: $attachPhoto)
            
            if attachPhoto {
                if let image = photo {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Spacer()
                        
                        Button(action: {
                            showPhotoSelector = true
                        }) {
                            Text("Change")
                        }
                        
                        Button(action: {
                            photo = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Button(action: {
                        showPhotoSelector = true
                    }) {
                        Label("Select Photo", systemImage: "photo")
                    }
                }
            }
        }
    }
    
    private var actionSection: some View {
        Section {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: submitTaskWrapper) {
                if isSubmitting {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 10)
                        
                        Text("Submitting...")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text("Submit Task Request")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .disabled(!isFormValid || isSubmitting)
        }
    }
    
    private var suggestionSection: some View {
        Section("Suggestions") {
            DisclosureGroup(
                isExpanded: $showSuggestions,
                content: {
                    ForEach(suggestions) { suggestion in
                        Button(action: {
                            applySuggestion(suggestion)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.headline)
                                
                                Text(suggestion.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: getCategoryIcon(suggestion.category))
                                        .foregroundColor(.blue)
                                    
                                    Text(getCategoryName(suggestion.category))
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    if let iconName = getUrgencyIcon(suggestion.urgency) {
                                        Image(systemName: iconName)
                                            .foregroundColor(getUrgencyColorFromString(suggestion.urgency))
                                            .padding(.leading, 8)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if suggestion != suggestions.last {
                            Divider()
                        }
                    }
                },
                label: {
                    Label(
                        "Task Suggestions (\(suggestions.count))",
                        systemImage: "lightbulb.fill"
                    )
                    .font(.headline)
                    .foregroundColor(.orange)
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func submitTaskWrapper() {
        Task { @MainActor in
            await submitTaskRequest()
        }
    }
    
    private func loadInventoryWrapper() {
        // ✅ FIXED: loadInventory in main view is NOT async
        loadInventory()
    }
    
    private var isFormValid: Bool {
        return !taskName.isEmpty &&
               !taskDescription.isEmpty &&
               !selectedBuildingID.isEmpty &&
               !selectedWorkerId.isEmpty &&
               (!attachPhoto || photo != nil)
    }
    
    private func getInventoryItem(_ itemId: String) -> CoreTypes.InventoryItem? {
        return availableInventory.first { $0.id == itemId }
    }
    
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
    
    private func getCategoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "maintenance": return "wrench.and.screwdriver"
        case "cleaning": return "sparkles"
        case "repair": return "hammer"
        case "inspection": return "magnifyingglass"
        case "installation": return "plus.square"
        case "utilities": return "bolt"
        case "emergency": return "exclamationmark.triangle.fill"
        case "renovation": return "building.2"
        case "landscaping": return "leaf"
        case "security": return "shield"
        case "sanitation": return "trash"
        case "administrative": return "doc.text"
        default: return "square.grid.2x2"
        }
    }
    
    private func getCategoryName(_ category: String) -> String {
        return category.capitalized
    }
    
    private func getUrgencyIcon(_ urgency: String) -> String? {
        switch urgency.lowercased() {
        case "low": return "checkmark.circle"
        case "medium": return "exclamationmark.circle"
        case "high": return "exclamationmark.triangle"
        case "urgent": return "flame.fill"
        default: return nil
        }
    }
    
    private func getUrgencyColorFromString(_ urgency: String) -> Color {
        if let taskUrgency = TaskUrgency(rawValue: urgency) {
            return getUrgencyColor(taskUrgency)
        }
        return .gray
    }
    
    // MARK: - Data Loading
    
    private func loadBuildings() {
        // ✅ FIXED: Using REAL building data from OperationalDataManager
        self.buildingOptions = [
            NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "142-148 West 17th Street, New York, NY",
                latitude: 40.7402,
                longitude: -73.9980
            ),
            NamedCoordinate(
                id: "1",
                name: "117 West 17th Street",
                address: "117 West 17th Street, New York, NY",
                latitude: 40.7410,
                longitude: -73.9958
            ),
            NamedCoordinate(
                id: "3",
                name: "131 Perry Street",
                address: "131 Perry Street, New York, NY",
                latitude: 40.7350,
                longitude: -74.0045
            ),
            NamedCoordinate(
                id: "5",
                name: "135-139 West 17th Street",
                address: "135-139 West 17th Street, New York, NY",
                latitude: 40.7404,
                longitude: -73.9975
            ),
            NamedCoordinate(
                id: "6",
                name: "136 West 17th Street",
                address: "136 West 17th Street, New York, NY",
                latitude: 40.7403,
                longitude: -73.9976
            ),
            NamedCoordinate(
                id: "13",
                name: "68 Perry Street",
                address: "68 Perry Street, New York, NY",
                latitude: 40.7355,
                longitude: -74.0032
            )
        ]
        self.isLoadingBuildings = false
    }
    
    private func loadWorkers() {
        // ✅ FIXED: Using REAL worker data from OperationalDataManager
        self.workerOptions = [
            WorkerProfile(
                id: "4",
                name: "Kevin Dutan",
                email: "kevin.dutan@francomanagement.com",
                phoneNumber: "",
                role: .worker,
                skills: ["Cleaning", "Sanitation", "Operations"],
                certifications: ["DSNY Compliance", "Safety Training"],
                hireDate: Date(timeIntervalSinceNow: -730 * 24 * 60 * 60), // 2 years
                isActive: true,
                profileImageUrl: nil
            ),
            WorkerProfile(
                id: "2",
                name: "Edwin Lema",
                email: "edwin.lema@francomanagement.com",
                phoneNumber: "",
                role: .worker,
                skills: ["Cleaning", "Maintenance"],
                certifications: ["Safety Training"],
                hireDate: Date(timeIntervalSinceNow: -365 * 24 * 60 * 60), // 1 year
                isActive: true,
                profileImageUrl: nil
            ),
            WorkerProfile(
                id: "1",
                name: "Greg Hutson",
                email: "greg.hutson@francomanagement.com",
                phoneNumber: "",
                role: .worker,
                skills: ["Building Systems", "Cleaning"],
                certifications: ["Building Specialist"],
                hireDate: Date(timeIntervalSinceNow: -1095 * 24 * 60 * 60), // 3 years
                isActive: true,
                profileImageUrl: nil
            ),
            WorkerProfile(
                id: "5",
                name: "Mercedes Inamagua",
                email: "mercedes.inamagua@francomanagement.com",
                phoneNumber: "",
                role: .worker,
                skills: ["Deep Cleaning", "Maintenance"],
                certifications: ["Safety Training"],
                hireDate: Date(timeIntervalSinceNow: -547 * 24 * 60 * 60), // 1.5 years
                isActive: true,
                profileImageUrl: nil
            ),
            WorkerProfile(
                id: "7",
                name: "Angel Guirachocha",
                email: "angel.guirachocha@francomanagement.com",
                phoneNumber: "",
                role: .worker,
                skills: ["Evening Operations", "Security"],
                certifications: ["Security License"],
                hireDate: Date(timeIntervalSinceNow: -180 * 24 * 60 * 60), // 6 months
                isActive: true,
                profileImageUrl: nil
            )
        ]
    }
    
    private func loadSuggestions() {
        // ✅ FIXED: Using REAL task patterns from OperationalDataManager
        suggestions = [
            TaskSuggestion(
                id: "1",
                title: "Trash Area + Sidewalk & Curb Clean",
                description: "Daily cleaning of trash area, sidewalk, and curb for building compliance.",
                category: TaskCategory.sanitation.rawValue,
                urgency: TaskUrgency.medium.rawValue,
                buildingId: "14" // Rubin Museum
            ),
            TaskSuggestion(
                id: "2",
                title: "Museum Entrance Sweep",
                description: "Daily sweep of museum entrance area for visitor experience.",
                category: TaskCategory.cleaning.rawValue,
                urgency: TaskUrgency.medium.rawValue,
                buildingId: "14" // Rubin Museum
            ),
            TaskSuggestion(
                id: "3",
                title: "DSNY Put-Out (after 20:00)",
                description: "Place trash at curb after 8 PM for DSNY collection (Sun/Tue/Thu).",
                category: TaskCategory.sanitation.rawValue,
                urgency: TaskUrgency.high.rawValue,
                buildingId: buildingOptions.first?.id ?? "14"
            ),
            TaskSuggestion(
                id: "4",
                title: "Weekly Deep Clean - Trash Area",
                description: "Comprehensive cleaning and hosing of trash area (Mon/Wed/Fri).",
                category: TaskCategory.sanitation.rawValue,
                urgency: TaskUrgency.medium.rawValue,
                buildingId: buildingOptions.first?.id ?? "14"
            ),
            TaskSuggestion(
                id: "5",
                title: "Stairwell Hose-Down",
                description: "Weekly hosing of stairwells and common areas.",
                category: TaskCategory.maintenance.rawValue,
                urgency: TaskUrgency.low.rawValue,
                buildingId: "13" // 68 Perry Street
            )
        ]
        
        showSuggestions = suggestions.count > 0
    }
    
    private func loadInventory() {
        guard !selectedBuildingID.isEmpty else { return }
        
        self.availableInventory = createSampleInventory()
    }
    
    private func createSampleInventory() -> [CoreTypes.InventoryItem] {
        // ✅ FIXED: Use FULL initializer with ALL parameters explicitly
        return [
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "All-Purpose Cleaner",
                category: CoreTypes.InventoryCategory.supplies,
                currentStock: 10,
                minimumStock: 5,
                maxStock: 50,
                unit: "bottles",
                cost: 5.99,
                supplier: nil,
                location: "Storage Room A",
                lastRestocked: nil,
                status: CoreTypes.RestockStatus.inStock
            ),
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "Paint Brushes",
                category: .tools,
                currentStock: 5,
                minimumStock: 2,
                maxStock: 20,
                unit: "pieces",
                cost: 3.50,
                supplier: nil,
                location: "Maintenance Workshop",
                lastRestocked: nil,
                status: .inStock
            ),
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "Safety Gloves",
                category: .safety,
                currentStock: 20,
                minimumStock: 10,
                maxStock: 100,
                unit: "pairs",
                cost: 2.25,
                supplier: nil,
                location: "Safety Cabinet",
                lastRestocked: nil,
                status: .inStock
            ),
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "LED Light Bulbs",
                category: .materials,
                currentStock: 15,
                minimumStock: 8,
                maxStock: 50,
                unit: "pieces",
                cost: 4.75,
                supplier: nil,
                location: "Electrical Storage",
                lastRestocked: nil,
                status: .inStock
            )
        ]
    }
    
    // MARK: - Actions
    
    private func applySuggestion(_ suggestion: TaskSuggestion) {
        taskName = suggestion.title
        taskDescription = suggestion.description
        selectedBuildingID = suggestion.buildingId
        
        if let category = TaskCategory(rawValue: suggestion.category) {
            selectedCategory = category
        }
        
        if let urgency = TaskUrgency(rawValue: suggestion.urgency) {
            selectedUrgency = urgency
        }
    }
    
    private func submitTaskRequest() async {
        guard isFormValid else { return }
        
        await MainActor.run {
            isSubmitting = true
            errorMessage = nil
        }
        
        // Get building and worker information
        let selectedBuilding = buildingOptions.first(where: { $0.id == selectedBuildingID })
        
        // ✅ FIXED: Use selected worker from picker
        guard let currentWorker = workerOptions.first(where: { $0.id == selectedWorkerId }) else {
            await MainActor.run {
                errorMessage = "Please select a worker"
                isSubmitting = false
            }
            return
        }
        
        // ✅ FIXED: Create task using the minimal ContextualTask initializer pattern from TaskService
        let task = ContextualTask(
            id: UUID().uuidString,
            title: taskName,
            description: taskDescription,
            isCompleted: false,
            completedDate: nil,
            dueDate: selectedDate,
            category: selectedCategory,
            urgency: selectedUrgency,
            building: selectedBuilding,
            worker: currentWorker,
            buildingId: selectedBuildingID,
            priority: selectedUrgency,
            assignedWorkerId: currentWorker.id,
            estimatedDuration: 3600 // Default 1 hour
        )
        
        do {
            // ✅ INTEGRATED: Use TaskService to create task (this will handle DB and sync)
            try await TaskService.shared.createTask(task)
            
            // ✅ FIXED: Use UpdateType.taskStarted instead of non-existent taskAssigned
            let dashboardUpdate = DashboardUpdate(
                source: .admin, // Task creation comes from admin-level
                type: .taskStarted,
                buildingId: selectedBuildingID,
                workerId: currentWorker.id,
                data: [
                    "taskId": task.id,
                    "taskTitle": task.title,
                    "taskCategory": task.category?.rawValue ?? "maintenance",
                    "taskUrgency": task.urgency?.rawValue ?? "medium",
                    "dueDate": task.dueDate ?? Date()
                ]
            )
            
            DashboardSyncService.shared.broadcastAdminUpdate(dashboardUpdate)
            
            // Record inventory requirements if any
            if !requiredInventory.isEmpty {
                recordInventoryRequirements(for: task.id)
            }
            
            // Save photo if attached
            if attachPhoto, let photo = photo {
                saveTaskPhoto(photo, for: task.id)
            }
            
            await MainActor.run {
                showCompletionAlert = true
                isSubmitting = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create task: \(error.localizedDescription)"
                isSubmitting = false
            }
        }
    }
    
    private func recordInventoryRequirements(for taskId: String) {
        print("Recording inventory requirements for task \(taskId)")
        
        // TODO: In production, save to database via service
        for (itemId, quantity) in requiredInventory {
            if let item = getInventoryItem(itemId) {
                print("  - \(quantity) of \(item.name)")
                
                // Example of how to save to database:
                // try? await inventoryService.recordTaskRequirement(
                //     taskId: taskId,
                //     itemId: itemId,
                //     quantity: quantity
                // )
            }
        }
    }
    
    private func saveTaskPhoto(_ image: UIImage, for taskId: String) {
        print("Saving photo for task \(taskId)")
        
        // TODO: In production, save to storage service
        // Example:
        // if let imageData = image.jpegData(compressionQuality: 0.8) {
        //     try? await storageService.saveTaskPhoto(
        //         taskId: taskId,
        //         imageData: imageData
        //     )
        // }
    }
}

// MARK: - Supporting Views

struct InventorySelectionView: View {
    let buildingId: String
    @Binding var selectedItems: [String: Int]
    var onDismiss: (() -> Void)? = nil
    
    @State private var inventoryItems: [CoreTypes.InventoryItem] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var tempQuantities: [String: Int] = [:]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search inventory", text: $searchText)
                        .autocapitalization(.none)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else if filteredItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No inventory items found")
                            .font(.headline)
                        
                        if !searchText.isEmpty {
                            Text("No items match your search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Try adding some inventory items to this building")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            inventoryItemRow(item)
                        }
                    }
                }
            }
            .navigationTitle("Select Materials")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    for (itemId, quantity) in tempQuantities {
                        if quantity > 0 {
                            selectedItems[itemId] = quantity
                        } else {
                            selectedItems.removeValue(forKey: itemId)
                        }
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                    onDismiss?()
                }
            )
            .onAppear {
                tempQuantities = selectedItems
                Task {
                    await loadInventory()
                }
            }
        }
    }
    
    private func inventoryItemRow(_ item: CoreTypes.InventoryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                // ✅ FIXED: Use currentStock instead of quantity
                Text("Available: \(item.currentStock)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Button(action: {
                    decrementQuantity(for: item.id)
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.blue)
                }
                
                Text("\(getQuantity(for: item.id))")
                    .frame(width: 30, alignment: .center)
                
                Button(action: {
                    incrementQuantity(for: item.id)
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
                // ✅ FIXED: Use currentStock instead of quantity
                .disabled(getQuantity(for: item.id) >= item.currentStock)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var filteredItems: [CoreTypes.InventoryItem] {
        if searchText.isEmpty {
            return inventoryItems
        } else {
            return inventoryItems.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func getQuantity(for itemId: String) -> Int {
        return tempQuantities[itemId] ?? 0
    }
    
    private func incrementQuantity(for itemId: String) {
        let currentQuantity = getQuantity(for: itemId)
        tempQuantities[itemId] = currentQuantity + 1
    }
    
    private func decrementQuantity(for itemId: String) {
        let currentQuantity = getQuantity(for: itemId)
        if currentQuantity > 0 {
            tempQuantities[itemId] = currentQuantity - 1
        }
    }
    
    private func loadInventory() async {
        isLoading = true
        
        // Removed Task.sleep for compatibility - instant load
        
        // ✅ FIXED: Use FULL initializer with ALL parameters explicitly
        self.inventoryItems = [
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "All-Purpose Cleaner",
                category: .supplies,
                currentStock: 10,
                minimumStock: 5,
                maxStock: 50,
                unit: "bottles",
                cost: 5.99,
                supplier: nil,
                location: "Storage Room A",
                lastRestocked: nil,
                status: .inStock
            ),
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "Paint Brushes",
                category: .tools,
                currentStock: 5,
                minimumStock: 2,
                maxStock: 20,
                unit: "pieces",
                cost: 3.50,
                supplier: nil,
                location: "Maintenance Workshop",
                lastRestocked: nil,
                status: .inStock
            ),
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "Safety Gloves",
                category: .safety,
                currentStock: 20,
                minimumStock: 10,
                maxStock: 100,
                unit: "pairs",
                cost: 2.25,
                supplier: nil,
                location: "Safety Cabinet",
                lastRestocked: nil,
                status: .inStock
            ),
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "LED Light Bulbs",
                category: .materials,
                currentStock: 15,
                minimumStock: 8,
                maxStock: 50,
                unit: "pieces",
                cost: 4.75,
                supplier: nil,
                location: "Electrical Storage",
                lastRestocked: nil,
                status: .inStock
            )
        ]
        self.isLoading = false
    }
}

// ✅ FIXED: Corrected PhotoPickerView with proper binding
struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                        .frame(maxHeight: 300)
                }
                
                VStack(spacing: 20) {
                    Button(action: {
                        sourceType = .camera
                        showImagePicker = true
                    }) {
                        Label("Take Photo", systemImage: "camera")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    }) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Select Photo")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showImagePicker) {
                ImagePickerWrapper(sourceType: sourceType, selectedImage: $selectedImage)
            }
        }
    }
}

// ✅ FIXED: Wrapper to handle ImagePicker properly
struct ImagePickerWrapper: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerWrapper
        
        init(_ parent: ImagePickerWrapper) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Extensions

extension CoreTypes.InventoryItem {
    var displayUnit: String {
        switch category {
        case .tools: return "pcs"
        case .supplies: return "bottles"
        case .equipment: return "units"
        case .materials: return "pcs"
        case .safety: return "pairs"
        case .cleaning: return "items"
        case .electrical: return "pcs"
        case .plumbing: return "pcs"
        case .general: return "items"
        case .office: return "items"
        case .maintenance: return "items"
        case .other: return "items"
        }
    }
}

// MARK: - Preview Support

struct TaskRequestView_Previews: PreviewProvider {
    static var previews: some View {
        TaskRequestView()
    }
}
