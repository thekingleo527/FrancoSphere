//
//  MapOverlayView.swift
//  FrancoSphere
//
//  🗺️ FIXED VERSION: Gesture Syntax and CGSize Issues Resolved
//  ✅ FIXED: CGSize.y -> CGSize.height (lines 55, 63)
//  ✅ FIXED: Malformed gesture syntax with semicolons
//  ✅ Full-screen map overlay with swipe-up gesture activation
//  ✅ All buildings with pulsing marker for focused building
//  ✅ Green halo for current clocked-in building
//  ✅ Drag-down to dismiss with 100pt threshold
//

import SwiftUI
import MapKit

struct MapOverlayView: View {
    let buildings: [FrancoSphere.NamedCoordinate]
    let currentBuildingId: String?
    let focusBuilding: FrancoSphere.NamedCoordinate?
    @Binding var isPresented: Bool
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var dragOffset: CGFloat = 0
    @State private var showBuildingList = false
    @State private var selectedBuilding: FrancoSphere.NamedCoordinate?
    
    private let dismissThreshold: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Full-screen map
            mapView
                .ignoresSafeArea()
            
            // Overlay controls
            VStack {
                // Top controls
                topControls
                
                Spacer()
                
                // Bottom building list toggle
                bottomControls
            }
            .background(.clear)
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // FIXED: Simplified gesture handling to avoid complex expression issues
                    let translation = value.translation.height
                    if translation > 0 {
                        dragOffset = translation
                    }
                }
                .onEnded { value in
                    // FIXED: Break down complex conditional into simpler parts
                    let translation = value.translation.height
                    let shouldDismiss = translation > dismissThreshold
                    
                    if shouldDismiss {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            setupMapPosition()
        }
        .sheet(item: $selectedBuilding) { building in
            BuildingMapDetailView(building: building)
        }
    }
    
    // MARK: - Map View
    
    @ViewBuilder
    private var mapView: some View {
        if #available(iOS 17.0, *) {
            // Modern Map API
            Map(position: $mapPosition) {
                ForEach(buildings, id: \.id) { building in
                    Annotation(building.name, coordinate: building.coordinate) {
                        BuildingMapMarker(
                            building: building,
                            isCurrent: currentBuildingId == building.id,
                            isFocused: focusBuilding?.id == building.id,
                            onTap: { selectedBuilding = building }
                        )
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
        } else {
            // Legacy Map for iOS 16
            Map(coordinateRegion: $region, annotationItems: buildings) { building in
                MapAnnotation(coordinate: building.coordinate) {
                    BuildingMapMarker(
                        building: building,
                        isCurrent: currentBuildingId == building.id,
                        isFocused: focusBuilding?.id == building.id,
                        onTap: { selectedBuilding = building }
                    )
                }
            }
        }
    }
    
    // MARK: - Top Controls
    
    private var topControls: some View {
        HStack {
            // Close button
            Button(action: { isPresented = false }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            // Title
            VStack {
                Text("Building Map")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(buildings.count) buildings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            
            Spacer()
            
            // Building list toggle
            Button(action: { showBuildingList.toggle() }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray)
                .frame(width: 40, height: 4)
                .opacity(0.6)
            
            // Building list
            if showBuildingList {
                buildingListView
            }
            
            // Current location info
            if let currentBuildingId = currentBuildingId,
               let currentBuilding = buildings.first(where: { $0.id == currentBuildingId }) {
                currentLocationCard(currentBuilding)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Building List View
    
    private var buildingListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(buildings, id: \.id) { building in
                    BuildingListCard(
                        building: building,
                        isCurrent: currentBuildingId == building.id,
                        onTap: {
                            selectedBuilding = building
                            focusOnBuilding(building)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 100)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Current Location Card
    
    private func currentLocationCard(_ building: FrancoSphere.NamedCoordinate) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.green)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Currently at:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(building.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button("Details") {
                selectedBuilding = building
            }
            .font(.caption.weight(.medium))
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    
    private func setupMapPosition() {
        guard !buildings.isEmpty else { return }
        
        // Calculate center point and span to show all buildings
        let latitudes = buildings.map { $0.latitude }
        let longitudes = buildings.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLng = longitudes.min() ?? 0
        let maxLng = longitudes.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        
        let latDelta = max(0.01, (maxLat - minLat) * 1.2)
        let lngDelta = max(0.01, (maxLng - minLng) * 1.2)
        
        let newRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
        
        region = newRegion
        
        if #available(iOS 17.0, *) {
            mapPosition = .region(newRegion)
        }
    }
    
    private func focusOnBuilding(_ building: FrancoSphere.NamedCoordinate) {
        let focusRegion = MKCoordinateRegion(
            center: building.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = focusRegion
            if #available(iOS 17.0, *) {
                mapPosition = .region(focusRegion)
            }
        }
    }
}

// MARK: - Building Map Marker

struct BuildingMapMarker: View {
    let building: FrancoSphere.NamedCoordinate
    let isCurrent: Bool
    let isFocused: Bool
    let onTap: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    
    private var markerSize: CGFloat {
        if isCurrent { return 60 }
        if isFocused { return 55 }
        return 50
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Pulsing ring for focused building
                if isFocused {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: markerSize + 10, height: markerSize + 10)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - pulseScale)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                }
                
                // Green halo for current building
                if isCurrent {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: markerSize + 8, height: markerSize + 8)
                        .opacity(0.6)
                }
                
                // Main marker
                Circle()
                    .fill(isCurrent ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                    .frame(width: markerSize, height: markerSize)
                    .overlay(
                        Circle()
                            .stroke(isCurrent ? Color.green : Color.blue, lineWidth: 2)
                    )
                
                // Building icon
                Image(systemName: "building.2.fill")
                    .font(.system(size: markerSize * 0.4))
                    .foregroundColor(isCurrent ? .green : .blue)
            }
            .shadow(radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isFocused {
                pulseScale = 1.2
            }
        }
    }
}

// MARK: - Building List Card

struct BuildingListCard: View {
    let building: FrancoSphere.NamedCoordinate
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isCurrent ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isCurrent ? .green : .blue)
                    )
                
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80, height: 32)
                
                if isCurrent {
                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .frame(width: 90, height: 90)
            .background(isCurrent ? Color.green.opacity(0.05) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrent ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Building Map Detail View

struct BuildingMapDetailView: View {
    let building: FrancoSphere.NamedCoordinate
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Building info
                VStack(spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text(building.name)
                        .font(.title2.weight(.medium))
                        .multilineTextAlignment(.center)
                    
                    Text("Building ID: \(building.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Location details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location Details")
                        .font(.headline)
                    
                    HStack {
                        Text("Latitude:")
                        Spacer()
                        Text("\(building.latitude, specifier: "%.4f")")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Longitude:")
                        Spacer()
                        Text("\(building.longitude, specifier: "%.4f")")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Actions
                VStack(spacing: 12) {
                    Button("View Building Details") {
                        // TODO: Navigate to BuildingDetailView
                        print("Navigate to building details for: \(building.name)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Button("Get Directions") {
                        openInMaps()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Building Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func openInMaps() {
        let coordinate = building.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = building.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// MARK: - Preview

struct MapOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        MapOverlayView(
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
            currentBuildingId: "1",
            focusBuilding: nil,
            isPresented: .constant(true)
        )
    }
}
