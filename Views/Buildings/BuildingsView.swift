//
//  BuildingsView.swift
//  FrancoSphere
//
//  Shows a searchable list of all portfolio buildings.
//  Requires: BuildingRepository.shared.allBuildings
//

import SwiftUI
import MapKit

struct BuildingsView: View {
    
    // Buildings loaded asynchronously from the repository
    @State private var buildings: [FrancoSphere.NamedCoordinate] = []
    @State private var isLoading = true
    @State private var searchText = ""
    
    // Filter helper
    private var filteredBuildings: [FrancoSphere.NamedCoordinate] {
        guard !searchText.isEmpty else { return buildings }
        return buildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.address ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: – UI
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // 🔍 Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search buildings", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding([.horizontal, .top])
                
                // 📋 List of buildings or loading indicator
                if isLoading {
                    Spacer()
                    ProgressView("Loading buildings...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if filteredBuildings.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "building.2.crop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        if searchText.isEmpty {
                            Text("No buildings available")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No buildings match '\(searchText)'")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button("Clear Search") {
                                searchText = ""
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredBuildings, id: \.id) { building in
                            NavigationLink {
                                // Use TempBuildingDetailView if it exists, otherwise use placeholder
                                if #available(iOS 15.0, *) {
                                    TempBuildingDetailView(building: building)
                                } else {
                                    BuildingDetailPlaceholder(building: building)
                                }
                            } label: {
                                // Building row view
                                buildingRow(for: building)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Buildings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadBuildings()
            }
        }
    }
    
    // MARK: - Building Row View
    private func buildingRow(for building: FrancoSphere.NamedCoordinate) -> some View {
        HStack(spacing: 12) {
            // Building image or placeholder
            if let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "building.2.crop.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let addr = building.address {
                    Text(addr)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Building ID badge
                Text("ID: \(building.id)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Data Loading
    private func loadBuildings() async {
        isLoading = true
        
        // Load buildings from the actor-based repository
        let loadedBuildings = await BuildingRepository.shared.allBuildings
        
        // Update on main thread
        await MainActor.run {
            self.buildings = loadedBuildings
            self.isLoading = false
        }
    }
}

// MARK: - Alternative Implementation with AsyncContent
struct BuildingsViewAlternative: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search buildings", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding([.horizontal, .top])
                
                // Buildings list with async loading
                BuildingsList(searchText: searchText)
            }
            .navigationTitle("Buildings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Separate view for async loading
struct BuildingsList: View {
    let searchText: String
    @State private var buildings: [FrancoSphere.NamedCoordinate] = []
    
    private var filteredBuildings: [FrancoSphere.NamedCoordinate] {
        guard !searchText.isEmpty else { return buildings }
        return buildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.address ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(filteredBuildings, id: \.id) { building in
            NavigationLink(destination:
                Group {
                    if #available(iOS 15.0, *) {
                        TempBuildingDetailView(building: building)
                    } else {
                        BuildingDetailPlaceholder(building: building)
                    }
                }
            ) {
                HStack {
                    Image(systemName: "building.2.crop.circle")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text(building.name)
                            .font(.headline)
                        if let addr = building.address {
                            Text(addr)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .task {
            buildings = await BuildingRepository.shared.allBuildings
        }
    }
}

// MARK: - Temporary Building Detail Placeholder
struct BuildingDetailPlaceholder: View {
    let building: FrancoSphere.NamedCoordinate
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.25),
                    Color(red: 0.15, green: 0.2, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Building image placeholder
                    if let image = UIImage(named: building.imageAssetName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.6)],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }
                    
                    // Building info card
                    GlassCard(intensity: .regular) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(building.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if let address = building.address {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(.blue)
                                Text("Building ID: \(building.id)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    
                    // Placeholder message
                    GlassCard(intensity: .thin) {
                        VStack(spacing: 12) {
                            Image(systemName: "hammer.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Text("Building Details Coming Soon")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("The full building detail view with tasks, workers, and inventory is being prepared.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

#if DEBUG
struct BuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview the main view
        BuildingsView()
            .previewDisplayName("Buildings View")
        
        // Preview the alternative implementation
        BuildingsViewAlternative()
            .previewDisplayName("Alternative Implementation")
        
        // Preview with mock data for faster previews
        MockBuildingsView()
            .previewDisplayName("Mock Data")
    }
}

// Mock view for previews with sample data
struct MockBuildingsView: View {
    @State private var searchText = ""
    
    // Sample buildings for preview
    private let sampleBuildings = [
        FrancoSphere.NamedCoordinate(
            id: "1",
            name: "12 West 18th Street",
            latitude: 40.739750,
            longitude: -73.994424,
            address: "12 West 18th Street, New York, NY",
            imageAssetName: "12_West_18th_Street"
        ),
        FrancoSphere.NamedCoordinate(
            id: "2",
            name: "29-31 East 20th Street",
            latitude: 40.738957,
            longitude: -73.986362,
            address: "29-31 East 20th Street, New York, NY",
            imageAssetName: "29_31_East_20th_Street"
        ),
        FrancoSphere.NamedCoordinate(
            id: "3",
            name: "36 Walker Street",
            latitude: 40.718922,
            longitude: -74.002657,
            address: "36 Walker Street, New York, NY",
            imageAssetName: "36_Walker_Street"
        )
    ]
    
    private var filteredBuildings: [FrancoSphere.NamedCoordinate] {
        guard !searchText.isEmpty else { return sampleBuildings }
        return sampleBuildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.address ?? "").localizedCaseInsensitiveContains(searchText)
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
                        .disableAutocorrection(true)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding([.horizontal, .top])
                
                // List
                List(filteredBuildings, id: \.id) { building in
                    HStack {
                        Image(systemName: "building.2.crop.circle")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(building.name)
                                .font(.headline)
                            if let addr = building.address {
                                Text(addr)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Buildings (Preview)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
