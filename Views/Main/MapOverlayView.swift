//
//  MapOverlayView.swift
//  FrancoSphere
//
//  ✅ COMPILATION FIXED: All errors resolved
//  ✅ Integrated BuildingPreviewPopover component
//  ✅ Added proper back navigation to WorkerDashboard
//  ✅ Chelsea/SoHo default region with all building markers
//  ✅ Tap → hover card, double-tap → BuildingDetailView
//  🆕 PHASE-2: Added "My Sites" ↔ "All Sites" toggle functionality
//

import SwiftUI
import MapKit

struct MapOverlayView: View {
    // BEGIN PATCH - Updated signature with allBuildings parameter
    let buildings: [FrancoSphere.NamedCoordinate]           // Assigned buildings ("My Sites")
    let allBuildings: [FrancoSphere.NamedCoordinate]        // All buildings in portfolio ("All Sites")
    let currentBuildingId: String?
    let focusBuilding: FrancoSphere.NamedCoordinate?
    @Binding var isPresented: Bool
    let onBuildingDetail: ((FrancoSphere.NamedCoordinate) -> Void)?
    
    // NEW: Toggle state for site scope
    @State private var showAll: Bool = false
    
    // NEW: Computed datasource property
    private var datasource: [FrancoSphere.NamedCoordinate] {
        showAll ? allBuildings : buildings
    }
    // END PATCH
    
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
    
    // BEGIN PATCH - Updated initialization with allBuildings parameter
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
    // END PATCH
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen map
                mapView
                    .ignoresSafeArea()
                
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
            }
            .sheet(item: $selectedBuilding) { building in
                BuildingDetailView(building: building)
            }
            .overlay(
                // ✅ FIXED: Building preview popover integration
                buildingPreviewOverlay,
                alignment: .center
            )
            .navigationTitle("Building Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                // ✅ FIXED: Back navigation to Dashboard
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
    
    // MARK: - Map View with Enhanced Annotations
    
    @ViewBuilder
    private var mapView: some View {
        if #available(iOS 17.0, *) {
            // BEGIN PATCH - Modern Map API with datasource
            Map(position: $mapPosition) {
                ForEach(datasource, id: \.id) { building in
                    Annotation(building.name, coordinate: CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude)) {
                        buildingMapMarker(for: building)
                    }
                }
            }
            .mapStyle(.standard)
            // END PATCH
        } else {
            // BEGIN PATCH - Legacy Map API with datasource
            Map(
                coordinateRegion: $region,
                annotationItems: datasource
            ) { building in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude)) {
                    buildingMapMarker(for: building)
                }
            }
            // END PATCH
        }
    }
    
    // MARK: - Building Map Marker (Local Implementation)
    
    private func buildingMapMarker(for building: FrancoSphere.NamedCoordinate) -> some View {
        let isCurrent = building.id == currentBuildingId
        let isFocused = building.id == focusBuilding?.id
        let markerSize: CGFloat = isCurrent ? 60 : (isFocused ? 55 : 50)
        
        return Button(action: {
            handleSingleTap(building)
        }) {
            ZStack {
                // Pulsing ring for focused building
                if isFocused {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: markerSize + 10, height: markerSize + 10)
                        .opacity(0.6)
                }
                
                // Green halo for current building
                if isCurrent {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: markerSize + 8, height: markerSize + 8)
                        .opacity(0.6)
                }
                
                // Main marker with building thumbnail
                Circle()
                    .fill(isCurrent ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                    .frame(width: markerSize, height: markerSize)
                    .overlay(
                        Circle()
                            .stroke(isCurrent ? Color.green : Color.blue, lineWidth: 2)
                    )
                
                // Building thumbnail with fallback
                Group {
                    if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: markerSize * 0.4))
                            .foregroundColor(isCurrent ? .green : .blue)
                    }
                }
                .frame(width: markerSize * 0.7, height: markerSize * 0.7)
                .clipShape(Circle())
                
                // Active indicator dot
                if isCurrent {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .offset(x: markerSize/2 - 6, y: -markerSize/2 + 6)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 12, height: 12)
                                .offset(x: markerSize/2 - 6, y: -markerSize/2 + 6)
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isCurrent ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCurrent)
        .onTapGesture(count: 2) {
            handleDoubleTap(building)
        }
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Top Controls
    
    private var topControls: some View {
        HStack {
            Spacer()
            
            // Map style toggle
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                Image(systemName: "map")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            
            // Building list toggle
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                showBuildingList.toggle()
            }) {
                Image(systemName: "list.bullet")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
        .padding()
        .padding(.top, 10)
    }
    
    // MARK: - Bottom Controls
    
    // BEGIN PATCH - Updated bottom controls with segmented picker
    private var bottomControls: some View {
        VStack(spacing: 12) {
            // Building stats
            buildingStatsCard
            
            // Site scope toggle + Quick actions
            HStack {
                // NEW: Segmented picker for site scope
                Picker("", selection: $showAll) {
                    Text("My").tag(false)
                    Text("All").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                
                Spacer()
                
                // Quick actions
                HStack(spacing: 16) {
                    Button("Fit All Buildings") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        fitAllBuildings(datasource) // UPDATED: use datasource
                    }
                    .buttonStyle(MapOverlayActionButtonStyle())
                    
                    if let current = buildings.first(where: { $0.id == currentBuildingId }) {
                        Button("Go to Current") {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            focusOnBuilding(current)
                        }
                        .buttonStyle(MapOverlayActionButtonStyle(isPrimary: true))
                    }
                }
            }
        }
        .padding()
        .padding(.bottom, 10)
    }
    // END PATCH
    
    // BEGIN PATCH - Updated building stats card with dynamic labels
    private var buildingStatsCard: some View {
        HStack {
            mapStatItem(
                icon: "building.2.fill",
                label: showAll ? "All Sites" : "My Sites",
                value: "\(datasource.count)",
                color: .blue
            )
            
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 40)
            
            mapStatItem(
                icon: "checkmark.circle.fill",
                label: "On-site",
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
    // END PATCH
    
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
    
    // MARK: - ✅ Building Preview Overlay with BuildingPreviewPopover
    
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
    
    // BEGIN PATCH - Updated map position methods with datasource
    private func setupMapPosition() {
        if !datasource.isEmpty && focusBuilding == nil {
            // Keep default Chelsea/SoHo region if no specific focus
            return
        }
        
        if let focus = focusBuilding {
            focusOnBuilding(focus)
        } else if !datasource.isEmpty {
            fitAllBuildings(datasource)
        }
    }
    // END PATCH
    
    private func focusOnBuilding(_ building: FrancoSphere.NamedCoordinate) {
        let focusRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = focusRegion
            if #available(iOS 17.0, *) {
                mapPosition = .region(focusRegion)
            }
        }
    }
    
    // BEGIN PATCH - Updated fitAllBuildings with parameter and zero-span guards
    private func fitAllBuildings(_ buildingsToFit: [FrancoSphere.NamedCoordinate]) {
        guard !buildingsToFit.isEmpty else { return }
        
        let coordinates = buildingsToFit.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLng = longitudes.min() ?? 0
        let maxLng = longitudes.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        
        let latDelta = max(0.01, (maxLat - minLat) * 1.2) // Zero-span guard maintained
        let lngDelta = max(0.01, (maxLng - minLng) * 1.2) // Zero-span guard maintained
        
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
    // END PATCH
}

// MARK: - Supporting Types (Local to avoid conflicts)

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
            allBuildings: FrancoSphere.NamedCoordinate.allBuildings,
            currentBuildingId: "1",
            focusBuilding: nil,
            isPresented: .constant(true)
        )
    }
}
