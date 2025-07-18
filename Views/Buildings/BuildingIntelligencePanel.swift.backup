//
//  BuildingIntelligencePanel.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: Building intelligence panel with coverage access
//  ✅ REAL DATA: Integrates with existing services
//

import SwiftUI

struct BuildingIntelligencePanel: View {
    let building: NamedCoordinate
    @Binding var selectedTab: IntelligenceTab
    
    @StateObject private var intelligenceVM = BuildingIntelligenceViewModel()
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @Environment(\.dismiss) private var dismiss
    
    enum IntelligenceTab: String, CaseIterable {
        case overview = "Overview"
        case workers = "All Workers"
        case schedule = "Full Schedule"
        case history = "History"
        case emergency = "Emergency"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .workers: return "person.3.fill"
            case .schedule: return "calendar.badge.clock"
            case .history: return "clock.arrow.circlepath"
            case .emergency: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    private var isMyBuilding: Bool {
        contextAdapter.assignedBuildings.contains { $0.id == building.id }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                intelligenceTabBar
                
                // Content
                ScrollView {
                    Group {
                        switch selectedTab {
                        case .overview:
                            BuildingOverviewTab(
                                building: building,
                                isMyBuilding: isMyBuilding,
                                intelligenceVM: intelligenceVM
                            )
                            
                        case .workers:
                            AllWorkersTab(
                                building: building,
                                intelligenceVM: intelligenceVM
                            )
                            
                        case .schedule:
                            FullScheduleTab(
                                building: building,
                                intelligenceVM: intelligenceVM
                            )
                            
                        case .history:
                            BuildingHistoryTab(
                                building: building,
                                intelligenceVM: intelligenceVM
                            )
                            
                        case .emergency:
                            EmergencyInfoTab(
                                building: building,
                                intelligenceVM: intelligenceVM
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(building.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                if !isMyBuilding {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        coverageIndicator
                    }
                }
            }
        }
        .task {
            await intelligenceVM.loadCompleteIntelligence(for: building)
        }
    }
    
    private var intelligenceTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(IntelligenceTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.title3)
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            selectedTab == tab ? 
                            Color.blue.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
    }
    
    private var coverageIndicator: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.orange)
            Text("Coverage")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
}

// MARK: - Tab Content Views

struct BuildingOverviewTab: View {
    let building: NamedCoordinate
    let isMyBuilding: Bool
    @ObservedObject var intelligenceVM: BuildingIntelligenceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !isMyBuilding {
                CoverageInfoCard(building: building)
            }
            
            // Building metrics
            if let metrics = intelligenceVM.metrics {
                BuildingMetricsCard(metrics: metrics)
            }
            
            // Current status
            CurrentStatusCard(
                building: building,
                workers: intelligenceVM.currentWorkersOnSite
            )
        }
    }
}

struct CoverageInfoCard: View {
    let building: NamedCoordinate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("Coverage Mode")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Text("You're viewing this building for coverage purposes. This building is not in your regular assignments.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// Additional tab implementations would go here...
struct AllWorkersTab: View {
    let building: NamedCoordinate
    @ObservedObject var intelligenceVM: BuildingIntelligenceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Workers assigned to this building")
                .font(.headline)
            
            ForEach(intelligenceVM.allAssignedWorkers, id: \.id) { worker in
                WorkerCard(worker: worker)
            }
        }
    }
}

struct FullScheduleTab: View {
    let building: NamedCoordinate
    @ObservedObject var intelligenceVM: BuildingIntelligenceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Complete schedule for this building")
                .font(.headline)
            
            ForEach(intelligenceVM.todaysCompleteSchedule, id: \.id) { task in
                ScheduleTaskCard(task: task)
            }
        }
    }
}

struct BuildingHistoryTab: View {
    let building: NamedCoordinate
    @ObservedObject var intelligenceVM: BuildingIntelligenceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Building maintenance history")
                .font(.headline)
            
            ForEach(intelligenceVM.buildingHistory, id: \.id) { task in
                HistoryTaskCard(task: task)
            }
        }
    }
}

struct EmergencyInfoTab: View {
    let building: NamedCoordinate
    @ObservedObject var intelligenceVM: BuildingIntelligenceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Emergency information")
                .font(.headline)
            
            ForEach(intelligenceVM.emergencyContacts, id: \.self) { contact in
                Text(contact)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }
        }
    }
}

// Supporting view components would be implemented here...
struct WorkerCard: View {
    let worker: WorkerProfile
    
    var body: some View {
        HStack {
            Text(worker.name)
                .font(.subheadline)
            Spacer()
            Text(worker.role.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct ScheduleTaskCard: View {
    let task: ContextualTask
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title ?? "Task")
                    .font(.subheadline)
                Text(task.description ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct HistoryTaskCard: View {
    let task: ContextualTask
    
    var body: some View {
        ScheduleTaskCard(task: task) // Reuse schedule card for now
    }
}

struct BuildingMetricsCard: View {
    let metrics: CoreTypes.BuildingMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Metrics")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Completion Rate")
                        .font(.caption)
                    Text("\(Int(metrics.completionRate * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Active Workers")
                        .font(.caption)
                    Text("\(metrics.activeWorkers)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct CurrentStatusCard: View {
    let building: NamedCoordinate
    let workers: [WorkerProfile]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Status")
                .font(.headline)
            
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.blue)
                Text("\(workers.count) workers on site")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}
