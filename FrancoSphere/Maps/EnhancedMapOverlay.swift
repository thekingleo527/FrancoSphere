//
//  EnhancedMapOverlay.swift
//  FrancoSphere
//
//  ✅ V6.0: Updated to use modern iOS 17+ MapKit APIs
//  ✅ FIXED: All deprecation warnings resolved
//  ✅ ALIGNED: Correct NamedCoordinate initializers
//

import SwiftUI
import MapKit

struct EnhancedMapOverlay: View {
    @Binding var isPresented: Bool
    let buildings: [NamedCoordinate]
    let currentBuildingId: String?
    
    @State private var mapCameraPosition: MapCameraPosition
    @State private var selectedBuilding: NamedCoordinate?
    
    init(isPresented: Binding<Bool>, buildings: [NamedCoordinate], currentBuildingId: String?) {
        self._isPresented = isPresented
        self.buildings = buildings
        self.currentBuildingId = currentBuildingId
        
        // Initialize map camera position based on buildings
        if let boundingRegion = Self.createBoundingRegion(for: buildings) {
            self._mapCameraPosition = State(initialValue: .region(boundingRegion))
        } else {
            // Default NYC region
            let defaultRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7380, longitude: -73.9970),
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
            self._mapCameraPosition = State(initialValue: .region(defaultRegion))
        }
        
        // Set initial selected building
        if let currentId = currentBuildingId,
           let current = buildings.first(where: { $0.id == currentId }) {
            self._selectedBuilding = State(initialValue: current)
        }
    }
    
    var body: some View {
        NavigationView {
            Map(position: $mapCameraPosition, selection: $selectedBuilding) {
                ForEach(buildings) { building in
                    Annotation(building.name, coordinate: building.coordinate) {
                        BuildingAnnotationView(
                            building: building,
                            isCurrentBuilding: building.id == currentBuildingId
                        )
                    }
                    .tag(building)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .navigationTitle("Building Assignments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let selectedBuilding = selectedBuilding {
                    BuildingInfoCard(building: selectedBuilding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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

// MARK: - Building Annotation View

struct BuildingAnnotationView: View {
    let building: NamedCoordinate
    let isCurrentBuilding: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isCurrentBuilding ? "mappin.circle.fill" : "building.2.fill")
                .font(.title2)
                .foregroundStyle(isCurrentBuilding ? .green : .blue)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 30, height: 30)
                )
                .shadow(radius: 3)
            
            Text(building.name)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(4)
        }
    }
}

// MARK: - Building Info Card

struct BuildingInfoCard: View {
    let building: NamedCoordinate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(building.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            if !building.address.isEmpty {
                Label(building.address, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Latitude: \(building.latitude, specifier: "%.4f")", systemImage: "arrow.up")
                    .font(.caption2)
                
                Spacer()
                
                Label("Longitude: \(building.longitude, specifier: "%.4f")", systemImage: "arrow.right")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding()
        .animation(.easeInOut, value: building.id)
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
                longitude: -73.9980
            ),
            NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                address: "12 W 18th St, New York, NY 10011",
                latitude: 40.7390,
                longitude: -73.9925
            ),
            NamedCoordinate(
                id: "2",
                name: "29-31 East 20th Street",
                address: "29-31 E 20th St, New York, NY 10003",
                latitude: 40.7380,
                longitude: -73.9890
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
