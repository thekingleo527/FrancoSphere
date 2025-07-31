//
//  TaskDetailView.swift
//  FrancoSphere v6.0
//
//  ✅ PRODUCTION READY: Complete task detail interface
//  ✅ PHOTO EVIDENCE: Camera integration with preview
//  ✅ REAL-TIME UPDATES: Progress tracking and sync
//  ✅ GLASS MORPHISM: Beautiful UI with FrancoSphere design
//  ✅ ERROR HANDLING: Comprehensive user feedback
//  ✅ FIXED: Updated deprecated Map API for iOS 17+
//

import SwiftUI
import PhotosUI
import MapKit

struct TaskDetailView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = TaskDetailViewModel()
    @EnvironmentObject var authManager: NewAuthManager
    @Environment(\.dismiss) private var dismiss
    
    let task: CoreTypes.ContextualTask
    
    // UI State
    @State private var showPhotoCapture = false
    @State private var showPhotoLibrary = false
    @State private var showLocationMap = false
    @State private var showResubmitSheet = false
    @State private var resubmissionNotes = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.black,
                    FrancoSphereDesign.DashboardColors.workerPrimary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    taskHeaderCard
                    
                    // Progress Indicator
                    if viewModel.taskProgress != .notStarted {
                        progressCard
                    }
                    
                    // Photo Evidence Section
                    if viewModel.taskProgress != .completed {
                        photoEvidenceCard
                    }
                    
                    // Verification Status
                    if viewModel.verificationStatus != .notRequired {
                        verificationCard
                    }
                    
                    // AI Suggestions (if enabled)
                    if !viewModel.aiSuggestions.isEmpty {
                        aiSuggestionsCard
                    }
                    
                    // Action Buttons
                    if viewModel.taskProgress != .completed {
                        actionButtonsCard
                    }
                    
                    // Completed Info
                    if viewModel.isCompleted {
                        completedInfoCard
                    }
                }
                .padding()
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Task Details")
        .task {
            await viewModel.loadTask(task)
            // Update map region if building coordinate is available
            if let coordinate = viewModel.buildingCoordinate {
                mapRegion = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text(viewModel.successMessage ?? "Task completed successfully")
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
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let item = newValue,
                   let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.capturePhoto(image)
                }
            }
        }
        .sheet(isPresented: $showResubmitSheet) {
            resubmitView
        }
        .sheet(isPresented: $showLocationMap) {
            locationMapView
        }
    }
    
    // MARK: - View Components
    
    private var taskHeaderCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Title and Category
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.taskTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let category = viewModel.taskCategory {
                            Label(category.rawValue.capitalized, systemImage: category.icon)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Urgency Badge
                    if let urgency = viewModel.taskUrgency {
                        Text(urgency.rawValue.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                FrancoSphereDesign.EnumColors.taskUrgency(urgency)
                                    .opacity(0.2)
                            )
                            .foregroundColor(FrancoSphereDesign.EnumColors.taskUrgency(urgency))
                            .cornerRadius(8)
                    }
                }
                
                // Description
                if let description = viewModel.taskDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                
                // Building & Worker Info
                HStack(spacing: 20) {
                    // Building
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Building", systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.buildingName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let address = viewModel.buildingAddress {
                            Text(address)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Worker
                    VStack(alignment: .trailing, spacing: 4) {
                        Label("Assigned To", systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.workerName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                // Due Date
                if let dueDate = viewModel.taskDueDate {
                    HStack {
                        Label("Due", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(dueDate, style: .date)
                            .font(.subheadline)
                        
                        Text(dueDate, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if dueDate < Date() && !viewModel.isCompleted {
                            Text("OVERDUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var progressCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Text("Progress")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(viewModel.taskProgress.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: viewModel.progressPercentage)
                    .progressViewStyle(.linear)
                    .tint(FrancoSphereDesign.DashboardColors.workerPrimary)
                
                if let timeRemaining = viewModel.estimatedTimeRemaining {
                    HStack {
                        Text("Estimated time remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(timeRemaining))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
        }
    }
    
    private var photoEvidenceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Photo Evidence", systemImage: "camera.fill")
                        .font(.headline)
                    
                    if requiresPhoto {
                        Text("Required")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                }
                
                if let photo = viewModel.capturedPhoto {
                    // Photo Preview
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)
                        
                        // Remove button
                        Button {
                            viewModel.capturedPhoto = nil
                            viewModel.photoData = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white, .black.opacity(0.6))
                                .padding(8)
                        }
                    }
                    
                    // Upload Progress
                    if viewModel.isUploadingPhoto {
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.photoUploadProgress)
                                .progressViewStyle(.linear)
                            
                            Text("Uploading photo...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // Capture Options
                    HStack(spacing: 16) {
                        Button {
                            showPhotoCapture = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text("Take Photo")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(12)
                        }
                        
                        Button {
                            showPhotoLibrary = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                Text("Choose Photo")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding()
        }
    }
    
    private var verificationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Verification Status", systemImage: viewModel.verificationStatus.icon)
                        .font(.headline)
                        .foregroundColor(viewModel.verificationStatus.color)
                    
                    Spacer()
                    
                    Text(viewModel.verificationStatus.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.verificationStatus.color)
                }
                
                if let notes = viewModel.verificationNotes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                if viewModel.verificationStatus == .rejected {
                    Button {
                        showResubmitSheet = true
                    } label: {
                        Label("Resubmit with Evidence", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FrancoSphereDesign.DashboardColors.workerPrimary)
                    .padding(.top, 8)
                }
                
                if let verifiedBy = viewModel.verifiedBy,
                   let verifiedAt = viewModel.verifiedAt {
                    HStack {
                        Text("Verified by \(verifiedBy)")
                        Spacer()
                        Text(verifiedAt, style: .relative)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                }
            }
            .padding()
        }
    }
    
    private var aiSuggestionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("AI Suggestions", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.workerAccent)
                    
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(FrancoSphereDesign.DashboardColors.workerAccent)
                }
                
                ForEach(viewModel.aiSuggestions) { suggestion in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(suggestion.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(Int(suggestion.confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(suggestion.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    private var actionButtonsCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                if viewModel.taskProgress == .notStarted {
                    Button {
                        viewModel.startTask()
                    } label: {
                        Label("Start Task", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FrancoSphereDesign.DashboardColors.workerPrimary)
                } else if viewModel.taskProgress != .submitting {
                    Button {
                        Task {
                            await viewModel.completeTask()
                        }
                    } label: {
                        if viewModel.isSubmitting {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                Text("Submitting...")
                            }
                        } else {
                            Label("Complete Task", systemImage: "checkmark.circle.fill")
                        }
                        
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.green)
                    .disabled(viewModel.isSubmitting || (requiresPhoto && viewModel.capturedPhoto == nil))
                }
                
                if viewModel.buildingCoordinate != nil {
                    Button {
                        showLocationMap = true
                    } label: {
                        Label("View on Map", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FrancoSphereDesign.DashboardColors.workerPrimary)
                }
            }
            .padding()
        }
    }
    
    private var completedInfoCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Success Icon
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Task Completed")
                    .font(.title3)
                    .fontWeight(.bold)
                
                if let completedDate = viewModel.completedDate {
                    VStack(spacing: 4) {
                        Text("Completed on")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(completedDate, style: .date)
                            .font(.subheadline)
                        
                        Text(completedDate, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let startTime = viewModel.startTime,
                   let completedDate = viewModel.completedDate {
                    HStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(completedDate.timeIntervalSince(startTime)))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Sheet Views
    
    private var resubmitView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Resubmit Task")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Please provide additional information and evidence for resubmission.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Notes")
                            .font(.headline)
                        
                        TextEditor(text: $resubmissionNotes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                
                if viewModel.capturedPhoto == nil {
                    Button {
                        showPhotoCapture = true
                        showResubmitSheet = false
                    } label: {
                        Label("Add New Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FrancoSphereDesign.DashboardColors.workerPrimary)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await viewModel.resubmitTask(
                            additionalNotes: resubmissionNotes,
                            newPhoto: nil
                        )
                        showResubmitSheet = false
                    }
                } label: {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(FrancoSphereDesign.DashboardColors.workerPrimary)
                .disabled(resubmissionNotes.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showResubmitSheet = false
                }
            )
        }
    }
    
    private var locationMapView: some View {
        NavigationView {
            if let coordinate = viewModel.buildingCoordinate {
                Map {
                    Marker(viewModel.buildingName, coordinate: coordinate)
                        .tint(FrancoSphereDesign.DashboardColors.workerPrimary)
                }
                .mapStyle(.standard(elevation: .realistic))
                .navigationTitle(viewModel.buildingName)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        showLocationMap = false
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var requiresPhoto: Bool {
        guard let category = viewModel.taskCategory else { return false }
        
        switch category {
        case .cleaning, .sanitation, .maintenance, .repair:
            return true
        case .inspection, .security:
            return viewModel.taskUrgency == .high || viewModel.taskUrgency == .critical
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
}

// MARK: - Supporting Views

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - Preview

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskDetailView(
                task: CoreTypes.ContextualTask(
                    id: "1",
                    title: "Clean Main Lobby",
                    description: "Daily cleaning of the main lobby area including floors, windows, and furniture",
                    isCompleted: false,
                    dueDate: Date().addingTimeInterval(3600),
                    category: .cleaning,
                    urgency: .high,
                    buildingId: "14",
                    assignedWorkerId: "4"
                )
            )
            .environmentObject(NewAuthManager.shared)
        }
    }
}
