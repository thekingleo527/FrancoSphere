//
//  ActionEvidence.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//
//
//  ActionEvidence.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 1.1 - Comprehensive DTO System
//  ✅ Defines the evidence payload for a worker's actions (photos, location, etc.).
//  ✅ Crucial for the offline queue and data synchronization.
//

import Foundation
import CoreLocation

/// A struct that encapsulates evidence for a worker's action, such as
/// completing a task or submitting a report. This data can be queued
/// for offline synchronization.
public struct ActionEvidence: Codable, Hashable {
    
    /// An optional array of photos, stored as raw Data.
    let photos: [Data]?
    
    /// The GPS coordinate where the action took place.
    /// This uses a Codable wrapper to handle the non-Codable CLLocationCoordinate2D.
    let location: CodableLocationCoordinate2D?
    
    /// Any text-based notes or comments provided by the worker.
    let comments: String?
    
    /// A simple wrapper to make CLLocationCoordinate2D conform to Codable.
    public struct CodableLocationCoordinate2D: Codable, Hashable {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees

        public init(_ coordinate: CLLocationCoordinate2D) {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        }

        public var clLocationCoordinate2D: CLLocationCoordinate2D {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    // Convenience initializer
    public init(photos: [Data]? = nil, location: CLLocationCoordinate2D? = nil, comments: String? = nil) {
        self.photos = photos
        if let location = location {
            self.location = CodableLocationCoordinate2D(location)
        } else {
            self.location = nil
        }
        self.comments = comments
    }
}
