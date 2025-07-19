//
//  PortfolioOverviewView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed incorrect CoreTypes module import
//  ✅ FIXED: All property references updated to match actual CoreTypes.PortfolioIntelligence structure
//  ✅ ALIGNED: With actual CoreTypes properties (no overallEfficiency, averageComplianceScore, etc.)
//  ✅ SIMPLIFIED: Uses available properties and calculates derived metrics
//

import SwiftUI

struct PortfolioOverviewView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    let onBuildingTap: ((NamedCoordinate) -> Void)?
    let onRefresh: (() async -> Void)?
    
    @State private var selectedMetric: MetricType = .efficiency
    @State private var showingDetailView = false
    @State private var isRefreshing = false
    
    init(intelligence: CoreTypes.PortfolioIntelligence,
         onBuildingTap: ((NamedCoordinate) -> Void)? = nil,
         onRefresh: (() async -> Void)? = nil) {
        self.intelligence = intelligence
        self.onBuildingTap = onBuildingTap
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Portfolio Summary Cards
                portfolioSummarySection
                
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
            .padding()
        }
        .refreshable {
            if let onRefresh = onRefresh {
                isRefreshing = true
                await onRefresh()
                isRefreshing = false
            }
        }
        .overlay(
            isRefreshing ? ProgressView("Refreshing...") : nil
        )
    }
    
    // MARK: - Portfolio Summary Section
    
    private var portfolioSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio Overview")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SummaryCard(
                    title: "Total Buildings",
                    value: "\(intelligence.totalBuildings)",
                    icon: "building.2",
                    color: .blue,
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
                    color: .green,
                    trend: nil
                )
                
                SummaryCard(
                    title: "Active Workers",
                    value: "\(intelligence.activeWorkers)",
                    icon: "person.2",
                    color: .purple,
                    trend: nil
                )
            }
        }
    }
    
    // MARK: - Metric Selector Section
    
    private var metricSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        MetricSelectorButton(
                            metric: metric,
                            isSelected: selectedMetric == metric,
                            onTap: {
                                withAnimation(Animation.easeInOut(duration: 0.3)) {
                                    selectedMetric = metric
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Selected Metric Detail Section
    
    private var selectedMetricDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: selectedMetric.icon)
                    .font(.title2)
                    .foregroundColor(selectedMetric.color)
                
                Text(selectedMetric.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Performance Summary Section
    
    private var performanceSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Summary")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compliance Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(intelligence.complianceScore)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(complianceColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon(for: intelligence.monthlyTrend))
                            .font(.caption)
                            .foregroundColor(trendColor(for: intelligence.monthlyTrend))
                        
                        Text(intelligence.monthlyTrend.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(trendColor(for: intelligence.monthlyTrend))
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    // MARK: - Alert Summary Section
    
    private var alertSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                
                Text("Portfolio Status")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 8) {
                StatusRow(
                    title: "Buildings Monitored",
                    value: "\(intelligence.totalBuildings)",
                    icon: "building.2",
                    color: .blue
                )
                
                StatusRow(
                    title: "Active Workers",
                    value: "\(intelligence.activeWorkers)",
                    icon: "person.2",
                    color: .purple
                )
                
                StatusRow(
                    title: "Critical Issues",
                    value: "\(intelligence.criticalIssues)",
                    icon: "exclamationmark.triangle",
                    color: intelligence.criticalIssues > 0 ? .red : .green
                )
                
                StatusRow(
                    title: "Overall Health",
                    value: healthStatus,
                    icon: healthIcon,
                    color: healthColor
                )
            }
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Last Updated Section
    
    private var lastUpdatedSection: some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Last updated just now")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties (FIXED to use actual CoreTypes properties)
    
    private var efficiencyColor: Color {
        if intelligence.completionRate >= 0.9 { return .green }
        if intelligence.completionRate >= 0.8 { return .blue }
        if intelligence.completionRate >= 0.7 { return .orange }
        return .red
    }
    
    private var complianceColor: Color {
        let score = Double(intelligence.complianceScore) / 100.0
        if score >= 0.9 { return .green }
        if score >= 0.8 { return .blue }
        if score >= 0.7 { return .orange }
        return .red
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
        
        if average >= 0.9 { return .green }
        if average >= 0.8 { return .blue }
        if average >= 0.7 { return .orange }
        return .red
    }
    
    // MARK: - Helper Functions
    
    private func trendIcon(for trend: CoreTypes.TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.circle"
        case .down: return "arrow.down.circle"
        case .stable: return "minus.circle"
        case .improving: return "arrow.up.right.circle"
        case .declining: return "arrow.down.right.circle"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private func trendColor(for trend: CoreTypes.TrendDirection) -> Color {
        switch trend {
        case .up, .improving: return .green
        case .down, .declining: return .red
        case .stable: return .orange
        case .unknown: return .gray
        }
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
        VStack(alignment: .leading, spacing: 8) {
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
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
        switch trend {
        case .up, .improving: return .green
        case .down, .declining: return .red
        case .stable: return .orange
        case .unknown: return .gray
        }
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
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? metric.color : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
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
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Metric Detail Views (FIXED to use actual properties)

struct EfficiencyDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Portfolio Efficiency")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(intelligence.completionRate * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: intelligence.completionRate)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("Target: 85%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(intelligence.completionRate >= 0.85 ? "Above Target" : "Below Target")
                    .font(.caption)
                    .foregroundColor(intelligence.completionRate >= 0.85 ? .green : .orange)
            }
        }
    }
}

struct TasksDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Completed Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(intelligence.completedTasks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Compliance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(intelligence.complianceScore)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                Label("Tasks Completed", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Label("Active Workers: \(intelligence.activeWorkers)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
}

struct PerformanceDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Performance is calculated based on completion rates, compliance scores, and worker productivity across your portfolio.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            HStack {
                PerformanceMetricItem(
                    title: "Completion",
                    value: "\(Int(intelligence.completionRate * 100))%",
                    color: intelligence.completionRate >= 0.8 ? .green : .orange
                )
                
                Spacer()
                
                PerformanceMetricItem(
                    title: "Compliance",
                    value: "\(intelligence.complianceScore)%",
                    color: intelligence.complianceScore >= 80 ? .green : .orange
                )
            }
        }
    }
}

struct AlertsDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            let overallHealth = (intelligence.completionRate + Double(intelligence.complianceScore) / 100.0) / 2
            
            if overallHealth >= 0.8 && intelligence.criticalIssues == 0 {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    
                    Text("Portfolio performing well")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if intelligence.criticalIssues > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            
                            Text("\(intelligence.criticalIssues) critical issues require attention")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if intelligence.completionRate < 0.8 {
                        Text("Completion rate needs improvement")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if intelligence.complianceScore < 80 {
                        Text("Compliance requires attention")
                            .font(.caption)
                            .foregroundColor(.orange)
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
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
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
    
    var color: Color {
        switch self {
        case .efficiency: return .blue
        case .tasks: return .green
        case .performance: return .purple
        case .alerts: return .orange
        }
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
