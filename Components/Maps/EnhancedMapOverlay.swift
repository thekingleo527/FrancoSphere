//
//  EnhancedMapOverlay.swift
//  FrancoSphere
//
//  ✅ V6.0: Gesture Conflict Resolution
//  ✅ Replaces the old MapOverlayView with a more robust, interactive map screen.
//  ✅ Uses a clear "Done" button for dismissal, avoiding gesture conflicts.
//

import SwiftUI
import MapKit

struct EnhancedMapOverlay: View {
    // Data passed in from the parent view
    let buildings: [NamedCoordinate]
    let currentBuildingId: String?
    
    // State for the map's position
    @State private var region: MKCoordinateRegion
    
    // Binding to control the presentation of this view
    @Binding var isPresented: Bool
    
    init(buildings: [NamedCoordinate], currentBuildingId: String?, isPresented: Binding<Bool>) {
        self.buildings = buildings
        self.currentBuildingId = currentBuildingId
        self._isPresented = isPresented
        
        // Initialize the map region to focus on the assigned buildings
        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7380, longitude: -73.9970),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
        self._region = State(initialValue: MKCoordinateRegion.boundingRegion(for: buildings) ?? defaultRegion)
    }
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: buildings) { building in
                MapAnnotation(coordinate: building.coordinate) {
                    BuildingMapAnnotation(
                        building: building,
                        isCurrent: building.id == currentBuildingId
                    )
                }
            }
            .navigationTitle("Building Assignments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom Map Annotation View
private struct BuildingMapAnnotation: View {
    let building: NamedCoordinate
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(building.name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundColor(.white)
                .shadow(radius: 2)

            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundColor(isCurrent ? .green : .blue)
                .background(Circle().fill(Color.white.opacity(0.8)))
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
}


// MARK: - MKCoordinateRegion Helper
extension MKCoordinateRegion {
    /// Creates a region that fits all the provided coordinates.
    static func boundingRegion(for coordinates: [NamedCoordinate]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.4, longitudeDelta: (maxLon - minLon) * 1.4)
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

struct EnhancedMapOverlay_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedMapOverlay(
            buildings: NamedCoordinate.allBuildings.prefix(5).map { $0 },
            currentBuildingId: "3",
            isPresented: .constant(true)
        )
    }
}
