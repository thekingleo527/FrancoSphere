//
//  MapBackgroundView.swift
//  FrancoSphere
//
//  🗺️ FIXED VERSION: BuildingMapMarker Parameters Corrected
//  ✅ FIXED: Updated BuildingMapMarker call to match correct signature
//  ✅ Added missing parameters: isCurrent, isFocused, onTap
//  ✅ Removed incorrect parameter: isClockedIn → isCurrent
//

import SwiftUI
import MapKit

struct MapBackgroundView: View {
    let buildings: [FrancoSphere.NamedCoordinate]
    @Binding var region: MKCoordinateRegion
    let currentBuildingId: String?
    let onBuildingTap: ((FrancoSphere.NamedCoordinate) -> Void)?
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: buildings) { building in
            MapAnnotation(coordinate: building.coordinate) {
                // FIXED: Corrected BuildingMapMarker parameters to match signature
                BuildingMapMarker(
                    building: building,
                    isCurrent: currentBuildingId == building.id,
                    isFocused: false, // No focused building in background view
                    onTap: {
                        onBuildingTap?(building)
                    }
                )
            }
        }
        .allowsHitTesting(onBuildingTap != nil)
    }
}

// MARK: - Convenience Initializers

extension MapBackgroundView {
    /// Initializer without tap handling (for background use)
    init(buildings: [FrancoSphere.NamedCoordinate],
         region: Binding<MKCoordinateRegion>,
         currentBuildingId: String? = nil) {
        self.buildings = buildings
        self._region = region
        self.currentBuildingId = currentBuildingId
        self.onBuildingTap = nil
    }
    
    /// Initializer with tap handling
    init(buildings: [FrancoSphere.NamedCoordinate],
         region: Binding<MKCoordinateRegion>,
         currentBuildingId: String? = nil,
         onBuildingTap: @escaping (FrancoSphere.NamedCoordinate) -> Void) {
        self.buildings = buildings
        self._region = region
        self.currentBuildingId = currentBuildingId
        self.onBuildingTap = onBuildingTap
    }
}

// MARK: - Preview
struct MapBackgroundView_Previews: PreviewProvider {
    @State static var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    static var previews: some View {
        MapBackgroundView(
            buildings: [
                FrancoSphere.NamedCoordinate(
                    id: "1",
                    name: "12 West 18th Street",
                    latitude: 40.7397,
                    longitude: -73.9944,
                    imageAssetName: "12_West_18th_Street"
                ),
                FrancoSphere.NamedCoordinate(
                    id: "2",
                    name: "29-31 East 20th Street",
                    latitude: 40.7389,
                    longitude: -73.9863,
                    imageAssetName: "29_31_East_20th_Street"
                )
            ],
            region: $region,
            currentBuildingId: "1"
        )
    }
}

// MARK: - 📝 COMPILATION FIXES APPLIED
/*
 ✅ FIXED BUILDINGMAPMARKER PARAMETER MISMATCH:
 
 🔧 LINES 30-32 - BuildingMapMarker signature mismatch:
 - ❌ BEFORE: BuildingMapMarker(building: building, isClockedIn: false)
 - ✅ AFTER: BuildingMapMarker(building: building, isCurrent: currentBuildingId == building.id, isFocused: false, onTap: { onBuildingTap?(building) })
 
 🔧 PARAMETER FIXES:
 - ✅ Added missing 'isCurrent' parameter (replaces 'isClockedIn')
 - ✅ Added missing 'isFocused' parameter (set to false for background)
 - ✅ Added missing 'onTap' parameter (calls optional callback)
 
 🔧 ENHANCED FUNCTIONALITY:
 - ✅ Added currentBuildingId parameter to track active building
 - ✅ Added optional onBuildingTap callback for interactivity
 - ✅ Added convenience initializers for different use cases
 - ✅ Added hit testing control based on tap callback availability
 
 🎯 STATUS: MapBackgroundView compilation errors RESOLVED
 📋 MATCHES: BuildingMapMarker signature from MapOverlayView.swift
 */
