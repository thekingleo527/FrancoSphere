
//  BuildingDetailSupporting.swift
//  FrancoSphere v6.0
//
//  📦 INVENTORY: Real-time inventory management
//  💬 MESSAGING: Integrated communication
//  📸 PHOTOS: Organized space documentation
//  📋 HISTORY: Maintenance and vendor tracking
//

import SwiftUI
import MessageUI
import PhotosUI

// MARK: - Inventory Management Components

struct InventoryCategoryCard: View {
    let category: InventoryCategory
    let items: [InventoryItem]
    let onUpdateQuantity: (InventoryItem, Int) -> Void
    let onReorder: (InventoryItem) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Label(category.rawValue, systemImage: category.icon)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        InventoryItemRow(
                            item: item,
                            onUpdateQuantity: { quantity in
                                onUpdateQuantity(item, quantity)
                            },
                            onReorder: {
                                onReorder(item)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct InventoryItemRow: View {
    let item: InventoryItem
    let onUpdateQuantity: (Int) -> Void
    let onReorder: () -> Void
    
    @State private var showingQuantityAdjuster = false
    
    private var stockLevel: StockLevel {
        let percentage = Double(item.quantity) / Double(item.minQuantity * 2)
        if percentage < 0.3 {
            return .critical
        } else if percentage < 0.6 {
            return .low
        } else {
            return .good
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("\(item.quantity) \(item.unit)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Stock indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(stockLevel.color)
                        .frame(width: 8, height: 8)
                    
                    Text(stockLevel.label)
                        .font(.caption2)
                        .foregroundColor(stockLevel.color)
                }
                
                // Actions
                HStack(spacing: 8) {
                    Button(action: { showingQuantityAdjuster = true }) {
                        Image(systemName: "plus.minus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    
                    if stockLevel != .good {
                        Button(action: onReorder) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            // Stock level bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(stockLevel.color)
                        .frame(
                            width: geometry.size.width * min(Double(item.quantity) / Double(item.minQuantity * 2), 1.0),
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
        .sheet(isPresented: $showingQuantityAdjuster) {
            QuantityAdjusterSheet(
                item: item,
                currentQuantity: item.quantity,
                onSave: onUpdateQuantity
            )
        }
    }
    
    enum StockLevel {
        case good, low, critical
        
        var color: Color {
            switch self {
            case .good: return .green
            case .low: return .orange
            case .critical: return .red
            }
        }
        
        var label: String {
            switch self {
            case .good: return "In Stock"
            case .low: return "Low"
            case .critical: return "Critical"
            }
        }
    }
}

struct QuantityAdjusterSheet: View {
    let item: InventoryItem
    let currentQuantity: Int
    let onSave: (Int) -> Void
    
    @State private var quantity: Int
    @State private var adjustmentReason = ""
    @State private var adjustmentType = AdjustmentType.use
    @Environment(\.dismiss) private var dismiss
    
    init(item: InventoryItem, currentQuantity: Int, onSave: @escaping (Int) -> Void) {
        self.item = item
        self.currentQuantity = currentQuantity
        self.onSave = onSave
        self._quantity = State(initialValue: currentQuantity)
    }
    
    enum AdjustmentType: String, CaseIterable {
        case use = "Used"
        case restock = "Restocked"
        case adjust = "Adjustment"
        
        var icon: String {
            switch self {
            case .use: return "minus.circle"
            case .restock: return "plus.circle"
            case .adjust: return "equal.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Item info
                VStack(spacing: 8) {
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Current: \(currentQuantity) \(item.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Adjustment type
                Picker("Type", selection: $adjustmentType) {
                    ForEach(AdjustmentType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Quantity adjuster
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        Button(action: { 
                            if quantity > 0 { quantity -= 1 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                        }
                        
                        Text("\(quantity)")
                            .font(.system(size: 48, weight: .semibold))
                            .frame(minWidth: 100)
                        
                        Button(action: { quantity += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(item.unit)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Quick adjust buttons
                HStack(spacing: 12) {
                    ForEach([-10, -5, -1, 1, 5, 10], id: \.self) { value in
                        Button(action: {
                            let newQuantity = quantity + value
                            if newQuantity >= 0 {
                                quantity = newQuantity
                            }
                        }) {
                            Text(value > 0 ? "+\(value)" : "\(value)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(value > 0 ? .green : .red)
                                .frame(width: 44, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(value > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                )
                        }
                    }
                }
                
                // Reason field
                TextField("Reason (optional)", text: $adjustmentReason)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
                
                // Save button
                Button(action: save) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Adjust Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func save() {
        onSave(quantity)
        
        // Log the adjustment
        let change = quantity - currentQuantity
        print("Inventory adjustment: \(item.name) \(change > 0 ? "+" : "")\(change) \(item.unit) - \(adjustmentType.rawValue)")
        
        dismiss()
    }
}

// MARK: - Message Composer

struct MessageComposerView: View {
    let recipients: [String]
    let subject: String
    let prefilledBody: String
    
    @State private var messageBody = ""
    @State private var isUrgent = false
    @State private var attachPhoto = false
    @State private var selectedPhotos: [UIImage] = []
    @State private var showingPhotoPicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Recipients
                VStack(alignment: .leading, spacing: 8) {
                    Text("To:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recipients, id: \.self) { recipient in
                                RecipientChip(email: recipient)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Message options
                HStack {
                    Toggle(isOn: $isUrgent) {
                        Label("Urgent", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    
                    Spacer()
                    
                    Button(action: { showingPhotoPicker = true }) {
                        Label(
                            selectedPhotos.isEmpty ? "Add Photo" : "\(selectedPhotos.count) Photos",
                            systemImage: "camera.fill"
                        )
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Message body
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $messageBody)
                        .font(.body)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Photo preview
                if !selectedPhotos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(selectedPhotos.indices, id: \.self) { index in
                                PhotoThumbnail(
                                    image: selectedPhotos[index],
                                    onRemove: {
                                        selectedPhotos.remove(at: index)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
                
                Spacer()
            }
            .navigationTitle(subject)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") { sendMessage() }
                        .fontWeight(.semibold)
                        .disabled(messageBody.isEmpty)
                }
            }
        }
        .onAppear {
            messageBody = prefilledBody
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(selectedImages: $selectedPhotos)
        }
    }
    
    private func sendMessage() {
        // Send message logic
        print("Sending message to: \(recipients.joined(separator: ", "))")
        print("Urgent: \(isUrgent)")
        print("Photos: \(selectedPhotos.count)")
        
        dismiss()
    }
}

struct RecipientChip: View {
    let email: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.circle.fill")
                .font(.caption)
            
            Text(displayName)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue)
        .cornerRadius(16)
    }
    
    private var displayName: String {
        if email.contains("@") {
            return email.components(separatedBy: "@").first?.capitalized ?? email
        }
        return email
    }
}

struct PhotoThumbnail: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Photo Management

struct PhotoCaptureView: View {
    let building: CoreTypes.Building
    let onSave: (UIImage) async -> Void
    
    @State private var capturedImage: UIImage?
    @State private var selectedSpace = "General"
    @State private var notes = ""
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss
    
    let spaceTypes = [
        "General",
        "Utility Room",
        "Basement",
        "Roof Access",
        "Loading Dock",
        "Trash Area",
        "Storage",
        "Lobby",
        "Stairwell",
        "Elevator",
        "Mechanical Room",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    // Preview captured image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding()
                    
                    // Space selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Space Type")
                            .font(.headline)
                        
                        Picker("Space", selection: $selectedSpace) {
                            ForEach(spaceTypes, id: \.self) { space in
                                Text(space).tag(space)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Notes field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.headline)
                        
                        TextField("Add notes about this photo", text: $notes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: retakePhoto) {
                            Label("Retake", systemImage: "camera.rotate")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                        }
                        
                        Button(action: savePhoto) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Label("Save", systemImage: "checkmark.circle.fill")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isProcessing)
                    }
                    .padding(.horizontal)
                    
                } else {
                    // Camera view placeholder
                    CameraPlaceholder(onCapture: { image in
                        capturedImage = image
                    })
                }
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func retakePhoto() {
        capturedImage = nil
    }
    
    private func savePhoto() {
        guard let image = capturedImage else { return }
        
        isProcessing = true
        
        Task {
            // Add metadata
            let metadata = PhotoMetadata(
                buildingId: building.id,
                buildingName: building.name,
                spaceType: selectedSpace,
                notes: notes,
                timestamp: Date(),
                location: nil // Could add GPS if needed
            )
            
            // Process and save
            await onSave(image)
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct CameraPlaceholder: View {
    let onCapture: (UIImage) -> Void
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Take a photo of the space")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: { showingImagePicker = true }) {
                Label("Open Camera", systemImage: "camera")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: .constant(nil), onImagePicked: onCapture)
        }
    }
}

// MARK: - Supporting Types

struct PhotoMetadata {
    let buildingId: String
    let buildingName: String
    let spaceType: String
    let notes: String
    let timestamp: Date
    let location: CLLocation?
}

// MARK: - History Components

struct MaintenanceHistoryCard: View {
    let records: [MaintenanceRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Maintenance", systemImage: "wrench.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            if records.isEmpty {
                Text("No recent maintenance")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical)
            } else {
                VStack(spacing: 12) {
                    ForEach(records.prefix(5)) { record in
                        MaintenanceRecordRow(record: record)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct MaintenanceRecordRow: View {
    let record: MaintenanceRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if let vendor = record.vendor {
                Text(vendor)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(record.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
            
            HStack {
                StatusBadge(status: record.status)
                
                Spacer()
                
                if let cost = record.cost {
                    Text("$\(cost.formatted())")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "completed", "passed":
            return .green
        case "pending", "scheduled":
            return .orange
        case "failed", "urgent":
            return .red
        default:
            return .blue
        }
    }
}

// MARK: - Team Components

struct AssignedWorkersCard: View {
    let workers: [WorkerAssignment]
    let onCall: (WorkerAssignment) -> Void
    let onMessage: (WorkerAssignment) -> Void
    let onViewTasks: (WorkerAssignment) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Assigned Workers", systemImage: "person.2.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(workers) { assignment in
                    WorkerAssignmentRow(
                        assignment: assignment,
                        onCall: { onCall(assignment) },
                        onMessage: { onMessage(assignment) },
                        onViewTasks: { onViewTasks(assignment) }
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct WorkerAssignmentRow: View {
    let assignment: WorkerAssignment
    let onCall: () -> Void
    let onMessage: () -> Void
    let onViewTasks: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Worker avatar
                ZStack {
                    Circle()
                        .fill(assignment.isOnSite ? Color.green : Color.gray)
                        .frame(width: 40, height: 40)
                    
                    Text(assignment.worker.name.initials)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(assignment.worker.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        if !assignment.specialties.isEmpty {
                            Text("• \(assignment.specialties.first!)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if assignment.isOnSite {
                            Label("On-site", systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text(assignment.schedule)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    ActionButton(icon: "phone.fill", color: .green, action: onCall)
                    ActionButton(icon: "message.fill", color: .blue, action: onMessage)
                    ActionButton(icon: "checklist", color: .purple, action: onViewTasks)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.2))
                .clipShape(Circle())
        }
    }
}

// MARK: - Extensions

extension String {
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: self) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        
        // Fallback
        let words = self.split(separator: " ")
        let initials = words.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}

// MARK: - Preview Helpers

struct PreviewData {
    static let sampleBuilding = CoreTypes.Building(
        id: "14",
        name: "Rubin Museum",
        address: "150 W 17th St, New York, NY 10011",
        type: .special,
        size: 85000,
        floors: 6,
        units: 1,
        yearBuilt: 1998,
        managementCompany: "Franco Management",
        primaryContact: CoreTypes.ContactInfo(
            name: "John Smith",
            role: "Building Manager",
            email: "john@rubinmuseum.org",
            phone: "(212) 555-0100",
            isEmergencyContact: false
        ),
        emergencyContact: CoreTypes.ContactInfo(
            name: "Security Desk",
            role: "24/7 Security",
            email: nil,
            phone: "(212) 555-0199",
            isEmergencyContact: true
        ),
        accessInstructions: "Main entrance on 17th St. Check in at security desk.",
        specialNotes: "Museum hours 10 AM - 5 PM. No cleaning during visiting hours.",
        amenities: ["elevator", "loading_dock", "freight_elevator"],
        complianceStatus: .compliant,
        lastInspectionDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
        createdAt: Date(),
        updatedAt: Date()
    )
}

// MARK: - Previews

#Preview("Inventory Management") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 20) {
                InventoryCategoryCard(
                    category: .cleaning,
                    items: [
                        InventoryItem(
                            id: "1",
                            name: "Floor Cleaner",
                            category: .cleaning,
                            quantity: 4,
                            unit: "gallons",
                            minQuantity: 2
                        ),
                        InventoryItem(
                            id: "2",
                            name: "Glass Cleaner",
                            category: .cleaning,
                            quantity: 1,
                            unit: "bottles",
                            minQuantity: 3
                        )
                    ],
                    onUpdateQuantity: { item, quantity in
                        print("Update \(item.name) to \(quantity)")
                    },
                    onReorder: { item in
                        print("Reorder \(item.name)")
                    }
                )
            }
            .padding()
        }
    }
}

#Preview("Message Composer") {
    MessageComposerView(
        recipients: ["david@francosphere.com", "jerry@francosphere.com"],
        subject: "Re: Rubin Museum",
        prefilledBody: """
        Building: Rubin Museum
        Address: 150 W 17th St
        Current Status: 92% complete
        Workers on site: 2
        
        ---
        """
    )
}

#Preview("Photo Capture") {
    PhotoCaptureView(
        building: PreviewData.sampleBuilding,
        onSave: { image in
            print("Saving photo...")
        }
    )
}
