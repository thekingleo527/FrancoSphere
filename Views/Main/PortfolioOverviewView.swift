//
//  PortfolioOverviewView.swift
//  FrancoSphere
//
//  ✅ V6.0: FIXED - Updated for CoreTypes architecture
//  ✅ Real-time portfolio metrics display
//  ✅ Performance trends and key indicators
//  ✅ Quick action dashboard for executives
//  ✅ Real-time portfolio health monitoring
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
                
                // Performance Summary (real estate metrics)
                performanceSummarySection
                
                // Alert Summary (status overview)
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
                    title: "Overall Efficiency",
                    value: "\(Int(intelligence.overallEfficiency * 100))%",
                    icon: "speedometer",
                    color: efficiencyColor,
                    trend: intelligence.trendDirection
                )
                
                SummaryCard(
                    title: "Completed Tasks",
                    value: "\(intelligence.totalCompletedTasks)",
                    icon: "checkmark.circle",
                    color: .green,
                    trend: nil
                )
                
                SummaryCard(
                    title: "Active Workers",
                    value: "\(intelligence.totalActiveWorkers)",
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
                                withAnimation(AnimationAnimation.easeInOut(duration: 0.3)) {
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
    
    // MARK: - Performance Summary Section (FIXED: Simplified)
    
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
                    
                    Text("\(Int(intelligence.averageComplianceScore * 100))%")
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
                        Image(systemName: intelligence.trendDirection.icon)
                            .font(.caption)
                            .foregroundColor(intelligence.trendDirection.color)
                        
                        Text(intelligence.trendDirection.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(intelligence.trendDirection.color)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    // MARK: - Alert Summary Section (FIXED: Simplified)
    
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
                    value: "\(intelligence.totalActiveWorkers)",
                    icon: "person.2",
                    color: .purple
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
            
            Text("Last updated just now")  // FIXED: Simplified since we don't have lastUpdated
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var efficiencyColor: Color {
        if intelligence.overallEfficiency >= 0.9 { return .green }
        if intelligence.overallEfficiency >= 0.8 { return .blue }
        if intelligence.overallEfficiency >= 0.7 { return .orange }
        return .red
    }
    
    private var complianceColor: Color {
        if intelligence.averageComplianceScore >= 0.9 { return .green }
        if intelligence.averageComplianceScore >= 0.8 { return .blue }
        if intelligence.averageComplianceScore >= 0.7 { return .orange }
        return .red
    }
    
    private var healthStatus: String {
        let efficiency = intelligence.overallEfficiency
        let compliance = intelligence.averageComplianceScore
        let average = (efficiency + compliance) / 2
        
        if average >= 0.9 { return "Excellent" }
        if average >= 0.8 { return "Good" }
        if average >= 0.7 { return "Fair" }
        return "Needs Attention"
    }
    
    private var healthIcon: String {
        let efficiency = intelligence.overallEfficiency
        let compliance = intelligence.averageComplianceScore
        let average = (efficiency + compliance) / 2
        
        if average >= 0.9 { return "checkmark.circle.fill" }
        if average >= 0.8 { return "checkmark.circle" }
        if average >= 0.7 { return "exclamationmark.circle" }
        return "exclamationmark.triangle.fill"
    }
    
    private var healthColor: Color {
        let efficiency = intelligence.overallEfficiency
        let compliance = intelligence.averageComplianceScore
        let average = (efficiency + compliance) / 2
        
        if average >= 0.9 { return .green }
        if average >= 0.8 { return .blue }
        if average >= 0.7 { return .orange }
        return .red
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
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
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

// MARK: - Metric Detail Views

struct EfficiencyDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Portfolio Efficiency")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(intelligence.overallEfficiency * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: intelligence.overallEfficiency)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("Target: 85%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(intelligence.overallEfficiency >= 0.85 ? "Above Target" : "Below Target")
                    .font(.caption)
                    .foregroundColor(intelligence.overallEfficiency >= 0.85 ? .green : .orange)
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
                    
                    Text("\(intelligence.totalCompletedTasks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Compliance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(intelligence.averageComplianceScore * 100))%")
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
                
                Label("Active Workers: \(intelligence.totalActiveWorkers)", systemImage: "person.2")
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
            Text("Performance is calculated based on efficiency metrics, compliance scores, and worker productivity across your portfolio.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            HStack {
                PerformanceMetricItem(
                    title: "Efficiency",
                    value: "\(Int(intelligence.overallEfficiency * 100))%",
                    color: intelligence.overallEfficiency >= 0.8 ? .green : .orange
                )
                
                Spacer()
                
                PerformanceMetricItem(
                    title: "Compliance",
                    value: "\(Int(intelligence.averageComplianceScore * 100))%",
                    color: intelligence.averageComplianceScore >= 0.8 ? .green : .orange
                )
            }
        }
    }
}

struct AlertsDetailView: View {
    let intelligence: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            let overallHealth = (intelligence.overallEfficiency + intelligence.averageComplianceScore) / 2
            
            if overallHealth >= 0.8 {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    
                    Text("Portfolio performing well")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance below target")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    if intelligence.overallEfficiency < 0.8 {
                        Text("Efficiency needs improvement")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if intelligence.averageComplianceScore < 0.8 {
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
                totalCompletedTasks: 132,
                averageComplianceScore: 0.92,
                totalActiveWorkers: 24,
                overallEfficiency: 0.87,
                trendDirection: CoreTypes.TrendDirection.up
            )
        )
        .preferredColorScheme(ColorScheme.dark)
    }
}
