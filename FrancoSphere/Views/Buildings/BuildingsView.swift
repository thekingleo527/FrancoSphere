//
//  BuildingsView.swift
//  FrancoSphere
//
//  ✅ REFACTORED: Uses real BuildingDetailView instead of placeholder
//  ✅ FIXED: Compilation errors resolved
//  ✅ PURPOSE: Portfolio-wide building browser for admins/managers
//

import SwiftUI
import MapKit

struct BuildingsView: View {
    
    // Buildings loaded asynchronously from the repository
    @State private var buildings: [NamedCoordinate] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var errorMessage: String?
    
    // Services
    private let buildingService = BuildingService.shared
    
    // Filter helper
    private var filteredBuildings: [NamedCoordinate] {
        guard !searchText.isEmpty else { return buildings }
        return buildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Building count by type
    private var buildingStats: (total: Int, residential: Int, commercial: Int) {
        let total = buildings.count
        let residential = buildings.filter { $0.name.contains("Perry") || $0.name.contains("Elizabeth") || $0.name.contains("Walker") }.count
        let commercial = buildings.filter { $0.name.contains("Museum") || $0.name.contains("Park") || $0.name.contains("West") }.count
        return (total, residential, commercial)
    }
    
    // MARK: – UI
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // 📊 Portfolio Stats
                if !buildings.isEmpty {
                    portfolioStatsView
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // 🔍 Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search buildings or addresses", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding([.horizontal, .top])
                
                // Error message if any
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .font(.caption)
                }
                
                // 📋 List of buildings or loading indicator
                if isLoading {
                    Spacer()
                    ProgressView("Loading portfolio...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if filteredBuildings.isEmpty {
                    emptyStateView
                } else {
                    List(filteredBuildings, id: \.id) { building in
                        NavigationLink {
                            // ✅ Use the real BuildingDetailView
                            BuildingDetailView(building: building)
                        } label: {
                            buildingRow(for: building)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Building Portfolio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await loadBuildings() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadBuildings()
            }
        }
    }
    
    // MARK: - Portfolio Stats View
    private var portfolioStatsView: some View {
        HStack(spacing: 16) {
            // Use the existing StatCard from the project
            StatCard(
                title: "Total",
                value: "\(buildingStats.total)",
                trend: nil,
                icon: "building.2"
            )
            
            StatCard(
                title: "Residential",
                value: "\(buildingStats.residential)",
                trend: nil,
                icon: "house"
            )
            
            StatCard(
                title: "Commercial",
                value: "\(buildingStats.commercial)",
                trend: nil,
                icon: "building"
            )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                Text("No buildings in portfolio")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Buildings will appear here once added to the system")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("No buildings match '\(searchText)'")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button("Clear Search") {
                    searchText = ""
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Building Row View
    private func buildingRow(for building: NamedCoordinate) -> some View {
        HStack(spacing: 12) {
            // Building image or icon
            if let imageAssetName = building.imageAssetName,
               let uiImage = UIImage(named: imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: iconForBuilding(building))
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.headline)
                    .lineLimit(1)
                
                // Address - it's not optional
                Text(building.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Building type badge
                HStack(spacing: 4) {
                    Image(systemName: iconForBuilding(building))
                        .font(.caption2)
                    
                    Text(buildingType(building))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(colorForBuilding(building).opacity(0.2))
                .foregroundColor(colorForBuilding(building))
                .cornerRadius(6)
            }
            
            Spacer()
            
            // Status indicator
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Show if it's a special building
                if building.name.contains("Rubin") {
                    Text("Museum")
                        .font(.caption2)
                        .foregroundColor(.purple)
                } else if building.name.contains("Park") {
                    Text("Park")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Functions
    
    private func iconForBuilding(_ building: NamedCoordinate) -> String {
        if building.name.contains("Museum") {
            return "building.columns"
        } else if building.name.contains("Park") {
            return "leaf"
        } else if building.name.contains("Perry") || building.name.contains("Elizabeth") {
            return "house"
        } else {
            return "building"
        }
    }
    
    private func buildingType(_ building: NamedCoordinate) -> String {
        if building.name.contains("Museum") {
            return "Cultural"
        } else if building.name.contains("Park") {
            return "Recreation"
        } else if building.name.contains("Perry") || building.name.contains("Elizabeth") {
            return "Residential"
        } else {
            return "Commercial"
        }
    }
    
    private func colorForBuilding(_ building: NamedCoordinate) -> Color {
        if building.name.contains("Museum") {
            return .purple
        } else if building.name.contains("Park") {
            return .green
        } else if building.name.contains("Perry") || building.name.contains("Elizabeth") {
            return .blue
        } else {
            return .orange
        }
    }
    
    // MARK: - Data Loading
    private func loadBuildings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedBuildings = try await buildingService.getAllBuildings()
            
            // Update on main thread
            await MainActor.run {
                self.buildings = loadedBuildings.sorted { $0.name < $1.name }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load buildings: \(error.localizedDescription)"
                self.isLoading = false
                
                // Fallback to production buildings from CoreTypes if service fails
                #if DEBUG
                self.buildings = CoreTypes.productionBuildings
                #endif
            }
        }
    }
}

// MARK: - Preview
struct BuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        BuildingsView()
    }
}
