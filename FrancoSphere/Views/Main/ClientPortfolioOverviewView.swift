//
//  ClientPortfolioOverviewView.swift
//  FrancoSphere v6.0
//
//  ✅ CLIENT-FILTERED: Only shows data for client's properties
//  ✅ PRIVACY: No worker-specific information exposed
//  ✅ FOCUSED: Metrics relevant to property owners
//  ✅ DARK ELEGANCE: Consistent theme with dashboards
//  ✅ FIXED: Resolved type ambiguity issues
//

import SwiftUI

struct ClientPortfolioOverviewView: View {
    // Using a type alias to resolve ambiguity
    typealias ClientIntelligence = CoreTypes.ClientPortfolioIntelligence
    
    let clientIntelligence: ClientIntelligence
    let onBuildingTap: ((NamedCoordinate) -> Void)?
    let onRefresh: (() async -> Void)?
    
    @State private var selectedMetric: ClientMetricType = .service
    @State private var showingDetailView = false
    @State private var isRefreshing = false
    @State private var isHeroCollapsed = false
    
    init(clientIntelligence: ClientIntelligence,
         onBuildingTap: ((NamedCoordinate) -> Void)? = nil,
         onRefresh: (() async -> Void)? = nil) {
        self.clientIntelligence = clientIntelligence
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
                    // Client Portfolio Hero Section (Collapsible)
                    ClientPortfolioHeroCard(
                        intelligence: clientIntelligence,
                        isCollapsed: $isHeroCollapsed
                    )
                    .zIndex(50)
                    
                    // Key Metrics Selector
                    metricSelectorSection
                    
                    // Selected Metric Detail
                    selectedMetricDetailSection
                    
                    // Service Summary
                    serviceSummarySection
                    
                    // Cost Overview
                    if clientIntelligence.showCostData {
                        costOverviewSection
                    }
                    
                    // Property Status
                    propertyStatusSection
                    
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
                    message: "Refreshing your property data...",
                    role: .client
                ) : nil
            )
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Metric Selector Section
    
    private var metricSelectorSection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
            Text("Property Metrics")
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                    ForEach(ClientMetricType.allCases, id: \.self) { metric in
                        if metric != .cost || clientIntelligence.showCostData {
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
                case .service:
                    ClientServiceDetailView(intelligence: clientIntelligence)
                case .compliance:
                    ClientComplianceDetailView(intelligence: clientIntelligence)
                case .coverage:
                    ClientCoverageDetailView(intelligence: clientIntelligence)
                case .cost:
                    ClientCostDetailView(intelligence: clientIntelligence)
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
    
    // MARK: - Service Summary Section
    
    private var serviceSummarySection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
            Text("Service Performance")
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Service Level")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text("\(Int(clientIntelligence.serviceLevel * 100))%")
                        .francoTypography(FrancoSphereDesign.Typography.title2)
                        .foregroundColor(serviceLevelColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Trend")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon(for: clientIntelligence.monthlyTrend))
                            .font(.caption)
                            .foregroundColor(trendColor(for: clientIntelligence.monthlyTrend))
                        
                        Text(clientIntelligence.monthlyTrend.rawValue.capitalized)
                            .francoTypography(FrancoSphereDesign.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(trendColor(for: clientIntelligence.monthlyTrend))
                    }
                }
            }
            .francoCardPadding()
            .francoDarkCardBackground()
        }
    }
    
    // MARK: - Cost Overview Section
    
    private var costOverviewSection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                
                Text("Cost Overview")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Month")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text(formatCurrency(clientIntelligence.monthlySpend))
                        .francoTypography(FrancoSphereDesign.Typography.title3)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Budget")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text(formatCurrency(clientIntelligence.monthlyBudget))
                        .francoTypography(FrancoSphereDesign.Typography.title3)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
            }
            
            // Budget progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(budgetProgressColor)
                        .frame(
                            width: min(
                                geometry.size.width * (clientIntelligence.monthlySpend / clientIntelligence.monthlyBudget),
                                geometry.size.width
                            ),
                            height: 8
                        )
                        .animation(.easeOut(duration: 0.5), value: clientIntelligence.monthlySpend)
                }
            }
            .frame(height: 8)
            .padding(.top, 8)
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Property Status Section
    
    private var propertyStatusSection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                
                Text("Property Status")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            
            VStack(spacing: FrancoSphereDesign.Spacing.sm) {
                StatusRow(
                    title: "Properties Managed",
                    value: "\(clientIntelligence.totalProperties)",
                    icon: "building.2",
                    color: FrancoSphereDesign.DashboardColors.info
                )
                
                StatusRow(
                    title: "Service Coverage",
                    value: "\(Int(clientIntelligence.coveragePercentage))%",
                    icon: "mappin.circle",
                    color: FrancoSphereDesign.DashboardColors.tertiaryAction
                )
                
                StatusRow(
                    title: "Compliance Issues",
                    value: "\(clientIntelligence.complianceIssues)",
                    icon: "exclamationmark.triangle",
                    color: clientIntelligence.complianceIssues > 0 ?
                        FrancoSphereDesign.DashboardColors.critical :
                        FrancoSphereDesign.DashboardColors.success
                )
                
                StatusRow(
                    title: "Overall Status",
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
    
    private var serviceLevelColor: Color {
        if clientIntelligence.serviceLevel >= 0.9 {
            return FrancoSphereDesign.DashboardColors.success
        } else if clientIntelligence.serviceLevel >= 0.8 {
            return FrancoSphereDesign.DashboardColors.info
        } else if clientIntelligence.serviceLevel >= 0.7 {
            return FrancoSphereDesign.DashboardColors.warning
        }
        return FrancoSphereDesign.DashboardColors.critical
    }
    
    private var budgetProgressColor: Color {
        let percentage = clientIntelligence.monthlySpend / clientIntelligence.monthlyBudget
        if percentage > 1.0 {
            return FrancoSphereDesign.DashboardColors.critical
        } else if percentage > 0.9 {
            return FrancoSphereDesign.DashboardColors.warning
        }
        return FrancoSphereDesign.DashboardColors.success
    }
    
    private var healthStatus: String {
        let service = clientIntelligence.serviceLevel
        let compliance = Double(clientIntelligence.complianceScore) / 100.0
        let average = (service + compliance) / 2
        
        if average >= 0.9 { return "Excellent" }
        if average >= 0.8 { return "Good" }
        if average >= 0.7 { return "Fair" }
        return "Needs Attention"
    }
    
    private var healthIcon: String {
        let service = clientIntelligence.serviceLevel
        let compliance = Double(clientIntelligence.complianceScore) / 100.0
        let average = (service + compliance) / 2
        
        if average >= 0.9 { return "checkmark.circle.fill" }
        if average >= 0.8 { return "checkmark.circle" }
        if average >= 0.7 { return "exclamationmark.circle" }
        return "exclamationmark.triangle.fill"
    }
    
    private var healthColor: Color {
        let service = clientIntelligence.serviceLevel
        let compliance = Double(clientIntelligence.complianceScore) / 100.0
        let average = (service + compliance) / 2
        
        return FrancoSphereDesign.EnumColors.dataHealthStatus(
            average >= 0.9 ? .healthy :
            average >= 0.7 ? .warning : .error
        )
    }
    
    // MARK: - Helper Functions
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func trendIcon(for trend: CoreTypes.TrendDirection) -> String {
        FrancoSphereDesign.Icons.statusIcon(for: trend.rawValue)
    }
    
    private func trendColor(for trend: CoreTypes.TrendDirection) -> Color {
        FrancoSphereDesign.EnumColors.trendDirection(trend)
    }
}

// MARK: - Client Portfolio Hero Card

struct ClientPortfolioHeroCard: View {
    // Using type alias to avoid ambiguity
    typealias ClientIntelligence = CoreTypes.ClientPortfolioIntelligence
    
    let intelligence: ClientIntelligence
    @Binding var isCollapsed: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                // Minimal collapsed version
                MinimalClientPortfolioHero(
                    intelligence: intelligence,
                    onExpand: {
                        withAnimation(FrancoSphereDesign.Animations.spring) {
                            isCollapsed = false
                        }
                    }
                )
            } else {
                // Full hero card
                FullClientPortfolioHero(
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

struct MinimalClientPortfolioHero: View {
    typealias ClientIntelligence = CoreTypes.ClientPortfolioIntelligence
    
    let intelligence: ClientIntelligence
    let onExpand: () -> Void
    
    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text("Property Overview")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text("•")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                
                // Key metrics
                HStack(spacing: 4) {
                    Image(systemName: "building.2")
                        .font(.caption)
                    Text("\(intelligence.totalProperties)")
                }
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Text("•")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                
                HStack(spacing: 4) {
                    Image(systemName: "star")
                        .font(.caption)
                    Text("\(Int(intelligence.serviceLevel * 100))%")
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
        let average = (intelligence.serviceLevel + Double(intelligence.complianceScore) / 100.0) / 2
        return average >= 0.8 ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.warning
    }
}

struct FullClientPortfolioHero: View {
    typealias ClientIntelligence = CoreTypes.ClientPortfolioIntelligence
    
    let intelligence: ClientIntelligence
    let onCollapse: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.md) {
                Text("Your Properties")
                    .francoTypography(FrancoSphereDesign.Typography.title2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: FrancoSphereDesign.Spacing.sm) {
                    SummaryCard(
                        title: "Properties",
                        value: "\(intelligence.totalProperties)",
                        icon: "building.2",
                        color: FrancoSphereDesign.DashboardColors.info,
                        trend: nil
                    )
                    
                    SummaryCard(
                        title: "Service Level",
                        value: "\(Int(intelligence.serviceLevel * 100))%",
                        icon: "star",
                        color: serviceLevelColor,
                        trend: intelligence.monthlyTrend
                    )
                    
                    SummaryCard(
                        title: "Compliance",
                        value: "\(intelligence.complianceScore)%",
                        icon: "checkmark.shield",
                        color: complianceColor,
                        trend: nil
                    )
                    
                    if intelligence.showCostData {
                        SummaryCard(
                            title: "Monthly Cost",
                            value: formatCurrency(intelligence.monthlySpend),
                            icon: "dollarsign.circle",
                            color: costColor,
                            trend: nil
                        )
                    } else {
                        SummaryCard(
                            title: "Coverage",
                            value: "\(Int(intelligence.coveragePercentage))%",
                            icon: "mappin.circle",
                            color: FrancoSphereDesign.DashboardColors.tertiaryAction,
                            trend: nil
                        )
                    }
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
    
    private var serviceLevelColor: Color {
        if intelligence.serviceLevel >= 0.9 {
            return FrancoSphereDesign.DashboardColors.success
        } else if intelligence.serviceLevel >= 0.8 {
            return FrancoSphereDesign.DashboardColors.info
        }
        return FrancoSphereDesign.DashboardColors.warning
    }
    
    private var complianceColor: Color {
        if intelligence.complianceScore >= 90 {
            return FrancoSphereDesign.DashboardColors.success
        } else if intelligence.complianceScore >= 80 {
            return FrancoSphereDesign.DashboardColors.info
        } else if intelligence.complianceScore >= 70 {
            return FrancoSphereDesign.DashboardColors.warning
        }
        return FrancoSphereDesign.DashboardColors.critical
    }
    
    private var costColor: Color {
        let percentage = intelligence.monthlySpend / intelligence.monthlyBudget
        if percentage > 1.0 {
            return FrancoSphereDesign.DashboardColors.critical
        } else if percentage > 0.9 {
            return FrancoSphereDesign.DashboardColors.warning
        }
        return FrancoSphereDesign.DashboardColors.success
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Supporting Components

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
    let metric: ClientMetricType
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

// MARK: - Client Metric Detail Views

struct ClientServiceDetailView: View {
    typealias ClientIntelligence = CoreTypes.ClientPortfolioIntelligence
    
    let intelligence: ClientIntelligence
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            HStack {
                Text("Service Performance")
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Text("\(Int(intelligence.serviceLevel * 100))%")
                    .francoTypography(FrancoSphereDesign.Typography.title)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            
            FrancoMetricsProgress(
                value: intelligence.serviceLevel,
                role: .client
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Service includes regular cleaning, maintenance, and compliance monitoring for all your properties.")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

struct ClientComplianceDetailView: View {
    typealias ClientIntelligence = CoreTypes.ClientPortfolioIntelligence
    
    let intelligence: ClientIntelligence
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Compliance Score")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text("\(intelligence.complianceScore)%")
                        .francoTypography(FrancoSphereDesign.Typography.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Issues")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text("\(intelligence.complianceIssues)")
                        .francoTypography(FrancoSphereDesign.Typography.title2)
                        .foregroundColor(intelligence.complianceIssues > 0 ?
                            FrancoSphereDesign.DashboardColors.warning :
                            FrancoSphereDesign.DashboardColors.success
                        )
                }
            }
            
            if intelligence.complianceIssues > 0 {
                Text("\(intelligence.complianceIssues) compliance issues require attention across your properties.")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
            } else {
                Text("All properties are in good standing with local regulations.")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.success)
            }
        }
    }
}

struct ClientCoverageDetailView: View {
    typealias ClientIntelligence = CoreTypes.ClientPortfolioIntelligence
    
    let intelligence: ClientIntelligence
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            HStack {
                Text("Service Coverage")
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Text("\(Int(intelligence.coveragePercentage))%")
                    .francoTypography(FrancoSphereDesign.Typography.title)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            
            FrancoMetricsProgress(
                value: intelligence.coveragePercentage / 100.0,
                role: .client
            )
            
            Text("Coverage indicates the percentage of scheduled services completed on time across all properties.")
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                .multilineTextAlignment(.leading)
        }
    }
}

struct ClientCostDetailView: View {
    typealias ClientIntelligence = CoreTypes.ClientPortfolioIntelligence
    
    let intelligence: ClientIntelligence
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Monthly Spend")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text(formatCurrency(intelligence.monthlySpend))
                        .francoTypography(FrancoSphereDesign.Typography.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Budget")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text(formatCurrency(intelligence.monthlyBudget))
                        .francoTypography(FrancoSphereDesign.Typography.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
            }
            
            // Budget utilization
            let utilization = intelligence.monthlySpend / intelligence.monthlyBudget
            HStack {
                Text("Budget Utilization: \(Int(utilization * 100))%")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Text(budgetStatus)
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(budgetStatusColor)
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private var budgetStatus: String {
        let utilization = intelligence.monthlySpend / intelligence.monthlyBudget
        if utilization > 1.0 { return "Over Budget" }
        if utilization > 0.9 { return "Near Budget" }
        return "On Track"
    }
    
    private var budgetStatusColor: Color {
        let utilization = intelligence.monthlySpend / intelligence.monthlyBudget
        if utilization > 1.0 { return FrancoSphereDesign.DashboardColors.critical }
        if utilization > 0.9 { return FrancoSphereDesign.DashboardColors.warning }
        return FrancoSphereDesign.DashboardColors.success
    }
}

// MARK: - Metric Types

enum ClientMetricType: String, CaseIterable {
    case service = "Service"
    case compliance = "Compliance"
    case coverage = "Coverage"
    case cost = "Cost"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .service: return "star"
        case .compliance: return "checkmark.shield"
        case .coverage: return "mappin.circle"
        case .cost: return "dollarsign.circle"
        }
    }
    
    var darkThemeColor: Color {
        switch self {
        case .service: return FrancoSphereDesign.DashboardColors.tertiaryAction
        case .compliance: return FrancoSphereDesign.DashboardColors.success
        case .coverage: return FrancoSphereDesign.DashboardColors.info
        case .cost: return FrancoSphereDesign.DashboardColors.warning
        }
    }
}

// MARK: - Preview

struct ClientPortfolioOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        ClientPortfolioOverviewView(
            clientIntelligence: CoreTypes.ClientPortfolioIntelligence(
                totalProperties: 3,
                serviceLevel: 0.92,
                complianceScore: 88,
                complianceIssues: 1,
                monthlyTrend: .stable,
                coveragePercentage: 95,
                monthlySpend: 15000,
                monthlyBudget: 18000,
                showCostData: true
            )
        )
        .preferredColorScheme(.dark)
    }
}
