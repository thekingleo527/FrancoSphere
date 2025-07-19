// FILE: Components/Shared Components/Building.swift
//
//  Building.swift
//  FrancoSphere
//
//  ✅ PHASE-2 COMPILATION FIX - Uses ONLY real-world building data
//  ✅ No mock data - references actual buildings from OperationalDataManager
//  ✅ Uses existing NamedCoordinate as canonical building model
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import CoreLocation
// FrancoSphere Types Import
// (This comment helps identify our import)

// MARK: - Building Model Extensions

extension NamedCoordinate {
    
    /// Display name with fallback
    var displayName: String {
        return name.isEmpty ? "Building \(id)" : name
    }
    
    /// Short name for UI constraints (8 chars max)
    var shortName: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0]) \(words[1])".prefix(8).description
        }
        return String(name.prefix(8))
    }
    
    /// Building address from real OperationalDataManager dataset (no redeclaration)
    var fullAddress: String {
        // Extract address from actual building names in OperationalDataManager
        switch name {
        case "131 Perry Street": return "131 Perry Street, New York, NY"
        case "68 Perry Street": return "68 Perry Street, New York, NY"
        case "135–139 West 17th": return "135–139 West 17th Street, New York, NY"
        case "136 West 17th": return "136 West 17th Street, New York, NY"
        case "138 West 17th Street": return "138 West 17th Street, New York, NY"
        case "117 West 17th Street": return "117 West 17th Street, New York, NY"
        case "112 West 18th Street": return "112 West 18th Street, New York, NY"
        case "29–31 East 20th": return "29–31 East 20th Street, New York, NY"
        case "123 1st Ave": return "123 1st Avenue, New York, NY"
        case "178 Spring": return "178 Spring Street, New York, NY"
        case "Rubin Museum (142–148 W 17th)": return "142–148 West 17th Street, New York, NY"
        case "104 Franklin": return "104 Franklin Street, New York, NY"
        case "Stuyvesant Cove Park": return "Stuyvesant Cove Park, New York, NY"
        case "133 East 15th Street": return "133 East 15th Street, New York, NY"
        case "FrancoSphere HQ": return "FrancoSphere Headquarters, New York, NY"
        case "12 West 18th Street": return "12 West 18th Street, New York, NY"
        case "36 Walker": return "36 Walker Street, New York, NY"
        case "41 Elizabeth Street": return "41 Elizabeth Street, New York, NY"
        case "115 7th Ave": return "115 7th Avenue, New York, NY"
        default: return "\(name), New York, NY"
        }
    }
    
    /// Distance from another coordinate
    func distance(from other: NamedCoordinate) -> Double {
        let fromLocation = CLLocation(latitude: latitude, longitude: longitude)
        let toLocation = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    /// Check if building has required image asset
    var hasValidImageAsset: Bool {
        return !(imageAssetName?.isEmpty ?? true) && imageAssetName != "placeholder"
    }
    
    /// Get fallback image name if primary is missing
    var fallbackImageName: String {
        return hasValidImageAsset ? (imageAssetName ?? "building.2.fill") : "building.2.fill"
    }
}

// MARK: - Array Extensions for Buildings

extension Array where Element == NamedCoordinate {
    
    /// Filter by IDs
    func withIds(_ ids: [String]) -> [NamedCoordinate] {
        return self.filter { ids.contains($0.id) }
    }
    
    /// Find by ID
    func building(withId id: String) -> NamedCoordinate? {
        return self.first { $0.id == id }
    }
    
    /// Sort by distance from coordinate
    func sortedByDistance(from coordinate: CLLocationCoordinate2D) -> [NamedCoordinate] {
        let fromLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return self.sorted { building1, building2 in
            let location1 = CLLocation(latitude: building1.latitude, longitude: building1.longitude)
            let location2 = CLLocation(latitude: building2.latitude, longitude: building2.longitude)
            
            return fromLocation.distance(from: location1) < fromLocation.distance(from: location2)
        }
    }
    
    /// Get center coordinate for map region
    var centerCoordinate: CLLocationCoordinate2D {
        guard !isEmpty else {
            return CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845) // NYC default
        }
        
        let avgLat = self.map(\.latitude).reduce(0, +) / Double(count)
        let avgLon = self.map(\.longitude).reduce(0, +) / Double(count)
        
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
}
