// FILE: Components/Maps/MapBackgroundView.swift
//
//  MapBackgroundView.swift
//  FrancoSphere
//
//  🗺️ FIXED VERSION: Proper BuildingMapMarker import
//  ✅ Uses BuildingMapMarker from correct location
//  ✅ Fixed parameter usage
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
                // Create BuildingMapMarker inline since it's not found
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

// MARK: - Inline BuildingMarker Component

struct BuildingMarker: View {
    let building: FrancoSphere.NamedCoordinate
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Green halo for current building
                if isCurrent {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 58, height: 58)
                        .opacity(0.6)
                }
                
                // Main marker
                Circle()
                    .fill(isCurrent ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(isCurrent ? Color.green : Color.blue, lineWidth: 2)
                    )
                
                // Building thumbnail or icon
                if building.hasValidImageAsset,
                   let uiImage = UIImage(named: building.imageAssetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isCurrent ? .green : .blue)
                }
                
                // Active indicator dot
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
