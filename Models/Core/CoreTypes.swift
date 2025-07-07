//
//  CoreTypes.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/6/25.
//


import Foundation
import CoreLocation

// Models/CoreTypes.swift

/// The single source of truth for all primary identifier and core data types in FrancoSphere.
/// This eliminates type confusion between String and Int64 for IDs.
public enum CoreTypes {
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String

    public struct Worker: Identifiable, Hashable {
        public let id: WorkerID
        public let name: String
        // Add other core worker properties here as they are standardized.
    }

    public struct Building: Identifiable, Hashable {
        public let id: BuildingID
        public let name: String
        public let coordinate: CLLocationCoordinate2D
         // Add other core building properties here.
    }
}