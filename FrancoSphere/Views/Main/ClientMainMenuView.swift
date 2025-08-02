//
//  ClientMainMenuView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 8/2/25.
//


//
//  ClientDashboardSupportingViews.swift
//  FrancoSphere v6.0
//
//  ✅ UNIFIED: Consistent Dark Elegance theme
//  ✅ COMPREHENSIVE: All supporting views for ClientDashboard
//  ✅ REAL-TIME: Live data updates throughout
//

import SwiftUI
import MapKit

// MARK: - Client Main Menu View

struct ClientMainMenuView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var contextEngine = ClientContextEngine.shared
    
    var body: some View {
        NavigationView {
            List {
                // Portfolio Section
                Section("Portfolio") {
                    MenuRow(
                        icon: "building.2",
                        title: "Buildings",
                        subtitle: "\(contextEngine.clientBuildings.count) properties",
                        color: FrancoSphereDesign.DashboardColors.clientPrimary
                    )
                    
                    MenuRow(
                        icon: "chart.pie",
                        title: "Analytics",
                        subtitle: "Performance insights",
                        color: FrancoSphereDesign.DashboardColors.info
                    )
                    
                    MenuRow(
                        icon: "doc.text",
                        title: "Reports",
                        subtitle: "Monthly summaries",
                        color: FrancoSphereDesign.DashboardColors.clientSecondary
                    )
                }
                .listRowBackground(FrancoSphereDesign.DashboardColors.cardBackground)
                
                // Compliance Section
                Section("Compliance") {
                    MenuRow(
                        icon: "checkmark.shield",
                        title: "Compliance Dashboard",
                        subtitle: "\(Int(contextEngine.complianceOverview.overallScore * 100))% compliant",
                        color: contextEngine.complianceOverview.overallScore > 0.9 ? FrancoSphereDesign.DashboardColors.compliant : FrancoSphereDesign.DashboardColors.warning
                    )
                    
                    MenuRow(
                        icon: "doc.badge.clock",
                        title: "Audit History",
                        subtitle: "Past inspections",
                        color: FrancoSphereDesign.DashboardColors.clientAccent
                    )
                }
                .listRowBackground(FrancoSphereDesign.DashboardColors.cardBackground)
                
                // Communication Section
                Section("Communication") {
                    MenuRow(
                        icon: "message",
                        title: "Messages",
                        subtitle: "Team communication",
                        color: FrancoSphereDesign.DashboardColors.info
                    )
                    
                    MenuRow(
                        icon: "bell",
                        title: "Notifications",
                        subtitle: contextEngine.realtimeAlerts.isEmpty ? "No new alerts" : "\(contextEngine.realtimeAlerts.count) new",
                        color: contextEngine.criticalAlerts.isEmpty ? FrancoSphereDesign.DashboardColors.inactive : FrancoSphereDesign.DashboardColors.warning
                    )
                }
                .listRowBackground(FrancoSphereDesign.DashboardColors.cardBackground)
                
                // Support Section
                Section("Support") {
                    MenuRow(
                        icon: "questionmark.circle",
                        title: "Help Center",
                        subtitle: "FAQs and guides",
                        color: FrancoSphereDesign.DashboardColors.tertiaryText
                    )
                    
                    MenuRow(
                        icon: "gear",
                        title: "Settings",
                        subtitle: "Account preferences",
                        color: FrancoSphereDesign.DashboardColors.tertiaryText
                    )
                }
                .listRowBackground(FrancoSphereDesign.DashboardColors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(FrancoSphereDesign.DashboardColors.baseBackground)
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Client Buildings List View

struct ClientBuildingsListView: View {
    let buildings: [NamedCoordinate]
    let performanceMap: [String: Double]
    let onSelectBuilding: (NamedCoordinate) -> Void
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .performance
    @State private var filterOption: FilterOption = .all
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case performance = "Performance"
        case location = "Location"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case highPerformance = "High Performance"
        case needsAttention = "Needs Attention"
        case critical = "Critical"
    }
    
    private var filteredBuildings: [NamedCoordinate] {
        let filtered = buildings.filter { building in
            searchText.isEmpty || building.name.localizedCaseInsensitiveContains(searchText)
        }.filter { building in
            switch filterOption {
            case .all:
                return true
            case .highPerformance:
                return (performanceMap[building.id] ?? 0) >= 0.8
            case .needsAttention:
                let performance = performanceMap[building.id] ?? 0
                return performance < 0.8 && performance >= 0.6
            case .critical:
                return (performanceMap[building.id] ?? 0) < 0.6
            }
        }
        
        return filtered.sorted { building1, building2 in
            switch sortOption {
            case .name:
                return building1.name < building2.name
            case .performance:
                let perf1 = performanceMap[building1.id] ?? 0
                let perf2 = performanceMap[building2.id] ?? 0
                return perf1 > perf2
            case .location:
                return building1.address < building2.address
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filters
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    
                    TextField("Search buildings...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            FilterChip(
                                title: option.rawValue,
                                isSelected: filterOption == option,
                                color: chipColor(for: option),
                                action: { filterOption = option }
                            )
                        }
                        
                        Spacer()
                        
                        // Sort menu
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { sortOption = option }) {
                                    Label(
                                        option.rawValue,
                                        systemImage: sortOption == option ? "checkmark" : ""
                                    )
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.caption)
                                Text("Sort")
                                    .font(.caption)
                            }
                            .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(FrancoSphereDesign.DashboardColors.clientPrimary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding()
            .background(FrancoSphereDesign.DashboardColors.cardBackground)
            
            // Buildings list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredBuildings, id: \.id) { building in
                        BuildingListRow(
                            building: building,
                            performance: performanceMap[building.id] ?? 0,
                            onTap: { onSelectBuilding(building) }
                        )
                    }
                }
                .padding()
            }
            
            // Summary footer
            HStack {
                Text("\(filteredBuildings.count) of \(buildings.count) buildings")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                
                Spacer()
                
                if let avgPerformance = averagePerformance {
                    Text("Avg: \(Int(avgPerformance * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(performanceColor(for: avgPerformance))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(FrancoSphereDesign.DashboardColors.cardBackground)
        }
        .background(FrancoSphereDesign.DashboardColors.baseBackground)
    }
    
    private var averagePerformance: Double? {
        let performances = filteredBuildings.compactMap { performanceMap[$0.id] }
        guard !performances.isEmpty else { return nil }
        return performances.reduce(0, +) / Double(performances.count)
    }
    
    private func chipColor(for option: FilterOption) -> Color {
        switch option {
        case .all:
            return FrancoSphereDesign.DashboardColors.clientPrimary
        case .highPerformance:
            return FrancoSphereDesign.DashboardColors.success
        case .needsAttention:
            return FrancoSphereDesign.DashboardColors.warning
        case .critical:
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
    
    private func performanceColor(for value: Double) -> Color {
        if value >= 0.8 {
            return FrancoSphereDesign.DashboardColors.success
        } else if value >= 0.6 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
}

// MARK: - Client Compliance Detail View

struct ClientComplianceDetailView: View {
    let complianceOverview: CoreTypes.ComplianceOverview
    let issues: [CoreTypes.ComplianceIssue]
    let selectedIssue: CoreTypes.ComplianceIssue?
    
    @State private var selectedSeverity: CoreTypes.ComplianceSeverity?
    @State private var selectedStatus: CoreTypes.ComplianceStatus?
    @State private var showingIssueDetail = false
    @State private var detailIssue: CoreTypes.ComplianceIssue?
    
    private var filteredIssues: [CoreTypes.ComplianceIssue] {
        issues.filter { issue in
            (selectedSeverity == nil || issue.severity == selectedSeverity) &&
            (selectedStatus == nil || issue.status == selectedStatus)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Compliance Score Card
                ComplianceScoreCard(overview: complianceOverview)
                
                // Quick Stats
                HStack(spacing: 12) {
                    QuickStatCard(
                        title: "Open Issues",
                        value: "\(complianceOverview.openIssues)",
                        icon: "exclamationmark.circle",
                        color: FrancoSphereDesign.DashboardColors.warning
                    )
                    
                    QuickStatCard(
                        title: "Critical",
                        value: "\(complianceOverview.criticalViolations)",
                        icon: "exclamationmark.triangle.fill",
                        color: FrancoSphereDesign.DashboardColors.critical
                    )
                    
                    QuickStatCard(
                        title: "Next Audit",
                        value: complianceOverview.nextAudit?.formatted(.dateTime.day().month()) ?? "TBD",
                        icon: "calendar",
                        color: FrancoSphereDesign.DashboardColors.info
                    )
                }
                
                // Filters
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filter Issues")
                        .font(.headline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    // Severity filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All Severities",
                                isSelected: selectedSeverity == nil,
                                action: { selectedSeverity = nil }
                            )
                            
                            ForEach(CoreTypes.ComplianceSeverity.allCases, id: \.self) { severity in
                                FilterChip(
                                    title: severity.rawValue,
                                    isSelected: selectedSeverity == severity,
                                    color: FrancoSphereDesign.EnumColors.complianceSeverity(severity),
                                    action: { selectedSeverity = severity }
                                )
                            }
                        }
                    }
                    
                    // Status filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All Statuses",
                                isSelected: selectedStatus == nil,
                                action: { selectedStatus = nil }
                            )
                            
                            ForEach([CoreTypes.ComplianceStatus.open, .inProgress, .resolved], id: \.self) { status in
                                FilterChip(
                                    title: status.rawValue,
                                    isSelected: selectedStatus == status,
                                    color: FrancoSphereDesign.EnumColors.complianceStatus(status),
                                    action: { selectedStatus = status }
                                )
                            }
                        }
                    }
                }
                
                // Issues List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Issues (\(filteredIssues.count))")
                            .font(.headline)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Label("Export", systemImage: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
                        }
                    }
                    
                    ForEach(filteredIssues) { issue in
                        ComplianceIssueCard(issue: issue) {
                            detailIssue = issue
                            showingIssueDetail = true
                        }
                    }
                }
            }
            .padding()
        }
        .background(FrancoSphereDesign.DashboardColors.baseBackground)
        .sheet(isPresented: $showingIssueDetail) {
            if let issue = detailIssue {
                ComplianceIssueDetailSheet(issue: issue)
            }
        }
        .onAppear {
            if let selected = selectedIssue {
                detailIssue = selected
                showingIssueDetail = true
            }
        }
    }
}

// MARK: - Supporting Components

struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = FrancoSphereDesign.DashboardColors.clientPrimary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BuildingListRow: View {
    let building: NamedCoordinate
    let performance: Double
    let onTap: () -> Void
    
    private var performanceColor: Color {
        if performance >= 0.8 {
            return FrancoSphereDesign.DashboardColors.success
        } else if performance >= 0.6 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Building icon with performance indicator
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(FrancoSphereDesign.DashboardColors.clientPrimary.opacity(0.1))
                        )
                    
                    Circle()
                        .fill(performanceColor)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(FrancoSphereDesign.DashboardColors.cardBackground, lineWidth: 2)
                        )
                }
                
                // Building details
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    Text(building.address)
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        .lineLimit(1)
                    
                    // Performance bar
                    HStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(performanceColor)
                                    .frame(width: geometry.size.width * performance)
                            }
                        }
                        .frame(width: 60, height: 4)
                        
                        Text("\(Int(performance * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(performanceColor)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FrancoSphereDesign.DashboardColors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComplianceScoreCard: View {
    let overview: CoreTypes.ComplianceOverview
    
    private var scoreColor: Color {
        if overview.overallScore >= 0.9 {
            return FrancoSphereDesign.DashboardColors.compliant
        } else if overview.overallScore >= 0.7 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.violation
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Score display
            VStack(spacing: 8) {
                Text("Overall Compliance Score")
                    .font(.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text("\(Int(overview.overallScore * 100))%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
                
                // Visual indicator
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [scoreColor, scoreColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 300 * overview.overallScore, height: 12)
                }
                .frame(width: 300)
            }
            
            // Last audit info
            if let lastAudit = overview.lastAudit {
                HStack {
                    Label(
                        "Last Audit: \(lastAudit.formatted(.dateTime.day().month()))",
                        systemImage: "checkmark.seal"
                    )
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .francoDarkCardBackground()
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ComplianceIssueCard: View {
    let issue: CoreTypes.ComplianceIssue
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    // Severity indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(FrancoSphereDesign.EnumColors.complianceSeverity(issue.severity))
                            .frame(width: 8, height: 8)
                        
                        Text(issue.severity.rawValue.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(FrancoSphereDesign.EnumColors.complianceSeverity(issue.severity))
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text(issue.status.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(FrancoSphereDesign.EnumColors.complianceStatus(issue.status).opacity(0.2))
                        )
                        .foregroundColor(FrancoSphereDesign.EnumColors.complianceStatus(issue.status))
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        .lineLimit(2)
                    
                    Text(issue.description)
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        .lineLimit(2)
                }
                
                // Metadata
                HStack(spacing: 16) {
                    if let buildingName = issue.buildingName {
                        Label(buildingName, systemImage: "building.2")
                            .font(.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                    }
                    
                    if let dueDate = issue.dueDate {
                        Label(dueDate.formatted(.dateTime.day().month()), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundColor(Date() > dueDate ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
            .padding()
            .francoDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComplianceIssueDetailSheet: View {
    let issue: CoreTypes.ComplianceIssue
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Issue header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(issue.severity.rawValue.uppercased(), systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(FrancoSphereDesign.EnumColors.complianceSeverity(issue.severity))
                            
                            Spacer()
                            
                            Text(issue.status.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(FrancoSphereDesign.EnumColors.complianceStatus(issue.status))
                                )
                                .foregroundColor(.white)
                        }
                        
                        Text(issue.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        
                        Text(issue.description)
                            .font(.body)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                    .padding()
                    .francoDarkCardBackground()
                    
                    // Details section
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Building", value: issue.buildingName ?? "Not specified", icon: "building.2")
                        DetailRow(label: "Type", value: issue.type.rawValue, icon: "tag")
                        DetailRow(label: "Reported", value: issue.reportedDate.formatted(.dateTime.day().month().year()), icon: "calendar")
                        
                        if let dueDate = issue.dueDate {
                            DetailRow(
                                label: "Due Date",
                                value: dueDate.formatted(.dateTime.day().month().year()),
                                icon: "clock",
                                color: Date() > dueDate ? FrancoSphereDesign.DashboardColors.critical : nil
                            )
                        }
                        
                        if let assignedTo = issue.assignedTo {
                            DetailRow(label: "Assigned To", value: assignedTo, icon: "person")
                        }
                    }
                    .padding()
                    .francoDarkCardBackground()
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: {}) {
                            Label("Contact Property Manager", systemImage: "phone")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle(style: .primary))
                        
                        Button(action: {}) {
                            Label("View Documentation", systemImage: "doc.text")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle(style: .secondary))
                    }
                    .padding()
                }
            }
            .background(FrancoSphereDesign.DashboardColors.baseBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    var color: Color?
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color ?? FrancoSphereDesign.DashboardColors.primaryText)
        }
    }
}

struct ClientProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Client Profile View")
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Preview Provider

#Preview("Client Main Menu") {
    ClientMainMenuView()
        .preferredColorScheme(.dark)
}

#Preview("Client Buildings List") {
    ClientBuildingsListView(
        buildings: [
            NamedCoordinate(
                id: "1",
                name: "123 Main Street",
                address: "123 Main St, New York, NY",
                latitude: 40.7128,
                longitude: -74.0060,
                type: .office
            ),
            NamedCoordinate(
                id: "2",
                name: "456 Park Avenue",
                address: "456 Park Ave, New York, NY",
                latitude: 40.7589,
                longitude: -73.9851,
                type: .residential
            )
        ],
        performanceMap: [
            "1": 0.85,
            "2": 0.65
        ],
        onSelectBuilding: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("Client Compliance Detail") {
    ClientComplianceDetailView(
        complianceOverview: .previewWithViolations,
        issues: CoreTypes.ComplianceIssue.previewSet,
        selectedIssue: nil
    )
    .preferredColorScheme(.dark)
}