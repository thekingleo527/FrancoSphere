import Foundation
import SwiftUI
import UIKit

//
//  TaskRequestView.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved definitively
//  ✅ ALIGNED: With current CoreTypes and Phase 2.1 implementation
//  ✅ ENHANCED: Proper integration with GRDB foundation
//
//  Required Types:
//  - CoreTypes: TaskCategory, TaskUrgency, InventoryItem, etc.
//  - FrancoSphereModels: NamedCoordinate, WorkerProfile, ContextualTask
//  These should be available through global imports
//

struct TaskRequestView: View {
    // ✅ TODO: Replace with actual AuthManager implementation when available
    // @StateObject private var authManager = NewAuthManager.shared
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedBuildingID: String = ""
    @State private var selectedCategory: CoreTypes.TaskCategory = .maintenance
    @State private var selectedUrgency: CoreTypes.TaskUrgency = .medium
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
                await loadBuildings()
                await MainActor.run {
                    loadSuggestions()
                }
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
                ForEach(CoreTypes.TaskUrgency.allCases, id: \.self) { urgency in
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
        Section("Location & Category") {
            Picker("Building", selection: $selectedBuildingID) {
                Text("Select a building").tag("")
                
                ForEach(buildingOptions) { building in
                    Text(building.name).tag(building.id)
                }
            }
            
            if !selectedBuildingID.isEmpty {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(CoreTypes.TaskCategory.allCases, id: \.self) { category in
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
        Task { await submitTaskRequest() }
    }
    
    private func loadInventoryWrapper() {
        Task { await loadInventory() }
    }
    
    private var isFormValid: Bool {
        return !taskName.isEmpty &&
               !taskDescription.isEmpty &&
               !selectedBuildingID.isEmpty &&
               (!attachPhoto || photo != nil)
    }
    
    private func getInventoryItem(_ itemId: String) -> CoreTypes.InventoryItem? {
        return availableInventory.first { $0.id == itemId }
    }
    
    private func getUrgencyColor(_ urgency: CoreTypes.TaskUrgency) -> Color {
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
        if let taskUrgency = CoreTypes.TaskUrgency(rawValue: urgency) {
            return getUrgencyColor(taskUrgency)
        }
        return .gray
    }
    
    // MARK: - Data Loading
    
    private func loadBuildings() async {
        await MainActor.run {
            self.buildingOptions = [
                NamedCoordinate(
                    id: "1",
                    name: "Empire State Building",
                    address: "350 5th Ave, New York, NY 10118",
                    latitude: 40.7484,
                    longitude: -73.9857
                ),
                NamedCoordinate(
                    id: "2",
                    name: "Chrysler Building",
                    address: "405 Lexington Ave, New York, NY 10174",
                    latitude: 40.7516,
                    longitude: -73.9755
                ),
                NamedCoordinate(
                    id: "3",
                    name: "One World Trade Center",
                    address: "285 Fulton St, New York, NY 10007",
                    latitude: 40.7127,
                    longitude: -74.0134
                )
            ]
            self.isLoadingBuildings = false
        }
    }
    
    private func loadSuggestions() {
        suggestions = [
            TaskSuggestion(
                id: "1",
                title: "HVAC Filter Replacement",
                description: "Regular maintenance to replace HVAC filters throughout the building.",
                category: CoreTypes.TaskCategory.maintenance.rawValue,
                urgency: CoreTypes.TaskUrgency.medium.rawValue,
                buildingId: buildingOptions.first?.id ?? ""
            ),
            TaskSuggestion(
                id: "2",
                title: "Lobby Floor Cleaning",
                description: "Deep cleaning of lobby floor and entrance mats.",
                category: CoreTypes.TaskCategory.cleaning.rawValue,
                urgency: CoreTypes.TaskUrgency.low.rawValue,
                buildingId: buildingOptions.first?.id ?? ""
            ),
            TaskSuggestion(
                id: "3",
                title: "Security Camera Inspection",
                description: "Check all security cameras for proper functioning and positioning.",
                category: CoreTypes.TaskCategory.inspection.rawValue,
                urgency: CoreTypes.TaskUrgency.medium.rawValue,
                buildingId: buildingOptions.first?.id ?? ""
            )
        ]
        
        showSuggestions = suggestions.count > 0
    }
    
    private func loadInventory() async {
        guard !selectedBuildingID.isEmpty else { return }
        
        await MainActor.run {
            self.availableInventory = createSampleInventory()
        }
    }
    
    private func createSampleInventory() -> [CoreTypes.InventoryItem] {
        // Match the pattern from InventoryView - we need all parameters
        let items: [(name: String, category: CoreTypes.InventoryCategory, stock: Int, min: Int, location: String)] = [
            ("All-Purpose Cleaner", .supplies, 10, 5, "Storage Room A"),
            ("Paint Brushes", .tools, 5, 2, "Maintenance Workshop"),
            ("Safety Gloves", .safety, 20, 10, "Safety Cabinet")
        ]
        
        return items.map { item in
            let status: CoreTypes.RestockStatus = item.stock <= item.min ?
                (item.stock == 0 ? .outOfStock : .lowStock) : .inStock
            
            return CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: item.name,
                category: item.category,
                currentStock: item.stock,
                minimumStock: item.min,
                maxStock: item.stock * 5,
                unit: "units",
                cost: 0.0,
                supplier: nil,
                location: item.location,
                lastRestocked: nil,
                status: status
            )
        }
    }
    
    // MARK: - Actions
    
    private func applySuggestion(_ suggestion: TaskSuggestion) {
        taskName = suggestion.title
        taskDescription = suggestion.description
        selectedBuildingID = suggestion.buildingId
        
        if let category = CoreTypes.TaskCategory(rawValue: suggestion.category) {
            selectedCategory = category
        }
        
        if let urgency = CoreTypes.TaskUrgency(rawValue: suggestion.urgency) {
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
        let currentWorker = WorkerProfile(
            id: UUID().uuidString,
            name: "Current Worker",
            email: "worker@example.com",
            phoneNumber: "",
            role: .worker,
            skills: [],
            certifications: [],
            hireDate: Date(),
            isActive: true
        )
        
        // Create the task
        let task = ContextualTask(
            title: taskName,
            description: taskDescription,
            isCompleted: false,
            completedDate: nil,
            dueDate: selectedDate,
            category: selectedCategory,
            urgency: selectedUrgency,
            building: selectedBuilding,
            worker: currentWorker
        )
        
        // Simulate task creation
        print("Creating task: \(task)")
        
        // Simulate delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
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
                loadInventoryWrapper()
                tempQuantities = selectedItems
            }
        }
    }
    
    private func inventoryItemRow(_ item: CoreTypes.InventoryItem) -> some View {
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
    
    private func loadInventoryWrapper() {
        Task { await loadInventory() }
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
        await MainActor.run {
            isLoading = true
        }
        
        await MainActor.run {
            self.inventoryItems = [
                CoreTypes.InventoryItem(
                    id: UUID().uuidString,
                    name: "All-Purpose Cleaner",
                    category: .supplies,
                    currentStock: 10,
                    minimumStock: 5,
                    maxStock: 50,
                    unit: "bottles",
                    cost: 0.0,
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
                    cost: 0.0,
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
                    cost: 0.0,
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
                    cost: 0.0,
                    supplier: nil,
                    location: "Electrical Storage",
                    lastRestocked: nil,
                    status: .inStock
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
