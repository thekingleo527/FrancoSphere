// Import Models

//
//  VerificationRecord.swift
//  FrancoSphere
//
//  ✅ FIXED: Implements all required protocols
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)


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

// MARK: - Codable Conformance
extension VerificationRecord {
    enum CodingKeys: String, CodingKey {
        case id, taskId, buildingId, workerId, verificationDate, status, notes, photoPaths
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        taskId = try container.decode(String.self, forKey: .taskId)
        buildingId = try container.decode(String.self, forKey: .buildingId)
        workerId = try container.decode(String.self, forKey: .workerId)
        verificationDate = try container.decode(Date.self, forKey: .verificationDate)
        status = try container.decode(VerificationStatus.self, forKey: .status)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        photoPaths = try container.decode([String].self, forKey: .photoPaths)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(taskId, forKey: .taskId)
        try container.encode(buildingId, forKey: .buildingId)
        try container.encode(workerId, forKey: .workerId)
        try container.encode(verificationDate, forKey: .verificationDate)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(photoPaths, forKey: .photoPaths)
    }
}
