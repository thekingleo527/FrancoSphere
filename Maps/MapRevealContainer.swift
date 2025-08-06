//
//  MapRevealContainer.swift
//  CyntientOps v6.0
//
//  ✅ ENHANCED: Dual-mode map with intelligence previews
//  ✅ FIXED: Uses WorkerContextEngine (not adapter)
//  ✅ INTEGRATED: BuildingPreviewPopover on tap
//  ✅ UNIFIED: Single building marker component
//  ✅ NEW: Shows building images when focused
//

import SwiftUI
import MapKit

struct MapRevealContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    // Map state
    @State private var isMapRevealed = false
    @State private var dragOffset: CGFloat = 0
    @State private var showHint = true
    @State private var selectedBuildingForPreview: NamedCoordinate?
    @State private var hoveredBuildingId: String?
    
    // Building data
    let buildings: [NamedCoordinate]
    let currentBuildingId: String?
    let focusBuildingId: String?
    
    // Callbacks
    let onBuildingTap: (NamedCoordinate) -> Void
    
    // Map camera
    @State private var position: MapCameraPosition
    
    // Intelligence data
    @State private var buildingMetrics: [String: BuildingMetrics] = [:]
    @State private var isLoadingMetrics = false
    
    // MARK: - Initialization
    
    init(
        buildings: [NamedCoordinate],
        currentBuildingId: String? = nil,
        focusBuildingId: String? = nil,
        onBuildingTap: @escaping (NamedCoordinate) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.buildings = buildings
        self.currentBuildingId = currentBuildingId
        self.focusBuildingId = focusBuildingId
        self.onBuildingTap = onBuildingTap
        self.content = content
        
        // Initialize map position
        let center = buildings.first?.coordinate ??
                    CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
        
        self._position = State(initialValue: .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        ))
    }
    
    var body: some View {
        ZStack {
            // Ambient mode: Blurred map background
            if !isMapRevealed {
                ambientMapBackground
            }
            
            // Interactive mode: Full map
            if isMapRevealed {
                interactiveMap
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
            
            // Main content overlay
            content()
                .offset(y: dragOffset)
                .offset(y: isMapRevealed ? UIScreen.main.bounds.height * 0.75 : 0)
                .gesture(swipeGesture)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isMapRevealed)
            
            // Map controls when revealed
            if isMapRevealed {
                mapControls
                    .transition(.opacity)
            }
            
            // Intelligence popover
            if let building = selectedBuildingForPreview {
                intelligencePopover(for: building)
            }
            
            // Swipe hint
            if showHint && !isMapRevealed {
                MapInteractionHint.automatic(showHint: $showHint)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .task {
            await preloadBuildingMetrics()
        }
    }
    
    // MARK: - Ambient Map Background
    
    private var ambientMapBackground: some View {
        ZStack {
            // Map with minimal interaction
            Map(position: .constant(position)) {
                ForEach(buildings, id: \.id) { building in
                    Annotation(
                        building.name,
                        coordinate: building.coordinate
                    ) {
                        MapBuildingBubble(
                            building: building,
                            isSelected: building.id == currentBuildingId,
                            isFocused: false,
                            isInteractive: false,
                            metrics: buildingMetrics[building.id]
                        )
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .allowsHitTesting(false)
            .blur(radius: 15)
            .opacity(0.4)
            
            // Dark overlay for better contrast
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Interactive Map
    
    private var interactiveMap: some View {
        Map(position: $position) {
            ForEach(buildings, id: \.id) { building in
                Annotation(
                    building.name,
                    coordinate: building.coordinate
                ) {
                    MapBuildingBubble(
                        building: building,
                        isSelected: building.id == currentBuildingId,
                        isFocused: building.id == focusBuildingId || building.id == hoveredBuildingId,
                        isInteractive: true,
                        metrics: buildingMetrics[building.id],
                        onTap: {
                            handleBuildingTap(building)
                        },
                        onHover: { isHovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hoveredBuildingId = isHovering ? building.id : nil
                            }
                        }
                    )
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
    
    // MARK: - Map Controls
    
    private var mapControls: some View {
        VStack {
            HStack {
                Spacer()
                
                // Close button
                Button(action: closeMap) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 60)
            }
            
            Spacer()
            
            // Map legend
            mapLegend
        }
    }
    
    // MARK: - Map Legend
    
    private var mapLegend: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.blue)
                
                Text("My Buildings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(buildings.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            if currentBuildingId != nil {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                    
                    Text("Currently clocked in")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
            }
            
            Text("Tap any building for quick intelligence")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Intelligence Popover
    
    private func intelligencePopover(for building: NamedCoordinate) -> some View {
        BuildingPreviewPopover(
            building: building,
            onDetails: {
                selectedBuildingForPreview = nil
                onBuildingTap(building)
            },
            onDismiss: {
                selectedBuildingForPreview = nil
            }
        )
        .position(popoverPosition(for: building))
        .transition(.scale.combined(with: .opacity))
        .zIndex(100)
    }
    
    // MARK: - Gesture Handling
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.height
                
                if !isMapRevealed && translation < 0 {
                    // Swiping up to reveal map
                    dragOffset = max(translation, -UIScreen.main.bounds.height * 0.75)
                } else if isMapRevealed && translation > 0 {
                    // Swiping down to hide map
                    dragOffset = min(translation, UIScreen.main.bounds.height * 0.75)
                }
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    let threshold: CGFloat = 100
                    
                    if !isMapRevealed && value.translation.height < -threshold {
                        // Reveal map
                        isMapRevealed = true
                        showHint = false
                    } else if isMapRevealed && value.translation.height > threshold {
                        // Hide map
                        isMapRevealed = false
                        selectedBuildingForPreview = nil
                    }
                    
                    dragOffset = 0
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func handleBuildingTap(_ building: NamedCoordinate) {
        if selectedBuildingForPreview?.id == building.id {
            // Second tap - navigate to details
            selectedBuildingForPreview = nil
            onBuildingTap(building)
        } else {
            // First tap - show preview
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedBuildingForPreview = building
            }
        }
    }
    
    private func closeMap() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isMapRevealed = false
            selectedBuildingForPreview = nil
            hoveredBuildingId = nil
        }
    }
    
    private func popoverPosition(for building: NamedCoordinate) -> CGPoint {
        // Calculate position above the building marker
        let screenSize = UIScreen.main.bounds
        
        // Get approximate screen position for building
        // This is simplified - in production, use MKMapView conversion
        return CGPoint(
            x: screenSize.width / 2,
            y: screenSize.height / 2 - 150
        )
    }
    
    private func preloadBuildingMetrics() async {
        isLoadingMetrics = true
        
        for building in buildings {
            do {
                let metrics = try await BuildingMetricsService.shared.calculateMetrics(for: building.id)
                await MainActor.run {
                    buildingMetrics[building.id] = metrics
                }
            } catch {
                print("Failed to load metrics for \(building.name): \(error)")
            }
        }
        
        isLoadingMetrics = false
    }
}

// MARK: - Enhanced Building Marker with Image Support

struct MapBuildingBubble: View {
    let building: NamedCoordinate
    let isSelected: Bool
    let isFocused: Bool
    let isInteractive: Bool
    let metrics: BuildingMetrics?
    var onTap: (() -> Void)?
    var onHover: ((Bool) -> Void)?
    
    @State private var isPressed = false
    
    // Building asset mappings (same as BuildingPreviewPopover)
    private let buildingAssetMap: [String: String] = [
        "1": "12_West_18th_Street",
        "2": "29_31_East_20th_Street",
        "3": "36_Walker_Street",
        "4": "41_Elizabeth_Street",
        "5": "68_Perry_Street",
        "6": "104_Franklin_Street",
        "7": "112_West_18th_Street",
        "8": "117_West_17th_Street",
        "9": "123_1st_Avenue",
        "10": "131_Perry_Street",
        "11": "133_East_15th_Street",
        "12": "135West17thStreet",
        "13": "136_West_17th_Street",
        "14": "Rubin_Museum_142_148_West_17th_Street",
        "15": "138West17thStreet",
        "16": "41_Elizabeth_Street",
        "park": "Stuyvesant_Cove_Park"
    ]
    
    var body: some View {
        Button(action: { onTap?() }) {
            ZStack {
                // Outer ring for focus/selection
                if isFocused || isSelected {
                    Circle()
                        .fill(ringColor.opacity(0.3))
                        .frame(width: 65, height: 65)
                        .blur(radius: 2)
                }
                
                // Main bubble with building image when focused
                if isFocused && !isSelected {
                    // Show building image when focused
                    buildingImageBubble
                } else {
                    // Show icon bubble for normal/selected state
                    iconBubble
                }
                
                // Status indicator
                if let metrics = metrics {
                    statusIndicator(metrics)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .scaleEffect(isFocused ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isInteractive)
        .onHover { hovering in
            onHover?(hovering)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    @ViewBuilder
    private var buildingImageBubble: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 55, height: 55)
            
            // Building image or fallback
            if let assetName = buildingAssetMap[building.id] {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 2)
                    )
            } else {
                // Fallback to icon bubble
                iconBubbleContent
            }
        }
        .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
    }
    
    @ViewBuilder
    private var iconBubble: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 2)
                )
            
            iconBubbleContent
        }
        .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var iconBubbleContent: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        } else {
            VStack(spacing: 0) {
                Image(systemName: buildingIcon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
        }
    }
    
    private var ringColor: Color {
        if isSelected {
            return .green
        } else if let metrics = metrics {
            return riskColor(for: metrics)
        } else {
            return .blue
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .green
        } else if let metrics = metrics {
            return riskColor(for: metrics).opacity(0.8)
        } else {
            return .white.opacity(0.3)
        }
    }
    
    private var shadowColor: Color {
        if isSelected {
            return .green.opacity(0.5)
        } else if isFocused {
            return .blue.opacity(0.5)
        } else {
            return .black.opacity(0.3)
        }
    }
    
    private var buildingIcon: String {
        let name = building.name.lowercased()
        
        // Enhanced icon matching based on actual building names
        if name.contains("museum") || name.contains("rubin") {
            return "building.columns.fill"
        } else if name.contains("park") || name.contains("stuyvesant") || name.contains("cove") {
            return "leaf.fill"
        } else if name.contains("perry") || name.contains("elizabeth") || name.contains("walker") {
            return "house.fill"
        } else if name.contains("west") || name.contains("east") || name.contains("franklin") {
            return "building.2.fill"
        } else if name.contains("avenue") {
            return "building.fill"
        } else {
            return "building.2.fill"
        }
    }
    
    private var iconColor: Color {
        if let metrics = metrics {
            return riskColor(for: metrics)
        } else {
            return .blue
        }
    }
    
    @ViewBuilder
    private func statusIndicator(_ metrics: BuildingMetrics) -> some View {
        if metrics.urgentTasksCount > 0 {
            ZStack {
                Circle()
                    .fill(.red)
                    .frame(width: 20, height: 20)
                
                Text("\(metrics.urgentTasksCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .offset(x: 18, y: -18)
        }
    }
    
    private func riskColor(for metrics: BuildingMetrics) -> Color {
        if metrics.overdueTasks > 0 || metrics.urgentTasksCount > 0 {
            return .red
        } else if metrics.completionRate < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Preview Provider

struct MapRevealContainer_Previews: PreviewProvider {
    static var previews: some View {
        let buildings = [
            NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St",
                latitude: 40.7402,
                longitude: -73.9980
            ),
            NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                address: "12 W 18th St",
                latitude: 40.7397,
                longitude: -73.9944
            ),
            NamedCoordinate(
                id: "park",
                name: "Stuyvesant Cove Park",
                address: "East River Greenway",
                latitude: 40.7356,
                longitude: -73.9772
            )
        ]
        
        MapRevealContainer(
            buildings: buildings,
            currentBuildingId: "14",
            onBuildingTap: { building in
                print("Navigate to: \(building.name)")
            }
        ) {
            // Preview content
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Worker Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Swipe up to reveal the map")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }
}
