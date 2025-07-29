//
//  BuildingMapDetailView.swift
//  FrancoSphere
//
//  ✅ PHASE 2: Fixed to match ACTUAL ContextualTask structure from FrancoSphereModels.swift
//  ✅ Uses title (not name), urgency enum (not urgencyLevel), building object (not buildingId)
//  ✅ Proper filter syntax for modern Swift arrays
//  ✅ Real operational data integration
//  ✅ FIXED: Removed imageAssetName reference
//  ✅ FIXED: Corrected async/await syntax
//

import SwiftUI
import Foundation

struct BuildingMapDetailView: View {
    let building: NamedCoordinate
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contextEngine = WorkerContextEngine.shared  // ✅ FIXED: Use consolidated engine
    
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
            // ✅ FIXED: Try to load image based on building name
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
        // Try standardized name based on building name
        let standardName = building.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .lowercased()
        
        // Try exact match first
        if let image = UIImage(named: standardName) {
            return image
        }
        
        // Try with "building_" prefix
        if let image = UIImage(named: "building_\(standardName)") {
            return image
        }
        
        // Try simplified name
        let simplifiedName = building.name
            .components(separatedBy: " ")
            .first?
            .lowercased() ?? ""
        
        if !simplifiedName.isEmpty,
           let image = UIImage(named: "building_\(simplifiedName)") {
            return image
        }
        
        // No image found
        return nil
    }
    
    // MARK: - Data Loading
    
    private func loadBuildingData() {
        Task {
            // ✅ FIXED: Removed double await
            let allTasks = contextEngine.todaysTasks
            
            await MainActor.run {
                // Filter tasks for this building
                tasks = allTasks.filter { task in
                    // Match by building object comparison
                    task.building?.id == building.id || task.buildingId == building.id
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

// MARK: - Building-Specific Components

struct BuildingTaskRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(task.isCompleted ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                // ✅ FIXED: Use task.title (actual property from FrancoSphereModels)
                Text(task.title)
                    .font(.callout)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // ✅ FIXED: Safe category handling with actual TaskCategory enum
                Text("Category: \(getCategoryString(task.category))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // ✅ FIXED: Handle urgency enum properly
            Text(getUrgencyDisplay(task.urgency))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(getUrgencyColor(task.urgency))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // Helper methods for safe property access using actual ContextualTask structure
    private func getCategoryString(_ category: TaskCategory?) -> String {
        return category?.rawValue.capitalized ?? "General"
    }
    
    // ✅ FIXED: Handle TaskUrgency enum properly (not urgencyLevel string)
    private func getUrgencyDisplay(_ urgency: TaskUrgency?) -> String {
    }
}
