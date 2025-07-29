//
//  MapBackgroundView.swift
//  FrancoSphere
//
//  ✅ V6.0 FIXED: Updated with proper Map API usage
//  ✅ FIXED: Removed non-existent imageAssetName reference
//  ✅ FIXED: Correct syntax for both old and new Map APIs
//

import SwiftUI
import MapKit

struct MapBackgroundView: View {
    let buildings: [NamedCoordinate]
    @Binding var region: MKCoordinateRegion
    let currentBuildingId: String?
    let onBuildingTap: ((NamedCoordinate) -> Void)?

    var body: some View {
        Map(coordinateRegion: $region,
            annotationItems: buildings) { building in
            MapAnnotation(coordinate: building.coordinate) {
                BuildingMarker(
                    building: building,
                    isCurrent: currentBuildingId == building.id,
                    onTap: { onBuildingTap?(building) }
                )
            }
        }
        .allowsHitTesting(onBuildingTap != nil)
    }
}

// MARK: - Building Marker Component

private struct BuildingMarker: View {
    let building: NamedCoordinate
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isCurrent {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 58, height: 58)
                        .opacity(0.6)
                }

                Circle()
                    .fill(isCurrent ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle().stroke(isCurrent ? Color.green : Color.blue, lineWidth: 2)
                    )

                // Use building-specific icon based on name
                buildingIcon
                    .font(.system(size: 20))
                    .foregroundColor(isCurrent ? .green : .blue)

                if isCurrent {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .offset(x: 19, y: -19)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 12, height: 12)
                                .offset(x: 19, y: -19)
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isCurrent ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCurrent)
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    // Building-specific icons based on name
    @ViewBuilder
    private var buildingIcon: some View {
        let name = building.name.lowercased()
        
        if name.contains("museum") || name.contains("rubin") {
            Image(systemName: "building.columns.fill")
        } else if name.contains("park") || name.contains("cove") {
            Image(systemName: "tree.fill")
        } else if name.contains("office") || name.contains("hq") {
            Image(systemName: "building.fill")
        } else if name.contains("perry") || name.contains("elizabeth") {
            Image(systemName: "house.fill")
        } else {
            Image(systemName: "building.2.fill")
        }
    }
}

// MARK: - Modern Map View Wrapper (iOS 17+)
// Use this wrapper if you want to suppress deprecation warnings

struct ModernMapWrapper: View {
    let buildings: [NamedCoordinate]
    @Binding var region: MKCoordinateRegion
    let currentBuildingId: String?
    let onBuildingTap: ((NamedCoordinate) -> Void)?
    
    var body: some View {
        if #available(iOS 17.0, *) {
            modernMap
        } else {
            MapBackgroundView(
                buildings: buildings,
                region: $region,
                currentBuildingId: currentBuildingId,
                onBuildingTap: onBuildingTap ?? { _ in }
            )
        }
    }
    
    @available(iOS 17.0, *)
    private var modernMap: some View {
        Map(initialPosition: .region(region)) {
            ForEach(buildings, id: \.id) { building in
                Annotation(building.name, coordinate: building.coordinate) {
                    BuildingMarker(
                        building: building,
                        isCurrent: currentBuildingId == building.id,
                        onTap: { onBuildingTap?(building) }
                    )
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .allowsHitTesting(onBuildingTap != nil)
        .onMapCameraChange { context in
            region = context.region
        }
    }
}

// MARK: - Convenience Initializers

extension MapBackgroundView {
    init(buildings: [NamedCoordinate],
         region: Binding<MKCoordinateRegion>,
         currentBuildingId: String? = nil) {
        self.buildings = buildings
        self._region = region
        self.currentBuildingId = currentBuildingId
        self.onBuildingTap = nil
    }

    init(buildings: [NamedCoordinate],
         region: Binding<MKCoordinateRegion>,
         currentBuildingId: String? = nil,
         onBuildingTap: @escaping (NamedCoordinate) -> Void) {
        self.buildings = buildings
        self._region = region
        self.currentBuildingId = currentBuildingId
        self.onBuildingTap = onBuildingTap
    }
}

// MARK: - Preview Provider

struct MapBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        MapBackgroundView(
            buildings: [
                NamedCoordinate(id: "1", name: "Rubin Museum", latitude: 40.7395, longitude: -73.9972),
                NamedCoordinate(id: "2", name: "Perry Street", latitude: 40.7355, longitude: -74.0029),
                NamedCoordinate(id: "3", name: "Stuyvesant Cove Park", latitude: 40.7322, longitude: -73.9750)
            ],
            region: .constant(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7355, longitude: -73.9900),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )),
            currentBuildingId: "1"
        )
    }
}
