//
//  MySitesCard.swift
//  FrancoSphere
//
//  🏢 MY SITES CARD - Enhanced Building Navigation (PHASE-2)
//  ✅ Shows assigned buildings with weather data
//  ✅ Error handling with fix button for Edwin diagnostics
//  ✅ Browse all buildings option
//  ✅ Building tap navigation integration
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
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
                    if workerId == "2" && assignedBuildings.isEmpty {
                        Button("Fix Edwin Buildings", action: { Task { await handleFix() } })
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Content
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if assignedBuildings.isEmpty {
                emptyStateView
            } else {
                buildingsListView
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            
            Text("Loading your assigned buildings...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Building Data Error")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Retry") {
                    Task { await handleRefresh() }
                }
                .buttonStyle(.secondary)
                
                if workerId == "2" {
                    Button("Fix Edwin Buildings") {
                        Task { await handleFix() }
                    }
                    .buttonStyle(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 40))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Buildings Assigned")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                if workerId == "2" {
                    Text("Edwin should have 8 building assignments")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                } else {
                    Text("Contact your manager to get building assignments")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 8) {
                if workerId == "2" {
                    Button {
                        Task { await handleFix() }
                    } label: {
                        HStack {
                            if isFixing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "wrench.and.screwdriver")
                            }
                            Text(isFixing ? "Fixing..." : "Fix Edwin Buildings")
                        }
                    }
                    .buttonStyle(.primary)
                }
                
                Button("Browse All Buildings", action: onBrowseAll)
                    .buttonStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Buildings List View
    
    private var buildingsListView: some View {
        VStack(spacing: 8) {
            ForEach(assignedBuildings, id: \.id) { building in
                BuildingSiteRow(
                    building: building,
                    weather: buildingWeatherMap[building.id],
                    isClockedIn: clockedInBuildingId == building.id,
                    onTap: { onBuildingTap(building) }
                )
            }
            
            // Browse all button
            if assignedBuildings.count >= 3 {
                Button("Browse All Buildings") {
                    onBrowseAll()
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        await onRefresh()
        isRefreshing = false
    }
    
    private func handleFix() async {
        guard !isFixing else { return }
        isFixing = true
        await onFixBuildings()
        isFixing = false
    }
}

// MARK: - Building Site Row

struct BuildingSiteRow: View {
    let building: FrancoSphere.NamedCoordinate
    let weather: FrancoSphere.WeatherData?
    let isClockedIn: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Building image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    )
                
                // Building info
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        // Status indicator
                        if isClockedIn {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                                Text("Active")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Weather info
                        if let weather = weather {
                            HStack(spacing: 4) {
                                Image(systemName: weather.condition.icon)
                                    .font(.caption2)
                                    .foregroundColor(weather.condition.conditionColor)
                                
                                Text(weather.formattedTemperature)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Navigation arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isClockedIn ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isClockedIn ? Color.green.opacity(0.3) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Button Styles

extension View {
    func buttonStyle(_ style: MySitesButtonStyle) -> some View {
        switch style {
        case .primary:
            return self
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
        case .secondary:
            return self
                .font(.caption.weight(.medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

enum MySitesButtonStyle {
    case primary
    case secondary
}

// MARK: - Preview

struct MySitesCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Normal state with buildings
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
                    
                    // Empty state (Edwin)
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
                    
                    // Loading state
                    MySitesCard(
                        workerId: "1",
                        workerName: "Greg Hutson",
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
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
