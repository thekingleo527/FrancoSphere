//
//  MapOverlayView.swift
//  FrancoSphere
//
//  ✅ PHASE-2 ENHANCED: Fail-soft fallback logic
//  ✅ Emergency recovery when no buildings assigned
//  ✅ Visual indicators for fallback state
//  ✅ Enhanced user guidance and debugging
//  ✅ Production-ready error handling
//  ✅ HF-03 HOTFIX: Orange warning overlays removed
//

import SwiftUI
import MapKit

struct MapOverlayView: View {
    let buildings: [FrancoSphere.NamedCoordinate]           // Assigned buildings ("My Sites")
    let allBuildings: [FrancoSphere.NamedCoordinate]        // All buildings in portfolio ("All Sites")
    let currentBuildingId: String?
    let focusBuilding: FrancoSphere.NamedCoordinate?
    @Binding var isPresented: Bool
    let onBuildingDetail: ((FrancoSphere.NamedCoordinate) -> Void)?
    
    // NEW: Enhanced toggle state with fallback detection
    @State private var showAll: Bool = false
    // BEGIN PATCH(HF-03): Remove warning state - no longer needed
    // @State private var showFallbackWarning: Bool = false
    // END PATCH(HF-03)
    
    // ✅ ENHANCED: Fail-soft datasource with automatic fallback
    private var datasource: [FrancoSphere.NamedCoordinate] {
        // If user explicitly chose "All Sites", show all
        if showAll {
            return allBuildings
        }
        
        // If assigned buildings are empty, automatically fall back to all buildings
        if buildings.isEmpty {
            // BEGIN PATCH(HF-03): Remove warning trigger - silent fallback now
            // No warning needed - graceful fallback is expected behavior
            // END PATCH(HF-03)
            return allBuildings
        }
        
        // Normal case: show assigned buildings
        return buildings
    }
    
    // ✅ NEW: Computed properties for UI state
    private var isInFallbackMode: Bool {
        buildings.isEmpty && !showAll
    }
    
    private var effectiveMode: String {
        if showAll {
            return "All Sites"
        } else if isInFallbackMode {
            return "All Sites (Auto)"  // Changed from "Fallback" to more user-friendly text
        } else {
            return "My Sites"
        }
    }
    
    // ✅ DEFAULT REGION: Chelsea/SoHo area as specified
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.733, longitude: -73.995),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    
    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.733, longitude: -73.995),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    ))
    
    @State private var dragOffset: CGFloat = 0
    @State private var showBuildingList = false
    @State private var selectedBuilding: FrancoSphere.NamedCoordinate?
    @State private var showBuildingPreview: MapBuildingPreviewData?
    
    private let dismissThreshold: CGFloat = 100
    
    init(buildings: [FrancoSphere.NamedCoordinate],
         allBuildings: [FrancoSphere.NamedCoordinate],
         currentBuildingId: String?,
         focusBuilding: FrancoSphere.NamedCoordinate?,
         isPresented: Binding<Bool>,
         onBuildingDetail: ((FrancoSphere.NamedCoordinate) -> Void)? = nil) {
        self.buildings = buildings
        self.allBuildings = allBuildings
        self.currentBuildingId = currentBuildingId
        self.focusBuilding = focusBuilding
        self._isPresented = isPresented
        self.onBuildingDetail = onBuildingDetail
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen map
                mapView
                    .ignoresSafeArea()
                
                // BEGIN PATCH(HF-03): Remove fallback warning overlay
                // Removed - no longer showing orange warning overlays
                // END PATCH(HF-03)
                
                // Overlay controls
                VStack {
                    // Top controls
                    topControls
                    
                    Spacer()
                    
                    // Bottom stats and controls
                    bottomControls
                }
                .background(.clear)
            }
            .offset(y: dragOffset)
            .gesture(dismissGesture)
            .onAppear {
                setupMapPosition()
                // BEGIN PATCH(HF-03): Remove fallback mode check
                // checkForFallbackMode() - no longer needed
                // END PATCH(HF-03)
            }
            .sheet(item: $selectedBuilding) { building in
                BuildingDetailView(building: building)
            }
            .overlay(
                buildingPreviewOverlay,
                alignment: .center
            )
            .navigationTitle("Building Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Dashboard")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Map View
    
    @ViewBuilder
    private var mapView: some View {
        if #available(iOS 17.0, *) {
            Map(position: $mapPosition) {
                ForEach(datasource, id: \.id) { building in
                    Annotation(building.name, coordinate: CLLocationCoordinate2D(
                        latitude: building.latitude,
                        longitude: building.longitude
                    )) {
                        buildingMarker(building)
                            .onTapGesture {
                                handleSingleTap(building)
                            }
                            .onLongPressGesture {
                                handleDoubleTap(building)
                            }
                    }
                }
            }
            .mapStyle(.standard)
        } else {
            Map(coordinateRegion: $region, annotationItems: datasource) { building in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                )) {
                    buildingMarker(building)
                        .onTapGesture {
                            handleSingleTap(building)
                        }
                        .onLongPressGesture {
                            handleDoubleTap(building)
                        }
                }
            }
        }
    }
    
    private func buildingMarker(_ building: FrancoSphere.NamedCoordinate) -> some View {
        ZStack {
            // Background with building image
            if !building.imageAssetName.isEmpty {
                Image(building.imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(markerBorderColor(for: building), lineWidth: 2)
                    )
            } else {
                Circle()
                    .fill(markerBackgroundColor(for: building))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(markerBorderColor(for: building), lineWidth: 2)
                    )
            }
            
            // Icon overlay for current building
            if building.id == currentBuildingId {
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private func markerBackgroundColor(for building: FrancoSphere.NamedCoordinate) -> Color {
        if building.id == currentBuildingId {
            return .green.opacity(0.8)
        }
        return .blue.opacity(0.8)
    }
    
    private func markerBorderColor(for building: FrancoSphere.NamedCoordinate) -> Color {
        if building.id == currentBuildingId {
            return .green
        }
        return .blue
    }
    
    private func markerIcon(for building: FrancoSphere.NamedCoordinate) -> String {
        if building.id == currentBuildingId {
            return "person.fill"
        }
        return "building.2.fill"
    }
    
    // MARK: - Top Controls
    
    private var topControls: some View {
        HStack {
            // Mode toggle
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring()) {
                        showAll = false
                    }
                    fitMapToBuildings()
                }) {
                    Text("My Sites")
                        .font(.caption)
                        .fontWeight(!showAll ? .bold : .medium)
                        .foregroundColor(!showAll ? .white : .white.opacity(0.7))
                }
                .buttonStyle(MapOverlayActionButtonStyle(isPrimary: !showAll))
                
                Button(action: {
                    withAnimation(.spring()) {
                        showAll = true
                    }
                    fitMapToBuildings()
                }) {
                    Text("All Sites")
                        .font(.caption)
                        .fontWeight(showAll ? .bold : .medium)
                        .foregroundColor(showAll ? .white : .white.opacity(0.7))
                }
                .buttonStyle(MapOverlayActionButtonStyle(isPrimary: showAll))
            }
            
            Spacer()
            
            // Current mode indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text(effectiveMode)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(datasource.count) buildings")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Bottom Controls (Simplified - No Orange Warnings)
    
    private var bottomControls: some View {
        HStack(spacing: 16) {
            mapStatItem(
                icon: "building.2.fill",
                label: "Buildings",
                value: "\(datasource.count)",
                color: .blue
            )
            
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 40)
            
            mapStatItem(
                icon: "person.fill",
                label: "Clocked In",
                value: currentBuildingId != nil ? "1" : "0",
                color: .green
            )
            
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 40)
            
            mapStatItem(
                icon: "location.fill",
                label: "Area",
                value: "NYC",
                color: .orange
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        // BEGIN PATCH(HF-03): Remove orange fallback border indicator
        // No more orange borders showing fallback state
        // END PATCH(HF-03)
    }
    
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
    
    // BEGIN PATCH(HF-03): Remove fallback warning overlay entirely
    // This entire section has been removed
    // END PATCH(HF-03)
    
    // MARK: - Building Preview Overlay
    
    @ViewBuilder
    private var buildingPreviewOverlay: some View {
        if let previewData = showBuildingPreview {
            BuildingPreviewPopover(
                building: previewData.building,
                onDetails: {
                    showBuildingPreview = nil
                    handleDoubleTap(previewData.building)
                },
                onDismiss: {
                    withAnimation(.spring()) {
                        showBuildingPreview = nil
                    }
                }
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Gesture Handling
    
    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > dismissThreshold {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                } else {
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
            }
    }
    
    // MARK: - Map Actions
    
    private func handleSingleTap(_ building: FrancoSphere.NamedCoordinate) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        withAnimation(.spring()) {
            showBuildingPreview = MapBuildingPreviewData(building: building)
        }
    }
    
    private func handleDoubleTap(_ building: FrancoSphere.NamedCoordinate) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        showBuildingPreview = nil
        
        // Show BuildingDetailView
        selectedBuilding = building
        
        // Also call the optional callback
        onBuildingDetail?(building)
    }
    
    private func setupMapPosition() {
        if let focusBuilding = focusBuilding {
            // Focus on specific building
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: focusBuilding.latitude, longitude: focusBuilding.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            withAnimation(.easeInOut(duration: 1.0)) {
                self.region = region
                if #available(iOS 17.0, *) {
                    mapPosition = .region(region)
                }
            }
        } else {
            // Fit to show all relevant buildings
            fitMapToBuildings()
        }
    }
    
    // BEGIN PATCH(HF-03): Remove fallback mode check method
    // This method has been removed as warning overlay is no longer needed
    // END PATCH(HF-03)
    
    private func fitMapToBuildings() {
        guard !datasource.isEmpty else { return }
        
        let latitudes = datasource.map { $0.latitude }
        let longitudes = datasource.map { $0.longitude }
        
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
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = newRegion
            if #available(iOS 17.0, *) {
                mapPosition = .region(newRegion)
            }
        }
    }
}

// MARK: - Supporting Types

struct MapBuildingPreviewData: Identifiable, Equatable {
    let id = UUID()
    let building: FrancoSphere.NamedCoordinate
    
    static func == (lhs: MapBuildingPreviewData, rhs: MapBuildingPreviewData) -> Bool {
        lhs.id == rhs.id && lhs.building.id == rhs.building.id
    }
}

struct MapOverlayActionButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    init(isPrimary: Bool = false) {
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(isPrimary ? .white : .blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPrimary ? Color.blue : Color.gray.opacity(0.2))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Building Preview Popover removed - using existing implementation
