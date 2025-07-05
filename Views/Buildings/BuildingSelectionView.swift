//
//  BuildingSelectionView.swift
//  FrancoSphere
//
//  Fixed all syntax errors and ambiguous references
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
    @State private var currentTab: FrancoSphere.BuildingTab = .overview
    
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
                    buildingListView
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
                    BuildingCard(building: building) {
                        onSelect(building)
                    }
                }
            }
            .padding()
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

struct BuildingCard: View {
    let building: NamedCoordinate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let address = building.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
