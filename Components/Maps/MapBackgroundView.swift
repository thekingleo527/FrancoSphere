//
//  MapBackgroundView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


// Components/Map/MapBackgroundView.swift
import SwiftUI
import MapKit

struct MapBackgroundView: View {
    @State private var region: MKCoordinateRegion
    let buildings: [NamedCoordinate]
    @State private var mapOpacity: Double = 0.0
    
    init(buildings: [NamedCoordinate]) {
        self.buildings = buildings
        // Center on Manhattan
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: buildings) { building in
            MapAnnotation(coordinate: building.coordinate) {
                BuildingMapMarker(
                    building: building,
                    isClockedIn: false
                )
            }
        }
        .ignoresSafeArea()
        .blur(radius: 8)
        .overlay(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                mapOpacity = 1.0
            }
        }
        .opacity(mapOpacity)
    }
}