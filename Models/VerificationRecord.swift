//
//  VerificationRecord.swift
//  FrancoSphere
//
//  ✅ FIXED: Implements all required protocols
//

import Foundation

public struct VerificationRecord: Identifiable, Codable, Hashable, Equatable {
    public let id: String
    public let taskId: String
    public let workerId: String
    public let verificationStatus: VerificationStatus
    public let verifiedAt: Date
    public let notes: String?
    public let photoPath: String?
    
    public init(
        id: String = UUID().uuidString,
        taskId: String,
        workerId: String,
        verificationStatus: VerificationStatus,
        verifiedAt: Date = Date(),
        notes: String? = nil,
        photoPath: String? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.workerId = workerId
        self.verificationStatus = verificationStatus
        self.verifiedAt = verifiedAt
        self.notes = notes
        self.photoPath = photoPath
    }
    
    // MARK: - Equatable
    public static func == (lhs: VerificationRecord, rhs: VerificationRecord) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Helper Methods
extension VerificationRecord {
    
    func createCompletionRecord() -> TaskCompletionRecord {
        return TaskCompletionRecord(
            taskId: taskId,
            workerId: workerId,
            completedAt: verifiedAt,
            photoPath: photoPath,
            notes: notes
        )
    }
    
    func updateVerificationStatus(_ newStatus: VerificationStatus) -> VerificationRecord {
        return VerificationRecord(
            id: id,
            taskId: taskId,
            workerId: workerId,
            verificationStatus: newStatus,
            verifiedAt: Date(),
            notes: notes,
            photoPath: photoPath
        )
    }
}
