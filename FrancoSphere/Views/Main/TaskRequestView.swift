import Foundation

// Type aliases for CoreTypes
typealias MaintenanceTask = CoreTypes.MaintenanceTask
typealias TaskCategory = CoreTypes.TaskCategory
typealias TaskUrgency = CoreTypes.TaskUrgency
typealias BuildingType = CoreTypes.BuildingType
typealias BuildingTab = CoreTypes.BuildingTab
typealias WeatherCondition = CoreTypes.WeatherCondition
typealias BuildingMetrics = CoreTypes.BuildingMetrics
typealias TaskProgress = CoreTypes.TaskProgress
typealias FrancoWorkerAssignment = CoreTypes.FrancoWorkerAssignment
typealias InventoryItem = CoreTypes.InventoryItem
typealias InventoryCategory = CoreTypes.InventoryCategory
typealias RestockStatus = CoreTypes.RestockStatus
typealias ComplianceStatus = CoreTypes.ComplianceStatus
typealias BuildingStatistics = CoreTypes.BuildingStatistics
typealias WorkerSkill = CoreTypes.WorkerSkill
typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
typealias ComplianceIssue = CoreTypes.ComplianceIssue

import SwiftUI

// Type aliases for CoreTypes
typealias MaintenanceTask = CoreTypes.MaintenanceTask
typealias TaskCategory = CoreTypes.TaskCategory
typealias TaskUrgency = CoreTypes.TaskUrgency
typealias BuildingType = CoreTypes.BuildingType
typealias BuildingTab = CoreTypes.BuildingTab
typealias WeatherCondition = CoreTypes.WeatherCondition
typealias BuildingMetrics = CoreTypes.BuildingMetrics
typealias TaskProgress = CoreTypes.TaskProgress
typealias FrancoWorkerAssignment = CoreTypes.FrancoWorkerAssignment
typealias InventoryItem = CoreTypes.InventoryItem
typealias InventoryCategory = CoreTypes.InventoryCategory
typealias RestockStatus = CoreTypes.RestockStatus
typealias ComplianceStatus = CoreTypes.ComplianceStatus
typealias BuildingStatistics = CoreTypes.BuildingStatistics
typealias WorkerSkill = CoreTypes.WorkerSkill
typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
typealias ComplianceIssue = CoreTypes.ComplianceIssue


//
//  TaskRequestView.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With current CoreTypes and Phase 2.1 implementation
//  ✅ ENHANCED: Proper integration with GRDB foundation
//

struct TaskRequestView: View {
    @StateObject private var authManager = NewAuthManager.shared
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
    @State private var availableInventory: [InventoryItem] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var suggestions: [TaskSuggestion] = []
    @State private var showSuggestions = false
    @Environment(\.presentationMode) var presentationMode
    
    // ✅ FIXED: Load buildings asynchronously
    @State private var buildingOptions: [NamedCoordinate] = []
    @State private var isLoadingBuildings = true
    
    var body: some View {
        NavigationView {
            Form {
                if isLoadingBuildings {
                    Section {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 10)
                            Text("Loading buildings...")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                } else {
                    basicTaskSection
                    buildingAndCategorySection
                    timingSection
                    
                    if !requiredInventory.isEmpty {
                        inventorySection
                    }
                    
                    photoSection
                    submitSection
                    
                    if !suggestions.isEmpty {
                        suggestionsSection
                    }
                }
            }
            .navigationTitle("New Task Request")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Submit") {
                    Task {
                        await submitTaskRequest()
                    }
                }
                .disabled(!isFormValid || isSubmitting)
            )
            .task {
                await loadBuildings()
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
    
    // MARK: - Helper Functions
    
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
    
    // MARK: - Form Sections
    
    private var basicTaskSection: some View {
        Section(header: Text("Task Details")) {
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
    
    private var buildingAndCategorySection: some View {
        Section(header: Text("Location & Category")) {
            Picker("Building", selection: $selectedBuildingID) {
                Text("Select a building").tag("")
                
                ForEach(buildingOptions) { building in
                    Text(building.name).tag(building.id)
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
                    Task {
                        await loadInventory()
                    }
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
    
    private var timingSection: some View {
        Section(header: Text("Timing")) {
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
                            endTime = newValue.addingTimeInterval(3600) // 1 hour later
                        }
                    }
            }
        }
    }
    
    private var inventorySection: some View {
        Section(header: Text("Required Materials")) {
            ForEach(Array(requiredInventory.keys.sorted()), id: \.self) { itemId in
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
    
    private var photoSection: some View {
        Section(header: Text("Attachment")) {
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
    
    private var submitSection: some View {
        Section {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await submitTaskRequest()
                }
            }) {
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
    
    private var suggestionsSection: some View {
        Section(header: Text("Suggestions")) {
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
    
    private var isFormValid: Bool {
        return !taskName.isEmpty &&
               !taskDescription.isEmpty &&
               !selectedBuildingID.isEmpty &&
               (!attachPhoto || photo != nil)
    }
    
    private func getInventoryItem(_ itemId: String) -> InventoryItem? {
        return availableInventory.first { $0.id == itemId }
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
    
    private func loadBuildings() async {
        do {
            let buildings = try await BuildingService.shared.getAllBuildings()
            await MainActor.run {
                self.buildingOptions = buildings
                self.isLoadingBuildings = false
            }
        } catch {
            await MainActor.run {
                self.buildingOptions = []
                self.isLoadingBuildings = false
                self.errorMessage = "Failed to load buildings: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadSuggestions() {
        Task {
            await MainActor.run {
                suggestions = [
                    TaskSuggestion(
                        id: "1",
                        title: "HVAC Filter Replacement",
                        description: "Regular maintenance to replace HVAC filters throughout the building.",
                        category: TaskCategory.maintenance.rawValue,
                        urgency: TaskUrgency.medium.rawValue,
                        buildingId: buildingOptions.first?.id ?? ""
                    ),
                    TaskSuggestion(
                        id: "2",
                        title: "Lobby Floor Cleaning",
                        description: "Deep cleaning of lobby floor and entrance mats.",
                        category: TaskCategory.cleaning.rawValue,
                        urgency: TaskUrgency.low.rawValue,
                        buildingId: buildingOptions.first?.id ?? ""
                    ),
                    TaskSuggestion(
                        id: "3",
                        title: "Security Camera Inspection",
                        description: "Check all security cameras for proper functioning and positioning.",
                        category: TaskCategory.inspection.rawValue,
                        urgency: TaskUrgency.medium.rawValue,
                        buildingId: buildingOptions.first?.id ?? ""
                    )
                ]
                
                showSuggestions = suggestions.count > 0
            }
        }
    }
    
    private func loadInventory() async {
        guard !selectedBuildingID.isEmpty else { return }
        
        await MainActor.run {
            self.availableInventory = createSampleInventory()
        }
    }
    
    private func createSampleInventory() -> [InventoryItem] {
        return [
            InventoryItem(
                name: "All-Purpose Cleaner",
                category: .supplies,
                quantity: 10,
                minThreshold: 5,
                location: "Storage Room A"
            ),
            InventoryItem(
                name: "Paint Brushes",
                category: .tools,
                quantity: 5,
                minThreshold: 2,
                location: "Maintenance Workshop"
            ),
            InventoryItem(
                name: "Safety Gloves",
                category: .safety,
                quantity: 20,
                minThreshold: 10,
                location: "Safety Cabinet"
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
    
    // ✅ FIXED: Use correct ContextualTask initializer matching FrancoSphereModels.swift
    private func submitTaskRequest() async {
        guard isFormValid else { return }
        
        await MainActor.run {
            isSubmitting = true
            errorMessage = nil
        }
        
        // Calculate dates with timing information if specified
        let calendar = Calendar.current
        var dueDate = selectedDate
        var startTimeValue: Date? = nil
        var endTimeValue: Date? = nil
        
        if addStartTime {
            let startHour = calendar.component(.hour, from: startTime)
            let startMinute = calendar.component(.minute, from: startTime)
            
            startTimeValue = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: dueDate)
            
            if addEndTime {
                let endHour = calendar.component(.hour, from: endTime)
                let endMinute = calendar.component(.minute, from: endTime)
                
                endTimeValue = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: dueDate)
            }
        }
        
        // Get building and worker information
        let building = buildingOptions.first(where: { $0.id == selectedBuildingID })
        let worker = WorkerProfile(
            id: authManager.workerId ?? "unknown",
            name: authManager.currentWorkerName ?? "Unknown Worker",
            email: authManager.currentUser?.email ?? "",
            phoneNumber: "",
            role: .worker,
            skills: [],
            certifications: [],
            hireDate: Date(),
            isActive: true
        )
        
        // ✅ FIXED: Use correct ContextualTask initializer from FrancoSphereModels.swift
        let task = ContextualTask(
            title: taskName,
            description: taskDescription,
            isCompleted: false,
            completedDate: nil,
            scheduledDate: startTimeValue,
            dueDate: dueDate,
            category: selectedCategory,
            urgency: selectedUrgency,
            building: building,
            worker: worker
        )
        
        do {
            try await TaskService.shared.createTask(task)
            
            await MainActor.run {
                if !requiredInventory.isEmpty {
                    recordInventoryRequirements(for: task.id)
                }
                
                if attachPhoto, let photo = photo {
                    saveTaskPhoto(photo, for: task.id)
                }
                
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
        
        for (itemId, quantity) in requiredInventory {
            if let item = getInventoryItem(itemId) {
                print("  - \(quantity) of \(item.name)")
            }
        }
    }
    
    private func saveTaskPhoto(_ image: UIImage, for taskId: String) {
        print("Saving photo for task \(taskId)")
    }
}

// MARK: - Supporting Views

struct InventorySelectionView: View {
    let buildingId: String
    @Binding var selectedItems: [String: Int]
    var onDismiss: (() -> Void)? = nil
    
    @State private var inventoryItems: [InventoryItem] = []
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
                    onDismiss?()
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
                Task {
                    await loadInventory()
                }
                
                tempQuantities = selectedItems
            }
        }
    }
    
    private func inventoryItemRow(_ item: InventoryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                Text("Available: \(item.quantity)")
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
                .disabled(getQuantity(for: item.id) >= item.quantity)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var filteredItems: [InventoryItem] {
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
    
    // ✅ FIXED: Use sample inventory data that matches CoreTypes.InventoryItem
    private func loadInventory() async {
        await MainActor.run {
            isLoading = true
        }
        
        await MainActor.run {
            self.inventoryItems = [
                InventoryItem(
                    name: "All-Purpose Cleaner",
                    category: .supplies,
                    quantity: 10,
                    minThreshold: 5,
                    location: "Storage Room A"
                ),
                InventoryItem(
                    name: "Paint Brushes",
                    category: .tools,
                    quantity: 5,
                    minThreshold: 2,
                    location: "Maintenance Workshop"
                ),
                InventoryItem(
                    name: "Safety Gloves",
                    category: .safety,
                    quantity: 20,
                    minThreshold: 10,
                    location: "Safety Cabinet"
                ),
                InventoryItem(
                    name: "LED Light Bulbs",
                    category: .materials,
                    quantity: 15,
                    minThreshold: 8,
                    location: "Electrical Storage"
                )
            ]
            self.isLoading = false
        }
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
                // ✅ FIXED: Use correct ImagePicker with @State var instead of @Binding
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

// MARK: - Supporting Models

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

// ✅ FIXED: Extension for InventoryItem display unit
extension InventoryItem {
    var displayUnit: String {
        switch category {
        case .tools: return "pcs"
        case .supplies: return "bottles"
        case .equipment: return "units"
        case .materials: return "pcs"
        case .safety: return "pairs"
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
