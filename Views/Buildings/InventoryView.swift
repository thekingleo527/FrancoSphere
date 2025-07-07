//
//  InventoryView.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: All compilation errors resolved.
//  ✅ FIXED: Uses the correct `InventoryItem` initializer and properties.
//  ✅ FIXED: Integrates with `BuildingService` for data fetching.
//  ✅ PRESERVED: All UI and functionality.
//

import SwiftUI

/// Displays and manages inventory for a selected building.
struct InventoryView: View {
    let buildingID: CoreTypes.BuildingID
    
    @StateObject private var viewModel: InventoryViewModel
    
    init(buildingID: CoreTypes.BuildingID) {
        self.buildingID = buildingID
        self._viewModel = StateObject(wrappedValue: InventoryViewModel(buildingID: buildingID))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                searchFilterBar
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredItems.isEmpty {
                    emptyStateView
                } else {
                    inventoryListView
                }
            }
            
            floatingActionButton
        }
        .navigationTitle("Building Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task { await viewModel.loadInventory() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await viewModel.loadInventory()
        }
        .sheet(isPresented: $viewModel.showAddItemSheet) {
            AddInventoryItemView(buildingID: buildingID) { success in
                viewModel.showAddItemSheet = false
                if success {
                    Task { await viewModel.loadInventory() }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchFilterBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search Inventory", text: $viewModel.searchText)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 12)
            
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
        .background(Color(.systemBackground))
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading inventory...")
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "archivebox").font(.system(size: 50)).foregroundColor(.gray)
            Text(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil ? "No Inventory Items" : "No matching items")
                .font(.headline)
            Text(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil ? "This building has no inventory items yet." : "Try adjusting your search or filters.")
                .multilineTextAlignment(.center).foregroundColor(.secondary)
            Button(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil ? "Add Item" : "Clear Filters") {
                if viewModel.searchText.isEmpty && viewModel.selectedCategory == nil {
                    viewModel.showAddItemSheet = true
                } else {
                    viewModel.clearFilters()
                }
            }
            .buttonStyle(.borderedProminent).padding(.top, 8)
            Spacer()
        }
        .padding()
    }
    
    private var inventoryListView: some View {
        List {
            ForEach(viewModel.filteredItems) { item in
                NavigationLink(destination: InventoryItemDetailView(item: item, onUpdate: {
                    Task { await viewModel.loadInventory() }
                })) {
                    InventoryItemRow(item: item)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteItem(item) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { viewModel.showAddItemSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 3)
                }
                .padding([.trailing, .bottom], 20)
            }
        }
    }
    
    private func categoryButton(_ category: InventoryCategory?, label: String) -> some View {
        Button(action: {
            withAnimation { viewModel.selectedCategory = category }
        }) {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.icon).font(.caption)
                } else {
                    Image(systemName: "tag").font(.caption)
                }
                Text(label).font(.subheadline)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(viewModel.selectedCategory == category ? Color.blue : Color(.systemGray5))
            .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - ViewModel for InventoryView

@MainActor
class InventoryViewModel: ObservableObject {
    @Published var inventoryItems: [InventoryItem] = []
    @Published var selectedCategory: InventoryCategory? = nil
    @Published var searchText: String = ""
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var showAddItemSheet = false
    
    let buildingID: CoreTypes.BuildingID
    private let buildingService = BuildingService.shared
    
    init(buildingID: CoreTypes.BuildingID) {
        self.buildingID = buildingID
    }
    
    var filteredItems: [InventoryItem] {
        inventoryItems.filter { item in
            (selectedCategory == nil || item.category == selectedCategory) &&
            (searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText))
        }.sorted { $0.name < $1.name }
    }
    
    func loadInventory() async {
        isLoading = true
        errorMessage = nil
        do {
            inventoryItems = try await buildingService.getInventoryItems(for: buildingID)
        } catch {
            errorMessage = "Failed to load inventory: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func deleteItem(_ item: InventoryItem) async {
        do {
            try await buildingService.deleteInventoryItem(itemId: item.id)
            inventoryItems.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
    }
}


// MARK: - Inventory Item Row

struct InventoryItemRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: item.category.icon)
                    .foregroundColor(item.statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline)
                HStack(spacing: 8) {
                    Text("Qty: \(item.currentStock) \(item.unit)")
                        .font(.subheadline).foregroundColor(.secondary)
                    if item.needsReorder {
                        Text(item.currentStock <= 0 ? "Out of Stock" : "Low Stock")
                            .font(.caption).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(item.statusColor.opacity(0.2))
                            .foregroundColor(item.statusColor)
                            .cornerRadius(4)
                    }
                }
            }
            Spacer()
            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 2) {
                    Text("\(item.currentStock)").font(.title3).fontWeight(.bold)
                    Text(item.unit).font(.caption).foregroundColor(.secondary)
                }
                Text("Min: \(item.minimumStock)").font(.caption2).foregroundColor(.secondary)
            }.frame(width: 70, alignment: .center)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Inventory Item Detail View

struct InventoryItemDetailView: View {
    @State var item: InventoryItem // Use @State to allow modification
    let onUpdate: () -> Void
    
    @State private var newQuantity: Int
    @State private var isEditing = false
    @State private var isUpdating = false
    @State private var showUpdateSuccess = false
    
    private let buildingService = BuildingService.shared
    
    init(item: InventoryItem, onUpdate: @escaping () -> Void = {}) {
        self._item = State(initialValue: item)
        self.onUpdate = onUpdate
        self._newQuantity = State(initialValue: item.currentStock)
    }
    
    var body: some View {
        Form {
            Section("Item Details") {
                LabeledContent("Name", value: item.name)
                if isEditing {
                    Stepper("Quantity: \(newQuantity) \(item.unit)", value: $newQuantity, in: 0...1000)
                } else {
                    LabeledContent("Quantity", value: "\(item.currentStock) \(item.unit)")
                }
                LabeledContent("Min Quantity", value: "\(item.minimumStock) \(item.unit)")
                LabeledContent("Category", value: item.category.rawValue.capitalized)
                if let lastRestocked = item.lastRestocked {
                    LabeledContent("Last Updated", value: lastRestocked.formatted(date: .medium, time: .short))
                }
                if item.needsReorder {
                    HStack {
                        Image(systemName: "exclamationmark.triangle").foregroundColor(item.statusColor)
                        Text("Restock Needed").foregroundColor(item.statusColor)
                    }
                }
            }
            
            if isEditing {
                Section {
                    Button("Save Changes") { saveQuantityChange() }
                        .frame(maxWidth: .infinity, alignment: .center).foregroundColor(.blue).disabled(isUpdating)
                    Button("Cancel") { newQuantity = item.currentStock; isEditing = false }
                        .frame(maxWidth: .infinity, alignment: .center).foregroundColor(.red).disabled(isUpdating)
                }
            }
        }
        .navigationTitle(item.name)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .primaryAction) { Button("Edit") { isEditing = true } }
            }
        }
        .overlay(successOverlay)
    }
    
    @ViewBuilder
    private var successOverlay: some View {
        if showUpdateSuccess {
            VStack {
                Spacer()
                Text("Quantity updated successfully")
                    .padding().background(Color.green.opacity(0.9)).foregroundColor(.white).cornerRadius(10)
                    .padding().transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showUpdateSuccess = false }
                        }
                    }
            }
            .animation(.easeInOut, value: showUpdateSuccess)
        }
    }
    
    private func saveQuantityChange() {
        isUpdating = true
        Task {
            do {
                try await buildingService.updateInventoryItemQuantity(itemId: item.id, newQuantity: newQuantity, workerId: "system")
                item.currentStock = newQuantity // Update local item
                isEditing = false
                onUpdate()
                withAnimation { showUpdateSuccess = true }
            } catch {
                print("Failed to update quantity: \(error)")
            }
            isUpdating = false
        }
    }
}

// MARK: - Add Item View

public struct AddInventoryItemView: View {
    public let buildingID: String
    public let onComplete: (Bool) -> Void
    
    @State private var itemName = ""
    @State private var quantity = 1
    @State private var minimumStock = 5
    @State private var unit = "pcs"
    @State private var selectedCategory: InventoryCategory = .other
    @State private var isSubmitting = false
    
    private let buildingService = BuildingService.shared
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $itemName)
                    Stepper("Quantity: \(quantity) \(unit)", value: $quantity, in: 1...1000)
                    Stepper("Min Stock: \(minimumStock) \(unit)", value: $minimumStock, in: 1...100)
                    Picker("Unit", selection: $unit) {
                        ForEach(["pcs", "bottles", "rolls", "boxes"], id: \.self) { Text($0) }
                    }
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(InventoryCategory.allCases, id: \.self) { Text($0.rawValue.capitalized) }
                    }
                }
                Section {
                    Button("Add Item") { addItem() }
                        .frame(maxWidth: .infinity, alignment: .center).disabled(itemName.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Add Inventory Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onComplete(false) } }
            }
        }
    }
    
    private func addItem() {
        isSubmitting = true
        // ✅ FIXED: Use correct initializer for InventoryItem
        let newItem = InventoryItem(
            name: itemName,
            description: "", // Default value
            category: selectedCategory,
            currentStock: quantity,
            minimumStock: minimumStock,
            unit: unit,
            supplier: "", // Default value
            costPerUnit: 0.0, // Default value
            restockStatus: quantity <= minimumStock ? .lowStock : .inStock,
            lastRestocked: Date()
        )
        Task {
            do {
                try await buildingService.saveInventoryItem(newItem)
                onComplete(true)
            } catch {
                print("Failed to add item: \(error)")
                onComplete(false)
            }
        }
    }
}
