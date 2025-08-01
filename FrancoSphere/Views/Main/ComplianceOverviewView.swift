//
//  ComplianceOverviewView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Renamed ComplianceIssue to ComplianceIssueData to avoid conflicts
//  ✅ FIXED: Proper ComplianceIssueType cases
//  ✅ FIXED: Added icon computation for issue types
//  ✅ FIXED: Correct PortfolioIntelligence initializer
//  ✅ FIXED: Broke up complex expressions
//  ✅ FIXED: Removed imageAssetName from NamedCoordinate
//  ✅ FIXED: Using FrancoSphereDesign.EnumColors for severity colors
//  ✅ ALIGNED: With CoreTypes definitions and dashboard architecture
//

import SwiftUI

struct ComplianceOverviewView: View {
    let intelligence: CoreTypes.PortfolioIntelligence?
    let onIssuesTap: ((ComplianceIssueData) -> Void)?
    let onScheduleAudit: (() -> Void)?
    let onExportReport: (() -> Void)?
    
    @State private var selectedTab: CoreTypes.ComplianceTab = .overview
    @State private var showingIssueDetail: ComplianceIssueData?
    @State private var showingAuditScheduler = false
    @State private var showingExportOptions = false
    
    init(intelligence: CoreTypes.PortfolioIntelligence?,
         onIssuesTap: ((ComplianceIssueData) -> Void)? = nil,
         onScheduleAudit: (() -> Void)? = nil,
         onExportReport: (() -> Void)? = nil) {
        self.intelligence = intelligence
        self.onIssuesTap = onIssuesTap
        self.onScheduleAudit = onScheduleAudit
        self.onExportReport = onExportReport
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Tab Selector
            tabSelectorSection
            
            // Tab Content
            tabContentSection
        }
        .sheet(item: $showingIssueDetail) { issue in
            ComplianceIssueDetailSheet(issue: issue)
        }
        .sheet(isPresented: $showingAuditScheduler) {
            AuditSchedulerSheet(onSchedule: onScheduleAudit ?? {})
        }
        .sheet(isPresented: $showingExportOptions) {
            ComplianceExportSheet(onExport: onExportReport ?? {})
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Compliance Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Menu {
                    Button(action: { showingAuditScheduler = true }) {
                        Label("Schedule Audit", systemImage: "calendar.badge.plus")
                    }
                    
                    Button(action: { showingExportOptions = true }) {
                        Label("Export Report", systemImage: "doc.badge.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Compliance Score Card
            if let intelligence = intelligence {
                complianceScoreCard(for: intelligence)
            } else {
                loadingScoreCard
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func complianceScoreCard(for compliance: CoreTypes.PortfolioIntelligence) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Compliance Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(compliance.complianceScore))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(complianceScoreColor(compliance.complianceScore))
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: complianceStatusIcon(compliance.complianceScore))
                        .font(.system(size: 32))
                        .foregroundColor(complianceScoreColor(compliance.complianceScore))
                    
                    Text(complianceStatusText(compliance.complianceScore))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(complianceScoreColor(compliance.complianceScore))
                }
            }
            
            progressBarSection(for: compliance)
        }
        .padding()
        .background(complianceScoreColor(compliance.complianceScore).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(complianceScoreColor(compliance.complianceScore).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func progressBarSection(for compliance: CoreTypes.PortfolioIntelligence) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Compliant Buildings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let compliantBuildings = calculateCompliantBuildings(compliance)
                Text("\(compliantBuildings)/\(compliance.totalBuildings)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            let compliancePercentage = calculateCompliancePercentage(compliance)
            ProgressView(value: compliancePercentage / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: complianceScoreColor(compliance.complianceScore)))
        }
    }
    
    private var loadingScoreCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Compliance Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(width: 80, height: 32)
                }
                
                Spacer()
                
                ProgressView()
                    .scaleEffect(1.2)
            }
            
            ProgressView()
                .progressViewStyle(LinearProgressViewStyle())
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Tab Selector Section
    
    private var tabSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // Fixed: Using proper computed tabIcon
                ForEach(CoreTypes.ComplianceTab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func tabButton(for tab: CoreTypes.ComplianceTab) -> some View {
        Button(action: {
            withAnimation(Animation.easeInOut(duration: 0.3)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: tabIcon(for: tab))
                        .font(.caption)
                    
                    Text(tab.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if tab == .issues, let intelligence = intelligence, intelligence.criticalIssues > 0 {
                        Text("\(intelligence.criticalIssues)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                    }
                }
                .foregroundColor(selectedTab == tab ? .blue : .secondary)
                
                Rectangle()
                    .fill(selectedTab == tab ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Tab Content Section
    
    private var tabContentSection: some View {
        Group {
            switch selectedTab {
            case .overview:
                overviewTabContent
            case .issues:
                issuesTabContent
            case .audit:  // Fixed: Changed from .audits to .audit
                auditsTabContent
            case .reports:
                reportsTabContent
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Overview Tab Content
    
    private var overviewTabContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let intelligence = intelligence {
                    quickStatsSection(for: intelligence)
                    
                    if intelligence.criticalIssues > 0 {
                        criticalIssuesSummary(for: intelligence)
                    }
                    
                    auditTimelineSection(for: intelligence)
                    complianceTrendsSection
                } else {
                    loadingView
                }
            }
            .padding()
        }
    }
    
    private func quickStatsSection(for compliance: CoreTypes.PortfolioIntelligence) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickStatCard(
                    title: "Pending Actions",
                    value: "\(compliance.criticalIssues)",
                    icon: "hourglass",
                    color: compliance.criticalIssues > 0 ? .orange : .green
                )
                
                QuickStatCard(
                    title: "Critical Issues",
                    value: "\(compliance.criticalIssues)",
                    icon: "exclamationmark.triangle",
                    color: compliance.criticalIssues == 0 ? .green : .red
                )
                
                QuickStatCard(
                    title: "Compliance Rate",
                    value: "\(Int(compliance.complianceScore))%",
                    icon: "checkmark.shield",
                    color: complianceScoreColor(compliance.complianceScore)
                )
            }
        }
    }
    
    private func criticalIssuesSummary(for compliance: CoreTypes.PortfolioIntelligence) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Critical Issues")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .issues
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            let mockIssues = createMockIssues(count: min(compliance.criticalIssues, 3))
            ForEach(mockIssues, id: \.id) { issue in
                CriticalIssueRow(
                    issue: issue,
                    onTap: {
                        if let onIssuesTap = onIssuesTap {
                            onIssuesTap(issue)
                        } else {
                            showingIssueDetail = issue
                        }
                    }
                )
            }
        }
        .padding()
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func auditTimelineSection(for compliance: CoreTypes.PortfolioIntelligence) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audit Timeline")
                .font(.headline)
            
            VStack(spacing: 12) {
                let lastAudit = Calendar.current.date(byAdding: .day, value: -30, to: Date())
                let nextAudit = Calendar.current.date(byAdding: .day, value: 30, to: Date())
                
                if let lastAudit = lastAudit {
                    AuditTimelineItem(
                        title: "Last Audit",
                        date: lastAudit,
                        status: .completed,
                        isUpcoming: false
                    )
                }
                
                if let nextAudit = nextAudit {
                    AuditTimelineItem(
                        title: "Next Audit",
                        date: nextAudit,
                        status: .scheduled,
                        isUpcoming: true
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var complianceTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compliance Trends")
                .font(.headline)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("Trend visualization coming soon")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView("Loading compliance data...")
                .progressViewStyle(CircularProgressViewStyle())
        }
        .padding(40)
    }
    
    // MARK: - Issues Tab Content
    
    private var issuesTabContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let intelligence = intelligence {
                    if intelligence.criticalIssues == 0 {
                        noIssuesView
                    } else {
                        let mockIssues = createMockIssues(count: intelligence.criticalIssues)
                        ForEach(mockIssues, id: \.id) { issue in
                            ComplianceIssueCard(
                                issue: issue,
                                onTap: {
                                    if let onIssuesTap = onIssuesTap {
                                        onIssuesTap(issue)
                                    } else {
                                        showingIssueDetail = issue
                                    }
                                }
                            )
                        }
                    }
                } else {
                    loadingView
                }
            }
            .padding()
        }
    }
    
    private var noIssuesView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.shield")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("No Critical Issues")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Your portfolio is in good compliance standing")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Audits Tab Content
    
    private var auditsTabContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let intelligence = intelligence {
                    upcomingAuditsSection(for: intelligence)
                    auditHistorySection(for: intelligence)
                } else {
                    loadingView
                }
            }
            .padding()
        }
    }
    
    private func upcomingAuditsSection(for compliance: CoreTypes.PortfolioIntelligence) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Audits")
                    .font(.headline)
                
                Spacer()
                
                Button("Schedule New") {
                    showingAuditScheduler = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            let nextAudit = Calendar.current.date(byAdding: .day, value: 30, to: Date())
            if let nextAudit = nextAudit {
                UpcomingAuditCard(
                    date: nextAudit,
                    daysUntil: daysUntil(nextAudit),
                    onReschedule: {
                        showingAuditScheduler = true
                    }
                )
            } else {
                NoUpcomingAuditsCard(
                    onSchedule: {
                        showingAuditScheduler = true
                    }
                )
            }
        }
    }
    
    private func auditHistorySection(for compliance: CoreTypes.PortfolioIntelligence) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audit History")
                .font(.headline)
            
            let lastAudit = Calendar.current.date(byAdding: .day, value: -30, to: Date())
            if let lastAudit = lastAudit {
                AuditHistoryCard(
                    date: lastAudit,
                    score: compliance.complianceScore,
                    status: .completed
                )
            } else {
                Text("No previous audits recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Reports Tab Content
    
    private var reportsTabContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                availableReportsSection
                reportTemplatesSection
            }
            .padding()
        }
    }
    
    private var availableReportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Reports")
                    .font(.headline)
                
                Spacer()
                
                Button("Export All") {
                    showingExportOptions = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            ForEach(ReportType.allCases, id: \.self) { reportType in
                ReportCard(
                    type: reportType,
                    onGenerate: {
                        showingExportOptions = true
                    }
                )
            }
        }
    }
    
    private var reportTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report Templates")
                .font(.headline)
            
            Text("Customize report templates to meet your specific compliance requirements and stakeholder needs.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helper Functions
    
    private func complianceScoreColor(_ score: Double) -> Color {
        if score >= 90 { return .green }
        if score >= 80 { return .blue }
        if score >= 70 { return .orange }
        return .red
    }
    
    private func complianceStatusIcon(_ score: Double) -> String {
        if score >= 90 { return "checkmark.shield.fill" }
        if score >= 80 { return "checkmark.shield" }
        if score >= 70 { return "exclamationmark.shield" }
        return "xmark.shield"
    }
    
    private func complianceStatusText(_ score: Double) -> String {
        if score >= 90 { return "Excellent" }
        if score >= 80 { return "Good" }
        if score >= 70 { return "Fair" }
        return "Poor"
    }
    
    private func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
    
    private func calculateCompliantBuildings(_ intelligence: CoreTypes.PortfolioIntelligence) -> Int {
        let percentage = intelligence.complianceScore / 100.0
        return Int(Double(intelligence.totalBuildings) * percentage)
    }
    
    private func calculateCompliancePercentage(_ intelligence: CoreTypes.PortfolioIntelligence) -> Double {
        return intelligence.complianceScore
    }
    
    // Fixed: Using proper ComplianceIssueType cases
    private func createMockIssues(count: Int) -> [ComplianceIssueData] {
        guard count > 0 else { return [] }
        
        // Fixed: Removed imageAssetName parameter
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            latitude: 40.7402,
            longitude: -73.9980
        )
        
        var issues: [ComplianceIssueData] = []
        let issueTypes: [CoreTypes.ComplianceIssueType] = [.safety, .environmental, .regulatory]
        
        for i in 0..<count {
            let issue = ComplianceIssueData(
                type: issueTypes[i % issueTypes.count],
                severity: .high,
                description: "Critical compliance issue \(i + 1) requiring immediate attention",
                buildingId: sampleBuilding.id,
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            )
            issues.append(issue)
        }
        
        return issues
    }
    
    // Helper function to get icon for ComplianceTab
    private func tabIcon(for tab: CoreTypes.ComplianceTab) -> String {
        switch tab {
        case .overview: return "chart.pie.fill"
        case .issues: return "exclamationmark.triangle.fill"
        case .reports: return "doc.text.fill"
        case .audit: return "checkmark.shield.fill"
        }
    }
    
    // Helper function to get icon for ComplianceIssueType
    private func issueTypeIcon(_ type: CoreTypes.ComplianceIssueType) -> String {
        switch type {
        case .safety: return "shield.fill"
        case .environmental: return "leaf.fill"
        case .regulatory: return "doc.badge.gearshape"
        case .financial: return "dollarsign.circle.fill"
        case .operational: return "gearshape.fill"
        case .documentation: return "doc.text.fill"
        }
    }
}

// MARK: - Supporting Components

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
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct CriticalIssueRow: View {
    let issue: ComplianceIssueData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: issueTypeIcon(issue.type))
                    .font(.title3)
                    .foregroundColor(FrancoSphereDesign.EnumColors.complianceSeverity(issue.severity))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Building \(issue.buildingId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    SeverityBadge(severity: issue.severity)
                    
                    if let dueDate = issue.dueDate {
                        Text(formattedDueDate(dueDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formattedDueDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Helper function to get icon for ComplianceIssueType
    private func issueTypeIcon(_ type: CoreTypes.ComplianceIssueType) -> String {
        switch type {
        case .safety: return "shield.fill"
        case .environmental: return "leaf.fill"
        case .regulatory: return "doc.badge.gearshape"
        case .financial: return "dollarsign.circle.fill"
        case .operational: return "gearshape.fill"
        case .documentation: return "doc.text.fill"
        }
    }
}

struct ComplianceIssueCard: View {
    let issue: ComplianceIssueData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: issueTypeIcon(issue.type))
                        .font(.title3)
                        .foregroundColor(FrancoSphereDesign.EnumColors.complianceSeverity(issue.severity))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(issue.type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Building \(issue.buildingId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    SeverityBadge(severity: issue.severity)
                }
                
                Text(issue.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let dueDate = issue.dueDate {
                    HStack {
                        Text("Due:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper function to get icon for ComplianceIssueType
    private func issueTypeIcon(_ type: CoreTypes.ComplianceIssueType) -> String {
        switch type {
        case .safety: return "shield.fill"
        case .environmental: return "leaf.fill"
        case .regulatory: return "doc.badge.gearshape"
        case .financial: return "dollarsign.circle.fill"
        case .operational: return "gearshape.fill"
        case .documentation: return "doc.text.fill"
        }
    }
}

struct SeverityBadge: View {
    let severity: CoreTypes.ComplianceSeverity
    
    var body: some View {
        Text(severity.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(FrancoSphereDesign.EnumColors.complianceSeverity(severity), in: Capsule())
    }
}

struct AuditTimelineItem: View {
    let title: String
    let date: Date
    let status: AuditStatus
    let isUpcoming: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .font(.title3)
                .foregroundColor(status.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(formattedDate(date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isUpcoming {
                Text(daysUntilText(date))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days > 0 {
            return "In \(days) days"
        } else if days == 0 {
            return "Today"
        } else {
            return "\(abs(days)) days ago"
        }
    }
}

struct UpcomingAuditCard: View {
    let date: Date
    let daysUntil: Int
    let onReschedule: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Next Audit Scheduled")
                    .font(.headline)
                
                Spacer()
                
                Button("Reschedule") {
                    onReschedule()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(formattedDate(date))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(daysUntil > 0 ? "In \(daysUntil) days" : "Today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "calendar.badge.clock")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct NoUpcomingAuditsCard: View {
    let onSchedule: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("No Upcoming Audits")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Schedule your next compliance audit to maintain good standing")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Schedule Audit") {
                onSchedule()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AuditHistoryCard: View {
    let date: Date
    let score: Double
    let status: AuditStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Audit")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(formattedDate(date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(score))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
                
                Text("Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var scoreColor: Color {
        if score >= 90 { return .green }
        if score >= 80 { return .blue }
        if score >= 70 { return .orange }
        return .red
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ReportCard: View {
    let type: ReportType
    let onGenerate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Generate") {
                onGenerate()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Sheet Views

struct ComplianceIssueDetailSheet: View {
    let issue: ComplianceIssueData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(issue.type.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            SeverityBadge(severity: issue.severity)
                        }
                        
                        Text("Building \(issue.buildingId)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(issue.description)
                            .font(.body)
                    }
                    
                    if let dueDate = issue.dueDate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Due Date")
                                .font(.headline)
                            
                            Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.body)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Issue Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AuditSchedulerSheet: View {
    let onSchedule: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Schedule a compliance audit for your portfolio")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                DatePicker("Audit Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.wheel)
                
                Button("Schedule Audit") {
                    onSchedule()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Schedule Audit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ComplianceExportSheet: View {
    let onExport: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export compliance reports in various formats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    ForEach(ReportType.allCases, id: \.self) { reportType in
                        Button(action: {
                            onExport()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: reportType.icon)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(reportType.title)
                                        .fontWeight(.medium)
                                    Text(reportType.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.down.doc")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Enums

enum AuditStatus: String, CaseIterable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case overdue = "Overdue"
    
    var icon: String {
        switch self {
        case .scheduled: return "calendar"
        case .inProgress: return "clock"
        case .completed: return "checkmark.circle"
        case .overdue: return "exclamationmark.triangle"
        }
    }
    
    var color: Color {
        switch self {
        case .scheduled: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .overdue: return .red
        }
    }
}

enum ReportType: String, CaseIterable {
    case compliance = "Compliance Report"
    case audit = "Audit Summary"
    case issues = "Issues Report"
    case performance = "Performance Report"
    
    var title: String { rawValue }
    
    var description: String {
        switch self {
        case .compliance: return "Overall compliance status and metrics"
        case .audit: return "Detailed audit findings and recommendations"
        case .issues: return "Critical issues and resolution status"
        case .performance: return "Performance trends and analytics"
        }
    }
    
    var icon: String {
        switch self {
        case .compliance: return "doc.badge.arrow.up"
        case .audit: return "doc.text.magnifyingglass"
        case .issues: return "doc.badge.exclamationmark"
        case .performance: return "chart.bar.doc.horizontal"
        }
    }
}

// MARK: - ComplianceIssueData Type Definition (Renamed to avoid conflicts)

struct ComplianceIssueData: Identifiable {
    let id = UUID()
    let type: CoreTypes.ComplianceIssueType
    let severity: CoreTypes.ComplianceSeverity
    let description: String
    let buildingId: String
    let dueDate: Date?
    
    init(type: CoreTypes.ComplianceIssueType, severity: CoreTypes.ComplianceSeverity, description: String, buildingId: String, dueDate: Date? = nil) {
        self.type = type
        self.severity = severity
        self.description = description
        self.buildingId = buildingId
        self.dueDate = dueDate
    }
}

// MARK: - Preview

struct ComplianceOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Fixed: Using correct PortfolioIntelligence initializer
        let sampleIntelligence = CoreTypes.PortfolioIntelligence(
            totalBuildings: 12,
            activeWorkers: 24,
            completionRate: 0.87,
            criticalIssues: 3,
            monthlyTrend: .up,
            complianceScore: 85
        )
        
        ComplianceOverviewView(intelligence: sampleIntelligence)
            .preferredColorScheme(.dark)
    }
}
