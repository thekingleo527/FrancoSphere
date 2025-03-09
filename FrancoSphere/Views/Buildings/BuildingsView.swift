//
//  BuildingsView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/1/25.
//

import SwiftUI
import MapKit

struct BuildingsView: View {
    // Use BuildingRepository instead of direct reference to allBuildings
    let buildings = BuildingRepository.shared.buildings
    
    @State private var searchText = ""
    
    var filteredBuildings: [NamedCoordinate] {
        if searchText.isEmpty {
            return buildings
        } else {
            return buildings.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search buildings", text: $searchText)
                        .autocapitalization(.none)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Buildings list
                List {
                    ForEach(filteredBuildings) { building in
                        NavigationLink(destination: BuildingDetailView(building: building)) {
                            BuildingCardView(building: building)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Buildings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
