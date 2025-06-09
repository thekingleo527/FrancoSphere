//
//  MapRevealContainer.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//


// MapRevealContainer.swift
// FrancoSphere - Swipe-to-reveal map with building markers

import SwiftUI
import MapKit

struct MapRevealContainer: View {
    @State private var isMapRevealed = false
    @State private var dragOffset: CGFloat = 0
    @State private var showHint = true
    
    let buildings: [NamedCoordinate]
    let onBuildingTap: (NamedCoordinate) -> Void
    
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
                // FIXED: Using existing BuildingMapMarker with correct interface
                Button(action: {
                    onBuildingTap(building)
                }) {
                    BuildingMapMarker(
                        building: building,
                        isClockedIn: false // TODO: Determine actual clock-in status
                    )
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
                .padding(.top, 60)
            }
            
            Spacer()
            
            // Map info overlay
            if isMapRevealed {
                mapInfoOverlay
            }
        }
    }
    
    private var mapInfoOverlay: some View {
        VStack {
            Spacer()
            
            GlassCard(intensity: .regular) {
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
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var swipeHint: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "chevron.up")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
                    .scaleEffect(1.2)
                
                Text("Swipe up to view map")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 40)
            .opacity(showHint ? 1 : 0)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: showHint)
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
