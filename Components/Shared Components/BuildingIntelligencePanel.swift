//
//  BuildingIntelligencePanel.swift
//  FrancoSphere v6.0
//
//  ✅ Phase 2.2: Enhanced Intelligence Panel
//  ✅ Five-tab system for complete building intelligence
//  ✅ Uses existing IntelligenceService and BuildingService
//  ✅ Supports both worker and coverage access modes
//

import SwiftUI

struct BuildingIntelligencePanel: View {
    let building: NamedCoordinate
    @Binding var selectedTab: IntelligenceTab
    let isMyBuilding: Bool
    let isPrimaryBuilding: Bool
    
    @StateObject private var viewModel: BuildingIntelligenceViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(building: NamedCoordinate, selectedTab: Binding<IntelligenceTab>, isMyBuilding: Bool, isPrimaryBuilding: Bool) {
        self.building = building
        self._selectedTab = selectedTab
        self.isMyBuilding = isMyBuilding
        self.isPrimaryBuilding = isPrimaryBuilding
        self._viewModel = StateObject(wrappedValue: BuildingIntelligenceViewModel())
    }
    
    enum IntelligenceTab: String, CaseIterable {
        case overview = "Overview"
        case allWorkers = "All Workers"
        case fullSchedule = "Full Schedule"
        case history = "History"
        case emergency = "Emergency"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .allWorkers: return "person.3.fill"
            case .fullSchedule: return "calendar.badge.clock"
            case .history: return "clock.arrow.circlepath"
            case .emergency: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overview: return .blue
            case .allWorkers: return .green
            case .fullSchedule: return .purple
            case .history: return .orange
            case .emergency: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Coverage indicator if not my building
                if !isMyBuilding {
                    coverageIndicatorBanner
                }
                
                // Tab bar
                intelligenceTabBar
                
                // Tab content
                tabContent
            }
            .background(Color.black)
            .navigationTitle(building.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    coverageStatusButton
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadCompleteIntelligence(for: building)
        }
    }
    
    // MARK: - Coverage Indicator Banner
    
    private var coverageIndicatorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.orange)
            
            Text("Coverage Mode - Emergency/Support Access")
                .font(.caption)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.1))
    }
    
    // MARK: - Intelligence Tab Bar
    
    private var intelligenceTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(IntelligenceTab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(.ultraThinMaterial)
    }
    
    private func tabButton(for tab: IntelligenceTab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.caption)
                    .foregroundColor(selectedTab == tab ? tab.color : .secondary)
                
                Text(tab.rawValue)
                    .font(.caption2)
                    .foregroundColor(selectedTab == tab ? tab.color : .secondary)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTab == tab ? tab.color.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Coverage Status Button
    
    private var coverageStatusButton: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isMyBuilding ? .green : .orange)
                .frame(width: 8, height: 8)
            
            Text(isMyBuilding ? "My Building" : "Coverage")
                .font(.caption2)
                .foregroundColor(isMyBuilding ? .green : .orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Tab Content
    
    private var tabContent: some View {
        ScrollView {
            Group {
                switch selectedTab {
                case .overview:
                    BuildingOverviewTab(
                        building: building,
                        metrics: viewModel.metrics,
                        currentStatus: viewModel.currentStatus,
                        isMyBuilding: isMyBuilding
                    )
                    
                case .allWorkers:
                    AllWorkersTab(
                        building: building,
                        primaryWorkers: viewModel.primaryWorkers,
                        allWorkers: viewModel.allAssignedWorkers,
                        workersOnSite: viewModel.currentWorkersOnSite
                    )
                    
                case .fullSchedule:
                    FullScheduleTab(
                        building: building,
                        todaysSchedule: viewModel.todaysCompleteSchedule,
                        weeklySchedule: viewModel.weeklyRoutineSchedule,
                        emergencyProcedures: viewModel.emergencyProcedures
                    )
                    
                case .history:
                    BuildingHistoryTab(
                        building: building,
                        history: viewModel.buildingHistory,
                        patterns: viewModel.patterns
                    )
                    
                case .emergency:
                    EmergencyInfoTab(
                        building: building,
                        contacts: viewModel.emergencyContacts,
                        procedures: viewModel.emergencyProcedures,
                        accessLevel: isMyBuilding ? .full : .coverage
                    )
                }
            }
            .padding()
        }
        .background(Color.black)
    }
}

// MARK: - Building Overview Tab

struct BuildingOverviewTab: View {
    let building: NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let currentStatus: BuildingOperationalStatus?
    let isMyBuilding: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Building status card
            buildingStatusCard
            
            // Metrics grid
            if let metrics = metrics {
                metricsGrid(metrics)
            }
            
            // Current activity
            currentActivitySection
        }
    }
    
    private func buildingStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Building Status")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            if let status = currentStatus {
                VStack(alignment: .leading, spacing: 8) {
                    statusRow("Operational Status", status.operational ? "✅ Operational" : "⚠️ Issues Detected")
                    statusRow("Security Status", status.secure ? "🔒 Secure" : "🔓 Security Alert")
                    statusRow("Last Updated", status.lastUpdated.formatted(.dateTime.hour().minute()))
                }
            } else {
                Text("Loading status...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func metricsGrid(_ metrics: CoreTypes.BuildingMetrics) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            metricCard("Completion Rate", "\(Int(metrics.completionRate * 100))%", "checkmark.circle.fill", .green)
            metricCard("Active Workers", "\(metrics.activeWorkers)", "person.fill", .blue)
            metricCard("Pending Tasks", "\(metrics.pendingTasks)", "clock.fill", .orange)
            metricCard("Overdue Tasks", "\(metrics.overdueTasks)", "exclamationmark.triangle.fill", .red)
        }
    }
    
    private func metricCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private var currentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Activity")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Real-time building activity and worker status will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func statusRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - All Workers Tab

struct AllWorkersTab: View {
    let building: NamedCoordinate
    let primaryWorkers: [WorkerProfile]
    let allWorkers: [WorkerProfile]
    let workersOnSite: [WorkerProfile]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Workers on site now
            currentWorkersSection
            
            // Primary workers
            primaryWorkersSection
            
            // All assigned workers
            allWorkersSection
        }
    }
    
    private var currentWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currently On Site")
                .font(.headline)
                .foregroundColor(.white)
            
            if workersOnSite.isEmpty {
                Text("No workers currently on site")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(workersOnSite, id: \.id) { worker in
                        WorkerRow(worker: worker, showOnSiteStatus: true)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var primaryWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary Workers")
                .font(.headline)
                .foregroundColor(.white)
            
            if primaryWorkers.isEmpty {
                Text("No primary workers assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(primaryWorkers, id: \.id) { worker in
                        WorkerRow(worker: worker, showPrimaryBadge: true)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var allWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Assigned Workers")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(allWorkers, id: \.id) { worker in
                    WorkerRow(worker: worker)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Worker Row Component

struct WorkerRow: View {
    let worker: WorkerProfile
    let showOnSiteStatus: Bool
    let showPrimaryBadge: Bool
    
    init(worker: WorkerProfile, showOnSiteStatus: Bool = false, showPrimaryBadge: Bool = false) {
        self.worker = worker
        self.showOnSiteStatus = showOnSiteStatus
        self.showPrimaryBadge = showPrimaryBadge
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Worker avatar
            Circle()
                .fill(.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(worker.name.prefix(1)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            // Worker info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(worker.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if showPrimaryBadge {
                        Text("PRIMARY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Text(worker.role.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicators
            VStack(alignment: .trailing, spacing: 2) {
                if showOnSiteStatus {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(worker.isActive ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(worker.isActive ? "Active" : "Inactive")
                            .font(.caption2)
                            .foregroundColor(worker.isActive ? .green : .gray)
                    }
                }
                
                Text("Standard")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types

struct BuildingOperationalStatus {
    let operational: Bool
    let secure: Bool
    let lastUpdated: Date
}

// MARK: - Placeholder Tab Views

struct FullScheduleTab: View {
    let building: NamedCoordinate
    let todaysSchedule: [ScheduleEntry]
    let weeklySchedule: [RoutineEntry]
    let emergencyProcedures: [EmergencyProcedure]
    
    var body: some View {
        VStack {
            Text("Full Schedule")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Complete schedule information will be implemented here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct BuildingHistoryTab: View {
    let building: NamedCoordinate
    let history: [HistoryEntry]
    let patterns: [Pattern]
    
    var body: some View {
        VStack {
            Text("Building History")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Historical data and patterns will be implemented here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct EmergencyInfoTab: View {
    let building: NamedCoordinate
    let contacts: [EmergencyContact]
    let procedures: [EmergencyProcedure]
    let accessLevel: AccessLevel
    
    enum AccessLevel {
        case full
        case coverage
    }
    
    var body: some View {
        VStack {
            Text("Emergency Information")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Emergency contacts and procedures will be implemented here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct BuildingIntelligencePanel_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            latitude: 40.7402,
            longitude: -73.9980
        )
        
        BuildingIntelligencePanel(
            building: sampleBuilding,
            selectedTab: .constant(.overview),
            isMyBuilding: false,
            isPrimaryBuilding: false
        )
        .preferredColorScheme(.dark)
    }
}
