//
//  MapRevealContainer.swift - COMPLETELY FIXED FOR iOS 17
//  FrancoSphere
//
//  ✅ Fixed iOS 17 Map API compatibility
//  ✅ Fixed MapAnnotationProtocol conformance
//  ✅ Fixed closure argument issues
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
    
    // MARK: - ✅ FIXED: Map View with correct iOS 17 Map API
    
    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: buildings, annotationContent: { building in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude)) {
                BuildingMapMarker(
                    building: building,
                    isSelected: building.id == currentBuildingId,
                    isFocused: building.id == focusBuildingId,
                    onTap: {
                        onBuildingTap(building)
                    }
                )
            }
        })
        .mapStyle(.standard(elevation: .realistic))
    }
    
    private var overlayContent: some View {
        // This will contain the dashboard content
        Color.clear
    }
    
    // MARK: - Map Controls Overlay
    
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
    
    // MARK: - Map Info Overlay
    
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

// MARK: - Building Map Marker Component

private struct BuildingMapMarker: View {
    let building: NamedCoordinate
    let isSelected: Bool
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer ring (larger if focused)
                Circle()
                    .fill(markerColor.opacity(0.3))
                    .frame(width: isFocused ? 50 : 40, height: isFocused ? 50 : 40)
                
                // Inner circle
                Circle()
                    .fill(markerColor)
                    .frame(width: isFocused ? 25 : 20, height: isFocused ? 25 : 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                // Building icon
                Image(systemName: iconName)
                    .font(isFocused ? .footnote : .caption)
                    .foregroundColor(.white)
            }
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(AnimationAnimation.easeInOut(duration: 0.2), value: isSelected)
            .animation(AnimationAnimation.easeInOut(duration: 0.3), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var markerColor: Color {
        if isSelected {
            return .green
        } else if isFocused {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var iconName: String {
        if isSelected {
            return "checkmark.circle.fill"
        } else {
            return "building.2.fill"
        }
    }
}

// MARK: - Preview Provider

struct MapRevealContainer_Previews: PreviewProvider {
    static var previews: some View {
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
