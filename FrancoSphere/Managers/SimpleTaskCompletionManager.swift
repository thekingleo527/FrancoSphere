//
//  SimpleTaskCompletionManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/30/25.
//


// Add to Managers folder as SimpleTaskCompletionManager.swift
import Foundation
import UIKit

// Simple manager to handle task completions
class SimpleTaskCompletionManager {
    static let shared = SimpleTaskCompletionManager()
    
    // In-memory storage for verification records
    private var completionRecords: [String: VerificationRecord] = [:]
    
    private init() {}
    
    // Save photo and log completion
    func completeTask(taskID: String, buildingID: String, workerID: String, image: UIImage) -> VerificationRecord? {
        // Save the image
        guard let photoPath = savePhoto(image, forTask: taskID) else {
            return nil
        }
        
        // Create verification record
        let record = VerificationRecord(
            taskId: taskID,
            buildingID: buildingID,
            workerId: workerID,
            photoPath: photoPath
        )
        
        // Store it
        completionRecords[taskID] = record
        return record
    }
    
    // Get verification status for a task
    func getVerificationStatus(for taskID: String) -> VerificationStatus? {
        return completionRecords[taskID]?.status
    }
    
    // Get photo path for a task
    func getPhotoPath(for taskID: String) -> String? {
        return completionRecords[taskID]?.photoPath
    }
    
    // Save a photo to disk
    private func savePhoto(_ image: UIImage, forTask taskID: String) -> String? {
        let fileName = "task_\(taskID)_\(Int(Date().timeIntervalSince1970)).jpg"
        
        // Get documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Convert to JPEG and save
        if let data = image.jpegData(compressionQuality: 0.8) {
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
}