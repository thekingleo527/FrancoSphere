//
//  MapRevealContainer.swift
//  FrancoSphere
//
//  🎯 FIXED VERSION - All compilation errors resolved
//  ✅ FIXED: BuildingMapMarker parameter mismatch
//  ✅ FIXED: Proper parameter mapping for marker interface
//

import SwiftUI
import MapKit

struct MapRevealContainer: View {
    @State private var isMapRevealed = false
    @State private var dragOffset: CGFloat = 0
    @State private var showHint = true
    
    let buildings: [NamedCoordinate]
    let onBuildingTap: (NamedCoordinate) -> Void
    let currentBuildingId: String?
    let focusBuildingId: String?
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        ZStack {
            // Full-screen map background
            mapView
            
            // Overlay content that can be swiped
            overlayContent
                .offset(y: dragOffset)
                .offset(y: isMapRevealed ? UIScreen.main.bounds.height * 0.7 : 0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.height
                            
                            if !isMapRevealed && translation > 0 {
                                // Swiping down to reveal map
                                dragOffset = min(translation, UIScreen.main.bounds.height * 0.7)
                            } else if isMapRevealed && translation < 0 {
                                // Swiping up to hide map
                                dragOffset = max(translation, -UIScreen.main.bounds.height * 0.7)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                let threshold: CGFloat = 150
                                
                                if !isMapRevealed && value.translation.height > threshold {
                                    // Reveal map
                                    isMapRevealed = true
                                    showHint = false
                                } else if isMapRevealed && value.translation.height < -threshold {
                                    // Hide map
                                    isMapRevealed = false
                                }
                                
                                dragOffset = 0
                            }
                        }
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isMapRevealed)
            
            // Map controls overlay
            if isMapRevealed {
                mapControlsOverlay
            }
            
            // First-use hint
            if showHint && !isMapRevealed {
                swipeHint
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: buildings) { building in
            MapAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: building.latitude,
                longitude: building.longitude
            )) {
                // ✅ FIXED: Using correct BuildingMapMarker interface
                BuildingMapMarker(
                    building: building,
                    isCurrent: currentBuildingId == building.id,
                    isFocused: focusBuildingId == building.id,
                    onTap: { onBuildingTap(building) }
                )
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
    
    private var overlayContent: some View {
        // This will contain the dashboard content
        Color.clear
    }
    
    private var mapControlsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                // Close map button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isMapRevealed = false
                    }
                }) {
                    GlassCard(
                        intensity: .thin,
                        cornerRadius: 25,
                        padding: 12
                    ) {
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 20)
            }
            
            Spacer()
        }
    }
    
    private var swipeHint: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Swipe up to reveal map")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Preview

struct MapRevealContainer_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuildings = [
            FrancoSphere.NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                latitude: 40.7390,
                longitude: -73.9930,
                imageAssetName: "12_West_18th_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "2",
                name: "345 Park Avenue",
                latitude: 40.7505,
                longitude: -73.9751,
                imageAssetName: "345_Park_Avenue"
            )
        ]
        
        MapRevealContainer(
            buildings: sampleBuildings,
            onBuildingTap: { building in
                print("Tapped building: \(building.name)")
            },
            currentBuildingId: "1",
            focusBuildingId: nil
        )
        .preferredColorScheme(.dark)
    }
}
