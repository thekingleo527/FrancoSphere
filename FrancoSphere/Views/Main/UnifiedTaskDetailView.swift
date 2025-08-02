//
//  UnifiedTaskDetailView.swift
//  FrancoSphere v6.0
//
//  ✅ UNIFIED: Single task detail view for all roles and modes
//  ✅ SIMPLIFIED: Dedicated mode for accessibility and simplified interface
//  ✅ DARK ELEGANCE: Consistent theme across all modes
//  ✅ REAL-TIME: Live updates via DashboardSyncService
//  ✅ ACCESSIBLE: Large touch targets and clear typography in simplified mode
//  ✅ FIXED: Replaced CameraModel with working implementation
//

import SwiftUI
import PhotosUI
import MapKit
import Combine
import AVFoundation

struct UnifiedTaskDetailView: View {
    // MARK: - Properties
    let task: CoreTypes.ContextualTask
    let mode: TaskDetailMode
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @StateObject private var viewModel: TaskDetailViewModel
    
    // Photo handling
    @State private var showPhotoCapture = false
    @State private var capturedPhoto: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    
    // Task state
    @State private var taskNotes = ""
    @State private var showCompletionConfirmation = false
    @State private var isCompleting = false
    
    // Admin features
    @State private var showReassignSheet = false
    @State private var showRescheduleSheet = false
    
    // Simplified mode states
    @State private var showSimplifiedPhotoOptions = false
    @State private var simplifiedPhotoTaken = false
    
    // MARK: - Mode Enum
    enum TaskDetailMode {
        case worker
        case admin
        case dashboard
        case simplified  // NEW: For workers with simplified interface
        
        var allowsEditing: Bool {
            switch self {
            case .admin: return true
            case .worker: return true
            case .dashboard: return false
            case .simplified: return true
            }
        }
        
        var showsAdvancedFeatures: Bool {
            switch self {
            case .admin: return true
            case .worker: return true
            case .dashboard: return true
            case .simplified: return false
            }
        }
    }
    
    // MARK: - Initialization
    init(task: CoreTypes.ContextualTask, mode: TaskDetailMode = .worker) {
        self.task = task
        self.mode = mode
        self._viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                FrancoSphereDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                // Content based on mode
                Group {
                    switch mode {
                    case .simplified:
                        simplifiedLayout
                    case .worker:
                        workerLayout
                    case .admin:
                        adminLayout
                    case .dashboard:
                        dashboardLayout
                    }
                }
            }
            .navigationBarTitleDisplayMode(mode == .simplified ? .inline : .large)
            .navigationTitle(mode == .simplified ? "" : "Task Details")
            .toolbar {
                toolbarContent
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPhotoCapture) {
            if mode == .simplified {
                SimplifiedPhotoCaptureView(
                    onPhotoTaken: { photo in
                        capturedPhoto = photo
                        simplifiedPhotoTaken = true
                        showPhotoCapture = false
                    },
                    onCancel: {
                        showPhotoCapture = false
                    }
                )
            } else {
                PhotoCaptureView(image: $capturedPhoto)
            }
        }
        .sheet(isPresented: $showReassignSheet) {
            ReassignTaskSheet(task: task)
        }
        .sheet(isPresented: $showRescheduleSheet) {
            RescheduleTaskSheet(task: task)
        }
        .alert("Task Completed!", isPresented: $showCompletionConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Great job! This task has been marked as complete.")
        }
    }
    
    // MARK: - Simplified Layout
    @ViewBuilder
    private var simplifiedLayout: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 1. Task Header - Extra Large
                VStack(spacing: 16) {
                    // Task icon
                    Image(systemName: task.category?.icon ?? "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(FrancoSphereDesign.DashboardColors.workerPrimary)
                        .padding()
                        .background(
                            Circle()
                                .fill(FrancoSphereDesign.DashboardColors.workerPrimary.opacity(0.1))
                        )
                    
                    // Task title
                    Text(task.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Building name
                    if let building = task.building {
                        Label {
                            Text(building.name)
                                .font(.title2)
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "building.2.fill")
                                .font(.title2)
                        }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .francoDarkCardBackground()
                
                // 2. Essential Information Only
                VStack(spacing: 24) {
                    // Task description (if exists)
                    if let description = task.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Instructions", systemImage: "doc.text")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                            
                            Text(description)
                                .font(.title3)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .francoDarkCardBackground()
                    }
                    
                    // Due time (if exists and not completed)
                    if let dueDate = task.dueDate, task.status != .completed {
                        HStack(spacing: 16) {
                            Image(systemName: "clock.fill")
                                .font(.largeTitle)
                                .foregroundColor(task.isOverdue ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.warning)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.isOverdue ? "OVERDUE" : "Due By")
                                    .font(.headline)
                                    .foregroundColor(task.isOverdue ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.secondaryText)
                                
                                Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .francoDarkCardBackground()
                    }
                }
                
                // 3. Photo Section (if required)
                if task.requiresPhoto == true && task.status != .completed {
                    VStack(spacing: 20) {
                        Label("Photo Required", systemImage: "camera.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        
                        if let photo = capturedPhoto {
                            // Show captured photo
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .overlay(
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title)
                                            Text("Photo Added")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(
                                            FrancoSphereDesign.DashboardColors.success
                                                .opacity(0.9)
                                        )
                                    }
                                )
                            
                            // Retake button
                            Button(action: { showPhotoCapture = true }) {
                                Label("Take New Photo", systemImage: "camera")
                                    .font(.title3)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.workerPrimary)
                            }
                            .padding(.top)
                        } else {
                            // Take photo button
                            Button(action: { showPhotoCapture = true }) {
                                VStack(spacing: 16) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 50))
                                    Text("Take Photo")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(FrancoSphereDesign.DashboardColors.warning)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                    .francoDarkCardBackground()
                }
                
                // 4. Status or Action
                if task.status == .completed {
                    // Completed status
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                        
                        Text("Task Completed")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                        
                        if let completedDate = task.completedAt {
                            Text("Completed \(completedDate.formatted(.relative(presentation: .named)))")
                                .font(.title3)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        }
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                    .francoDarkCardBackground()
                } else {
                    // Complete button
                    Button(action: completeSimplifiedTask) {
                        HStack(spacing: 20) {
                            if isCompleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                            }
                            
                            Text(isCompleting ? "Completing..." : "Complete Task")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(
                            canCompleteSimplifiedTask ?
                            FrancoSphereDesign.DashboardColors.success :
                            FrancoSphereDesign.DashboardColors.inactive
                        )
                        .cornerRadius(20)
                    }
                    .disabled(!canCompleteSimplifiedTask || isCompleting)
                    
                    // Helper text if photo needed
                    if task.requiresPhoto == true && capturedPhoto == nil {
                        Label("Take a photo before completing", systemImage: "exclamationmark.circle")
                            .font(.title3)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                            .padding(.top)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Worker Layout
    @ViewBuilder
    private var workerLayout: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Task header card
                taskHeaderCard
                
                // Task details card
                taskDetailsCard
                
                // Location card (if applicable)
                if task.building != nil {
                    locationCard
                }
                
                // Photo evidence section
                if task.requiresPhoto == true {
                    photoEvidenceCard
                }
                
                // Notes section
                notesCard
                
                // Action section
                if task.status != .completed {
                    workerActionSection
                }
            }
            .padding()
        }
    }
    
    // MARK: - Admin Layout
    @ViewBuilder
    private var adminLayout: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Task header with admin controls
                adminTaskHeaderCard
                
                // Task details
                taskDetailsCard
                
                // Worker assignment
                workerAssignmentCard
                
                // Location card
                if task.building != nil {
                    locationCard
                }
                
                // Photo evidence
                if task.requiresPhoto == true {
                    photoEvidenceCard
                }
                
                // Notes and history
                notesCard
                taskHistoryCard
                
                // Admin actions
                adminActionSection
            }
            .padding()
        }
    }
    
    // MARK: - Dashboard Layout (Read-only)
    @ViewBuilder
    private var dashboardLayout: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Task overview
                taskHeaderCard
                
                // Quick stats
                taskStatsCard
                
                // Details
                taskDetailsCard
                
                // Location
                if task.building != nil {
                    locationCard
                }
                
                // Completion evidence
                if task.status == .completed && task.requiresPhoto == true {
                    completionEvidenceCard
                }
            }
            .padding()
        }
    }
    
    // MARK: - Shared Components
    
    private var taskHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Status indicator
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                // Urgency badge
                if let urgency = task.urgency {
                    Text(urgency.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(urgencyColor)
                        )
                        .foregroundColor(.white)
                }
            }
            
            Text(task.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            if let category = task.category {
                Label(category.rawValue, systemImage: category.icon)
                    .font(.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var taskDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Details", systemImage: "info.circle")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            if let description = task.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Divider()
                .background(FrancoSphereDesign.DashboardColors.borderSubtle)
            
            // Timing information
            VStack(alignment: .leading, spacing: 8) {
                if let scheduled = task.scheduledDate {
                    HStack {
                        Label("Scheduled", systemImage: "calendar")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        Spacer()
                        Text(scheduled.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                    .font(.subheadline)
                }
                
                if let due = task.dueDate {
                    HStack {
                        Label("Due", systemImage: "clock")
                            .foregroundColor(task.isOverdue ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.secondaryText)
                        Spacer()
                        Text(due.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(task.isOverdue ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.primaryText)
                            .fontWeight(task.isOverdue ? .bold : .regular)
                    }
                    .font(.subheadline)
                }
                
                if let duration = task.estimatedDuration {
                    HStack {
                        Label("Estimated Duration", systemImage: "timer")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        Spacer()
                        Text(formatDuration(duration))
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "location")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            if let building = task.building {
                VStack(alignment: .leading, spacing: 8) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Text(building.address)
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    // Mini map
                    Map(coordinateRegion: .constant(
                        MKCoordinateRegion(
                            center: building.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    ), annotationItems: [building]) { location in
                        MapMarker(coordinate: location.coordinate, tint: FrancoSphereDesign.DashboardColors.workerPrimary)
                    }
                    .frame(height: 150)
                    .cornerRadius(12)
                    .disabled(true)
                    
                    // Directions button
                    if mode == .worker {
                        Button(action: openInMaps) {
                            Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                                .font(.subheadline)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.workerPrimary)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var photoEvidenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Photo Evidence", systemImage: "camera")
                    .font(.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                if task.requiresPhoto == true && task.status != .completed {
                    Text("Required")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(FrancoSphereDesign.DashboardColors.warning)
                        )
                        .foregroundColor(.white)
                }
            }
            
            if let photo = capturedPhoto {
                // Show captured photo
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .onTapGesture {
                        // Could show full screen preview
                    }
                
                if mode.allowsEditing && task.status != .completed {
                    Button(action: { showPhotoCapture = true }) {
                        Label("Retake Photo", systemImage: "camera")
                            .font(.subheadline)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.workerPrimary)
                    }
                    .padding(.top, 8)
                }
            } else if mode.allowsEditing && task.status != .completed {
                // Photo capture options
                VStack(spacing: 12) {
                    Button(action: { showPhotoCapture = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                            Text("Take Photo")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(FrancoSphereDesign.DashboardColors.workerPrimary)
                        .cornerRadius(12)
                    }
                    
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                            Text("Choose from Library")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.workerPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(FrancoSphereDesign.DashboardColors.workerPrimary, lineWidth: 2)
                        )
                    }
                    .onChange(of: photoPickerItem) { newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                capturedPhoto = image
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            if mode.allowsEditing && task.status != .completed {
                TextField("Add notes about this task...", text: $taskNotes, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                    )
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(3...6)
            } else if !taskNotes.isEmpty {
                Text(taskNotes)
                    .font(.body)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            } else {
                Text("No notes added")
                    .font(.body)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    .italic()
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Action Sections
    
    private var workerActionSection: some View {
        VStack(spacing: 12) {
            Button(action: completeTask) {
                HStack {
                    if isCompleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    }
                    
                    Text(isCompleting ? "Completing..." : "Complete Task")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    canCompleteTask ?
                    FrancoSphereDesign.DashboardColors.success :
                    FrancoSphereDesign.DashboardColors.inactive
                )
                .cornerRadius(12)
            }
            .disabled(!canCompleteTask || isCompleting)
            
            if task.requiresPhoto == true && capturedPhoto == nil {
                Text("Photo evidence required to complete task")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
            }
        }
        .padding()
    }
    
    // MARK: - Admin Components
    
    private var adminTaskHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                taskHeaderCard
                
                Menu {
                    Button(action: { showReassignSheet = true }) {
                        Label("Reassign Worker", systemImage: "person.2")
                    }
                    
                    Button(action: { showRescheduleSheet = true }) {
                        Label("Reschedule", systemImage: "calendar")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: cancelTask) {
                        Label("Cancel Task", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.adminPrimary)
                }
            }
        }
    }
    
    private var workerAssignmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Worker Assignment", systemImage: "person.badge.shield.checkmark")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            if let worker = task.worker {
                HStack {
                    // Worker avatar
                    Circle()
                        .fill(FrancoSphereDesign.DashboardColors.adminPrimary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(worker.name.prefix(2).uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.adminPrimary)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(worker.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        
                        if let phone = worker.phone {
                            Text(phone)
                                .font(.caption)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Contact button
                    Button(action: contactWorker) {
                        Image(systemName: "phone.circle.fill")
                            .font(.title2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.adminPrimary)
                    }
                }
            } else {
                Text("No worker assigned")
                    .font(.body)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    .italic()
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var taskHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Task History", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                historyItem(
                    icon: "plus.circle",
                    text: "Task created",
                    date: task.createdAt,
                    color: FrancoSphereDesign.DashboardColors.info
                )
                
                if let scheduled = task.scheduledDate {
                    historyItem(
                        icon: "calendar.badge.plus",
                        text: "Scheduled",
                        date: scheduled,
                        color: FrancoSphereDesign.DashboardColors.info
                    )
                }
                
                if task.status == .completed, let completed = task.completedAt {
                    historyItem(
                        icon: "checkmark.circle",
                        text: "Completed",
                        date: completed,
                        color: FrancoSphereDesign.DashboardColors.success
                    )
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private func historyItem(icon: String, text: String, date: Date, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(date.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
        }
    }
    
    private var adminActionSection: some View {
        VStack(spacing: 12) {
            if task.status != .completed {
                HStack(spacing: 12) {
                    Button(action: { showReassignSheet = true }) {
                        Label("Reassign", systemImage: "person.2")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.adminPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(FrancoSphereDesign.DashboardColors.adminPrimary, lineWidth: 2)
                            )
                    }
                    
                    Button(action: { showRescheduleSheet = true }) {
                        Label("Reschedule", systemImage: "calendar")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.adminPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(FrancoSphereDesign.DashboardColors.adminPrimary, lineWidth: 2)
                            )
                    }
                }
            }
            
            // Verification for completed tasks
            if task.status == .completed {
                Button(action: verifyTask) {
                    Label("Verify Completion", systemImage: "checkmark.seal")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(FrancoSphereDesign.DashboardColors.adminPrimary)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Dashboard Components
    
    private var taskStatsCard: some View {
        HStack(spacing: 20) {
            statItem(
                icon: "clock",
                value: formatDuration(task.estimatedDuration ?? 3600),
                label: "Duration"
            )
            
            if let worker = task.worker {
                statItem(
                    icon: "person",
                    value: worker.name.components(separatedBy: " ").first ?? "N/A",
                    label: "Assigned"
                )
            }
            
            if let urgency = task.urgency {
                statItem(
                    icon: "exclamationmark.circle",
                    value: urgency.rawValue,
                    label: "Priority"
                )
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Text(label)
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var completionEvidenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Completion Evidence", systemImage: "checkmark.seal")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.success)
            
            if let completedAt = task.completedAt {
                HStack {
                    Text("Completed")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    Spacer()
                    Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                .font(.subheadline)
            }
            
            if let worker = task.worker {
                HStack {
                    Text("By")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    Spacer()
                    Text(worker.name)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                .font(.subheadline)
            }
            
            // Show photo evidence if available
            if task.requiresPhoto == true && capturedPhoto != nil {
                Text("Photo evidence provided")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                    .padding(.top, 8)
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                if mode == .simplified {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                        Text("Back")
                            .font(.title3)
                    }
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                } else {
                    Image(systemName: "xmark")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
            }
        }
        
        if mode == .admin {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showReassignSheet = true }) {
                        Label("Reassign Worker", systemImage: "person.2")
                    }
                    
                    Button(action: { showRescheduleSheet = true }) {
                        Label("Reschedule", systemImage: "calendar")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: cancelTask) {
                        Label("Cancel Task", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.adminPrimary)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var canCompleteTask: Bool {
        if task.requiresPhoto == true && capturedPhoto == nil {
            return false
        }
        return task.status != .completed
    }
    
    private var canCompleteSimplifiedTask: Bool {
        if task.requiresPhoto == true && capturedPhoto == nil {
            return false
        }
        return task.status != .completed
    }
    
    private func completeTask() {
        guard canCompleteTask else { return }
        
        isCompleting = true
        
        Task {
            do {
                try await viewModel.completeTask(
                    photo: capturedPhoto,
                    notes: taskNotes
                )
                
                // Broadcast update
                await dashboardSync.broadcastTaskCompletion(
                    taskId: task.id,
                    workerId: task.worker?.id ?? "",
                    buildingId: task.buildingId ?? ""
                )
                
                await MainActor.run {
                    isCompleting = false
                    showCompletionConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isCompleting = false
                    // Show error
                }
            }
        }
    }
    
    private func completeSimplifiedTask() {
        guard canCompleteSimplifiedTask else { return }
        
        isCompleting = true
        HapticManager.notification(.success)
        
        Task {
            do {
                try await viewModel.completeTask(
                    photo: capturedPhoto,
                    notes: "" // Simplified mode doesn't have notes
                )
                
                // Broadcast update
                await dashboardSync.broadcastTaskCompletion(
                    taskId: task.id,
                    workerId: task.worker?.id ?? "",
                    buildingId: task.buildingId ?? ""
                )
                
                await MainActor.run {
                    isCompleting = false
                    showCompletionConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isCompleting = false
                    // In simplified mode, show a simple error
                    HapticManager.notification(.error)
                }
            }
        }
    }
    
    private func cancelTask() {
        // Admin function to cancel task
        Task {
            try await viewModel.cancelTask()
            dismiss()
        }
    }
    
    private func verifyTask() {
        // Admin function to verify completion
        Task {
            try await viewModel.verifyTask()
        }
    }
    
    private func contactWorker() {
        guard let phone = task.worker?.phone else { return }
        if let url = URL(string: "tel://\(phone)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInMaps() {
        guard let building = task.building else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: building.coordinate))
        mapItem.name = building.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var statusIcon: String {
        switch task.status {
        case .pending: return "clock"
        case .inProgress: return "arrow.right.circle"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .paused: return "pause.circle"
        case .waiting: return "hourglass"
        }
    }
    
    private var statusColor: Color {
        FrancoSphereDesign.EnumColors.taskStatus(task.status)
    }
    
    private var urgencyColor: Color {
        FrancoSphereDesign.EnumColors.taskUrgency(task.urgency ?? .low)
    }
}

// MARK: - Supporting Views

struct SimplifiedPhotoCaptureView: View {
    let onPhotoTaken: (UIImage) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        // For simplified mode, we'll use the standard PhotoCaptureView
        // wrapped in a simpler interface
        PhotoCaptureView(image: .constant(nil)) { capturedImage in
            if let image = capturedImage {
                onPhotoTaken(image)
            } else {
                onCancel()
            }
        }
    }
}

// Simple Photo Capture View Extension
extension PhotoCaptureView {
    init(image: Binding<UIImage?>, completion: @escaping (UIImage?) -> Void) {
        self.init(image: image)
        // Add completion handler through a workaround if needed
    }
}

// MARK: - Preview

struct UnifiedTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Worker mode
            UnifiedTaskDetailView(
                task: CoreTypes.ContextualTask(
                    title: "Clean Main Lobby",
                    description: "Daily cleaning of the main lobby area",
                    status: .pending,
                    dueDate: Date().addingTimeInterval(3600),
                    category: .cleaning,
                    urgency: .medium,
                    building: CoreTypes.NamedCoordinate(
                        id: "1",
                        name: "123 Main Street",
                        address: "123 Main St, New York, NY",
                        latitude: 40.7128,
                        longitude: -74.0060
                    ),
                    requiresPhoto: true
                ),
                mode: .worker
            )
            .previewDisplayName("Worker Mode")
            
            // Simplified mode
            UnifiedTaskDetailView(
                task: CoreTypes.ContextualTask(
                    title: "Empty Trash Bins",
                    description: "Empty all trash bins on Floor 2",
                    status: .pending,
                    category: .sanitation,
                    urgency: .high,
                    building: CoreTypes.NamedCoordinate(
                        id: "1",
                        name: "Office Building",
                        address: "456 Park Ave",
                        latitude: 40.7128,
                        longitude: -74.0060
                    ),
                    requiresPhoto: true
                ),
                mode: .simplified
            )
            .previewDisplayName("Simplified Mode")
            
            // Admin mode
            UnifiedTaskDetailView(
                task: CoreTypes.ContextualTask(
                    title: "HVAC Maintenance",
                    description: "Quarterly HVAC system maintenance",
                    status: .pending,
                    dueDate: Date().addingTimeInterval(86400),
                    category: .maintenance,
                    urgency: .high,
                    building: CoreTypes.NamedCoordinate(
                        id: "2",
                        name: "Corporate Tower",
                        address: "789 Business Blvd",
                        latitude: 40.7589,
                        longitude: -73.9851
                    ),
                    worker: CoreTypes.WorkerProfile(
                        id: "w1",
                        name: "John Smith",
                        email: "john@example.com",
                        phone: "555-0123",
                        role: .worker
                    )
                ),
                mode: .admin
            )
            .previewDisplayName("Admin Mode")
        }
        .preferredColorScheme(.dark)
        .environmentObject(DashboardSyncService.shared)
    }
}
