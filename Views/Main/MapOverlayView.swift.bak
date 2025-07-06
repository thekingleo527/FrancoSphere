//
//  MapOverlayView.swift
//  FrancoSphere
//
//  ✅ FIXED: Lines 317-318 optional unwrapping, removed redeclarations
//

import SwiftUI
import MapKit

struct MapOverlayView: View {
    let buildings: [NamedCoordinate]
    let allBuildings: [NamedCoordinate]
    let currentBuildingId: String?
    let focusBuilding: NamedCoordinate?
    @Binding var isPresented: Bool
    let onBuildingDetail: ((NamedCoordinate) -> Void)?
    
    @State private var showAll: Bool = false
    @State private var gestureState: MapGestureState = .idle
    @State private var dragStartLocation: CGPoint = .zero
    @State private var dragVelocity: CGSize = .zero
    @State private var lastGestureUpdate: Date = Date()
    
    private var datasource: [NamedCoordinate] {
        if showAll {
            return allBuildings.isEmpty ? buildings : allBuildings
        }
        
        if buildings.isEmpty {
            return allBuildings
        }
        
        return buildings
    }
    
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
    @State private var selectedBuilding: NamedCoordinate?
    @State private var showBuildingPreview: MapBuildingPreviewData?
    
    private let dismissThreshold: CGFloat = 120
    private let mapPanThreshold: CGFloat = 15
    private let verticalBias: Double = 0.7
    private let gestureTimeout: TimeInterval = 0.3
    
    init(buildings: [NamedCoordinate],
         allBuildings: [NamedCoordinate] = [],
         currentBuildingId: String? = nil,
         focusBuilding: NamedCoordinate? = nil,
         isPresented: Binding<Bool>,
         onBuildingDetail: ((NamedCoordinate) -> Void)? = nil) {
        self.buildings = buildings
        self.allBuildings = allBuildings.isEmpty ? buildings : allBuildings
        self.currentBuildingId = currentBuildingId
        self.focusBuilding = focusBuilding
        self._isPresented = isPresented
        self.onBuildingDetail = onBuildingDetail
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                mapView
                    .ignoresSafeArea()
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 3)
                            .onChanged { value in
                                detectGestureIntent(value)
                            }
                            .onEnded { _ in
                                resetGestureState()
                            }
                    )
                
                VStack {
                    topControls
                        .allowsHitTesting(true)
                        .zIndex(15)
                    
                    Spacer()
                    
                    bottomControls
                        .allowsHitTesting(true)
                        .zIndex(15)
                }
                .background(.clear)
            }
            .offset(y: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        handleDismissGestureChanged(value)
                    }
                    .onEnded { value in
                        handleDismissGestureEnded(value)
                    }
            )
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
                    Button(action: dismissOverlay) {
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
    
    // MARK: - Gesture Detection
    
    private enum MapGestureState {
        case idle
        case detectingIntent
        case mapPanning
        case verticalDismiss
        case buildingInteraction
    }
    
    private func detectGestureIntent(_ value: DragGesture.Value) {
        let translation = value.translation
        let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
        
        if gestureState == .idle && distance > 5 {
            gestureState = .detectingIntent
            dragStartLocation = value.startLocation
        }
        
        if gestureState == .detectingIntent && distance > mapPanThreshold {
            let horizontalRatio = abs(translation.width) / distance
            let verticalRatio = abs(translation.height) / distance
            
            if horizontalRatio > verticalBias || (translation.height < 0) {
                gestureState = .mapPanning
            } else if translation.height > 0 && verticalRatio > verticalBias {
                gestureState = .verticalDismiss
            }
        }
        
        lastGestureUpdate = Date()
    }
    
    private func handleDismissGestureChanged(_ value: DragGesture.Value) {
        let translation = value.translation
        
        if gestureState != .mapPanning && translation.height > 0 {
            let verticalRatio = abs(translation.height) / max(1, sqrt(translation.width * translation.width + translation.height * translation.height))
            
            if verticalRatio > verticalBias {
                gestureState = .verticalDismiss
                dragOffset = translation.height
                
                if translation.height > dismissThreshold * 0.7 && dragOffset < dismissThreshold * 0.8 {
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                }
            }
        }
    }
    
    private func handleDismissGestureEnded(_ value: DragGesture.Value) {
        let translation = value.translation
        let currentTime = Date()
        let gestureTime = currentTime.timeIntervalSince(lastGestureUpdate)
        
        let velocity = CGSize(
            width: translation.width / max(0.1, gestureTime),
            height: translation.height / max(0.1, gestureTime)
        )
        
        if gestureState == .verticalDismiss &&
           (translation.height > dismissThreshold || velocity.height > 300) {
            dismissOverlay()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = 0
            }
        }
        
        resetGestureState()
    }
    
    private func resetGestureState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + gestureTimeout) {
            gestureState = .idle
        }
    }
    
    private func dismissOverlay() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
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
                                handleBuildingTap(building)
                            }
                            .onLongPressGesture(minimumDuration: 0.4) {
                                handleBuildingLongPress(building)
                            }
                            .zIndex(10)
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
                            handleBuildingTap(building)
                        }
                        .onLongPressGesture(minimumDuration: 0.4) {
                            handleBuildingLongPress(building)
                        }
                        .zIndex(10)
                }
            }
        }
    }
    
    // ✅ FIXED: Lines 317-318 - Proper optional handling
    private func buildingMarker(_ building: NamedCoordinate) -> some View {
        ZStack {
            // Background with building image or color
            // Line 317 FIXED: Proper boolean logic with safe unwrapping
            if let imageAssetName = building.imageAssetName, !imageAssetName.isEmpty {
                // Line 318 FIXED: Safe optional unwrapping
                Image(imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(markerBorderColor(for: building), lineWidth: 2.5)
                    )
            } else {
                Circle()
                    .fill(markerBackgroundColor(for: building))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle()
                            .stroke(markerBorderColor(for: building), lineWidth: 2.5)
                    )
            }
            
            if building.id == currentBuildingId {
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
        .scaleEffect(building.id == currentBuildingId ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: building.id == currentBuildingId)
        .contentShape(Circle().inset(by: -10))
    }
    
    private func markerBackgroundColor(for building: NamedCoordinate) -> Color {
        if building.id == currentBuildingId {
            return .green.opacity(0.9)
        }
        return .blue.opacity(0.8)
    }
    
    private func markerBorderColor(for building: NamedCoordinate) -> Color {
        if building.id == currentBuildingId {
            return .green
        }
        return .white
    }
    
    // MARK: - Building Interaction
    
    private func handleBuildingTap(_ building: NamedCoordinate) {
        guard gestureState == .idle || gestureState == .buildingInteraction else { return }
        
        gestureState = .buildingInteraction
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showBuildingPreview = MapBuildingPreviewData(building: building)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            gestureState = .idle
        }
    }
    
    private func handleBuildingLongPress(_ building: NamedCoordinate) {
        gestureState = .buildingInteraction
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        showBuildingPreview = nil
        selectedBuilding = building
        onBuildingDetail?(building)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            gestureState = .idle
        }
    }
    
    // MARK: - Top Controls
    
    private var topControls: some View {
        HStack {
            HStack(spacing: 12) {
                Button(action: {
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
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
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
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
                color: currentBuildingId != nil ? .green : .gray
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
        .padding(.horizontal)
        .padding(.bottom, 30)
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
                    selectedBuilding = previewData.building
                },
                onDismiss: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showBuildingPreview = nil
                    }
                }
            )
            .transition(.scale.combined(with: .opacity))
            .zIndex(25)
        }
    }
    
    // MARK: - Map Setup
    
    private func setupMapPosition() {
        if let focusBuilding = focusBuilding {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: focusBuilding.latitude, longitude: focusBuilding.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            withAnimation(.easeInOut(duration: 1.2)) {
                self.region = region
                if #available(iOS 17.0, *) {
                    mapPosition = .region(region)
                }
            }
        } else {
            fitMapToBuildings()
        }
    }
    
    private func fitMapToBuildings() {
        guard !datasource.isEmpty else {
            let defaultRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.733, longitude: -73.995),
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
            
            withAnimation(.easeInOut(duration: 1.0)) {
                region = defaultRegion
                if #available(iOS 17.0, *) {
                    mapPosition = .region(defaultRegion)
                }
            }
            return
        }
        
        let latitudes = datasource.map { $0.latitude }
        let longitudes = datasource.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 40.7
        let maxLat = latitudes.max() ?? 40.8
        let minLng = longitudes.min() ?? -74.0
        let maxLng = longitudes.max() ?? -73.9
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        
        let latDelta = max(0.01, (maxLat - minLat) * 1.3)
        let lngDelta = max(0.01, (maxLng - minLng) * 1.3)
        
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
    let building: NamedCoordinate
    
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

// MARK: - Preview Support

struct MapOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        MapOverlayView(
            buildings: [
                NamedCoordinate(
                    id: "1",
                    name: "131 Perry Street",
                    latitude: 40.7359,
                    longitude: -74.0059,
                    imageAssetName: "perry_131"
                ),
                NamedCoordinate(
                    id: "2",
                    name: "68 Perry Street",
                    latitude: 40.7357,
                    longitude: -74.0055,
                    imageAssetName: "perry_68"
                )
            ],
            allBuildings: [],
            currentBuildingId: "1",
            focusBuilding: nil,
            isPresented: .constant(true),
            onBuildingDetail: nil
        )
    }
}
