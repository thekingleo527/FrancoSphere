//
//  InventoryView.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: All compilation errors resolved.
//  ✅ PHASE 0 INTEGRATION: Works with existing model extensions
//  ✅ FIXED: Removes conflicting extension declarations
//  ✅ FIXED: Uses existing properties and methods from codebase
//

import SwiftUI

// MARK: - Phase 0: Only Add Non-Conflicting Extensions

extension InventoryItem {
    /// Phase 0: Status text for consistent display - only if not already defined
    var statusText: String {
        // Use existing status property (RestockStatus) and convert to string
        switch restockStatus {
        case .inStock:
            return "In Stock"
        case .lowStock:
            return "Low Stock"
        case .outOfStock:
            return "Out of Stock"
        case .onOrder:
            return "On Order"
        }
    }
    
    /// Phase 0: Formatted quantity display
    var formattedQuantity: String {
        return "\(currentStock) \(unit)"
    }
    
    /// Phase 0: Stock level percentage for intelligence metrics
    var stockLevelPercentage: Double {
        guard minimumStock > 0 else { return 1.0 }
        return Double(currentStock) / Double(minimumStock * 2) // 2x minimum as "full"
    }
    
    /// Phase 0: Urgency level for prioritization
    var urgencyLevel: InventoryUrgency {
        if currentStock <= 0 {
            return .critical
        } else if currentStock <= minimumStock {
            return .high
        } else if currentStock <= Int(Double(minimumStock) * 1.5) {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Phase 0: Supporting Types

public enum InventoryUrgency: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

// MARK: - Helper Functions (Use existing pattern from codebase)

func statusColor(for item: InventoryItem) -> Color {
    if item.currentStock <= 0 {
        return .red
    } else if item.currentStock <= item.minimumStock {
        return .orange
    } else {
        return .green
    }
}

func needsReorder(for item: InventoryItem) -> Bool {
    return item.currentStock <= item.minimumStock
}

// MARK: - Inventory View Model

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
    
    // MARK: - Phase 0: Intelligence Metrics
    
    var inventoryIntelligence: InventoryIntelligence {
        return InventoryIntelligence(items: inventoryItems)
    }

    func loadInventory() async {
        isLoading = true
        errorMessage = nil
        do {
            // Using the new service to fetch data
            inventoryItems = try await buildingService.getInventoryItems(for: buildingID)
        } catch {
            errorMessage = "Failed to load inventory: \(error.localizedDescription)"
            print("❌ \(errorMessage!)")
            
            // Load mock data for development
            loadMockData()
        }
        isLoading = false
    }
    
    private func loadMockData() {
        inventoryItems = [
            InventoryItem(
                name: "All-Purpose Cleaner",
                description: "Multi-surface cleaning solution",
                category: .cleaningSupplies,
                currentStock: 5,
                minimumStock: 10,
                unit: "bottles",
                supplier: "CleanCorp",
                costPerUnit: 12.99,
                restockStatus: .lowStock
            ),
            InventoryItem(
                name: "Screwdriver Set",
                description: "Professional grade screwdriver set",
                category: .tools,
                currentStock: 0,
                minimumStock: 2,
                unit: "sets",
                supplier: "ToolMaster",
                costPerUnit: 45.99,
                restockStatus: .outOfStock
            ),
            InventoryItem(
                name: "Safety Goggles",
                description: "Protective eyewear",
                category: .safety,
                currentStock: 15,
                minimumStock: 8,
                unit: "pairs",
                supplier: "SafetyFirst",
                costPerUnit: 8.99,
                restockStatus: .inStock
            ),
            InventoryItem(
                name: "Paint Rollers",
                description: "9-inch paint rollers",
                category: .paint,
                currentStock: 3,
                minimumStock: 5,
                unit: "pcs",
                supplier: "PaintPro",
                costPerUnit: 7.50,
                restockStatus: .lowStock
            )
        ]
    }

    func deleteItem(_ item: InventoryItem) async {
        do {
            try await buildingService.deleteInventoryItem(itemId: item.id)
            inventoryItems.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
            print("❌ \(errorMessage!)")
        }
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
    }
}

// MARK: - Phase 0: Inventory Intelligence Model

struct InventoryIntelligence {
    let items: [InventoryItem]
    
    var criticalItemsCount: Int {
        items.filter { $0.urgencyLevel == .critical }.count
    }
    
    var lowStockCount: Int {
        items.filter { $0.urgencyLevel == .high || $0.urgencyLevel == .medium }.count
    }
    
    var wellStockedCount: Int {
        items.filter { $0.urgencyLevel == .low }.count
    }
    
    var totalValue: Double {
        items.reduce(0) { $0 + (Double($1.currentStock) * $1.costPerUnit) }
    }
    
    var averageStockLevel: Double {
        guard !items.isEmpty else { return 0 }
        return items.map { $0.stockLevelPercentage }.reduce(0, +) / Double(items.count)
    }
}

// MARK: - Inventory View

struct InventoryView: View {
    @StateObject private var viewModel: InventoryViewModel

    init(buildingID: CoreTypes.BuildingID) {
        _viewModel = StateObject(wrappedValue: InventoryViewModel(buildingID: buildingID))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Phase 0: Intelligence Summary Panel
                intelligenceSummaryPanel
                
                searchFilterBar
                
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
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
                Button(action: { Task { await viewModel.loadInventory() } }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await viewModel.loadInventory()
        }
        .sheet(isPresented: $viewModel.showAddItemSheet) {
            AddInventoryItemView(buildingID: viewModel.buildingID) { success in
                viewModel.showAddItemSheet = false
                if success { Task { await viewModel.loadInventory() } }
            }
        }
    }
    
    // MARK: - Phase 0: Intelligence Summary Panel
    
    private var intelligenceSummaryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inventory Intelligence")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(viewModel.inventoryItems.count) Items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Intelligence metrics
            HStack(spacing: 16) {
                intelligenceMetric(
                    title: "Critical",
                    value: "\(viewModel.inventoryIntelligence.criticalItemsCount)",
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                intelligenceMetric(
                    title: "Low Stock",
                    value: "\(viewModel.inventoryIntelligence.lowStockCount)",
                    color: .orange,
                    icon: "chart.bar.doc.horizontal"
                )
                
                intelligenceMetric(
                    title: "Well Stocked",
                    value: "\(viewModel.inventoryIntelligence.wellStockedCount)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                intelligenceMetric(
                    title: "Total Value",
                    value: "$\(Int(viewModel.inventoryIntelligence.totalValue))",
                    color: .blue,
                    icon: "dollarsign.circle.fill"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func intelligenceMetric(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Subviews
    private var searchFilterBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search Inventory", text: $viewModel.searchText)
            }
            .padding(10).background(Color(.systemGray6)).cornerRadius(10)
            .padding(.horizontal).padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryButton(nil, label: "All")
                    // ✅ FIX: Explicit generic parameter specification
                    ForEach(Array(InventoryCategory.allCases), id: \.self) { category in
                        categoryButton(category, label: category.rawValue.capitalized)
                    }
                }.padding(.horizontal)
            }.padding(.bottom, 8)
        }.background(Color(.systemBackground))
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading inventory...")
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error Loading Inventory")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task { await viewModel.loadInventory() }
            }
            .buttonStyle(.bordered)
            Spacer()
        }.padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "archivebox").font(.system(size: 50)).foregroundColor(.gray)
            Text(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil ? "No Inventory Items" : "No Matching Items")
                .font(.headline)
            Text(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil ? "This building has no inventory items yet." : "Try adjusting your search or filters.")
                .multilineTextAlignment(.center).foregroundColor(.secondary)
            Button(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil ? "Add Item" : "Clear Filters") {
                if viewModel.searchText.isEmpty && viewModel.selectedCategory == nil {
                    viewModel.showAddItemSheet = true
                } else {
                    viewModel.clearFilters()
                }
            }.buttonStyle(.borderedProminent).padding(.top, 8)
            Spacer()
        }.padding()
    }

    private var inventoryListView: some View {
        List {
            ForEach(viewModel.filteredItems, id: \.id) { item in
                NavigationLink(destination: InventoryItemDetailView(item: item, onUpdate: {
                    Task { await viewModel.loadInventory() }
                })) {
                    InventoryItemRow(item: item)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteItem(item) }
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }.listStyle(.plain)
    }

    private var floatingActionButton: some View {
        Button(action: { viewModel.showAddItemSheet = true }) {
            Image(systemName: "plus")
                .font(.title2.bold()).foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.blue))
                .shadow(radius: 3)
        }.padding(20)
    }

    private func categoryButton(_ category: InventoryCategory?, label: String) -> some View {
        Button(action: { withAnimation { viewModel.selectedCategory = category } }) {
            HStack(spacing: 4) {
                // Use existing icon property from InventoryCategory
                Image(systemName: category?.icon ?? "tag").font(.caption)
                Text(label).font(.subheadline)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(viewModel.selectedCategory == category ? Color.blue : Color(.systemGray5))
            .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Inventory Item Row
struct InventoryItemRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle().fill(statusColor(for: item).opacity(0.2)).frame(width: 40, height: 40)
                // Use existing icon property from InventoryCategory
                Image(systemName: item.category.icon).foregroundColor(statusColor(for: item))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline)
                HStack(spacing: 8) {
                    Text("Qty: \(item.currentStock) \(item.unit)").font(.subheadline).foregroundColor(.secondary)
                    // Use helper function instead of property
                    if needsReorder(for: item) {
                        Text(item.statusText).font(.caption).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(statusColor(for: item).opacity(0.2)).foregroundColor(statusColor(for: item)).cornerRadius(4)
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
                
                // Urgency indicator
                Circle()
                    .fill(item.urgencyLevel.color)
                    .frame(width: 8, height: 8)
            }.frame(width: 70, alignment: .center)
        }.padding(.vertical, 4)
    }
}

// MARK: - Inventory Item Detail View
struct InventoryItemDetailView: View {
    @State var item: InventoryItem // Use @State to allow modification
    let onUpdate: () -> Void
    
    @State private var newQuantity: Int
    @State private var isEditing = false
    @State private var isUpdating = false
    
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
                LabeledContent("Description", value: item.description.isEmpty ? "No description" : item.description)
                
                if isEditing {
                    Stepper("Quantity: \(newQuantity) \(item.unit)", value: $newQuantity, in: 0...1000)
                } else {
                    LabeledContent("Quantity", value: "\(item.currentStock) \(item.unit)")
                }
                
                LabeledContent("Min Quantity", value: "\(item.minimumStock) \(item.unit)")
                LabeledContent("Category", value: item.category.rawValue.capitalized)
                LabeledContent("Status", value: item.statusText)
                LabeledContent("Supplier", value: item.supplier.isEmpty ? "Not specified" : item.supplier)
                LabeledContent("Cost per Unit", value: String(format: "$%.2f", item.costPerUnit))
                
                if let lastRestocked = item.lastRestocked {
                    LabeledContent("Last Updated", value: lastRestocked.formatted(date: .medium, time: .short))
                }
            }
            
            Section("Inventory Intelligence") {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(item.urgencyLevel.color)
                    Text("Urgency Level")
                    Spacer()
                    Text(item.urgencyLevel.rawValue)
                        .foregroundColor(item.urgencyLevel.color)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "percent")
                        .foregroundColor(.blue)
                    Text("Stock Level")
                    Spacer()
                    Text("\(Int(item.stockLevelPercentage * 100))%")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                if needsReorder(for: item) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Reorder Recommended")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
            
            if isEditing {
                Section {
                    Button("Save Changes", action: saveQuantityChange)
                        .disabled(isUpdating)
                    
                    Button("Cancel", role: .destructive) {
                        isEditing = false
                        newQuantity = item.currentStock
                    }
                    .disabled(isUpdating)
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
    }

    private func saveQuantityChange() {
        isUpdating = true
        Task {
            do {
                try await buildingService.updateInventoryItemQuantity(itemId: item.id, newQuantity: newQuantity, workerId: "admin")
                
                // Update the local item
                await MainActor.run {
                    item = InventoryItem(
                        id: item.id,
                        name: item.name,
                        description: item.description,
                        category: item.category,
                        currentStock: newQuantity,
                        minimumStock: item.minimumStock,
                        unit: item.unit,
                        supplier: item.supplier,
                        costPerUnit: item.costPerUnit,
                        restockStatus: newQuantity <= item.minimumStock ?
                            (newQuantity <= 0 ? .outOfStock : .lowStock) : .inStock,
                        lastRestocked: Date()
                    )
                    isEditing = false
                }
                
                onUpdate()
            } catch {
                print("❌ Failed to update quantity: \(error)")
            }
            isUpdating = false
        }
    }
}

// MARK: - Add Inventory Item View
public struct AddInventoryItemView: View {
    public let buildingID: String
    public let onComplete: (Bool) -> Void
    
    @State private var itemName = ""
    @State private var itemDescription = ""
    @State private var quantity = 1
    @State private var minimumStock = 5
    @State private var unit = "pcs"
    @State private var selectedCategory: InventoryCategory = .other
    @State private var supplier = ""
    @State private var costPerUnit = 0.0
    @State private var isSubmitting = false
    
    private let buildingService = BuildingService.shared
    
    private let commonUnits = ["pcs", "bottles", "rolls", "boxes", "kg", "lbs", "liters", "gallons", "meters", "feet"]
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Item Name", text: $itemName)
                    TextField("Description (optional)", text: $itemDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Quantity & Stock") {
                    Stepper("Initial Quantity: \(quantity)", value: $quantity, in: 0...1000)
                    Stepper("Minimum Stock: \(minimumStock)", value: $minimumStock, in: 1...100)
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(commonUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                }
                
                Section("Category & Supplier") {
                    Picker("Category", selection: $selectedCategory) {
                        // ✅ FIX: Explicit generic parameter specification
                        ForEach(Array(InventoryCategory.allCases), id: \.self) { category in
                            Label(category.rawValue.capitalized, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    TextField("Supplier (optional)", text: $supplier)
                    
                    HStack {
                        Text("Cost per Unit")
                        Spacer()
                        TextField("0.00", value: $costPerUnit, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("Add Item", action: addItem)
                        .disabled(itemName.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Add Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onComplete(false) }
                }
            }
        }
    }
    
    private func addItem() {
        isSubmitting = true
        
        // ✅ FIXED: Use correct initializer for InventoryItem with all required fields
        let newItem = InventoryItem(
            name: itemName,
            description: itemDescription,
            category: selectedCategory,
            currentStock: quantity,
            minimumStock: minimumStock,
            unit: unit,
            supplier: supplier,
            costPerUnit: costPerUnit,
            restockStatus: quantity <= minimumStock ?
                (quantity <= 0 ? .outOfStock : .lowStock) : .inStock,
            lastRestocked: Date()
        )
        
        Task {
            do {
                try await buildingService.saveInventoryItem(newItem)
                await MainActor.run {
                    onComplete(true)
                }
            } catch {
                print("❌ Failed to add item: \(error)")
                await MainActor.run {
                    onComplete(false)
                }
            }
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
}

// MARK: - Preview

struct InventoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InventoryView(buildingID: "1")
        }
    }
}
