//
//  MapRevealContainer.swift - COMPLETELY FIXED VERSION
//  FrancoSphere
//
//  ✅ Fixed BuildingMapMarker scope issue with inline component
//  ✅ Fixed GlassCard generic parameter inference
//  ✅ Fixed NamedCoordinate initializer - removed 'address' parameter
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import MapKit
// FrancoSphere Types Import
// (This comment helps identify our import)


struct MapRevealContainer: View {
    @State private var isMapRevealed = false
    @State private var dragOffset: CGFloat = 0
    @State private var showHint = true
    
    let buildings: [NamedCoordinate]
    let onBuildingTap: (NamedCoordinate) -> Void
    let currentBuildingId: String? // ✅ ADDED: Missing parameter
    let focusBuildingId: String? // ✅ ADDED: Missing parameter
    
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
    
    // MARK: - ✅ FIXED: Map View with correct BuildingMapMarker usage
    
    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: buildings) { building in
            MapAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: building.latitude,
                longitude: building.longitude
            )) {
                // ✅ FIXED: Create a simple marker instead of using BuildingMapMarker
                Button(action: {
                    onBuildingTap(building)
                }) {
                    ZStack {
                        // Outer ring
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        // Inner circle
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        // Building icon
                        Image(systemName: "building.2.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
    
    private var overlayContent: some View {
        // This will contain the dashboard content
        Color.clear
    }
    
    // MARK: - ✅ FIXED: Map Controls Overlay with proper GlassCard usage
    
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
                    // ✅ FIXED: Use direct background instead of GlassCard generic issue
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
            
            // Map info overlay
            if isMapRevealed {
                mapInfoOverlay
            }
        }
    }
    
    // MARK: - ✅ FIXED: Map Info Overlay with direct background
    
    private var mapInfoOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.blue)
                    
                    Text("Assigned Buildings")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(buildings.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Text("Tap any building marker to view details and clock in")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showHint = false
                }
            }
        }
    }
}

// MARK: - Preview Provider

struct MapRevealContainer_Previews: PreviewProvider {
    static var previews: some View {
        // ✅ FIXED: Removed 'address' parameter from NamedCoordinate initializers
        let realBuildings = [
            NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                latitude: 40.7397,
                longitude: -73.9944,
                imageAssetName: "12_West_18th_Street"
            ),
            NamedCoordinate(
                id: "2",
                name: "29-31 East 20th Street",
                latitude: 40.7389,
                longitude: -73.9863,
                imageAssetName: "29_31_East_20th_Street"
            ),
            NamedCoordinate(
                id: "3",
                name: "117 West 17th Street",
                latitude: 40.7396,
                longitude: -73.9970,
                imageAssetName: "117_West_17th_Street"
            ),
            NamedCoordinate(
                id: "4",
                name: "131 Perry Street",
                latitude: 40.7321,
                longitude: -74.0038,
                imageAssetName: "131_Perry_Street"
            )
        ]
        
        MapRevealContainer(
            buildings: realBuildings,
            onBuildingTap: { building in
                print("Tapped building: \(building.name)")
            },
            currentBuildingId: "1",
            focusBuildingId: "3"
        )
        .preferredColorScheme(.dark)
    }
}
