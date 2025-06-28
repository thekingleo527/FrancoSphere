//
//  MySitesCard.swift - SIMPLIFIED DATA DISPLAYER
//  FrancoSphere
//
//  🎯 PHASE-3 CRITICAL FIX: Pure data display component
//  ✅ Uses WorkerContextEngine.shared as single source of truth
//  ✅ No data loading, CSV imports, or retry logic
//  ✅ Simple display of real Kevin assignments
//  🚫 Removed all emergency fixes and complex state management
//

import SwiftUI

struct MySitesCard: View {
    // MARK: - Simple Data Source
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    
    // MARK: - Callback Props
    let onRefresh: () async -> Void
    let onBrowseAll: () -> Void
    let onBuildingTap: (FrancoSphere.NamedCoordinate) -> Void
    
    // MARK: - Simple Computed Properties
    
    private var buildings: [FrancoSphere.NamedCoordinate] {
        contextEngine.getAssignedBuildings()
    }
    
    private var isLoading: Bool {
        contextEngine.isLoading
    }
    
    private var workerName: String {
        contextEngine.getWorkerName()
    }
    
    private var workerId: String {
        contextEngine.getWorkerId()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text("My Sites")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if buildings.count > 0 {
                    Text("(\(buildings.count))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Simple actions menu
                Menu {
                    Button("Refresh", action: { Task { await onRefresh() } })
                    Button("Browse All", action: onBrowseAll)
                } label: {
                    Image(systemName: isLoading ? "arrow.circlepath" : "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                }
            }
            
            // Content
            if isLoading {
                loadingView
            } else if buildings.isEmpty {
                emptyStateView
            } else {
                buildingsGridView
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            
            Text("Loading your sites...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.4))
            
            VStack(spacing: 6) {
                Text("No Buildings Assigned")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(getEmptyStateMessage())
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Simple action buttons
            HStack(spacing: 12) {
                Button("Browse All") {
                    onBrowseAll()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Refresh") {
                    Task { await onRefresh() }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    // MARK: - Buildings Grid View
    
    private var buildingsGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
            ForEach(buildings.prefix(4), id: \.id) { building in
                BuildingSiteCard(building: building) {
                    onBuildingTap(building)
                }
            }
            
            if buildings.count > 4 {
                moreBuildings
            }
        }
    }
    
    // MARK: - More Buildings Card
    
    private var moreBuildings: some View {
        Button(action: onBrowseAll) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("+\(buildings.count - 4) more")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    private func getEmptyStateMessage() -> String {
        if workerId == "4" {
            return "Kevin should have 6+ buildings assigned (expanded duties). Try refreshing."
        } else if !workerName.isEmpty {
            return "\(workerName) hasn't been assigned to any buildings yet."
        } else {
            return "You haven't been assigned to any buildings yet."
        }
    }
}

// MARK: - Building Site Card

struct BuildingSiteCard: View {
    let building: FrancoSphere.NamedCoordinate
    let onTap: () -> Void
    
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    
    private var taskCount: Int {
        contextEngine.getTaskCount(forBuilding: building.id)
    }
    
    private var completedCount: Int {
        contextEngine.getCompletedTaskCount(forBuilding: building.id)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Building image or icon
                AsyncImage(url: URL(string: "building_\(building.imageAssetName)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Building name
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Task count
                if taskCount > 0 {
                    Text("\(completedCount)/\(taskCount)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Button Styles

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
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
