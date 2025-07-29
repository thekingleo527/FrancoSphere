//
//  BuildingMapDetailView.swift
//  FrancoSphere
//
//  ✅ COMPLETE VERSION: All missing components added
//  ✅ FIXED: BuildingStatCard component defined
//  ✅ FIXED: getUrgencyDisplay and getUrgencyColor methods implemented
//  ✅ ALIGNED: With CoreTypes structure
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
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [.black, .blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Building header
                        buildingHeader
                        
                        // Quick stats
                        quickStats
                        
                        // Today's tasks
                        if !tasks.isEmpty {
                            todaysTasksSection
                        }
                        
                        // Actions
                        actionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)
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
        VStack(spacing: 12) {
            // Building image
            if let buildingImage = getBuildingImage() {
                Image(uiImage: buildingImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            
            // Building info
            VStack(spacing: 4) {
                Text(building.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(building.address)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Quick Stats
    
    private var quickStats: some View {
        HStack(spacing: 16) {
            BuildingStatCard(
                title: "Open Tasks",
                value: "\(tasks.filter { !$0.isCompleted }.count)",
                icon: "list.bullet",
                color: .blue
            )
            
            BuildingStatCard(
                title: "Urgent",
                value: "\(getUrgentTaskCount())",
                icon: "exclamationmark.triangle",
                color: .orange
            )
            
            BuildingStatCard(
                title: "Completed",
                value: "\(tasks.filter { $0.isCompleted }.count)",
                icon: "checkmark.circle",
                color: .green
            )
        }
    }
    
    // MARK: - Today's Tasks Section
    
    private var todaysTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Tasks")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(tasks.prefix(5), id: \.id) { task in
                    BuildingTaskRow(task: task)
                }
            }
            
            if tasks.count > 5 {
                Button("View All \(tasks.count) Tasks") {
                    showAllTasks = true
                }
                .font(.callout)
                .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showClockIn = true }) {
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Clock In at Building")
                }
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            }
            
            Button("View Building Details") {
                showDetails = true
            }
            .font(.callout)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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

// MARK: - Building Stat Card Component

struct BuildingStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Building Task Row Component

struct BuildingTaskRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(task.isCompleted ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.callout)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Category: \(getCategoryString(task.category))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(getUrgencyDisplay(task.urgency))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(getUrgencyColor(task.urgency))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // Helper methods for safe property access
    private func getCategoryString(_ category: CoreTypes.TaskCategory?) -> String {
        return category?.rawValue.capitalized ?? "General"
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
        guard let urgency = urgency else { return .gray }
        
        switch urgency {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .urgent:
            return .orange
        case .critical:
            return .red
        case .emergency:
            return .red
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
