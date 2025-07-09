//
//  ActionEvidence.swift
//  FrancoSphere
//
//  Task completion evidence model
//

import Foundation

public struct ActionEvidence: Codable {
    public let photos: [Data]
    public let notes: String?
    public let location: (latitude: Double, longitude: Double)?
    public let timestamp: Date

    public init(
        photos: [Data] = [],
        notes: String? = nil,
        location: (latitude: Double, longitude: Double)? = nil,
        timestamp: Date = Date()
    ) {
        self.photos = photos
        self.notes = notes
        self.location = location
        self.timestamp = timestamp
    }
}
