//
//  ActionEvidence.swift
//  FrancoSphere
//

import Foundation

public struct ActionEvidence: Codable, Hashable, Equatable {
    public enum EvidenceType: String, Codable { case photo, text, location, signature }
    public struct Location: Codable, Hashable, Equatable {
        public let latitude, longitude, accuracy: Double
    }
    public let id: String
    public let taskId: String
    public let workerId: String
    public let timestamp: Date
    public let evidenceType: EvidenceType
    public let photos: [Data]
    public let notes: String?
    public let location: Location?
}
