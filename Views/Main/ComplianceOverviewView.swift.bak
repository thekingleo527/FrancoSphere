//
//  ComplianceOverviewView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  ComplianceOverviewView.swift
//  FrancoSphere
//
//  🎯 PHASE 4: COMPLIANCE OVERVIEW COMPONENT
//  ✅ Portfolio-wide compliance monitoring
//  ✅ Critical issues tracking and alerts
//  ✅ Audit scheduling and documentation
//  ✅ Regulatory compliance reporting
//

import SwiftUI

struct ComplianceOverviewView: View {
    let intelligence: PortfolioIntelligence?
    let onIssuesTap: ((ComplianceIssue) -> Void)?
    let onScheduleAudit: (() -> Void)?
    let onExportReport: (() -> Void)?
    
    @State private var selectedTab: ComplianceTab = .overview
    @State private var showingIssueDetail: ComplianceIssue?
    @State private var showingAuditScheduler = false
    @State private var showingExportOptions = false
    
    init(intelligence: PortfolioIntelligence?,
         onIssuesTap: ((ComplianceIssue) -> Void)? = nil,
         onScheduleAudit: (() -> Void)? = nil,
         onExportReport: (() -> Void)? = nil) {
        self.compliance = compliance
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
            complianceScoreCard
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var complianceScoreCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Compliance Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(compliance.overallScore))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(complianceScoreColor)
                }
                
                Spacer()
                
                // Compliance Status Icon
                VStack {
                    Image(systemName: complianceStatusIcon)
                        .font(.system(size: 32))
                        .foregroundColor(complianceScoreColor)
                    
                    Text(complianceStatusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(complianceScoreColor)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Compliant Buildings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(compliance.compliantBuildings)/\(compliance.totalBuildings)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                ProgressView(value: compliance.compliancePercentage / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: complianceScoreColor))
            }
        }
        .padding()
        .background(complianceScoreColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(complianceScoreColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Tab Selector Section
    
    private var tabSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(ComplianceTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.caption)
                                
                                Text(tab.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if tab == .issues && !compliance.criticalIssues.isEmpty {
                                    Text("\(compliance.criticalIssues.count)")
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
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tab Content Section
    
    private var tabContentSection: some View {
        Group {
            switch selectedTab {
            case .overview:
                overviewTabContent
            case .issues:
                issuesTabContent
            case .audits:
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
                // Quick Stats
                quickStatsSection
                
                // Critical Issues Summary
                if !compliance.criticalIssues.isEmpty {
                    criticalIssuesSummary
                }
                
                // Audit Timeline
                auditTimelineSection
                
                // Compliance Trends (Placeholder)
                complianceTrendsSection
            }
            .padding()
        }
    }
    
    private var quickStatsSection: some View {
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
                    value: "\(compliance.pendingActions)",
                    icon: "hourglass",
                    color: compliance.pendingActions > 0 ? .orange : .green
                )
                
                QuickStatCard(
                    title: "Critical Issues",
                    value: "\(compliance.criticalIssues.count)",
                    icon: "exclamationmark.triangle",
                    color: compliance.criticalIssues.isEmpty ? .green : .red
                )
                
                QuickStatCard(
                    title: "Compliance Rate",
                    value: "\(Int(compliance.compliancePercentage))%",
                    icon: "checkmark.shield",
                    color: complianceScoreColor
                )
            }
        }
    }
    
    private var criticalIssuesSummary: some View {
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
            
            ForEach(compliance.criticalIssues.prefix(3), id: \.id) { issue in
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
    
    private var auditTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audit Timeline")
                .font(.headline)
            
            VStack(spacing: 12) {
                if let lastAudit = compliance.lastAuditDate {
                    AuditTimelineItem(
                        title: "Last Audit",
                        date: lastAudit,
                        status: .completed,
                        isUpcoming: false
                    )
                }
                
                if let nextAudit = compliance.nextAuditDate {
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
            
            // Placeholder for trend chart
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
    
    // MARK: - Issues Tab Content
    
    private var issuesTabContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if compliance.criticalIssues.isEmpty {
                    noIssuesView
                } else {
                    ForEach(compliance.criticalIssues, id: \.id) { issue in
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
                // Upcoming Audits
                upcomingAuditsSection
                
                // Audit History
                auditHistorySection
            }
            .padding()
        }
    }
    
    private var upcomingAuditsSection: some View {
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
            
            if let nextAudit = compliance.nextAuditDate {
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
    
    private var auditHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audit History")
                .font(.headline)
            
            if let lastAudit = compliance.lastAuditDate {
                AuditHistoryCard(
                    date: lastAudit,
                    score: compliance.overallScore,
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
                // Available Reports
                availableReportsSection
                
                // Report Templates
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
                        // Handle report generation
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
    
    // MARK: - Computed Properties
    
    private var complianceScoreColor: Color {
        if compliance.overallScore >= 90 { return .green }
        if compliance.overallScore >= 80 { return .blue }
        if compliance.overallScore >= 70 { return .orange }
        return .red
    }
    
    private var complianceStatusIcon: String {
        if compliance.overallScore >= 90 { return "checkmark.shield.fill" }
        if compliance.overallScore >= 80 { return "checkmark.shield" }
        if compliance.overallScore >= 70 { return "exclamationmark.shield" }
        return "xmark.shield"
    }
    
    private var complianceStatusText: String {
        if compliance.overallScore >= 90 { return "Excellent" }
        if compliance.overallScore >= 80 { return "Good" }
        if compliance.overallScore >= 70 { return "Fair" }
        return "Poor"
    }
    
    private func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
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
    let issue: ComplianceIssue
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: issue.issueType.icon)
                    .font(.title3)
                    .foregroundColor(issue.severity.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.issueType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(issue.building.name)
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
}

struct SeverityBadge: View {
    let severity: ComplianceSeverity
    
    var body: some View {
        Text(severity.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severity.color, in: Capsule())
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

struct ComplianceIssueCard: View {
    let issue: ComplianceIssue
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(issue.issueType.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(issue.building.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    SeverityBadge(severity: issue.severity)
                }
                
                Text(issue.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if let dueDate = issue.dueDate {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Due: \(formattedDueDate(dueDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(issue.severity.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formattedDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Additional Components (Sheets and Cards)

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

// MARK: - Placeholder Sheets

struct ComplianceIssueDetailSheet: View {
    let issue: ComplianceIssue
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Issue Detail")
                Text(issue.description)
            }
            .navigationTitle(issue.issueType.rawValue)
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
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Schedule Audit")
                Button("Schedule") {
                    onSchedule()
                    dismiss()
                }
            }
            .navigationTitle("Schedule Audit")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
            VStack {
                Text("Export Reports")
                Button("Export") {
                    onExport()
                    dismiss()
                }
            }
            .navigationTitle("Export Reports")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Enums

enum ComplianceTab: String, CaseIterable {
    case overview = "Overview"
    case issues = "Issues"
    case audits = "Audits"
    case reports = "Reports"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "chart.pie"
        case .issues: return "exclamationmark.triangle"
        case .audits: return "calendar.badge.clock"
        case .reports: return "doc.text"
        }
    }
}

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

extension ComplianceIssueType {
    var icon: String {
        switch self {
        case .maintenanceOverdue: return "wrench.and.screwdriver"
        case .safetyViolation: return "exclamationmark.shield"
        case .documentationMissing: return "doc.badge.exclamationmark"
        case .inspectionRequired: return "magnifyingglass"
        }
    }
}

// MARK: - Preview

struct ComplianceOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        ComplianceOverviewView(
            intelligence: PortfolioIntelligence?(
                overallScore: 85.0,
                compliantBuildings: 10,
                totalBuildings: 12,
                pendingActions: 5,
                criticalIssues: [],
                lastAuditDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                nextAuditDate: Calendar.current.date(byAdding: .day, value: 23, to: Date())
            )
        )
        .preferredColorScheme(.dark)
    }
}