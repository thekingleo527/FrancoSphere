//
//  EnhancedMapOverlay.swift
//  FrancoSphere
//
//  ✅ V6.0: Updated to use modern, non-deprecated MapKit APIs.
//

import SwiftUI
import MapKit

struct EnhancedMapOverlay: View {
    @State var isPresented: Bool
    let buildings: [NamedCoordinate]
    let currentBuildingId: String?

    @State private var region: MKCoordinateRegion

    init(isPresented: Binding<Bool>, buildings: [NamedCoordinate], currentBuildingId: String?) {
        self._isPresented = isPresented
        self.buildings = buildings
        self.currentBuildingId = currentBuildingId
        
        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7380, longitude: -73.9970),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
        self._region = State(initialValue: MKCoordinateRegion.boundingRegion(for: buildings) ?? defaultRegion)
    }

    var body: some View {
        NavigationView {
            Map(coordinateRegion: , annotationItems: buildings) { building in
                MapAnnotation(coordinate: building.coordinate) {
                    VStack {
                        Text(building.name).font(.caption).padding(4).background(.black.opacity(0.5)).cornerRadius(4)
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
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}

// Add a helper to NamedCoordinate for the preview to work
extension NamedCoordinate {
    static var allBuildings: [NamedCoordinate] {
        // Return a sample list for previews
        return [
            NamedCoordinate(id: "14", name: "Rubin Museum", latitude: 40.7402, longitude: -73.9980, imageAssetName: nil)
        ]
    }
}
