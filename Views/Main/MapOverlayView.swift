//
//  MapOverlayView.swift
//  FrancoSphere
//
//  ✅ HF-36: FIXED GESTURE CONFLICTS
//  ✅ Vertical drag vs map pin tap resolution
//  ✅ High priority gesture handling for scroll interactions
//  ✅ Simultaneous gesture support for map interactions
//  ✅ Enhanced tap detection with minimum distance
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
    
    // Enhanced toggle state with fallback detection
    @State private var showAll: Bool = false
    
    // ✅ HF-36: Enhanced gesture state management
    @State private var isPanningMap: Bool = false
    @State private var lastTapLocation: CGPoint = .zero
    @State private var dragStartTime: Date = Date()
    
    // ✅ ENHANCED: Fail-soft datasource with automatic fallback
    private var datasource: [FrancoSphere.NamedCoordinate] {
        if showAll {
            return allBuildings
        }
        
        if buildings.isEmpty {
            return allBuildings
        }
        
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
            return "All Sites (Auto)"
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
    // ✅ HF-36: Gesture conflict resolution constants
    private let minTapDistance: CGFloat = 5.0
    private let maxTapDuration: TimeInterval = 0.5
    
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
                // Full-screen map with enhanced gesture handling
                mapView
                    .ignoresSafeArea()
                    // ✅ HF-36: Enhanced gesture system
                    .highPriorityGesture(
                        DragGesture(minimumDistance: minTapDistance)
                            .onChanged { value in
                                isPanningMap = true
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isPanningMap = false
                                }
                            }
                    )
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                // Allow map interactions to continue
                                // Building taps are handled separately in annotations
                            }
                    )
                
                // Overlay controls with gesture-safe interactions
                VStack {
                    // Top controls
                    topControls
                        // ✅ HF-36: Prevent gesture conflicts with map
                        .allowsHitTesting(true)
                        .zIndex(10)
                    
                    Spacer()
                    
                    // Bottom stats and controls
                    bottomControls
                        // ✅ HF-36: Prevent gesture conflicts with map
                        .allowsHitTesting(true)
                        .zIndex(10)
                }
                .background(.clear)
            }
            .offset(y: dragOffset)
            .gesture(enhancedDismissGesture) // ✅ HF-36: Enhanced dismiss gesture
            .onAppear {
                setupMapPosition()
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
    
    // MARK: - Map View with Enhanced Gesture Handling
    
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
                            // ✅ HF-36: Enhanced tap handling with gesture conflict resolution
                            .onTapGesture {
                                handleBuildingTap(building)
                            }
                            .onLongPressGesture(minimumDuration: 0.5) {
                                handleBuildingLongPress(building)
                            }
                            // Ensure building markers stay above map gestures
                            .zIndex(5)
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
                        // ✅ HF-36: Enhanced tap handling with gesture conflict resolution
                        .onTapGesture {
                            handleBuildingTap(building)
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            handleBuildingLongPress(building)
                        }
                        // Ensure building markers stay above map gestures
                        .zIndex(5)
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
        // ✅ HF-36: Enhanced interactive area for better tap detection
        .contentShape(Circle().inset(by: -8)) // Expand tap area slightly
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
    
    // MARK: - Top Controls with Gesture Safety
    
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
    
    // MARK: - Bottom Controls
    
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
    
    // MARK: - Building Preview Overlay
    
    @ViewBuilder
    private var buildingPreviewOverlay: some View {
        if let previewData = showBuildingPreview {
            BuildingPreviewPopover(
                building: previewData.building,
                onDetails: {
                    showBuildingPreview = nil
                    handleBuildingLongPress(previewData.building)
                },
                onDismiss: {
                    withAnimation(.spring()) {
                        showBuildingPreview = nil
                    }
                }
            )
            .transition(.scale.combined(with: .opacity))
            .zIndex(20) // ✅ HF-36: Ensure preview stays above all interactions
        }
    }
    
    // MARK: - ✅ HF-36: Enhanced Gesture Handling
    
    private var enhancedDismissGesture: some Gesture {
        DragGesture(minimumDistance: 10) // ✅ Increased minimum distance to avoid conflicts
            .onChanged { value in
                // Only respond to vertical drags that aren't map panning
                if !isPanningMap && value.translation.height > 0 && abs(value.translation.width) < abs(value.translation.height) {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                // Only dismiss on significant vertical movement
                if !isPanningMap &&
                   value.translation.height > dismissThreshold &&
                   abs(value.translation.width) < abs(value.translation.height) {
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
    
    // ✅ HF-36: Enhanced building interaction handlers
    
    private func handleBuildingTap(_ building: FrancoSphere.NamedCoordinate) {
        // Ignore taps during map panning
        guard !isPanningMap else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring()) {
            showBuildingPreview = MapBuildingPreviewData(building: building)
        }
    }
    
    private func handleBuildingLongPress(_ building: FrancoSphere.NamedCoordinate) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        showBuildingPreview = nil
        
        // Show BuildingDetailView
        selectedBuilding = building
        
        // Also call the optional callback
        onBuildingDetail?(building)
    }
    
    // MARK: - Map Setup and Actions
    
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

// MARK: - Supporting Types (Unchanged)

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

// MARK: - Building Preview Popover
// 🔧 FIXED: Using existing BuildingPreviewPopover from project - removed duplicate
