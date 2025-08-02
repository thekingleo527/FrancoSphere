
//  UnifiedTaskDetailView.swift
//  FrancoSphere v6.0
//
//  ✅ UNIFIED: Combines TaskDetailView, BuildingTaskDetailView, and DashboardTaskDetailView
//  ✅ DARK ELEGANT: Full FrancoSphereDesign implementation
//  ✅ FLEXIBLE: Supports worker, admin, and simplified modes
//  ✅ GLASS MORPHISM: Consistent with system design
//

import SwiftUI
import PhotosUI
import MapKit

// MARK: - View Mode
enum TaskDetailMode {
    case worker
    case admin
    case simplified
    case dashboard
}

// MARK: - Unified Task Detail View
struct UnifiedTaskDetailView: View {
    // MARK: - Properties
    let task: CoreTypes.ContextualTask
    let mode: TaskDetailMode
    
    @StateObject private var viewModel = TaskDetailViewModel()
    @EnvironmentObject var authManager: NewAuthManager
    @Environment(\.dismiss) private var dismiss
    
    // UI State
    @State private var showPhotoCapture = false
    @State private var showPhotoLibrary = false
    @State private var showLocationMap = false
    @State private var showWorkerAssignment = false
    @State private var showInventoryPicker = false
    @State private var showEditTask = false
    @State private var showCompletionSheet = false
    @State private var completionNotes = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // MARK: - Body
    var body: some View {
        Group {
            // Check for simplified interface
            if viewModel.workerCapabilities?.simplifiedInterface == true || mode == .simplified {
                SimplifiedTaskDetailView(task: task, viewModel: viewModel)
            } else {
                standardDetailView
            }
        }
        .task {
            await viewModel.loadTask(task)
        }
        .sheet(isPresented: $showPhotoCapture) {
            ImagePicker(
                image: .constant(nil),
                onImagePicked: { image in
                    Task {
                        await viewModel.capturePhoto(image)
                    }
                },
                sourceType: .camera
            )
        }
        .sheet(isPresented: $showLocationMap) {
            locationMapSheet
        }
        .sheet(isPresented: $showWorkerAssignment) {
            WorkerAssignmentSheet(task: task)
        }
        .sheet(isPresented: $showInventoryPicker) {
            InventorySelectionSheet(buildingId: task.buildingId ?? "")
        }
        .sheet(isPresented: $showEditTask) {
            EditTaskSheet(task: task)
        }
        .sheet(isPresented: $showCompletionSheet) {
            TaskCompletionSheet(
                task: task,
                notes: $completionNotes,
                onComplete: {
                    Task {
                        await viewModel.completeTask()
                        dismiss()
                    }
                }
            )
        }
    }
    
    // MARK: - Standard Detail View
    private var standardDetailView: some View {
        ZStack {
            // Dark elegant background
            FrancoSphereDesign.DashboardGradients.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with task info
                    taskHeaderCard
                        .animatedGlassAppear(delay: 0.1)
                    
                    // Progress tracking (worker mode)
                    if mode == .worker && viewModel.taskProgress != .notStarted {
                        progressCard
                            .animatedGlassAppear(delay: 0.2)
                    }
                    
                    // Worker assignment (admin mode)
                    if mode == .admin {
                        workerAssignmentCard
                            .animatedGlassAppear(delay: 0.2)
                    }
                    
                    // Inventory section (admin/worker modes)
                    if mode == .admin || mode == .worker {
                        inventoryCard
                            .animatedGlassAppear(delay: 0.3)
                    }
                    
                    // Photo evidence (all modes)
                    if !viewModel.isCompleted {
                        photoEvidenceCard
                            .animatedGlassAppear(delay: 0.4)
                    }
                    
                    // Action buttons
                    actionButtonsCard
                        .animatedGlassAppear(delay: 0.5)
                    
                    // Completed info
                    if viewModel.isCompleted {
                        completedInfoCard
                            .animatedGlassAppear(delay: 0.6)
                    }
                }
                .padding()
            }
            
            // Loading overlay
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Task Details")
        .toolbar {
            if mode == .admin {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showEditTask = true }) {
                            Label("Edit Task", systemImage: "pencil")
                        }
                        Button(action: { showWorkerAssignment = true }) {
                            Label("Assign Workers", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Card
    private var taskHeaderCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title and badges
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .glassHeading()
                        
                        if let category = task.category {
                            Label(category.rawValue.capitalized, systemImage: categoryIcon(category))
                                .glassCaption()
                                .foregroundColor(categoryColor(category))
                        }
                    }
                    
                    Spacer()
                    
                    // Urgency badge
                    if let urgency = task.urgency {
                        Text(urgency.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(FrancoSphereDesign.EnumColors.taskUrgency(urgency))
                            )
                    }
                }
                
                // Description
                if let description = task.description {
                    Text(description)
                        .glassSubtitle()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Building and timing info
            VStack(spacing: 16) {
                // Building info
                if let building = task.building {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                        VStack(alignment: .leading) {
                            Text(building.name)
                                .glassText()
                            if let address = building.address {
                                Text(address)
                                    .glassCaption()
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        if mode == .worker || mode == .dashboard {
                            Button(action: { showLocationMap = true }) {
                                Image(systemName: "map")
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                            }
                        }
                    }
                }
                
                // Due date
                if let dueDate = task.dueDate {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(dueDate < Date() && !task.isCompleted ? 
                                           FrancoSphereDesign.DashboardColors.critical : 
                                           FrancoSphereDesign.DashboardColors.info)
                        VStack(alignment: .leading) {
                            Text(dueDate, style: .date)
                                .glassText()
                            Text(dueDate, style: .time)
                                .glassCaption()
                        }
                        Spacer()
                        if dueDate < Date() && !task.isCompleted {
                            Text("OVERDUE")
                                .glassCaption()
                                .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(FrancoSphereDesign.DashboardColors.critical.opacity(0.2))
                                )
                        }
                    }
                }
            }
        }
        .padding(24)
        .francoGlassCard(intensity: .regular)
    }
    
    // MARK: - Progress Card (Worker Mode)
    private var progressCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progress")
                    .glassHeading()
                Spacer()
                Text(viewModel.taskProgress.rawValue)
                    .glassCaption()
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(.linear)
                .tint(FrancoSphereDesign.DashboardColors.workerPrimary)
                .scaleEffect(x: 1, y: 2)
            
            if let timeRemaining = viewModel.estimatedTimeRemaining {
                HStack {
                    Text("Estimated time remaining")
                        .glassCaption()
                    Spacer()
                    Text(formatDuration(timeRemaining))
                        .glassText(size: .caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.workerAccent)
                }
            }
        }
        .padding(20)
        .francoGlassCard(intensity: .thin)
    }
    
    // MARK: - Worker Assignment Card (Admin Mode)
    private var workerAssignmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Assigned Workers")
                    .glassHeading()
                Spacer()
                Button(action: { showWorkerAssignment = true }) {
                    Label("Manage", systemImage: "person.badge.plus")
                        .glassCaption()
                }
                .glassButton(style: .ghost, size: .small)
            }
            
            if let worker = task.worker {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                    
                    VStack(alignment: .leading) {
                        Text(worker.name)
                            .glassText()
                        Text(worker.role.rawValue.capitalized)
                            .glassCaption()
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            } else {
                Text("No workers assigned")
                    .glassSubtitle()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(FrancoSphereDesign.DashboardColors.warning.opacity(0.1))
                    )
            }
        }
        .padding(20)
        .francoGlassCard(intensity: .regular)
    }
    
    // MARK: - Inventory Card
    private var inventoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Required Inventory")
                    .glassHeading()
                Spacer()
                if mode == .admin {
                    Button(action: { showInventoryPicker = true }) {
                        Label("Select", systemImage: "cart.badge.plus")
                            .glassCaption()
                    }
                    .glassButton(style: .ghost, size: .small)
                }
            }
            
            // Placeholder inventory items
            VStack(spacing: 12) {
                ForEach(["Cleaning Supplies", "Safety Equipment"], id: \.self) { item in
                    HStack {
                        Image(systemName: "cube.box")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                        Text(item)
                            .glassText(size: .callout)
                        Spacer()
                        Text("Available")
                            .glassCaption()
                            .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
        .padding(20)
        .francoGlassCard(intensity: .thin)
    }
    
    // MARK: - Photo Evidence Card
    private var photoEvidenceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Photo Evidence", systemImage: "camera.fill")
                    .glassHeading()
                
                if requiresPhoto {
                    Text("Required")
                        .glassCaption()
                        .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(FrancoSphereDesign.DashboardColors.critical.opacity(0.2))
                        )
                }
                Spacer()
            }
            
            if let photo = viewModel.capturedPhoto {
                // Photo preview with glass overlay
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(FrancoSphereDesign.CornerRadius.medium)
                    
                    Button(action: {
                        viewModel.capturedPhoto = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .padding(8)
                }
            } else {
                // Capture options
                HStack(spacing: 16) {
                    Button(action: { showPhotoCapture = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Take Photo")
                                .glassCaption()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .glassButton(style: .secondary, size: .medium)
                    
                    Button(action: { showPhotoLibrary = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                            Text("Choose Photo")
                                .glassCaption()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .glassButton(style: .secondary, size: .medium)
                }
            }
        }
        .padding(20)
        .francoGlassCard(intensity: .regular)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsCard: some View {
        VStack(spacing: 16) {
            if !viewModel.isCompleted {
                if viewModel.taskProgress == .notStarted && mode == .worker {
                    Button(action: { viewModel.startTask() }) {
                        Label("Start Task", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .glassButton(style: .primary, size: .large)
                } else {
                    Button(action: { showCompletionSheet = true }) {
                        Label("Complete Task", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .glassButton(style: .success, size: .large)
                    .disabled(requiresPhoto && viewModel.capturedPhoto == nil)
                    .pulsingGlow(color: .green)
                }
            }
        }
        .padding(20)
        .francoGlassCard(intensity: .thin)
    }
    
    // MARK: - Completed Info Card
    private var completedInfoCard: some View {
        VStack(spacing: 20) {
            GlassSuccessCheckmark()
            
            Text("Task Completed")
                .glassHeading()
            
            if let completedDate = viewModel.completedDate {
                VStack(spacing: 8) {
                    Text("Completed on")
                        .glassCaption()
                    Text(completedDate, format: .dateTime)
                        .glassText()
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .francoGlassCard(intensity: .regular)
    }
    
    // MARK: - Location Map Sheet
    private var locationMapSheet: some View {
        NavigationView {
            if let coordinate = viewModel.buildingCoordinate {
                Map {
                    Marker(viewModel.buildingName, coordinate: coordinate)
                        .tint(FrancoSphereDesign.DashboardColors.workerPrimary)
                }
                .mapStyle(.standard(elevation: .realistic))
                .navigationTitle(viewModel.buildingName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showLocationMap = false }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var requiresPhoto: Bool {
        guard let category = task.category else { return false }
        switch category {
        case .cleaning, .sanitation, .maintenance, .repair:
            return true
        case .inspection, .security:
            return task.urgency == .high || task.urgency == .critical
        default:
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
    
    private func categoryIcon(_ category: CoreTypes.TaskCategory) -> String {
        switch category {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.and.screwdriver"
        case .repair: return "hammer"
        case .sanitation: return "trash"
        case .inspection: return "magnifyingglass"
        case .landscaping: return "leaf"
        case .security: return "shield"
        case .emergency: return "exclamationmark.triangle"
        case .installation: return "plus.circle"
        case .utilities: return "bolt"
        case .renovation: return "paintbrush"
        case .administrative: return "folder"
        }
    }
    
    private func categoryColor(_ category: CoreTypes.TaskCategory) -> Color {
        switch category {
        case .cleaning: return FrancoSphereDesign.DashboardColors.info
        case .maintenance: return FrancoSphereDesign.DashboardColors.warning
        case .repair: return FrancoSphereDesign.DashboardColors.critical
        case .sanitation: return FrancoSphereDesign.DashboardColors.success
        default: return FrancoSphereDesign.DashboardColors.secondaryText
        }
    }
}

// MARK: - Simplified Task Detail View
struct SimplifiedTaskDetailView: View {
    let task: CoreTypes.ContextualTask
    let viewModel: TaskDetailViewModel
    
    var body: some View {
        ZStack {
            FrancoSphereDesign.DashboardGradients.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Large task title
                Text(task.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Building name
                if let building = task.building {
                    Text(building.name)
                        .font(.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                // Big complete button
                Button(action: {
                    Task {
                        await viewModel.completeTask()
                    }
                }) {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                        Text("Complete Task")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                .glassButton(style: .success, size: .large)
                .padding()
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Sheet Views
struct WorkerAssignmentSheet: View {
    let task: CoreTypes.ContextualTask
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Worker Assignment")
                .navigationTitle("Assign Workers")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct InventorySelectionSheet: View {
    let buildingId: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Inventory Selection")
                .navigationTitle("Select Inventory")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct EditTaskSheet: View {
    let task: CoreTypes.ContextualTask
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Edit Task")
                .navigationTitle("Edit Task")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct TaskCompletionSheet: View {
    let task: CoreTypes.ContextualTask
    @Binding var notes: String
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Complete Task")
                    .glassHeading()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completion Notes")
                        .glassText()
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                }
                .padding()
                
                Spacer()
                
                Button(action: onComplete) {
                    Text("Complete Task")
                        .frame(maxWidth: .infinity)
                }
                .glassButton(style: .success, size: .large)
                .padding()
            }
            .padding()
            .background(FrancoSphereDesign.DashboardGradients.backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
            }
        }
    }
}

// MARK: - Preview
struct UnifiedTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTask = CoreTypes.ContextualTask(
            id: "1",
            title: "Clean Main Lobby",
            description: "Daily cleaning of the main lobby area",
            isCompleted: false,
            dueDate: Date().addingTimeInterval(3600),
            category: .cleaning,
            urgency: .high,
            buildingId: "14",
            building: CoreTypes.NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St",
                latitude: 40.7402,
                longitude: -73.9980
            )
        )
        
        Group {
            // Worker Mode
            NavigationView {
                UnifiedTaskDetailView(task: sampleTask, mode: .worker)
            }
            .previewDisplayName("Worker Mode")
            
            // Admin Mode
            NavigationView {
                UnifiedTaskDetailView(task: sampleTask, mode: .admin)
            }
            .previewDisplayName("Admin Mode")
            
            // Simplified Mode
            NavigationView {
                UnifiedTaskDetailView(task: sampleTask, mode: .simplified)
            }
            .previewDisplayName("Simplified Mode")
        }
        .preferredColorScheme(.dark)
        .environmentObject(NewAuthManager.shared)
    }
}
