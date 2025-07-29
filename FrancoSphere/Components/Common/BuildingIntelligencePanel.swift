//
//  BuildingIntelligencePanel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: LoadingView reference corrected to IntelligenceLoadingView
//  ✅ ALIGNED: With existing CoreTypes and BuildingIntelligenceViewModel
//  ✅ USES: Existing service patterns and data types
//  ✅ INTEGRATED: With real operational data
//

import SwiftUI
import Foundation

struct BuildingIntelligencePanel: View {
    let building: NamedCoordinate
    @Binding var selectedTab: IntelligenceTab
    let isMyBuilding: Bool
    let isPrimaryBuilding: Bool
    
    @StateObject private var viewModel = BuildingIntelligenceViewModel()
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(building: NamedCoordinate, selectedTab: Binding<IntelligenceTab>, isMyBuilding: Bool, isPrimaryBuilding: Bool) {
        self.building = building
        self._selectedTab = selectedTab
        self.isMyBuilding = isMyBuilding
        self.isPrimaryBuilding = isPrimaryBuilding
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
            VStack {
                switch selectedTab {
                case .overview:
                    BuildingOverviewTab(
                        building: building,
                        metrics: viewModel.metrics,
                        isMyBuilding: isMyBuilding,
                        isLoading: viewModel.isLoading
                    )
                    
                case .allWorkers:
                    AllWorkersTab(
                        building: building,
                        primaryWorkers: viewModel.primaryWorkers,
                        allWorkers: viewModel.allAssignedWorkers,
                        workersOnSite: viewModel.currentWorkersOnSite,
                        isLoading: viewModel.isLoading
                    )
                    
                case .fullSchedule:
                    FullScheduleTab(
                        building: building,
                        todaysSchedule: viewModel.todaysCompleteSchedule,
                        weeklySchedule: viewModel.weeklyRoutineSchedule,
                        isLoading: viewModel.isLoading
                    )
                    
                case .history:
                    BuildingHistoryTab(
                        building: building,
                        history: viewModel.buildingHistory,
                        patterns: viewModel.patterns,
                        isLoading: viewModel.isLoading
                    )
                    
                case .emergency:
                    EmergencyInfoTab(
                        building: building,
                        contacts: viewModel.emergencyContacts,
                        procedures: viewModel.emergencyProcedures,
                        accessLevel: isMyBuilding ? .full : .coverage,
                        isLoading: viewModel.isLoading
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
    let isMyBuilding: Bool
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                IntelligenceLoadingView(message: "Loading building overview...")
            } else {
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
    }
    
    private var buildingStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Building Status")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                statusRow("Building Type", building.name.contains("Museum") ? "Cultural" : "Commercial")
                statusRow("Access Level", isMyBuilding ? "Full Access" : "Coverage Access")
                statusRow("Last Updated", Date().formatted(.dateTime.hour().minute()))
                
                if let metrics = metrics {
                    statusRow("Status", metrics.displayStatus)
                }
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
            
            Text("Real-time building activity and worker status")
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
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                IntelligenceLoadingView(message: "Loading worker information...")
            } else {
                // Workers on site now
                currentWorkersSection
                
                // Primary workers
                primaryWorkersSection
                
                // All assigned workers
                allWorkersSection
            }
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
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
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
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
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
            
            if allWorkers.isEmpty {
                Text("No workers assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(allWorkers, id: \.id) { worker in
                        WorkerRow(worker: worker)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Full Schedule Tab

struct FullScheduleTab: View {
    let building: NamedCoordinate
    let todaysSchedule: [ContextualTask]
    let weeklySchedule: [ContextualTask]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                IntelligenceLoadingView(message: "Loading schedule information...")
            } else {
                // Today's schedule
                todaysScheduleSection
                
                // Weekly routines
                weeklyRoutinesSection
            }
        }
    }
    
    private var todaysScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Schedule")
                .font(.headline)
                .foregroundColor(.white)
            
            if todaysSchedule.isEmpty {
                Text("No scheduled activities today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(todaysSchedule, id: \.id) { task in
                        TaskScheduleRow(task: task)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var weeklyRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Routines")
                .font(.headline)
                .foregroundColor(.white)
            
            if weeklySchedule.isEmpty {
                Text("No weekly routines configured")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(weeklySchedule, id: \.id) { task in
                        TaskScheduleRow(task: task)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Building History Tab

struct BuildingHistoryTab: View {
    let building: NamedCoordinate
    let history: [ContextualTask]
    let patterns: [String]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                IntelligenceLoadingView(message: "Loading building history...")
            } else {
                // Recent history
                recentHistorySection
                
                // Patterns
                patternsSection
            }
        }
    }
    
    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.white)
            
            if history.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(history.prefix(10), id: \.id) { task in
                        TaskHistoryRow(task: task)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns & Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            if patterns.isEmpty {
                Text("No patterns detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(patterns, id: \.self) { pattern in
                        PatternRow(pattern: pattern)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Emergency Info Tab

struct EmergencyInfoTab: View {
    let building: NamedCoordinate
    let contacts: [String]
    let procedures: [String]
    let accessLevel: AccessLevel
    let isLoading: Bool
    
    enum AccessLevel {
        case full
        case coverage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                // ✅ FIXED: Changed LoadingView to IntelligenceLoadingView
                IntelligenceLoadingView(message: "Loading emergency information...")
            } else {
                // Emergency contacts
                emergencyContactsSection
                
                // Emergency procedures
                emergencyProceduresSection
            }
        }
    }
    
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Contacts")
                .font(.headline)
                .foregroundColor(.white)
            
            if contacts.isEmpty {
                Text("No emergency contacts configured")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(contacts, id: \.self) { contact in
                        ContactRow(contact: contact)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var emergencyProceduresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Procedures")
                .font(.headline)
                .foregroundColor(.white)
            
            if procedures.isEmpty {
                Text("No emergency procedures configured")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(procedures, id: \.self) { procedure in
                        ProcedureRow(procedure: procedure)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Supporting Components

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

struct TaskScheduleRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let description = task.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                }
                
                if let urgency = task.urgency {
                    Text(urgency.rawValue)
                        .font(.caption2)
                        .foregroundColor(urgencyColor(urgency))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func urgencyColor(_ urgency: CoreTypes.TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .urgent: return .red
        case .emergency: return .red
        }
    }
}

struct TaskHistoryRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let completedDate = task.completedDate {
                    Text("Completed: \(completedDate.formatted(.dateTime.month().day().hour().minute()))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

struct PatternRow: View {
    let pattern: String
    
    var body: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(.blue)
            
            Text(pattern)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ContactRow: View {
    let contact: String
    
    var body: some View {
        HStack {
            Image(systemName: "phone.fill")
                .foregroundColor(.red)
            
            Text(contact)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ProcedureRow: View {
    let procedure: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(procedure)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct IntelligenceLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Fixed BuildingIntelligenceViewModel Integration
// Note: This assumes the BuildingIntelligenceViewModel from earlier artifact exists
// If not, create it in ViewModels/BuildingIntelligenceViewModel.swift

// MARK: - Preview

struct BuildingIntelligencePanel_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "150 W 17th St, New York, NY 10011", latitude: 40.7402,
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
