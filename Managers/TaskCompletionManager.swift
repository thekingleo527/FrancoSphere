// FILE: Managers/TaskCompletionManager.swift
//
//  TaskCompletionManager.swift - TYPE CONFLICTS RESOLVED
//  FrancoSphere
//
//  ✅ FIXED: Renamed types to avoid conflicts with existing FrancoSphere types
//  ✅ FIXED: Uses existing ImagePicker component
//  ✅ FIXED: Removed duplicate BuildingStatusManager (uses existing one)
//  ✅ FIXED: Updated to use correct method signatures
//  ✅ FIXED: Cleaned up file structure and removed corrupted code
//

import Foundation
import UIKit
import SwiftUI

// MARK: - ✅ FIXED: Renamed Types to Avoid Conflicts

/// Status of a task verification (renamed to avoid conflict)
enum TaskVerificationStatus {
    case pending
    case verified
    case rejected
}

/// Record of a completed task with verification data (renamed to avoid conflict)
struct TaskVerificationRecord {
    let id: String
    let taskId: String
    let buildingID: String
    let workerId: String
    let completionDate: Date
    let photoPath: String
    var status: TaskVerificationStatus
    var verifierID: String?
    var verificationDate: Date?
}

/// Manages the task completion process, verification, and logging
class TaskCompletionManager {
    static let shared = TaskCompletionManager()
    
    // In-memory storage for task completion records
    // In a real app, this would be stored in a database
    private var taskCompletions: [String: TaskVerificationRecord] = [:]
    
    private init() {
        // Setup work if needed
    }
    
    // MARK: - Task Completion Logging
    
    /// Logs a completed task with photo evidence
    func logTaskCompletion(taskID: String, workerID: String, buildingID: String, photoPath: String) -> TaskVerificationRecord {
        let id = UUID().uuidString
        let timestamp = Date()
        
        // Create a completion record
        let record = TaskVerificationRecord(
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
        
        // ✅ FIXED: Use existing BuildingStatusManager
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
        
        // ✅ FIXED: Use existing BuildingStatusManager
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
        
        // ✅ FIXED: Use existing BuildingStatusManager
        BuildingStatusManager.shared.recalculateStatus(for: record.buildingID)
    }
    
    // MARK: - Query Methods
    
    /// Gets verification status for a task
    func getVerificationStatus(for taskID: String) -> TaskVerificationStatus {
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
    func getPendingVerifications() -> [TaskVerificationRecord] {
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

// MARK: - ✅ FIXED: Photo Uploader View (Clean Implementation)

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
            // ✅ FIXED: Use existing ImagePicker with correct parameters
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
                            .stroke(Color.blue, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("Verification photo required")
                                .font(.headline)
                                .foregroundColor(.white)
                                
                            Text("Take a photo of the completed task")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
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
                .background(Color.blue)
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
