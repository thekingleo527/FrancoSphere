import Foundation
import CoreLocation

// Models/Core/CoreTypes.swift

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

        // ✅ FIX: Manually implement Equatable conformance.
        // We only need to compare the unique 'id' to determine if two buildings are the same.
        public static func == (lhs: Building, rhs: Building) -> Bool {
            return lhs.id == rhs.id
        }

        // ✅ FIX: Manually implement Hashable conformance.
        // We only need to hash the unique 'id'.
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
