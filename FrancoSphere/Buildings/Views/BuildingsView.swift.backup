//
//  BuildingsView.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ Shows a searchable list of all portfolio buildings
//  ✅ Proper optional handling and async/await patterns
//  ✅ Compatible with current BuildingService API
//

import SwiftUI
import MapKit

struct BuildingsView: View {
    
    // Buildings loaded asynchronously from the repository
    @State private var buildings: [NamedCoordinate] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var errorMessage: String?
    
    // Filter helper
    private var filteredBuildings: [NamedCoordinate] {
        guard !searchText.isEmpty else { return buildings }
        return buildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
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
                    List(filteredBuildings, id: \.id) { building in
                        NavigationLink {
                            // Use BuildingDetailPlaceholder for now
                            BuildingDetailPlaceholder(building: building)
                        } label: {
                            // Building row view
                            buildingRow(for: building)
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
    private func buildingRow(for building: NamedCoordinate) -> some View {
        HStack(spacing: 12) {
            // ✅ FIXED: Proper optional handling for imageAssetName
            if let imageAssetName = building.imageAssetName,
               let uiImage = UIImage(named: imageAssetName) {
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
                
                // Show coordinates or address if available
                if let address = building.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Lat: \(building.latitude, specifier: "%.4f"), Lng: \(building.longitude, specifier: "%.4f")")
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
        errorMessage = nil
        
        do {
            // ✅ FIXED: Add try await for BuildingService.shared.getAllBuildings()
            let loadedBuildings = try await BuildingService.shared.getAllBuildings()
            
            // Update on main thread
            await MainActor.run {
                self.buildings = loadedBuildings
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load buildings: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// MARK: - Building Detail Placeholder
struct BuildingDetailPlaceholder: View {
    let building: NamedCoordinate
    @State private var assignedWorkers: String = "Loading..."
    @State private var isLoadingData = true
    @State private var workerProfiles: [WorkerProfile] = []
    
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
                    buildingImageView
                    
                    // Building info card - using manual glass effect
                    buildingInfoCard
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task {
            await loadBuildingData()
        }
    }
    
    // MARK: - Building Image View
    private var buildingImageView: some View {
        Group {
            // ✅ FIXED: Proper optional handling for imageAssetName
            if let imageAssetName = building.imageAssetName,
               let image = UIImage(named: imageAssetName) {
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
        }
    }
    
    // MARK: - Building Info Card
    private var buildingInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(building.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                if let address = building.address {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("Lat: \(building.latitude, specifier: "%.4f"), Lng: \(building.longitude, specifier: "%.4f")")
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
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Assigned Workers
            VStack(alignment: .leading, spacing: 8) {
                Text("Assigned Workers")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if isLoadingData {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if workerProfiles.isEmpty {
                    Text("No workers assigned")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    ForEach(workerProfiles, id: \.id) { worker in
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue.opacity(0.8))
                                .font(.caption)
                            Text(worker.name)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            Text("(\(worker.role.rawValue.capitalized))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            
            // Additional building metrics could go here
            if !workerProfiles.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Stats")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.green.opacity(0.8))
                            .font(.caption)
                        Text("\(workerProfiles.count) worker(s) assigned")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange.opacity(0.8))
                            .font(.caption)
                        Text("Active building operations")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - Data Loading
    private func loadBuildingData() async {
        isLoadingData = true
        
        do {
            //
        }
    }
}
