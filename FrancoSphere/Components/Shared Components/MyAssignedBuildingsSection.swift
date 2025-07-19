//
//  MyAssignedBuildingsSection.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: BuildingMetricsService actor usage (removed @StateObject)
//  ✅ FIXED: Uses CoreTypes.BuildingMetrics instead of BuildingMetrics
//  ✅ ALIGNED: With existing BuildingMetricsService actor pattern
//  ✅ ENHANCED: Proper async/await patterns for actor service calls
//

import SwiftUI

struct MyAssignedBuildingsSection: View {
    let buildings: [NamedCoordinate]
    let primaryBuilding: NamedCoordinate?
    let onBuildingTap: (NamedCoordinate) -> Void
    let onShowAllBuildings: () -> Void
    
    // FIXED: Remove @StateObject wrapper - BuildingMetricsService is an actor, not ObservableObject
    private let buildingMetricsService = BuildingMetricsService.shared
    
    @State private var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @State private var isLoadingMetrics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader
            
            if buildings.isEmpty {
                emptyState
            } else {
                buildingsList
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task {
            await loadAllBuildingMetrics()
        }
    }
    
    // MARK: - Section Header
    
    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Buildings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(buildings.count) assigned building\(buildings.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Coverage access button
            Button(action: onShowAllBuildings) {
                HStack(spacing: 4) {
                    Text("View All")
                    Image(systemName: "arrow.right.circle")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Buildings List
    
    private var buildingsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(buildings, id: \.id) { building in
                MyBuildingCard(
                    building: building,
                    isPrimary: building.id == primaryBuilding?.id,
                    metrics: buildingMetrics[building.id],
                    isLoadingMetrics: isLoadingMetrics,
                    onTap: { onBuildingTap(building) }
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("No Buildings Assigned")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Contact your supervisor to get building assignments.")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
    }
    
    // MARK: - Metrics Loading
    
    private func loadAllBuildingMetrics() async {
        isLoadingMetrics = true
        
        await withTaskGroup(of: (String, CoreTypes.BuildingMetrics?).self) { group in
            for building in buildings {
                group.addTask {
                    do {
                        // FIXED: Proper async actor call to BuildingMetricsService
                        let metrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                        return (building.id, metrics)
                    } catch {
                        print("❌ Failed to load metrics for building \(building.id): \(error)")
                        return (building.id, nil)
                    }
                }
            }
            
            for await (buildingId, metrics) in group {
                if let metrics = metrics {
                    buildingMetrics[buildingId] = metrics
                }
            }
        }
        
        isLoadingMetrics = false
    }
}

// MARK: - My Building Card Component

struct MyBuildingCard: View {
    let building: NamedCoordinate
    let isPrimary: Bool
    let metrics: CoreTypes.BuildingMetrics?
    let isLoadingMetrics: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Building image
                buildingImage
                
                // Building info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(building.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        if isPrimary {
                            primaryBadge
                        }
                    }
                    
                    // Metrics display
                    if isLoadingMetrics {
                        loadingMetrics
                    } else if let metrics = metrics {
                        buildingMetrics(metrics)
                    } else {
                        Text("Metrics unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Navigation indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPrimary ? .blue.opacity(0.2) : .gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPrimary ? .blue : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Building Image
    
    private var buildingImage: some View {
        AsyncImage(url: URL(string: building.imageAssetName ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "building.2")
                        .font(.title2)
                        .foregroundColor(.secondary)
                )
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Primary Badge
    
    private var primaryBadge: some View {
        Text("PRIMARY")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.blue.opacity(0.2))
            .clipShape(Capsule())
    }
    
    // MARK: - Loading Metrics
    
    private var loadingMetrics: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.6)
            
            Text("Loading metrics...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Building Metrics Display
    
    private func buildingMetrics(_ metrics: CoreTypes.BuildingMetrics) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Completion indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(completionColor(metrics.completionRate))
                        .frame(width: 8, height: 8)
                    
                    Text("\(Int(metrics.completionRate * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Worker status
                if metrics.hasWorkerOnSite {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        
                        Text("Worker on site")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Task summary
            if metrics.pendingTasks > 0 || metrics.overdueTasks > 0 {
                HStack {
                    if metrics.pendingTasks > 0 {
                        Text("\(metrics.pendingTasks) pending")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    if metrics.overdueTasks > 0 {
                        Text("\(metrics.overdueTasks) overdue")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            } else {
                Text("All tasks complete")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func completionColor(_ rate: Double) -> Color {
        switch rate {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview

struct MyAssignedBuildingsSection_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuildings = [
            NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                latitude: 40.7402,
                longitude: -73.9980,
                imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
            ),
            NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                latitude: 40.7398,
                longitude: -73.9972,
                imageAssetName: "12_West_18th_Street"
            ),
            NamedCoordinate(
                id: "10",
                name: "131 Perry Street",
                latitude: 40.7348,
                longitude: -74.0063,
                imageAssetName: "131_Perry_Street"
            )
        ]
        
        let primaryBuilding = sampleBuildings[0]
        
        VStack(spacing: 20) {
            MyAssignedBuildingsSection(
                buildings: sampleBuildings,
                primaryBuilding: primaryBuilding,
                onBuildingTap: { building in
                    print("Building tapped: \(building.name)")
                },
                onShowAllBuildings: {
                    print("Show all buildings tapped")
                }
            )
            
            // Empty state preview
            MyAssignedBuildingsSection(
                buildings: [],
                primaryBuilding: nil,
                onBuildingTap: { _ in },
                onShowAllBuildings: { }
            )
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
