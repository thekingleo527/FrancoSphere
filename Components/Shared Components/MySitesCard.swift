//
//  MySitesCard.swift - REAL DATA INTEGRATION FIX
//  FrancoSphere
//
//  ✅ 3. MY SITES CARD: Real data integration with WorkerContextEngine counts
//  ✅ 3. Uses getTaskCount(forBuilding:) and getCompletedTaskCount for each cell
//  ✅ 3. Removes emergency placeholders, relies on CSV fallback in WorkerDashboardView
//  ✅ 6. GLASSMORPHISM: Consistent .ultraThinMaterial styling
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct MySitesCard: View {
    let onRefresh: () async -> Void
    let onBrowseAll: () -> Void
    let onBuildingTap: (NamedCoordinate) -> Void
    
    // ✅ 3. REAL DATA: Integration with WorkerContextEngine
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    @State private var isLoading = false
    
    // Get real assigned buildings from context engine
    private var buildings: [NamedCoordinate] {
        contextEngine.getAssignedBuildings()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with refresh and browse actions
            header
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Content
            if isLoading {
                loadingView
            } else if buildings.isEmpty {
                emptyStateView
            } else {
                buildingsGridView
            }
        }
        // ✅ 6. GLASSMORPHISM: Consistent .ultraThinMaterial styling
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("My Sites")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if !buildings.isEmpty {
                    Text("\(buildings.count) assigned")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Menu {
                Button("Refresh Sites") {
                    Task {
                        isLoading = true
                        await onRefresh()
                        isLoading = false
                    }
                }
                Button("Browse All Buildings") {
                    onBrowseAll()
                }
            } label: {
                Image(systemName: isLoading ? "arrow.circlepath" : "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
            }
        }
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
    
    // ✅ 3. EMPTY STATE: Removed emergency placeholders, clean empty state
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.4))
            
            VStack(spacing: 6) {
                Text("No Buildings Assigned")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Contact your supervisor to get building assignments")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Simple action buttons (no emergency fixes)
            HStack(spacing: 12) {
                Button("Browse All") {
                    onBrowseAll()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Refresh") {
                    Task {
                        isLoading = true
                        await onRefresh()
                        isLoading = false
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    // ✅ 3. BUILDINGS GRID: Real data with live task counts
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
    
    private var moreBuildings: some View {
        Button {
            onBrowseAll()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("+\(buildings.count - 4) more")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ✅ 3. BUILDING SITE CARD: Real data integration with live task counts
struct BuildingSiteCard: View {
    let building: NamedCoordinate
    let onTap: () -> Void
    
    // ✅ 3. REAL DATA: Live task counts from WorkerContextEngine
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    
    private var totalTasks: Int {
        contextEngine.getTaskCount(for: building.id)
    }
    
    private var completedTasks: Int {
        contextEngine.getCompletedTaskCount(for: building.id)
    }
    
    private var openTasks: Int {
        totalTasks - completedTasks
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Building image
                buildingImage
                
                // Building info
                VStack(spacing: 4) {
                    Text(building.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    // ✅ 3. LIVE TASK COUNTS: Real data from WorkerContextEngine
                    taskCountBadge
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buildingImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 50)
            .overlay(
                Image(building.imageAssetName ?? "placeholder")
                    .resizable()
                    .scaledToFill()
                    .clipped()
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // ✅ 3. TASK COUNT BADGE: Live counts from WorkerContextEngine
    private var taskCountBadge: some View {
        HStack(spacing: 4) {
            if totalTasks > 0 {
                // Show completion ratio
                Text("\(completedTasks)/\(totalTasks)")
                    .font(.caption2)
                    .foregroundColor(completedTasks == totalTasks ? .green : .white.opacity(0.6))
                
                if openTasks > 0 {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                }
            } else {
                Text("No tasks")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Supporting Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
