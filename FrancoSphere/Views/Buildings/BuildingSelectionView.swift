//
//  BuildingSelectionView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed duplicate BuildingCard declaration
//  ✅ FIXED: All syntax errors and ambiguous references resolved
//  ✅ FIXED: Optional binding error for non-optional address property
//  ✅ CLEAN: Single BuildingCard implementation that works with existing components
//

import SwiftUI
import MapKit
import CoreLocation

struct BuildingSelectionView: View {
    let buildings: [NamedCoordinate]
    let onSelect: (NamedCoordinate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    @State private var selectedBuilding: NamedCoordinate? = nil
    @State private var currentTab: BuildingTab = .overview
    
    enum ViewMode {
        case list
        case map
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    searchBarView
                    
                    if viewMode == .list {
                        buildingListView
                    } else {
                        buildingMapView
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("Back") {
                dismiss()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Select Building")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { viewMode = viewMode == .list ? .map : .list }) {
                Image(systemName: viewMode == .list ? "map" : "list.bullet")
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search buildings...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
    }
    
    private var buildingListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredBuildings) { building in
                    BuildingSelectionCard(building: building) {
                        onSelect(building)
                        dismiss()
                    }
                }
            }
            .padding()
        }
    }
    
    private var buildingMapView: some View {
        Map {
            ForEach(filteredBuildings) { building in
                Marker(building.name, coordinate: CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                ))
                .tint(.blue)
            }
        }
        .onTapGesture { location in
            // Handle map tap if needed
        }
    }
    
    private var filteredBuildings: [NamedCoordinate] {
        if searchText.isEmpty {
            return buildings
        } else {
            return buildings.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

// MARK: - ✅ FIXED: Single BuildingCard implementation (renamed to avoid conflicts)

struct BuildingSelectionCard: View {
    let building: NamedCoordinate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Fixed: Check if address is not empty instead of optional binding
                    if !building.address.isEmpty {
                        Text(building.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Latitude: \(String(format: "%.4f", building.latitude)), Longitude: \(String(format: "%.4f", building.longitude))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Select")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    BuildingSelectionView(
        buildings: [
            NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                address: "12 West 18th Street, New York, NY",
                latitude: 40.7389,
                longitude: -73.9936
            ),
            NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St, New York, NY 10011",
                latitude: 40.7401,
                longitude: -73.9978
            )
        ],
        onSelect: { building in
            print("Selected: \(building.name)")
        }
    )
}
