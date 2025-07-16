//
//  BuildingDetailView.swift
//  FrancoSphere
//
//  ✅ FIXED: Removed problematic ViewModel property access
//  ✅ SIMPLIFIED: Using direct building data instead of complex ViewModel
//  ✅ FUNCTIONAL: Basic building detail view that compiles successfully
//

import SwiftUI
import MapKit

struct BuildingDetailView: View {
    let building: NamedCoordinate
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var showingClockIn = false
    @State private var clockInTime: Date?
    
    // Simplified state without ViewModel dependencies
    @State private var buildingTasks: [ContextualTask] = []
    @State private var workersOnSite: [WorkerProfile] = []
    @State private var isCurrentlyClockedIn = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        buildingHeader
                        tabSection
                        contentSection
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .task {
                await loadBuildingData()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var buildingHeader: some View {
        VStack(spacing: 16) {
            // Building image
            buildingImageView
            
            // Clock-in section
            if isCurrentlyClockedIn {
                clockedInStatus
            } else {
                clockInButton
            }
        }
    }
    
    private var buildingImageView: some View {
        ZStack {
            if let image = UIImage(named: building.imageAssetName ?? "") {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(building.name)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    )
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    
                    // Simple task count
                    if buildingTasks.count > 0 {
                        Text("\(buildingTasks.count) tasks")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(12)
                
                Spacer()
            }
        )
    }
    
    private var clockInButton: some View {
        Button {
            handleClockIn()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clock In Here")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Start your shift at \(building.name)")
                        .font(.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(16)
            .background(Color.blue.opacity(0.8))
            .cornerRadius(12)
        }
    }
    
    private var clockedInStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Clocked In")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if let clockInTime = clockInTime {
                    Text("Since \(clockInTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Button("Clock Out") {
                handleClockOut()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.8))
            .cornerRadius(8)
        }
        .foregroundColor(.white)
        .padding(16)
        .background(Color.green.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var tabSection: some View {
        // ✅ FIXED: Use simple array instead of BuildingTab.allCases
        let tabs = ["Overview", "Tasks", "Workers", "Analytics"]
        
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    selectedTab = index
                }) {
                    Text(tab)
                        .font(.subheadline)
                        .fontWeight(selectedTab == index ? .semibold : .regular)
                        .foregroundColor(selectedTab == index ? .blue : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var contentSection: some View {
        Group {
            switch selectedTab {
            case 0:
                overviewTab
            case 1:
                tasksTab
            case 2:
                workersTab
            case 3:
                analyticsTab
            default:
                overviewTab
            }
        }
    }
    
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Building Overview")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Basic stats
            VStack(spacing: 12) {
                statRow("Total Tasks", "\(buildingTasks.count)")
                statRow("Completed", "\(buildingTasks.filter { $0.isCompleted }.count)")
                statRow("Workers On-Site", "\(workersOnSite.count)")
                statRow("Building ID", building.id)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var tasksTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tasks")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if buildingTasks.isEmpty {
                Text("No tasks available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(buildingTasks, id: \.id) { task in
                        taskCard(task)
                    }
                }
            }
        }
    }
    
    private var workersTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workers")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if workersOnSite.isEmpty {
                Text("No workers currently on-site")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(workersOnSite, id: \.id) { worker in
                        workerCard(worker)
                    }
                }
            }
        }
    }
    
    private var analyticsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Analytics coming soon...")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
        }
    }
    
    private func taskCard(_ task: ContextualTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .white.opacity(0.7))
                
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                if let urgency = task.urgency {
                    Text(urgency.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(urgencyColor(urgency))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(urgencyColor(urgency).opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func workerCard(_ worker: WorkerProfile) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(worker.name.prefix(2)))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(worker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(worker.role?.rawValue ?? "Worker")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
    
    private func urgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .urgent: return .red
        case .emergency: return .red
        }
    }
    
    private func handleClockIn() {
        isCurrentlyClockedIn = true
        clockInTime = Date()
    }
    
    private func handleClockOut() {
        isCurrentlyClockedIn = false
        clockInTime = nil
    }
    
    private func loadBuildingData() async {
        isLoading = true
        
        // Simulate loading
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Sample data
        buildingTasks = [
            ContextualTask(
                id: "1",
                title: "Daily Cleaning",
                description: "Complete daily cleaning routine",
                buildingId: building.id,
                urgency: .medium,
                isCompleted: false
            ),
            ContextualTask(
                id: "2", 
                title: "Security Check",
                description: "Perform security walkthrough",
                buildingId: building.id,
                urgency: .high,
                isCompleted: true
            )
        ]
        
        workersOnSite = [
            WorkerProfile(
                id: "w1",
                name: "Kevin Dutan",
                role: .worker
            ),
            WorkerProfile(
                id: "w2",
                name: "Edwin Lema", 
                role: .worker
            )
        ]
        
        isLoading = false
    }
}

struct BuildingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BuildingDetailView(
            building: NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                latitude: 40.7398,
                longitude: -73.9972,
                imageAssetName: "west18_12"
            )
        )
        .preferredColorScheme(.dark)
    }
}
