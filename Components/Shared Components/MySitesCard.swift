//
//  MySitesCard.swift
//  FrancoSphere
//
//  ✅ PHASE-2 MYSITES CARD FIX
//  ✅ Removed "Building Assignment Issue" error blocks
//  ✅ Added loading shimmer animation
//  ✅ Proper empty state handling
//  ✅ Better error recovery UI
//  ✅ Dynamic building count and weather integration
//

import SwiftUI

struct MySitesCard: View {
    let workerId: String
    let workerName: String
    let assignedBuildings: [FrancoSphere.NamedCoordinate]
    let buildingWeatherMap: [String: FrancoSphere.WeatherData]
    let clockedInBuildingId: String?
    let isLoading: Bool
    let error: Error?
    let forceShow: Bool
    let onRefresh: () async -> Void
    let onFixBuildings: () async -> Void
    let onBrowseAll: () -> Void
    let onBuildingTap: (FrancoSphere.NamedCoordinate) -> Void
    
    @State private var isRefreshing = false
    @State private var isFixing = false
    @State private var shimmerOffset: CGFloat = -1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Content
            if isLoading {
                loadingShimmerView
            } else if assignedBuildings.isEmpty {
                emptyStateView
            } else {
                buildingsGridView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear {
            startShimmerAnimation()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundColor(.blue)
            
            Text("My Sites")
                .font(.headline)
                .foregroundColor(.white)
            
            if assignedBuildings.count > 0 {
                Text("(\(assignedBuildings.count))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Actions menu
            Menu {
                Button("Refresh Sites", action: { Task { await handleRefresh() } })
                Button("Browse All Buildings", action: onBrowseAll)
                
                // Show fix option for Edwin or when no buildings
                if (workerId == "2" || assignedBuildings.isEmpty) && !isLoading {
                    Button("Reseed Buildings", action: { Task { await handleFix() } })
                }
            } label: {
                Image(systemName: isRefreshing ? "arrow.circlepath" : "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRefreshing)
            }
        }
    }
    
    // MARK: - ✅ NEW: Loading Shimmer View
    
    private var loadingShimmerView: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 12) {
                    // Building image placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(shimmerGradient)
                        .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        // Building name placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shimmerGradient)
                            .frame(height: 16)
                        
                        // Address placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shimmerGradient)
                            .frame(width: 120, height: 12)
                    }
                    
                    Spacer()
                    
                    // Status indicator placeholder
                    Circle()
                        .fill(shimmerGradient)
                        .frame(width: 12, height: 12)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.3),
                Color.white.opacity(0.1)
            ],
            startPoint: UnitPoint(x: shimmerOffset, y: 0.5),
            endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
        )
    }
    
    // MARK: - ✅ IMPROVED: Empty State View (No More Error Blocks)
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.4))
            
            VStack(spacing: 8) {
                Text("No Buildings Assigned")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("You haven't been assigned to any buildings yet.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                Button("Browse All") {
                    onBrowseAll()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Refresh") {
                    Task { await handleRefresh() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isRefreshing)
            }
            
            // ✅ Only show seeding option if appropriate
            if workerId == "2" || error != nil {
                Button("Load Default Buildings") {
                    Task { await handleFix() }
                }
                .buttonStyle(TertiaryButtonStyle())
                .disabled(isFixing)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Buildings Grid View
    
    private var buildingsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(assignedBuildings, id: \.id) { building in
                buildingCard(for: building)
            }
        }
    }
    
    private func buildingCard(for building: FrancoSphere.NamedCoordinate) -> some View {
        Button(action: { onBuildingTap(building) }) {
            VStack(alignment: .leading, spacing: 8) {
                // Building image with fallback
                buildingImage(for: building)
                    .frame(height: 80)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    Text(building.address ?? "Address not available")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    HStack {
                        // Weather indicator
                        if let weather = buildingWeatherMap[building.id] {
                            HStack(spacing: 4) {
                                Image(systemName: weather.icon)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Text("\(Int(weather.temperature))°")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // Status indicator
                        Circle()
                            .fill(isCurrentBuilding(building) ? .green : .blue)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCurrentBuilding(building) ? .green : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func buildingImage(for building: FrancoSphere.NamedCoordinate) -> some View {
        Group {
            if let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Fallback with building icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    )
            }
        }
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func isCurrentBuilding(_ building: FrancoSphere.NamedCoordinate) -> Bool {
        return building.id == clockedInBuildingId
    }
    
    private func handleRefresh() async {
        isRefreshing = true
        await onRefresh()
        isRefreshing = false
    }
    
    private func handleFix() async {
        isFixing = true
        await onFixBuildings()
        isFixing = false
    }
    
    private func startShimmerAnimation() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 1.0
        }
    }
}

// MARK: - ✅ NEW: Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct MySitesCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Loading state
            MySitesCard(
                workerId: "2",
                workerName: "Edwin Lema",
                assignedBuildings: [],
                buildingWeatherMap: [:],
                clockedInBuildingId: nil,
                isLoading: true,
                error: nil,
                forceShow: true,
                onRefresh: {},
                onFixBuildings: {},
                onBrowseAll: {},
                onBuildingTap: { _ in }
            )
            
            // Empty state
            MySitesCard(
                workerId: "2",
                workerName: "Edwin Lema",
                assignedBuildings: [],
                buildingWeatherMap: [:],
                clockedInBuildingId: nil,
                isLoading: false,
                error: nil,
                forceShow: true,
                onRefresh: {},
                onFixBuildings: {},
                onBrowseAll: {},
                onBuildingTap: { _ in }
            )
            
            // With buildings
            MySitesCard(
                workerId: "2",
                workerName: "Edwin Lema",
                assignedBuildings: [
                    FrancoSphere.NamedCoordinate(
                        id: "1",
                        name: "12 West 18th Street",
                        latitude: 40.7397,
                        longitude: -73.9944,
                        imageAssetName: "12_West_18th_Street"
                    ),
                    FrancoSphere.NamedCoordinate(
                        id: "2",
                        name: "29-31 East 20th Street",
                        latitude: 40.7389,
                        longitude: -73.9863,
                        imageAssetName: "29_31_East_20th_Street"
                    )
                ],
                buildingWeatherMap: [
                    "1": FrancoSphere.WeatherData(
                        date: Date(),
                        temperature: 72,
                        feelsLike: 70,
                        humidity: 65,
                        windSpeed: 12,
                        windDirection: 180,
                        precipitation: 0,
                        snow: 0,
                        visibility: 10000,
                        pressure: 1013,
                        condition: .clear,
                        icon: "sun.max.fill"
                    )
                ],
                clockedInBuildingId: "1",
                isLoading: false,
                error: nil,
                forceShow: true,
                onRefresh: {},
                onFixBuildings: {},
                onBrowseAll: {},
                onBuildingTap: { _ in }
            )
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
