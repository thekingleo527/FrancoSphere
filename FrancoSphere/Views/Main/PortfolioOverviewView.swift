//
//  PortfolioOverviewView.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ALIGNED: Mirrors WorkerDashboardView design patterns
//  ✅ ENHANCED: Glass morphism effects and animations
//  ✅ FIXED: All colors now use FrancoSphereDesign.DashboardColors
//

import SwiftUI

struct PortfolioOverviewView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    let onBuildingTap: ((NamedCoordinate) -> Void)?
    let onRefresh: (() async -> Void)?
    
    @State private var selectedMetric: MetricType = .efficiency
    @State private var showingDetailView = false
    @State private var isRefreshing = false
    @State private var isHeroCollapsed = false
    
    init(intelligence: CoreTypes.PortfolioIntelligence,
         onBuildingTap: ((NamedCoordinate) -> Void)? = nil,
         onRefresh: (() async -> Void)? = nil) {
        self.intelligence = intelligence
        self.onBuildingTap = onBuildingTap
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        ZStack {
            // Dark Elegance Background
            FrancoSphereDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: FrancoSphereDesign.Spacing.lg) {
                    // Portfolio Hero Section (Collapsible like Worker Dashboard)
                    PortfolioHeroCard(
                        intelligence: intelligence,
                        isCollapsed: $isHeroCollapsed
                    )
                    .zIndex(50)
                    
                    // Key Metrics Selector
                    metricSelectorSection
                    
                    // Selected Metric Detail
                    selectedMetricDetailSection
                    
                    // Performance Summary
                    performanceSummarySection
                    
                    // Alert Summary
                    alertSummarySection
                    
                    // Last Updated Info
                    lastUpdatedSection
                }
                .padding(.horizontal, FrancoSphereDesign.Spacing.md)
                .padding(.vertical, FrancoSphereDesign.Spacing.lg)
            }
            .refreshable {
                if let onRefresh = onRefresh {
                    isRefreshing = true
                    await onRefresh()
                    isRefreshing = false
                }
            }
            .overlay(
                isRefreshing ?
                FrancoLoadingView(
                    message: "Refreshing portfolio data...",
                    role: .admin
                ) : nil
            )
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Metric Selector Section
    
    private var metricSelectorSection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
            Text("Key Metrics")
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        MetricSelectorButton(
                            metric: metric,
                            isSelected: selectedMetric == metric,
                            onTap: {
                                withAnimation(FrancoSphereDesign.Animations.spring) {
                                    selectedMetric = metric
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Selected Metric Detail Section
    
    private var selectedMetricDetailSection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.md) {
            HStack {
                Image(systemName: selectedMetric.icon)
                    .font(.title2)
                    .foregroundColor(selectedMetric.darkThemeColor)
                
                Text(selectedMetric.title)
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
            }
            
            Group {
                switch selectedMetric {
                case .efficiency:
                    EfficiencyDetailView(intelligence: intelligence)
                case .tasks:
                    TasksDetailView(intelligence: intelligence)
                case .performance:
                    PerformanceDetailView(intelligence: intelligence)
                case .alerts:
                    AlertsDetailView(intelligence: intelligence)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Performance Summary Section
    
    private var performanceSummarySection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
            Text("Performance Summary")
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compliance Score")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text("\(intelligence.complianceScore)%")
                        .francoTypography(FrancoSphereDesign.Typography.title2)
                        .foregroundColor(complianceColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Trend")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon(for: intelligence.monthlyTrend))
                            .font(.caption)
                            .foregroundColor(trendColor(for: intelligence.monthlyTrend))
                        
                        Text(intelligence.monthlyTrend.rawValue.capitalized)
                            .francoTypography(FrancoSphereDesign.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(trendColor(for: intelligence.monthlyTrend))
                    }
                }
            }
            .francoCardPadding()
            .francoDarkCardBackground()
        }
    }
    
    // MARK: - Alert Summary Section
    
    private var alertSummarySection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                
                Text("Portfolio Status")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            
            VStack(spacing: FrancoSphereDesign.Spacing.sm) {
                StatusRow(
                    title: "Buildings Monitored",
                    value: "\(intelligence.totalBuildings)",
                    icon: "building.2",
                    color: FrancoSphereDesign.DashboardColors.info
                )
                
                StatusRow(
                    title: "Active Workers",
                    value: "\(intelligence.activeWorkers)",
                    icon: "person.2",
                    color: FrancoSphereDesign.DashboardColors.tertiaryAction
                )
                
                StatusRow(
                    title: "Critical Issues",
                    value: "\(intelligence.criticalIssues)",
                    icon: "exclamationmark.triangle",
                    color: intelligence.criticalIssues > 0 ?
                        FrancoSphereDesign.DashboardColors.critical :
                        FrancoSphereDesign.DashboardColors.success
                )
                
                StatusRow(
                    title: "Overall Health",
                    value: healthStatus,
                    icon: healthIcon,
                    color: healthColor
                )
            }
            .francoCardPadding()
            .background(
                RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                    .fill(FrancoSphereDesign.DashboardColors.info.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                            .stroke(FrancoSphereDesign.DashboardColors.info.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Last Updated Section
    
    private var lastUpdatedSection: some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            
            Text("Last updated just now")
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var efficiencyColor: Color {
        FrancoSphereDesign.EnumColors.trendDirection(
            intelligence.completionRate >= 0.9 ? .up :
            intelligence.completionRate >= 0.7 ? .stable : .down
        )
    }
    
    private var complianceColor: Color {
        let score = Double(intelligence.complianceScore) / 100.0
        return FrancoSphereDesign.EnumColors.complianceStatus(
            score >= 0.9 ? .compliant :
            score >= 0.7 ? .warning : .violation
        )
    }
    
    private var healthStatus: String {
        let efficiency = intelligence.completionRate
        let compliance = Double(intelligence.complianceScore) / 100.0
        let average = (efficiency + compliance) / 2
        
        if average >= 0.9 { return "Excellent" }
        if average >= 0.8 { return "Good" }
        if average >= 0.7 { return "Fair" }
        return "Needs Attention"
    }
    
    private var healthIcon: String {
        let efficiency = intelligence.completionRate
        let compliance = Double(intelligence.complianceScore) / 100.0
        let average = (efficiency + compliance) / 2
        
        if average >= 0.9 { return "checkmark.circle.fill" }
        if average >= 0.8 { return "checkmark.circle" }
        if average >= 0.7 { return "exclamationmark.circle" }
        return "exclamationmark.triangle.fill"
    }
    
    private var healthColor: Color {
        let efficiency = intelligence.completionRate
        let compliance = Double(intelligence.complianceScore) / 100.0
        let average = (efficiency + compliance) / 2
        
        return FrancoSphereDesign.EnumColors.dataHealthStatus(
            average >= 0.9 ? .healthy :
            average >= 0.7 ? .warning : .error
        )
    }
    
    // MARK: - Helper Functions
    
    private func trendIcon(for trend: CoreTypes.TrendDirection) -> String {
        FrancoSphereDesign.Icons.statusIcon(for: trend.rawValue)
    }
    
    private func trendColor(for trend: CoreTypes.TrendDirection) -> Color {
        FrancoSphereDesign.EnumColors.trendDirection(trend)
    }
}

// MARK: - Portfolio Hero Card

struct PortfolioHeroCard: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    @Binding var isCollapsed: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                // Minimal collapsed version
                MinimalPortfolioHero(
                    intelligence: intelligence,
                    onExpand: {
                        withAnimation(FrancoSphereDesign.Animations.spring) {
                            isCollapsed = false
                        }
                    }
                )
            } else {
                // Full hero card
                FullPortfolioHero(
                    intelligence: intelligence,
                    onCollapse: {
                        withAnimation(FrancoSphereDesign.Animations.spring) {
                            isCollapsed = true
                        }
                    }
                )
            }
        }
    }
}

struct MinimalPortfolioHero: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    let onExpand: () -> Void
    
    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text("Portfolio Overview")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text("•")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                
                // Key metrics
                HStack(spacing: 4) {
                    Image(systemName: "building.2")
                        .font(.caption)
                    Text("\(intelligence.totalBuildings)")
                }
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Text("•")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                
                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.caption)
                    Text("\(Int(intelligence.completionRate * 100))%")
                }
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            .padding(.horizontal, FrancoSphereDesign.Spacing.md)
            .padding(.vertical, FrancoSphereDesign.Spacing.sm)
            .francoDarkCardBackground(cornerRadius: FrancoSphereDesign.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        let average = (intelligence.completionRate + Double(intelligence.complianceScore) / 100.0) / 2
        return average >= 0.8 ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.warning
    }
}

struct FullPortfolioHero: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    let onCollapse: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.md) {
                Text("Portfolio Overview")
                    .francoTypography(FrancoSphereDesign.Typography.title2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: FrancoSphereDesign.Spacing.sm) {
                    SummaryCard(
                        title: "Total Buildings",
                        value: "\(intelligence.totalBuildings)",
                        icon: "building.2",
                        color: FrancoSphereDesign.DashboardColors.info,
                        trend: nil
                    )
                    
                    SummaryCard(
                        title: "Completion Rate",
                        value: "\(Int(intelligence.completionRate * 100))%",
                        icon: "speedometer",
                        color: efficiencyColor,
                        trend: intelligence.monthlyTrend
                    )
                    
                    SummaryCard(
                        title: "Completed Tasks",
                        value: "\(intelligence.completedTasks)",
                        icon: "checkmark.circle",
                        color: FrancoSphereDesign.DashboardColors.success,
                        trend: nil
                    )
                    
                    SummaryCard(
                        title: "Active Workers",
                        value: "\(intelligence.activeWorkers)",
                        icon: "person.2",
                        color: FrancoSphereDesign.DashboardColors.tertiaryAction,
                        trend: nil
                    )
                }
            }
            .francoCardPadding()
            .francoDarkCardBackground()
            
            // Collapse button
            Button(action: onCollapse) {
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                    )
            }
            .padding(FrancoSphereDesign.Spacing.sm)
        }
    }
    
    private var efficiencyColor: Color {
        FrancoSphereDesign.EnumColors.trendDirection(
            intelligence.completionRate >= 0.9 ? .up :
            intelligence.completionRate >= 0.7 ? .stable : .down
        )
    }
}

// MARK: - Supporting Components (Updated for Dark Theme)

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: CoreTypes.TrendDirection?
    
    var body: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trendIconForCard(trend))
                        .font(.caption)
                        .foregroundColor(trendColorForCard(trend))
                }
            }
            
            Text(value)
                .francoTypography(FrancoSphereDesign.Typography.title2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Text(title)
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                .lineLimit(1)
        }
        .francoCardPadding()
        .francoGlassBackground()
    }
    
    private func trendIconForCard(_ trend: CoreTypes.TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.circle"
        case .down: return "arrow.down.circle"
        case .stable: return "minus.circle"
        case .improving: return "arrow.up.right.circle"
        case .declining: return "arrow.down.right.circle"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private func trendColorForCard(_ trend: CoreTypes.TrendDirection) -> Color {
        FrancoSphereDesign.EnumColors.trendDirection(trend)
    }
}

struct MetricSelectorButton: View {
    let metric: MetricType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.caption)
                
                Text(metric.title)
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, FrancoSphereDesign.Spacing.sm)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.round)
                    .fill(isSelected ?
                        metric.darkThemeColor :
                        FrancoSphereDesign.DashboardColors.glassOverlay
                    )
            )
            .foregroundColor(isSelected ?
                .white :
                FrancoSphereDesign.DashboardColors.primaryText
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(title)
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
        }
    }
}

// MARK: - Metric Detail Views (Updated for Dark Theme)

struct EfficiencyDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            HStack {
                Text("Portfolio Efficiency")
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Text("\(Int(intelligence.completionRate * 100))%")
                    .francoTypography(FrancoSphereDesign.Typography.title)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            
            FrancoMetricsProgress(
                value: intelligence.completionRate,
                role: .admin
            )
            
            HStack {
                Text("Target: 85%")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                
                Spacer()
                
                Text(intelligence.completionRate >= 0.85 ? "Above Target" : "Below Target")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(intelligence.completionRate >= 0.85 ?
                        FrancoSphereDesign.DashboardColors.success :
                        FrancoSphereDesign.DashboardColors.warning
                    )
            }
        }
    }
}

struct TasksDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Completed Tasks")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text("\(intelligence.completedTasks)")
                        .francoTypography(FrancoSphereDesign.Typography.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Compliance")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text("\(intelligence.complianceScore)%")
                        .francoTypography(FrancoSphereDesign.Typography.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
            }
            
            HStack {
                Label("Tasks Completed", systemImage: "checkmark.circle")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                
                Spacer()
                
                Label("Active Workers: \(intelligence.activeWorkers)", systemImage: "person.2")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.info)
            }
        }
    }
}

struct PerformanceDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            Text("Performance is calculated based on completion rates, compliance scores, and worker productivity across your portfolio.")
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                .multilineTextAlignment(.leading)
            
            HStack {
                PerformanceMetricItem(
                    title: "Completion",
                    value: "\(Int(intelligence.completionRate * 100))%",
                    color: intelligence.completionRate >= 0.8 ?
                        FrancoSphereDesign.DashboardColors.success :
                        FrancoSphereDesign.DashboardColors.warning
                )
                
                Spacer()
                
                PerformanceMetricItem(
                    title: "Compliance",
                    value: "\(intelligence.complianceScore)%",
                    color: intelligence.complianceScore >= 80 ?
                        FrancoSphereDesign.DashboardColors.success :
                        FrancoSphereDesign.DashboardColors.warning
                )
            }
        }
    }
}

struct AlertsDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            let overallHealth = (intelligence.completionRate + Double(intelligence.complianceScore) / 100.0) / 2
            
            if overallHealth >= 0.8 && intelligence.criticalIssues == 0 {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                    
                    Text("Portfolio performing well")
                        .francoTypography(FrancoSphereDesign.Typography.subheadline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                }
            } else {
                VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
                    if intelligence.criticalIssues > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                            
                            Text("\(intelligence.criticalIssues) critical issues require attention")
                                .francoTypography(FrancoSphereDesign.Typography.subheadline)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                        }
                    }
                    
                    if intelligence.completionRate < 0.8 {
                        Text("Completion rate needs improvement")
                            .francoTypography(FrancoSphereDesign.Typography.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                    }
                    
                    if intelligence.complianceScore < 80 {
                        Text("Compliance requires attention")
                            .francoTypography(FrancoSphereDesign.Typography.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                    }
                }
            }
        }
    }
}

struct PerformanceMetricItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .francoTypography(FrancoSphereDesign.Typography.title3)
                .foregroundColor(color)
            
            Text(title)
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
        }
    }
}

// MARK: - Metric Types

enum MetricType: String, CaseIterable {
    case efficiency = "Efficiency"
    case tasks = "Tasks"
    case performance = "Performance"
    case alerts = "Alerts"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .efficiency: return "speedometer"
        case .tasks: return "checklist"
        case .performance: return "chart.line.uptrend.xyaxis"
        case .alerts: return "exclamationmark.triangle"
        }
    }
    
    var darkThemeColor: Color {
        switch self {
        case .efficiency: return FrancoSphereDesign.DashboardColors.info
        case .tasks: return FrancoSphereDesign.DashboardColors.success
        case .performance: return FrancoSphereDesign.DashboardColors.tertiaryAction
        case .alerts: return FrancoSphereDesign.DashboardColors.warning
        }
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
    let insight: CoreTypes.IntelligenceInsight
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.lg) {
                // Insight header
                VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
                    HStack {
                        Image(systemName: iconForInsightType(insight.type))
                            .foregroundColor(colorForInsightType(insight.type))
                        
                        Text(insight.type.rawValue.capitalized)
                            .francoTypography(FrancoSphereDesign.Typography.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        
                        Spacer()
                        
                        if insight.actionRequired {
                            Label("Action Required", systemImage: "exclamationmark.circle.fill")
                                .francoTypography(FrancoSphereDesign.Typography.caption)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        }
                    }
                    
                    Text(insight.title)
                        .francoTypography(FrancoSphereDesign.Typography.title3)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                // Description
                Text(insight.description)
                    .francoTypography(FrancoSphereDesign.Typography.body)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                // Affected buildings
                if !insight.affectedBuildings.isEmpty {
                    VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
                        Text("Affected Buildings")
                            .francoTypography(FrancoSphereDesign.Typography.headline)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        
                        ForEach(insight.affectedBuildings, id: \.self) { buildingId in
                            HStack {
                                Image(systemName: "building.2")
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                                
                                Text("Building \(buildingId)")
                                    .francoTypography(FrancoSphereDesign.Typography.body)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                            }
                            .padding(.vertical, FrancoSphereDesign.Spacing.xs)
                        }
                    }
                    .francoCardPadding()
                    .francoGlassBackground()
                }
                
                Spacer()
            }
            .padding(FrancoSphereDesign.Spacing.lg)
            .background(FrancoSphereDesign.DashboardColors.baseBackground)
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func iconForInsightType(_ type: CoreTypes.InsightCategory) -> String {
        switch type {
        case .efficiency: return "speedometer"
        case .cost: return "dollarsign.circle"
        case .safety: return "shield"
        case .compliance: return "checkmark.shield"
        case .quality: return "star"
        case .operations: return "gear"
        case .maintenance: return "wrench"
        }
    }
    
    private func colorForInsightType(_ type: CoreTypes.InsightCategory) -> Color {
        FrancoSphereDesign.EnumColors.insightCategory(type)
    }
}

// MARK: - Preview

struct PortfolioOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioOverviewView(
            intelligence: CoreTypes.PortfolioIntelligence(
                totalBuildings: 12,
                activeWorkers: 24,
                completionRate: 0.87,
                criticalIssues: 3,
                monthlyTrend: .up,
                completedTasks: 132,
                complianceScore: 92,
                weeklyTrend: 0.05
            )
        )
        .preferredColorScheme(.dark)
    }
}
