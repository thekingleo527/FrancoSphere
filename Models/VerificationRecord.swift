//
//  VerificationRecord.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/30/25.
//


import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


/// Represents a verification record for a completed task
struct VerificationRecord: Identifiable, Codable, Hashable {
    let id: String
    let taskId: String
    let buildingID: String
    let workerId: String
    let completionDate: Date
    let photoPath: String
    var status: VerificationStatus
    var verifierID: String?
    var verificationDate: Date?
    var notes: String?
    
    init(id: String = UUID().uuidString,
         taskId: String,
         buildingID: String,
         workerId: String,
         completionDate: Date = Date(),
         photoPath: String,
         status: VerificationStatus = .pending,
         verifierID: String? = nil,
         verificationDate: Date? = nil,
         notes: String? = nil) {
        self.id = id
        self.taskId = taskId
        self.buildingID = buildingID
        self.workerId = workerId
        self.completionDate = completionDate
        self.photoPath = photoPath
        self.status = status
        self.verifierID = verifierID
        self.verificationDate = verificationDate
        self.notes = notes
    }
    
    /// Format the completion date for display
    var formattedCompletionDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completionDate)
    }
    
    /// Format the verification date for display (if available)
    var formattedVerificationDate: String? {
        guard let date = verificationDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Add conversion to/from FrancoSphere types if needed
    func toTaskCompletionRecord() -> FrancoSphere.TaskCompletionRecord {
        return FrancoSphere.TaskCompletionRecord(
            id: id,
            taskId: taskId,
            buildingID: buildingID,
            workerId: workerId,
            completionDate: completionDate,
            notes: notes,
            photoPath: photoPath,
            verificationStatus: status,
            verifierID: verifierID,
            verificationDate: verificationDate
        )
    }
    
    static func fromTaskCompletionRecord(_ record: FrancoSphere.TaskCompletionRecord) -> VerificationRecord {
        return VerificationRecord(
            id: record.id,
            taskId: record.taskId,
            buildingID: record.buildingID,
            workerId: record.workerId,
            completionDate: record.completionDate,
            photoPath: record.photoPath ?? "",
            status: record.verificationStatus,
            verifierID: record.verifierID,
            verificationDate: record.verificationDate,
            notes: record.notes
        )
    }
}
