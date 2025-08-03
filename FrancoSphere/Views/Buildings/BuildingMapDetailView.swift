//
//  BuildingMapDetailView.swift
//  FrancoSphere
//
//  ✅ REFACTORED: Dark Elegant Design aligned with FrancoSphereDesign
//  ✅ GLASS MORPHISM: Using AdaptiveGlassModifier components
//  ✅ CONSISTENT: Matches WorkerDashboardView patterns
//  ✅ DARK THEME: Full dark elegance implementation
//  ✅ FIXED: Renamed BuildingStatCard to avoid redeclaration
//

import SwiftUI
import Foundation

struct BuildingMapDetailView: View {
    let building: NamedCoordinate
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    
    @State private var tasks: [ContextualTask] = []
    @State private var isLoading = true
    @State private var showClockIn = false
    @State private var showAllTasks = false
    @State private var showDetails = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark elegant background
                FrancoSphereDesign.DashboardGradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Building header with glass effect
                        buildingHeader
                            .animatedGlassAppear(delay: 0.1)
                        
                        // Quick stats with glass cards
                        quickStats
                            .animatedGlassAppear(delay: 0.2)
                        
                        // Today's tasks with glass container
                        if !tasks.isEmpty {
                            todaysTasksSection
                                .animatedGlassAppear(delay: 0.3)
                        }
                        
                        // Actions with glass buttons
                        actionsSection
                            .animatedGlassAppear(delay: 0.4)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Loading overlay
                if isLoading {
                    GlassLoadingState()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(FrancoSphereDesign.DashboardColors.baseBackground.opacity(0.8))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(building.name)
                        .glassHeading()
                        .lineLimit(1)
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .navigationDestination(isPresented: $showAllTasks) {
                TaskScheduleView(buildingID: building.id)
            }
            .navigationDestination(isPresented: $showDetails) {
                BuildingDetailView(building: building)
            }
        }
        .onAppear {
            loadBuildingData()
        }
    }
    
    // MARK: - Building Header
    
    private var buildingHeader: some View {
        VStack(spacing: 16) {
            // Building image with glass overlay
            ZStack {
                if let buildingImage = getBuildingImage() {
                    Image(uiImage: buildingImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.large))
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    FrancoSphereDesign.DashboardColors.baseBackground.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.large))
                        )
                } else {
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.large)
                        .fill(.ultraThinMaterial)
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        )
                }
            }
            .francoGlassCard(intensity: .ultraThin)
            
            // Building info with glass text
            VStack(spacing: 8) {
                Text(building.name)
                    .glassHeading()
                    .multilineTextAlignment(.center)
                
                Text(building.address)
                    .glassSubtitle()
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Quick Stats
    
    private var quickStats: some View {
        HStack(spacing: 16) {
            BuildingQuickStatCard(
                title: "Open Tasks",
                value: "\(tasks.filter { !$0.isCompleted }.count)",
                icon: "list.bullet",
                color: FrancoSphereDesign.DashboardColors.info
            )
            
            BuildingQuickStatCard(
                title: "Urgent",
                value: "\(getUrgentTaskCount())",
                icon: "exclamationmark.triangle",
                color: FrancoSphereDesign.DashboardColors.warning
            )
            
            BuildingQuickStatCard(
                title: "Completed",
                value: "\(tasks.filter { $0.isCompleted }.count)",
                icon: "checkmark.circle",
                color: FrancoSphereDesign.DashboardColors.success
            )
        }
    }
    
    // MARK: - Today's Tasks Section
    
    private var todaysTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Tasks")
                .glassHeading()
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(tasks.prefix(5), id: \.id) { task in
                    BuildingTaskRow(task: task)
                        .transition(.glassSlideUp)
                }
            }
            
            if tasks.count > 5 {
                Button(action: { showAllTasks = true }) {
                    HStack {
                        Text("View All \(tasks.count) Tasks")
                        Image(systemName: "chevron.right")
                    }
                    .glassText(size: .callout)
                }
                .glassButton(style: .ghost, size: .medium)
            }
        }
        .padding(20)
        .francoGlassCard(intensity: .regular)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Button(action: { showClockIn = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                    Text("Clock In at Building")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .glassButton(style: .success, size: .large)
            .pulsingGlow(color: .green)
            
            Button(action: { showDetails = true }) {
                HStack {
                    Text("View Building Details")
                    Image(systemName: "arrow.right.circle")
                }
                .frame(maxWidth: .infinity)
            }
            .glassButton(style: .secondary, size: .medium)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getBuildingImage() -> UIImage? {
        // Map building IDs to their image assets
        switch building.id {
        case "14", "15":
            return UIImage(named: "Rubin_Museum_142_148_West_17th_Street")
        case "1":
            return UIImage(named: "building_12w18")
        case "2":
            return UIImage(named: "building_29e20")
        case "3":
            return UIImage(named: "building_133e15")
        case "4":
            return UIImage(named: "building_104franklin")
        case "5":
            return UIImage(named: "building_36walker")
        case "6":
            return UIImage(named: "building_68perry")
        case "7":
            return UIImage(named: "building_136w17")
        case "8":
            return UIImage(named: "building_41elizabeth")
        case "9":
            return UIImage(named: "building_117w17")
        case "10":
            return UIImage(named: "building_123first")
        case "11":
            return UIImage(named: "building_131perry")
        case "12":
            return UIImage(named: "building_135w17")
        case "13":
            return UIImage(named: "building_138w17")
        case "16":
            return UIImage(named: "stuyvesant_park")
        default:
            // Try to create a name from the building name
            let cleanName = building.name
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "-", with: "_")
            return UIImage(named: cleanName)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadBuildingData() {
        Task {
            let allTasks = contextAdapter.getTodaysTasks()
            
            await MainActor.run {
                // Filter tasks for this building
                tasks = allTasks.filter { task in
                    task.buildingId == building.id
                }
                isLoading = false
            }
        }
    }
    
    // Helper method for urgent task counting using actual urgency enum
    private func getUrgentTaskCount() -> Int {
        return tasks.filter { task in
            guard let urgency = task.urgency else { return false }
            switch urgency {
            case .high, .critical, .urgent, .emergency:
                return true
            case .medium, .low:
                return false
            }
        }.count
    }
}


// MARK: - Building Task Row Component

struct BuildingTaskRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator with glow
            Circle()
                .fill(task.isCompleted ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.warning)
                .frame(width: 10, height: 10)
                .shadow(color: task.isCompleted ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.warning, radius: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .glassText(size: .callout)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(getCategoryString(task.category), systemImage: getCategoryIcon(task.category))
                        .glassCaption()
                }
            }
            
            Spacer()
            
            // Urgency badge with glass effect
            Text(getUrgencyDisplay(task.urgency))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(getUrgencyColor(task.urgency).opacity(0.8))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.small)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.small)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .glassHover()
    }
    
    // Helper methods for safe property access
    private func getCategoryString(_ category: CoreTypes.TaskCategory?) -> String {
        return category?.rawValue.capitalized ?? "General"
    }
    
    private func getCategoryIcon(_ category: CoreTypes.TaskCategory?) -> String {
        guard let category = category else { return "folder" }
        
        switch category {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.and.screwdriver"
        case .repair: return "hammer"
        case .sanitation: return "trash"
        case .inspection: return "magnifyingglass"
        case .landscaping: return "leaf"
        case .security: return "shield"
        case .emergency: return "exclamationmark.triangle"
        case .installation: return "plus.circle"
        case .utilities: return "bolt"
        case .renovation: return "paintbrush"
        case .administrative: return "folder"
        }
    }
    
    private func getUrgencyDisplay(_ urgency: CoreTypes.TaskUrgency?) -> String {
        guard let urgency = urgency else { return "Normal" }
        
        switch urgency {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .urgent:
            return "Urgent"
        case .critical:
            return "Critical"
        case .emergency:
            return "Emergency"
        }
    }
    
    private func getUrgencyColor(_ urgency: CoreTypes.TaskUrgency?) -> Color {
        guard let urgency = urgency else { return FrancoSphereDesign.DashboardColors.secondaryText }
        
        switch urgency {
        case .low:
            return FrancoSphereDesign.DashboardColors.success
        case .medium:
            return FrancoSphereDesign.DashboardColors.info
        case .high:
            return FrancoSphereDesign.DashboardColors.warning
        case .urgent:
            return FrancoSphereDesign.DashboardColors.warning
        case .critical:
            return FrancoSphereDesign.DashboardColors.critical
        case .emergency:
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
}

// MARK: - Preview

struct BuildingMapDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BuildingMapDetailView(
                building: NamedCoordinate(
                    id: "14",
                    name: "Rubin Museum",
                    address: "150 W 17th St, New York, NY 10011",
                    latitude: 40.7402,
                    longitude: -73.9980
                )
            )
        }
        .preferredColorScheme(.dark)
    }
}
