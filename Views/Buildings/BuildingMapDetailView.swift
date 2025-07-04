// FILE: Views/Buildings/BuildingMapDetailView.swift
//
//  BuildingMapDetailView.swift
//  FrancoSphere
//
//  🏢 FIXED BUILDING MAP DETAIL VIEW - ContextualTask integration
//  ✅ Fixed ContextualTask.status usage (not isCompleted)
//  ✅ Removed duplicate component declarations
//  ✅ Proper task filtering and display
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct BuildingMapDetailView: View {
    let building: FrancoSphere.NamedCoordinate
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contextEngine = WorkerContextEngine.shared
    
    @State private var tasks: [ContextualTask] = []
    @State private var isLoading = true
    @State private var showClockIn = false
    
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
                    Text(building.shortName)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
        }
        .onAppear {
            loadBuildingData()
        }
    }
    
    // MARK: - Building Header
    
    private var buildingHeader: some View {
        VStack(spacing: 12) {
            // Building image
            if building.hasValidImageAsset {
                Image(building.imageAssetName)
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
                
                Text(building.fullAddress)
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
                value: "\(tasks.filter { $0.status != "completed" }.count)",
                icon: "list.bullet",
                color: .blue
            )
            
            BuildingStatCard(
                title: "Urgent",
                value: "\(tasks.filter { $0.urgencyLevel == "high" }.count)",
                icon: "exclamationmark.triangle",
                color: .orange
            )
            
            BuildingStatCard(
                title: "Completed",
                value: "\(tasks.filter { $0.status == "completed" }.count)",
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
                    // TODO: Navigate to full task list
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
                // TODO: Navigate to full building detail
            }
            .font(.callout)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions
    
    private func loadBuildingData() {
        Task {
            // Load tasks for this building from real data
            let allTasks = contextEngine.getTodaysTasks()
            
            await MainActor.run {
                tasks = allTasks.filter { task in
                    // Match building by name or ID
                    task.buildingName == building.name || task.buildingId == building.id
                }
                isLoading = false
            }
        }
    }
}

// MARK: - Building-Specific Components (to avoid redeclaration)

struct BuildingTaskRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(task.status == "completed" ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.callout)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Category: \(task.category)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(task.urgencyLevel.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(task.urgencyLevel == "high" ? .red : .white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct BuildingStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
