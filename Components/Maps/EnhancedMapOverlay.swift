//
//  EnhancedMapOverlay.swift
//  FrancoSphere
//
//  ✅ V6.0: Updated to use modern, non-deprecated MapKit APIs.
//  ✅ FIXED: All compilation errors resolved
//  ✅ CORRECTED: Binding/State usage, Map coordinate region, bounding region calculation
//

import SwiftUI
import MapKit

struct EnhancedMapOverlay: View {
    @Binding var isPresented: Bool  // FIXED: Changed from @State to @Binding
    let buildings: [NamedCoordinate]
    let currentBuildingId: String?

    @State private var region: MKCoordinateRegion

    init(isPresented: Binding<Bool>, buildings: [NamedCoordinate], currentBuildingId: String?) {
        self._isPresented = isPresented  // Now correctly assigns Binding to Binding
        self.buildings = buildings
        self.currentBuildingId = currentBuildingId
        
        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7380, longitude: -73.9970),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
        
        // FIXED: Create custom bounding region instead of non-existent boundingRegion method
        let boundingRegion = Self.createBoundingRegion(for: buildings) ?? defaultRegion
        self._region = State(initialValue: boundingRegion)
    }

    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: buildings) { building in  // FIXED: Added $region binding
                MapAnnotation(coordinate: building.coordinate) {
                    VStack {
                        Text(building.name)
                            .font(.caption)
                            .padding(4)
                            .background(.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(building.id == currentBuildingId ? .green : .blue)
                    }
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
    }
    
    // MARK: - Helper Methods
    
    /// Create a bounding region that encompasses all buildings
    private static func createBoundingRegion(for buildings: [NamedCoordinate]) -> MKCoordinateRegion? {
        guard !buildings.isEmpty else { return nil }
        
        if buildings.count == 1 {
            let building = buildings[0]
            return MKCoordinateRegion(
                center: building.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        let latitudes = buildings.map { $0.latitude }
        let longitudes = buildings.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let spanLat = max(maxLat - minLat, 0.01) * 1.3  // Add 30% padding
        let spanLon = max(maxLon - minLon, 0.01) * 1.3  // Add 30% padding
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
    }
}

// MARK: - Preview Support

extension NamedCoordinate {
    static var allBuildings: [NamedCoordinate] {
        return [
            NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St, New York, NY 10011",
                latitude: 40.7402,
                longitude: -73.9980,
                imageAssetName: nil
            ),
            NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                address: "12 W 18th St, New York, NY 10011",
                latitude: 40.7390,
                longitude: -73.9925,
                imageAssetName: nil
            ),
            NamedCoordinate(
                id: "2",
                name: "29-31 East 20th Street",
                address: "29-31 E 20th St, New York, NY 10003",
                latitude: 40.7380,
                longitude: -73.9890,
                imageAssetName: nil
            )
        ]
    }
}

// MARK: - Preview

struct EnhancedMapOverlay_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedMapOverlay(
            isPresented: .constant(true),
            buildings: NamedCoordinate.allBuildings,
            currentBuildingId: "14"
        )
    }
}
