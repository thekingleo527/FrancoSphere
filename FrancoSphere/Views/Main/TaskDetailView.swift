import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem
    @State private var isCompleted: Bool
    @State private var showingCompletionDialog = false
    @State private var image: UIImage?
    @State private var isSubmitting = false
    @State private var showCompletionSuccess = false
    
    // Define verification status locally
    enum VerificationStatus: String {
        case pending = "Pending Verification"
        case verified = "Verified"
        case rejected = "Verification Failed"
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .verified: return .green
            case .rejected: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .verified: return "checkmark.seal.fill"
            case .rejected: return "xmark.seal.fill"
            }
        }
    }
    
    @State private var verificationStatus: VerificationStatus = .pending
    @Environment(\.presentationMode) var presentationMode
    
    init(task: TaskItem) {
        self.task = task
        // Use the task's isCompleted property if it exists, otherwise default to false
        _isCompleted = State(initialValue: false)
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
                
                // Photo upload section (only shown when completing a task)
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
            .background(FrancoSphereColors.primaryBackground)
        }
        .navigationTitle("Task Details")
        .background(FrancoSphereColors.primaryBackground)
        .alert("Complete Task", isPresented: $showingCompletionDialog) {
            Button("Cancel", role: .cancel) {
                showingCompletionDialog = false
                image = nil
            }
            Button("Submit", action: submitTaskCompletion)
                .disabled(image == nil)
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
                Text(task.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(FrancoSphereColors.textPrimary)
                
                Spacer()
                
                statusBadge
            }
            
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(FrancoSphereColors.accentBlue)
                Text(getBuildingName())
                    .font(.subheadline)
                    .foregroundColor(FrancoSphereColors.textSecondary)
                
                Spacer()
                
                // Use a default label if recurrence doesn't exist
                Label("Scheduled", systemImage: "calendar")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FrancoSphereColors.deepNavy)
                    .foregroundColor(FrancoSphereColors.accentBlue)
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
    
    // Helper functions to get status info
    private func getStatusColor() -> Color {
        if isCompleted {
            return .green
        } else if isPastDue() {
            return .red
        } else if isHighPriority() {
            return .orange
        } else {
            return .blue
        }
    }
    
    private func getStatusText() -> String {
        if isCompleted {
            return "Completed"
        } else if isPastDue() {
            return "Overdue"
        } else if isDueSoon() {
            return "Due Soon"
        } else {
            return "Scheduled"
        }
    }
    
    private func isPastDue() -> Bool {
        // If the task is completed, it's not past due
        if isCompleted {
            return false
        }
        // Otherwise, check if current date is past the scheduled date
        return Date() > task.scheduledDate
    }
    
    private func isDueSoon() -> Bool {
        // If scheduledDate is nil, it's not due soon
        if task.scheduledDate == nil {
            return false
        }
        // Otherwise, check if scheduled within the next hour
        return Date().addingTimeInterval(3600) > task.scheduledDate
    }
    
    private func isHighPriority() -> Bool {
        // Adjust to match your priority naming/structure
        return false  // Default to false if no priority field
    }
    
    // MARK: - Task Details Section
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                // Use dummy badges if your model doesn't have category/priority
                categoryBadge
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(FrancoSphereColors.textPrimary)
                
                Text(task.description)
                    .font(.body)
                    .foregroundColor(FrancoSphereColors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FrancoSphereColors.cardBackground)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Schedule")
                    .font(.headline)
                    .foregroundColor(FrancoSphereColors.textPrimary)
                
                scheduleContent
            }
        }
    }
    
    private var categoryBadge: some View {
        HStack {
            Image(systemName: "wrench.fill")
                .foregroundColor(.white)
            Text("Maintenance")  // Default value if no category
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
                    .foregroundColor(FrancoSphereColors.textSecondary)
                Text(formatDate(task.scheduledDate))
                    .font(.body)
                    .foregroundColor(FrancoSphereColors.textPrimary)
            }
            
            Spacer()
        }
        .padding()
        .background(FrancoSphereColors.cardBackground)
        .cornerRadius(8)
    }
    
    // MARK: - Location Section
    
    private var locationAndAssignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .foregroundColor(FrancoSphereColors.textPrimary)
            
            Text("Building: \(getBuildingName())")
                .font(.subheadline)
                .foregroundColor(FrancoSphereColors.textSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FrancoSphereColors.cardBackground)
                .cornerRadius(8)
            
            // If you have worker assignment info
            Text("Assigned Worker")
                .font(.headline)
                .foregroundColor(FrancoSphereColors.textPrimary)
                .padding(.top, 4)
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(FrancoSphereColors.accentBlue)
                
                Text("Worker #\(task.workerId)")
                    .font(.subheadline)
                    .foregroundColor(FrancoSphereColors.textPrimary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FrancoSphereColors.cardBackground)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Photo Upload Section
    
    private var photoUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verification Photo")
                .font(.headline)
                .foregroundColor(FrancoSphereColors.textPrimary)
            
            PhotoUploaderView(image: $image) { selectedImage in
                self.image = selectedImage
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Verification Status Section
    
    private var verificationStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verification Status")
                .font(.headline)
                .foregroundColor(FrancoSphereColors.textPrimary)
            
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
            
            // Show completion photo if available
            if let imagePath = getCompletionPhotoPath(), let uiImage = UIImage(contentsOfFile: imagePath) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completion Photo")
                        .font(.subheadline)
                        .foregroundColor(FrancoSphereColors.textPrimary)
                    
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
                        .foregroundColor(FrancoSphereColors.textSecondary)
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
                
                if isPastDue() {
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
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not scheduled" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getBuildingName() -> String {
        // Use BuildingRepository to get building name
        let buildingIdString = String(task.buildingId)
        return BuildingRepository.shared.getBuildingName(forId: buildingIdString)
    }
    
    private func getCompletionDate() -> String {
        // Fetch the completion timestamp or use the current date as fallback
        if let completionDate = getCompletionTimestamp() {
            return formatDate(completionDate)
        }
        return formatDate(Date())
    }
    
    private func submitTaskCompletion() {
        guard let image = image else { return }
        
        isSubmitting = true
        
        // Save the image to disk
        if let imagePath = saveImage(image) {
            // Log the task completion
            logTaskCompletion(photoPath: imagePath)
            
            // Update local state
            isCompleted = true
            verificationStatus = .pending
            
            // Update the task status in the TaskManager
            let taskIdString = String(task.id)
            TaskManager.shared.toggleTaskCompletion(taskID: taskIdString)
            
            // Show success message
            isSubmitting = false
            showingCompletionDialog = false
            showCompletionSuccess = true
        } else {
            // Handle error saving image
            isSubmitting = false
            showingCompletionDialog = false
        }
    }
    
    private func saveImage(_ image: UIImage) -> String? {
        // Create a unique filename
        let taskIdString = String(task.id)
        let fileName = "task_\(taskIdString)_\(Int(Date().timeIntervalSince1970)).jpg"
        
        // Get the documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Convert UIImage to JPEG data
        if let data = image.jpegData(compressionQuality: 0.8) {
            // Write to disk
            do {
                try data.write(to: fileURL)
                return fileURL.path
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    // MARK: - Task Completion Helpers
    
    private func logTaskCompletion(photoPath: String) {
        // In a real app, this would use your TaskManager
        
        // Convert Int64 to String for UserDefaults
        let taskIdString = String(task.id)
        let timestamp = Date()
        
        let completionInfo: [String: Any] = [
            "photoPath": photoPath,
            "timestamp": timestamp,
            "isVerified": 0 // 0 = pending, 1 = verified, -1 = rejected
        ]
        
        var taskCompletions = UserDefaults.standard.dictionary(forKey: "TaskCompletions") as? [String: [String: Any]] ?? [:]
        taskCompletions[taskIdString] = completionInfo
        
        UserDefaults.standard.set(taskCompletions, forKey: "TaskCompletions")
    }
    
    private func getCompletionTimestamp() -> Date? {
        let taskIdString = String(task.id)
        
        guard let taskCompletions = UserDefaults.standard.dictionary(forKey: "TaskCompletions") as? [String: [String: Any]],
              let completionInfo = taskCompletions[taskIdString],
              let timestamp = completionInfo["timestamp"] as? Date else {
            return nil
        }
        
        return timestamp
    }
    
    private func getCompletionPhotoPath() -> String? {
        let taskIdString = String(task.id)
        
        guard let taskCompletions = UserDefaults.standard.dictionary(forKey: "TaskCompletions") as? [String: [String: Any]],
              let completionInfo = taskCompletions[taskIdString],
              let photoPath = completionInfo["photoPath"] as? String else {
            return nil
        }
        
        return photoPath
    }
}

// MARK: - Preview Provider

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Adjust this to match the constructor for your TaskItem
            let previewTask = TaskItem(
                id: 1,
                name: "Inspect HVAC System",
                description: "Regular maintenance inspection of HVAC units",
                buildingId: 101,
                workerId: 1001,
                isCompleted: false,
                scheduledDate: Date()
            )
            
            TaskDetailView(task: previewTask)
        }
        .preferredColorScheme(.dark)
    }
}
