//
//  TaskDetailView.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: ContextualTask ambiguity resolved by storing properties
//  ✅ FIXED: PhotosPicker using task modifier
//  ✅ FIXED: Preview with explicit types
//

import SwiftUI
import PhotosUI

struct TaskDetailView: View {
    // Store individual properties to avoid ContextualTask ambiguity
    let taskId: String
    let taskTitle: String
    let taskDescription: String?
    let taskIsCompleted: Bool
    let taskDueDate: Date?
    let taskCategory: CoreTypes.TaskCategory?
    let taskUrgency: CoreTypes.TaskUrgency?
    let taskBuilding: NamedCoordinate?
    let taskWorker: WorkerProfile?
    let taskBuildingId: String?
    let taskAssignedWorkerId: String?
    
    @State private var isCompleted: Bool
    @State private var showingCompletionDialog = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isSubmitting = false
    @State private var showCompletionSuccess = false
    
    // Define verification status locally
    enum LocalVerificationStatus: String {
        case pending  = "Pending Verification"
        case verified = "Verified"
        case rejected = "Verification Failed"
        
        var color: Color {
            switch self {
            case .pending:  return .orange
            case .verified: return .green
            case .rejected: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .pending:  return "clock.fill"
            case .verified: return "checkmark.seal.fill"
            case .rejected: return "xmark.seal.fill"
            }
        }
    }
    
    @State private var verificationStatus: LocalVerificationStatus = .pending
    @Environment(\.presentationMode) var presentationMode
    
    // Generic initializer that accepts any task object with the required properties
    init<T>(task: T) where T: Any {
        // Use Mirror to extract properties dynamically
        let mirror = Mirror(reflecting: task)
        
        // Default values
        var id = UUID().uuidString
        var title = "Unknown Task"
        var description: String? = nil
        var isCompleted = false
        var dueDate: Date? = nil
        var category: CoreTypes.TaskCategory? = nil
        var urgency: CoreTypes.TaskUrgency? = nil
        var building: NamedCoordinate? = nil
        var worker: WorkerProfile? = nil
        var buildingId: String? = nil
        var assignedWorkerId: String? = nil
        
        // Extract values from the task object
        for child in mirror.children {
            switch child.label {
            case "id": id = child.value as? String ?? id
            case "title": title = child.value as? String ?? title
            case "description": description = child.value as? String
            case "isCompleted": isCompleted = child.value as? Bool ?? false
            case "dueDate": dueDate = child.value as? Date
            case "category": category = child.value as? CoreTypes.TaskCategory
            case "urgency": urgency = child.value as? CoreTypes.TaskUrgency
            case "building": building = child.value as? NamedCoordinate
            case "worker": worker = child.value as? WorkerProfile
            case "buildingId": buildingId = child.value as? String
            case "assignedWorkerId": assignedWorkerId = child.value as? String
            default: break
            }
        }
        
        // Assign to properties
        self.taskId = id
        self.taskTitle = title
        self.taskDescription = description
        self.taskIsCompleted = isCompleted
        self.taskDueDate = dueDate
        self.taskCategory = category
        self.taskUrgency = urgency
        self.taskBuilding = building
        self.taskWorker = worker
        self.taskBuildingId = buildingId
        self.taskAssignedWorkerId = assignedWorkerId
        
        _isCompleted = State(initialValue: isCompleted)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Task header
                taskHeaderSection
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Task details
                taskDetailsSection
                
                // Task location and assignment info
                locationAndAssignmentSection
                
                // Photo upload section (only shown when marking complete)
                if showingCompletionDialog && !isCompleted {
                    photoUploadSection
                }
                
                // Verification status (only for completed tasks)
                if isCompleted {
                    verificationStatusSection
                }
                
                // Action buttons
                actionButtonsSection
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Task Details")
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert("Complete Task", isPresented: $showingCompletionDialog) {
            Button("Cancel", role: .cancel) {
                showingCompletionDialog = false
                imageData = nil
            }
            Button("Submit", action: submitTaskCompletion)
                .disabled(imageData == nil)
        } message: {
            Text("Please add a photo to verify task completion.")
        }
        .alert("Task Completed", isPresented: $showCompletionSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your task has been submitted for verification.")
        }
    }
    
    // MARK: - Task Header Section
    
    private var taskHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(taskTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                statusBadge
            }
            
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.blue)
                Text(getBuildingName())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("Scheduled", systemImage: "calendar")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
    }
    
    private var statusBadge: some View {
        HStack {
            Circle()
                .fill(getStatusColor())
                .frame(width: 8, height: 8)
            Text(getStatusText())
                .font(.caption)
                .foregroundColor(getStatusColor())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(getStatusColor().opacity(0.1))
        .cornerRadius(20)
    }
    
    private func getStatusColor() -> Color {
        if isCompleted {
            return .green
        } else if isPastDue {
            return .red
        } else if isDueSoon {
            return .orange
        } else {
            return .blue
        }
    }
    
    private func getStatusText() -> String {
        if isCompleted {
            return "Completed"
        } else if isPastDue {
            return "Overdue"
        } else if isDueSoon {
            return "Due Soon"
        } else {
            return "Scheduled"
        }
    }
    
    // MARK: - Computed Properties
    
    private var isPastDue: Bool {
        guard let dueDate = taskDueDate else { return false }
        return Date() > dueDate && !isCompleted
    }
    
    private var isDueSoon: Bool {
        guard let dueDate = taskDueDate else { return false }
        return Date().addingTimeInterval(3600) > dueDate
    }
    
    // MARK: - Task Details Section
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                categoryBadge
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(taskDescription ?? "No description available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Schedule")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                scheduleContent
            }
        }
    }
    
    private var categoryBadge: some View {
        HStack {
            Image(systemName: "wrench.fill")
                .foregroundColor(.white)
            Text((taskCategory ?? CoreTypes.TaskCategory.maintenance).rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue)
        .cornerRadius(20)
    }
    
    // MARK: - Schedule Content
    
    private var scheduleContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scheduled Date")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatDate(taskDueDate ?? Date()))
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Location and Assignment Section
    
    private var locationAndAssignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Building: \(getBuildingName())")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Text("Assigned Worker")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 4)
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                
                Text(getWorkerName())
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Photo Upload Section
    
    private var photoUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verification Photo")
                .font(.headline)
                .foregroundColor(.primary)
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Select Photo")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            }
            
            if let imageData = imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            }
        }
        .task(id: selectedItem) {
            if let item = selectedItem {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
    }
    
    // MARK: - Verification Status Section
    
    private var verificationStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verification Status")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: verificationStatus.icon)
                    .foregroundColor(verificationStatus.color)
                    .font(.system(size: 20))
                
                Text(verificationStatus.rawValue)
                    .font(.subheadline)
                    .foregroundColor(verificationStatus.color)
                
                Spacer()
                
                if verificationStatus == .pending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .background(verificationStatus.color.opacity(0.1))
            .cornerRadius(8)
            
            if let photoPath = getCompletionPhotoPath(),
               let uiImage = UIImage(contentsOfFile: photoPath) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completion Photo")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if isCompleted {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("This task has been completed")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Text("Completed on \(getCompletionDate())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            } else {
                Button(action: {
                    showingCompletionDialog = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text(isSubmitting ? "SUBMITTING..." : "MARK AS COMPLETE")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(isSubmitting ? Color.gray : Color.green)
                    .cornerRadius(10)
                }
                .disabled(isSubmitting)
                
                if isPastDue {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("This task is past due")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getBuildingName() -> String {
        return taskBuilding?.name ?? "Unknown Building"
    }
    
    private func getWorkerName() -> String {
        if let worker = taskWorker {
            return worker.name
        } else if let workerId = taskAssignedWorkerId {
            return "Worker #\(workerId)"
        } else {
            return "Unassigned"
        }
    }
    
    private func getCompletionDate() -> String {
        if let completionDate = getCompletionTimestamp() {
            return formatDate(completionDate)
        }
        return formatDate(Date())
    }
    
    private func submitTaskCompletion() {
        guard let imageData = imageData else { return }
        
        isSubmitting = true
        
        if let imagePath = saveImageData(imageData) {
            logTaskCompletion(photoPath: imagePath)
            
            isCompleted = true
            verificationStatus = .pending
            
            submitTaskToService()
            
            isSubmitting = false
            showingCompletionDialog = false
            showCompletionSuccess = true
        } else {
            isSubmitting = false
            showingCompletionDialog = false
        }
    }
    
    private func submitTaskToService() {
        Task {
            do {
                // Create ActionEvidence
                let evidence = ActionEvidence(
                    description: "Task completed via mobile app with photo verification",
                    photoURLs: [],
                    timestamp: Date()
                )
                
                // Use correct method signature
                try await TaskService.shared.completeTask(
                    taskId,
                    evidence: evidence
                )
                
                print("✅ Task submitted to TaskService successfully")
                
            } catch {
                print("❌ Error submitting task to TaskService: \(error)")
            }
        }
    }
    
    private func saveImageData(_ data: Data) -> String? {
        let fileName = "task_\(taskId)_\(Int(Date().timeIntervalSince1970)).jpg"
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    // MARK: - Task Completion Helpers
    
    private func logTaskCompletion(photoPath: String) {
        let timestamp = Date()
        
        let completionInfo: [String: Any] = [
            "photoPath": photoPath,
            "timestamp": timestamp,
            "isVerified": 0
        ]
        
        var taskCompletions = UserDefaults.standard.dictionary(forKey: "TaskCompletions") as? [String: [String: Any]] ?? [:]
        taskCompletions[taskId] = completionInfo
        
        UserDefaults.standard.set(taskCompletions, forKey: "TaskCompletions")
    }
    
    private func getCompletionTimestamp() -> Date? {
        guard let taskCompletions = UserDefaults.standard.dictionary(forKey: "TaskCompletions") as? [String: [String: Any]],
              let completionInfo = taskCompletions[taskId],
              let timestamp = completionInfo["timestamp"] as? Date else {
            return nil
        }
        
        return timestamp
    }
    
    private func getCompletionPhotoPath() -> String? {
        guard let taskCompletions = UserDefaults.standard.dictionary(forKey: "TaskCompletions") as? [String: [String: Any]],
              let completionInfo = taskCompletions[taskId],
              let photoPath = completionInfo["photoPath"] as? String else {
            return nil
        }
        
        return photoPath
    }
}

// MARK: - Preview Provider

struct TaskDetailView_Previews: PreviewProvider {
    // Move PreviewTask struct OUTSIDE of the previews property
    struct PreviewTask {
        let id = "preview_1"
        let title = "Sample Task"
        let description: String? = "Sample description for testing"
        let isCompleted = false
        let completedDate: Date? = nil
        let dueDate: Date? = Date().addingTimeInterval(86400)
        let category: CoreTypes.TaskCategory? = CoreTypes.TaskCategory.maintenance
        let urgency: CoreTypes.TaskUrgency? = CoreTypes.TaskUrgency.medium
        let building: NamedCoordinate? = NamedCoordinate(
            id: "1",
            name: "Sample Building",
            address: "123 Main St, Anytown",
            latitude: 40.7128,
            longitude: -74.0060
        )
        let worker: WorkerProfile? = nil
        let buildingId: String? = "1"
        let assignedWorkerId: String? = "4"
    }
    
    static var previews: some View {
        // Now just use PreviewTask here
        NavigationView {
            TaskDetailView(task: PreviewTask())
        }
    }
}
