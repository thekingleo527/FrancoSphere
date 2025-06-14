//
//  MapOverlayView.swift
//  FrancoSphere
//
//  🗺️ FULL-SCREEN MAP OVERLAY WITH SWIPE GESTURE (PHASE-2)
//  ✅ Swipe-up anywhere → Full-screen Map Overlay
//  ✅ Shows all buildings ("My Sites") with pulsing marker for focused building
//  ✅ Green halo for current clocked-in building
//  ✅ Drag down to close with 100pt threshold
//  ✅ Building marker sizing: 50pt default, 60pt current, pulse yellow if focused
//  ✅ Uses existing HapticManager and GlassCard - NO duplicates
//

import SwiftUI
import MapKit
import CoreLocation

struct MapOverlayView: View {
    
    // MARK: - Properties
    let buildings: [FrancoSphere.NamedCoordinate]
    let currentBuildingId: String?
    let focusBuilding: String? // Optional building to highlight with pulsing
    @Binding var isPresented: Bool
    
    // MARK: - State
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845), // NYC center
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Map content
            mapView
                .ignoresSafeArea()
            
            // Overlay controls
            overlayControls
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    // Only allow downward drag
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    isDragging = false
                    
                    // Close if dragged down more than 100pt
                    if value.translation.height > 100 {
                        HapticManager.impact(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    } else {
                        // Snap back to original position
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            updateMapRegion()
        }
    }
    
    // MARK: - Map View
    
    @ViewBuilder
    private var mapView: some View {
        if #available(iOS 17.0, *) {
            Map(initialPosition: .region(region)) {
                ForEach(buildings, id: \.id) { building in
                    Annotation(building.name, coordinate: CLLocationCoordinate2D(
                        latitude: building.latitude,
                        longitude: building.longitude
                    )) {
                        MapBuildingMarker(
                            building: building,
                            isCurrentLocation: building.id == currentBuildingId,
                            isFocused: building.id == focusBuilding
                        )
                        .onTapGesture {
                            handleBuildingTap(building)
                        }
                    }
                }
            }
            .mapStyle(.standard)
        } else {
            Map(
                coordinateRegion: .constant(region),
                annotationItems: buildings
            ) { building in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                )) {
                    MapBuildingMarker(
                        building: building,
                        isCurrentLocation: building.id == currentBuildingId,
                        isFocused: building.id == focusBuilding
                    )
                    .onTapGesture {
                        handleBuildingTap(building)
                    }
                }
            }
        }
    }
    
    // MARK: - Overlay Controls
    
    private var overlayControls: some View {
        VStack {
            // Top controls
            HStack {
                Spacer()
                
                // Close button
                Button(action: {
                    HapticManager.impact(.light)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 60)
                .padding(.trailing, 20)
            }
            
            Spacer()
            
            // Bottom info panel
            bottomInfoPanel
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
    }
    
    // MARK: - Bottom Info Panel
    
    private var bottomInfoPanel: some View {
        VStack(spacing: 12) {
            // Building count and current location
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text("\(buildings.count) Buildings")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Current building indicator
                if let currentId = currentBuildingId,
                   let currentBuilding = buildings.first(where: { $0.id == currentId }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text(getBuildingShortName(currentBuilding.name))
                            .font(.caption.weight(.medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            // Instructions
            HStack {
                Image(systemName: "hand.draw")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Tap markers for details • Drag down to close")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
            }
            
            // Quick stats
            if !buildings.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                HStack(spacing: 20) {
                    mapStatItem(
                        icon: "checkmark.circle.fill",
                        label: "Active",
                        value: currentBuildingId != nil ? "1" : "0",
                        color: .green
                    )
                    
                    mapStatItem(
                        icon: "clock.arrow.circlepath",
                        label: "Available",
                        value: "\(buildings.count - (currentBuildingId != nil ? 1 : 0))",
                        color: .blue
                    )
                    
                    mapStatItem(
                        icon: "location.fill",
                        label: "NYC Area",
                        value: "All",
                        color: .orange
                    )
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Map Stat Item
    
    private func mapStatItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func updateMapRegion() {
        if let focusBuilding = focusBuilding,
           let building = buildings.first(where: { $0.id == focusBuilding }) {
            // Focus on specific building
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        } else if !buildings.isEmpty {
            // Center on all buildings
            let coordinates = buildings.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            
            let center = calculateCenterCoordinate(coordinates)
            let span = calculateSpanToFitCoordinates(coordinates)
            
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    private func calculateCenterCoordinate(_ coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        let totalLat = coordinates.reduce(0) { $0 + $1.latitude }
        let totalLng = coordinates.reduce(0) { $0 + $1.longitude }
        
        return CLLocationCoordinate2D(
            latitude: totalLat / Double(coordinates.count),
            longitude: totalLng / Double(coordinates.count)
        )
    }
    
    private func calculateSpanToFitCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateSpan {
        guard !coordinates.isEmpty else {
            return MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLng = longitudes.min() ?? 0
        let maxLng = longitudes.max() ?? 0
        
        // Add padding around the buildings
        let latDelta = max((maxLat - minLat) * 1.2, 0.01)
        let lngDelta = max((maxLng - minLng) * 1.2, 0.01)
        
        return MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
    }
    
    private func handleBuildingTap(_ building: FrancoSphere.NamedCoordinate) {
        HapticManager.impact(.light)
        print("🏢 Building tapped: \(building.name)")
        
        // Could open building detail view or clock-in sheet
        // For now, just provide haptic feedback
    }
    
    private func getBuildingShortName(_ buildingName: String) -> String {
        // Extract meaningful short names for display
        if buildingName.contains("12 West 18th") || buildingName.contains("12 W 18th") { return "12 W18" }
        if buildingName.contains("29") && buildingName.contains("East 20th") { return "29 E20" }
        if buildingName.contains("36 Walker") { return "36 Walker" }
        if buildingName.contains("41 Elizabeth") { return "41 Eliz" }
        if buildingName.contains("68 Perry") { return "68 Perry" }
        if buildingName.contains("104 Franklin") { return "104 Frank" }
        if buildingName.contains("112") && buildingName.contains("West 18th") { return "112 W18" }
        if buildingName.contains("117") && buildingName.contains("West 17th") { return "117 W17" }
        if buildingName.contains("Rubin") { return "Rubin" }
        if buildingName.contains("Stuyvesant") || buildingName.contains("Cove") { return "Stuy Cove" }
        
        // Fallback: take first word + last word
        let words = buildingName.components(separatedBy: " ")
        if words.count >= 2 {
            return "\(words.first ?? "")\(words.count > 2 ? " " + (words.last ?? "") : "")"
        }
        
        return String(buildingName.prefix(8)) // Last resort: first 8 characters
    }
}

// MARK: - Map Building Marker Component

struct MapBuildingMarker: View {
    let building: FrancoSphere.NamedCoordinate
    let isCurrentLocation: Bool
    let isFocused: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Pulse animation for focused building
            if isFocused {
                Circle()
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: markerSize + 10, height: markerSize + 10)
                    .scaleEffect(pulseScale)
                    .opacity(0.6)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseScale)
            }
            
            // Green halo for current location
            if isCurrentLocation {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: markerSize + 16, height: markerSize + 16)
                    .overlay(
                        Circle()
                            .stroke(Color.green, lineWidth: 3)
                            .opacity(0.6)
                    )
            }
            
            // Main marker circle
            Circle()
                .fill(markerColor.opacity(0.3))
                .frame(width: markerSize, height: markerSize)
                .overlay(
                    Circle()
                        .stroke(markerColor, lineWidth: 3)
                )
            
            // Building icon
            Image(systemName: "building.2.fill")
                .font(.system(size: iconSize))
                .foregroundColor(markerColor)
            
            // Active indicator dot
            if isCurrentLocation {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .offset(x: markerSize/2 - 4, y: -markerSize/2 + 4)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        .scaleEffect(isCurrentLocation ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCurrentLocation)
        .onAppear {
            if isFocused {
                pulseScale = 1.2
            }
        }
    }
    
    private var markerColor: Color {
        if isCurrentLocation { return .green }
        if isFocused { return .yellow }
        return .blue
    }
    
    private var markerSize: CGFloat {
        if isCurrentLocation { return 60 } // Spec: 60pt for current
        return 50 // Spec: 50pt default
    }
    
    private var iconSize: CGFloat {
        isCurrentLocation ? 24 : 20
    }
}

// MARK: - Preview

struct MapOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        MapOverlayView(
            buildings: [
                FrancoSphere.NamedCoordinate(id: "1", name: "12 West 18th Street", latitude: 40.7590, longitude: -73.9845, imageAssetName: ""),
                FrancoSphere.NamedCoordinate(id: "2", name: "29 East 20th Street", latitude: 40.7580, longitude: -73.9835, imageAssetName: "")
            ],
            currentBuildingId: "1",
            focusBuilding: nil,
            isPresented: .constant(true)
        )
    }
}
