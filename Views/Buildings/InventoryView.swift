// InventoryView.swift
// FrancoSphere
// Created by Shawn Magloire on 3/3/25.
// ✅ FIXED: Updated to use BuildingService instead of InventoryManager
// ✅ REMOVED: References to eliminated InventoryManager
// ✅ FIXED: Removed duplicate property declarations
// ✅ PRESERVED: All inventory functionality with new service architecture

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


extension InventoryItem {
    var statusColor: Color {
        if quantity <= 0 {
            return .red
        } else if quantity <= minimumQuantity {
            return .orange
        } else {
            return .green
        }
    }
}

/// Displays and manages inventory for a selected building.
struct InventoryView: View {
    @State private var inventoryItems: [InventoryItem] = []
    @State private var selectedCategory: InventoryCategory? = nil
    @State private var searchText: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showAddItemSheet = false
    
    let buildingID: String
    
    var filteredItems: [InventoryItem] {
        let filtered = inventoryItems.filter { item in
            (selectedCategory == nil || item.category == selectedCategory) &&
            (searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText))
        }
        return filtered.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Search and filter controls
                VStack(spacing: 8) {
                    TextField("Search Inventory", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryButton(nil, label: "All")
                            
                            ForEach(InventoryCategory.allCases, id: \.self) { category in
                                categoryButton(category, label: category.rawValue.capitalized)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.top, 12)
                .background(Color(.systemBackground))
                
                // Inventory list
                if let error = errorMessage {
                    errorView(message: error)
                } else if isLoading {
                    loadingView
                } else if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    inventoryListView
                }
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAddItemSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Building Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    loadInventory()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            loadInventory()
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddInventoryItemView(buildingID: buildingID) { success in
                showAddItemSheet = false
                if success {
                    loadInventory()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading inventory...")
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "archivebox")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            if searchText.isEmpty && selectedCategory == nil {
                Text("No Inventory Items")
                    .font(.headline)
                
                Text("This building doesn't have any inventory items yet.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showAddItemSheet = true
                }) {
                    Text("Add Item")
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            } else {
                Text("No matching items")
                    .font(.headline)
                
                Text("Try adjusting your search or filters")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    searchText = ""
                    selectedCategory = nil
                }) {
                    Text("Clear Filters")
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var inventoryListView: some View {
        List {
            ForEach(filteredItems) { item in
                NavigationLink(destination: InventoryItemDetailView(item: item, onUpdate: {
                    loadInventory() // Refresh when item is updated
                })) {
                    InventoryItemRow(item: item)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        deleteItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Inventory Database Error")
                .font(.headline)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            Button(action: {
                loadInventory()
            }) {
                Text("Retry")
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    private func categoryButton(_ category: InventoryCategory?, label: String) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.systemImage)
                        .font(.caption)
                } else {
                    Image(systemName: "tag")
                        .font(.caption)
                }
                
                Text(label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
            .foregroundColor(selectedCategory == category ? .white : .primary)
            .cornerRadius(20)
        }
    }
    
    // MARK: - Data methods
    
    private func loadInventory() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let items = try await BuildingService.shared.getInventoryItems(for: buildingID)
                inventoryItems = items
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to load inventory: \(error.localizedDescription)"
            }
        }
    }
    
    private func deleteItem(_ item: InventoryItem) {
        Task { @MainActor in
            do {
                try await BuildingService.shared.deleteInventoryItem(itemId: item.id)
                if let index = inventoryItems.firstIndex(where: { $0.id == item.id }) {
                    inventoryItems.remove(at: index)
                }
            } catch {
                errorMessage = "Failed to delete item: \(error.localizedDescription)"
            }
        }
    }
}

/// Represents a row in the inventory list.
struct InventoryItemRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(item.statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.category.systemImage)
                    .foregroundColor(item.statusColor)
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text("Quantity: \(item.quantity) \(item.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // ✅ FIXED: Use item properties that exist in InventoryItem
                    if item.needsReorder {
                        Text(item.quantity <= 0 ? "Out of Stock" : "Low Stock")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(item.statusColor.opacity(0.2))
                            .foregroundColor(item.statusColor)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Quantity indicator
            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 2) {
                    Text("\(item.quantity)")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(item.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Min: \(item.minimumQuantity)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70, alignment: .center)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View

struct InventoryItemDetailView: View {
    let item: InventoryItem
    let onUpdate: () -> Void
    @State private var newQuantity: Int
    @State private var isEditing = false
    @State private var showUpdateSuccess = false
    @State private var isUpdating = false
    @Environment(\.presentationMode) var presentationMode
    
    init(item: InventoryItem, onUpdate: @escaping () -> Void = {}) {
        self.item = item
        self.onUpdate = onUpdate
        _newQuantity = State(initialValue: item.quantity)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Item Details")) {
                LabeledContent("Name", value: item.name)
                
                if isEditing {
                    Stepper("Quantity: \(newQuantity) \(item.unit)", value: $newQuantity, in: 0...1000)
                } else {
                    LabeledContent("Quantity", value: "\(item.quantity) \(item.unit)")
                }
                
                LabeledContent("Min Quantity", value: "\(item.minimumQuantity) \(item.unit)")
                LabeledContent("Category", value: item.category.rawValue.capitalized)
                
                // Format the date appropriately
                if let formattedDate = formattedDate(item.lastRestockDate) {
                    LabeledContent("Last Updated", value: formattedDate)
                }
                
                // ✅ FIXED: Use correct property name
                if item.needsReorder {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(item.statusColor)
                        Text("Restock Needed")
                            .foregroundColor(item.statusColor)
                    }
                }
            }
            
            if isEditing {
                Section {
                    Button("Save Changes") {
                        saveQuantityChange()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                    .disabled(isUpdating)
                    
                    Button("Cancel") {
                        newQuantity = item.quantity
                        isEditing = false
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                    .disabled(isUpdating)
                }
            }
        }
        .navigationTitle(item.name)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .overlay {
            if showUpdateSuccess {
                VStack {
                    Spacer()
                    Text("Quantity updated successfully")
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showUpdateSuccess = false
                                }
                            }
                        }
                }
                .animation(.easeInOut, value: showUpdateSuccess)
            }
        }
    }
    
    private func saveQuantityChange() {
        isUpdating = true
        
        Task { @MainActor in
            do {
                try await BuildingService.shared.updateInventoryItemQuantity(
                    itemId: item.id,
                    newQuantity: newQuantity,
                    workerId: "system"
                )
                
                isEditing = false
                onUpdate()
                withAnimation {
                    showUpdateSuccess = true
                }
                isUpdating = false
            } catch {
                isUpdating = false
                print("Failed to update quantity: \(error)")
            }
        }
    }
    
    // Updated to handle Date instead of String
    private func formattedDate(_ date: Date) -> String? {
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .short
        return outputFormatter.string(from: date)
    }
}

// MARK: - Add Item View

public struct AddInventoryItemView: View {
    public let buildingID: String
    public let onComplete: (Bool) -> Void
    
    @State private var itemName = ""
    @State private var quantity = 1
    @State private var unit = "pcs"
    @State private var minimumQuantity = 1
    @State private var selectedCategory: InventoryCategory = .other
    @State private var location = ""
    @State private var notes = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSubmitting = false
    
    private var unitOptions = ["pcs", "bottles", "rolls", "boxes", "gallons", "liters", "feet", "inches", "lbs", "kg", "units"]
    
    // Explicit public initializer
    public init(buildingID: String, onComplete: @escaping (Bool) -> Void) {
        self.buildingID = buildingID
        self.onComplete = onComplete
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $itemName)
                        .autocapitalization(.words)
                    
                    Stepper("Quantity: \(quantity) \(unit)", value: $quantity, in: 1...1000)
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(unitOptions, id: \.self) { unitOption in
                            Text(unitOption).tag(unitOption)
                        }
                    }
                    
                    Stepper("Minimum Quantity: \(minimumQuantity)", value: $minimumQuantity, in: 1...100)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(InventoryCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.systemImage)
                                Text(category.rawValue.capitalized)
                            }.tag(category)
                        }
                    }
                    
                    TextField("Location (optional)", text: $location)
                        .autocapitalization(.words)
                    
                    TextField("Notes (optional)", text: $notes)
                        .autocapitalization(.sentences)
                }
                
                Section {
                    Button("Add Item") {
                        addItem()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                    .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                    
                    if isSubmitting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Adding item...")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Add Inventory Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete(false)
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func addItem() {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            errorMessage = "Please enter an item name"
            showError = true
            return
        }
        
        isSubmitting = true
        
        let newItem = InventoryItem(
            name: trimmedName,
            buildingID: buildingID,
            category: selectedCategory,
            quantity: quantity,
            unit: unit,
            minimumQuantity: minimumQuantity,
            needsReorder: quantity <= minimumQuantity,
            lastRestockDate: Date(),
            location: location.isEmpty ? "Unknown" : location,
            notes: notes.isEmpty ? nil : notes
        )
        
        Task { @MainActor in
            do {
                try await BuildingService.shared.saveInventoryItem(newItem)
                isSubmitting = false
                onComplete(true)
            } catch {
                isSubmitting = false
                errorMessage = "Failed to add inventory item. Please try again."
                showError = true
            }
        }
    }
}

// ✅ REMOVED: Duplicate property declarations for shouldReorder and statusText
// These properties are already defined in the InventoryItem type
