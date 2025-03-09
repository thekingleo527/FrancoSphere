import Foundation
import UIKit
import SwiftUI

/// Manages the task completion process, verification, and logging
class TaskCompletionManager {
    static let shared = TaskCompletionManager()
    
    // In-memory storage for task completion records
    // In a real app, this would be stored in a database
    private var taskCompletions: [String: VerificationRecord] = [:]
    
    private init() {
        // Setup work if needed
    }
    
    // MARK: - Task Completion Logging
    
    /// Logs a completed task with photo evidence
    func logTaskCompletion(taskID: String, workerID: String, buildingID: String, photoPath: String) -> VerificationRecord {
        let id = UUID().uuidString
        let timestamp = Date()
        
        // Create a completion record
        let record = VerificationRecord(
            id: id,
            taskId: taskID,
            buildingID: buildingID,
            workerId: workerID,
            completionDate: timestamp,
            photoPath: photoPath,
            status: .pending
        )
        
        // Store the record
        taskCompletions[taskID] = record
        
        // Notify listeners that a task has been completed
        NotificationCenter.default.post(
            name: NSNotification.Name("TaskCompletionStatusChanged"),
            object: nil,
            userInfo: ["taskID": taskID]
        )
        
        // Update building status
        BuildingStatusManager.shared.recalculateStatus(for: buildingID)
        
        // Schedule auto-verification after 24 hours
        scheduleAutoVerification(taskID: taskID)
        
        return record
    }
    
    /// Verifies a completed task (for supervisors)
    func verifyTaskCompletion(taskID: String, verifierID: String, isApproved: Bool, notes: String? = nil) {
        guard let record = taskCompletions[taskID] else { return }
        
        // Update the record
        var updatedRecord = record
        updatedRecord.status = isApproved ? .verified : .rejected
        updatedRecord.verifierID = verifierID
        updatedRecord.verificationDate = Date()
        
        // Store the updated record
        taskCompletions[taskID] = updatedRecord
        
        // Notify listeners that verification status has changed
        NotificationCenter.default.post(
            name: NSNotification.Name("TaskVerificationStatusChanged"),
            object: nil,
            userInfo: ["taskID": taskID]
        )
        
        // Update building status
        BuildingStatusManager.shared.recalculateStatus(for: record.buildingID)
    }
    
    /// Auto-verifies a task after 24 hours if still pending
    private func scheduleAutoVerification(taskID: String) {
        // In a real app, this would use a more robust scheduling system
        DispatchQueue.global().asyncAfter(deadline: .now() + 86400) { [weak self] in
            self?.autoVerifyIfNeeded(taskID: taskID)
        }
    }
    
    private func autoVerifyIfNeeded(taskID: String) {
        guard let record = taskCompletions[taskID], record.status == .pending else { return }
        
        // Auto-verify
        var updatedRecord = record
        updatedRecord.status = .verified
        updatedRecord.verificationDate = Date()
        
        // Store the updated record
        taskCompletions[taskID] = updatedRecord
        
        // Notify listeners
        NotificationCenter.default.post(
            name: NSNotification.Name("TaskVerificationStatusChanged"),
            object: nil,
            userInfo: ["taskID": taskID]
        )
        
        // Update building status
        BuildingStatusManager.shared.recalculateStatus(for: record.buildingID)
    }
    
    // MARK: - Query Methods
    
    /// Gets verification status for a task
    func getVerificationStatus(for taskID: String) -> VerificationStatus {
        return taskCompletions[taskID]?.status ?? .pending
    }
    
    /// Gets the completion timestamp for a task
    func getCompletionTimestamp(for taskID: String) -> Date? {
        return taskCompletions[taskID]?.completionDate
    }
    
    /// Gets the photo path for a completed task
    func getCompletionPhotoPath(for taskID: String) -> String? {
        return taskCompletions[taskID]?.photoPath
    }
    
    /// Gets all pending verifications
    func getPendingVerifications() -> [VerificationRecord] {
        return taskCompletions.values.filter { $0.status == .pending }
    }
    
    // MARK: - Photo Handling
    
    /// Saves an image and returns the file path
    func saveImage(_ image: UIImage, forTask taskID: String) -> String? {
        // Create a unique filename
        let fileName = "task_\(taskID)_\(Int(Date().timeIntervalSince1970)).jpg"
        
        // Get documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Convert to JPEG and save
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
                return fileURL.path
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
        
        return nil
    }
}

// MARK: - Photo Uploader View
struct PhotoUploaderView: View {
    @Binding var image: UIImage?
    var onPhotoSelected: (UIImage) -> Void
    
    @State private var showImagePicker = false
    @State private var showCameraSheet = false
    @State private var imageSource: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        VStack(spacing: 12) {
            // Display selected image or placeholder
            imagePreview
            
            // Button actions
            buttonRow
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imageSource, selectedImage: $image)
                .onDisappear {
                    if let selectedImage = image {
                        onPhotoSelected(selectedImage)
                    }
                }
        }
        .actionSheet(isPresented: $showCameraSheet) {
            ActionSheet(
                title: Text("Select Photo"),
                message: Text("Choose a source"),
                buttons: [
                    .default(Text("Camera")) {
                        imageSource = .camera
                        showImagePicker = true
                    },
                    .default(Text("Photo Library")) {
                        imageSource = .photoLibrary
                        showImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private var imagePreview: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FrancoSphereColors.accentBlue, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(FrancoSphereColors.cardBackground)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(FrancoSphereColors.accentBlue)
                            
                            Text("Verification photo required")
                                .font(.headline)
                                .foregroundColor(FrancoSphereColors.textSecondary)
                                
                            Text("Take a photo of the completed task")
                                .font(.caption)
                                .foregroundColor(FrancoSphereColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    )
            }
        }
    }
    
    private var buttonRow: some View {
        HStack(spacing: 12) {
            Button(action: {
                showCameraSheet = true
            }) {
                HStack {
                    Image(systemName: image == nil ? "camera.fill" : "arrow.triangle.2.circlepath")
                    Text(image == nil ? "Add Photo" : "Change Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(FrancoSphereColors.accentBlue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .contentShape(Rectangle())
            }
            
            if image != nil {
                Button(action: {
                    image = nil
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Remove")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                }
            }
        }
    }
}
