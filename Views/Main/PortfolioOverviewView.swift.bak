//
//  PortfolioOverviewView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  PortfolioOverviewView.swift
//  FrancoSphere
//
//  🎯 PHASE 4: PORTFOLIO OVERVIEW COMPONENT
//  ✅ High-level portfolio metrics display
//  ✅ Performance trends and key indicators  
//  ✅ Quick action dashboard for executives
//  ✅ Real-time portfolio health monitoring
//

import SwiftUI

struct PortfolioOverviewView: View {
    let intelligence: PortfolioIntelligence
    let onBuildingTap: ((NamedCoordinate) -> Void)?
    let onRefresh: (() async -> Void)?
    
    @State private var selectedMetric: MetricType = .efficiency
    @State private var showingDetailView = false
    @State private var isRefreshing = false
    
    init(intelligence: PortfolioIntelligence, 
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
                
                // Top Performing Buildings
                topPerformingSection
                
                // Alert Buildings (if any)
                if !intelligence.alertBuildings.isEmpty {
                    alertBuildingsSection
                }
                
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
                    title: "Avg Efficiency",
                    value: "\(Int(intelligence.averageEfficiency * 100))%",
                    icon: "speedometer",
                    color: efficiencyColor,
                    trend: efficiencyTrend
                )
                
                SummaryCard(
                    title: "Completed Tasks",
                    value: "\(intelligence.completedTasks)",
                    icon: "checkmark.circle",
                    color: .green,
                    trend: nil
                )
                
                SummaryCard(
                    title: "Overdue Tasks",
                    value: "\(intelligence.overdueTasks)",
                    icon: "exclamationmark.triangle",
                    color: intelligence.overdueTasks > 0 ? .red : .gray,
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
                                withAnimation(.easeInOut(duration: 0.3)) {
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
    
    // MARK: - Top Performing Section
    
    private var topPerformingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performing Buildings")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(intelligence.topPerformingBuildings, id: \.id) { building in
                TopPerformingBuildingRow(
                    building: building,
                    onTap: { onBuildingTap?(building) }
                )
            }
        }
    }
    
    // MARK: - Alert Buildings Section
    
    private var alertBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                
                Text("Buildings Requiring Attention")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            ForEach(intelligence.alertBuildings, id: \.id) { building in
                AlertBuildingRow(
                    building: building,
                    onTap: { onBuildingTap?(building) }
                )
            }
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Last Updated Section
    
    private var lastUpdatedSection: some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Last updated \(formattedUpdateTime)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var efficiencyColor: Color {
        if intelligence.averageEfficiency >= 0.9 { return .green }
        if intelligence.averageEfficiency >= 0.8 { return .blue }
        if intelligence.averageEfficiency >= 0.7 { return .orange }
        return .red
    }
    
    private var efficiencyTrend: TrendDirection {
        // Placeholder - in real implementation would compare with historical data
        if intelligence.averageEfficiency >= 0.85 { return .up }
        if intelligence.averageEfficiency < 0.7 { return .down }
        return .neutral
    }
    
    private var formattedUpdateTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: intelligence.lastUpdated, relativeTo: Date())
    }
}

// MARK: - Supporting Components

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
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

struct TopPerformingBuildingRow: View {
    let building: NamedCoordinate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: building.imageAssetName)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("High Performance")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AlertBuildingRow: View {
    let building: NamedCoordinate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: building.imageAssetName)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Requires Attention")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Metric Detail Views

struct EfficiencyDetailView: View {
    let intelligence: PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Portfolio Efficiency")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(intelligence.averageEfficiency * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: intelligence.averageEfficiency)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("Target: 85%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(intelligence.averageEfficiency >= 0.85 ? "Above Target" : "Below Target")
                    .font(.caption)
                    .foregroundColor(intelligence.averageEfficiency >= 0.85 ? .green : .orange)
            }
        }
    }
}

struct TasksDetailView: View {
    let intelligence: PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Completion Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(intelligence.completionRate * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(intelligence.totalTasks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                Label("\(intelligence.completedTasks) Completed", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                if intelligence.overdueTasks > 0 {
                    Label("\(intelligence.overdueTasks) Overdue", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct PerformanceDetailView: View {
    let intelligence: PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Performance is calculated based on task completion rates, efficiency metrics, and compliance scores across your portfolio.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            HStack {
                PerformanceMetricItem(
                    title: "Efficiency",
                    value: "\(Int(intelligence.averageEfficiency * 100))%",
                    color: intelligence.averageEfficiency >= 0.8 ? .green : .orange
                )
                
                Spacer()
                
                PerformanceMetricItem(
                    title: "Buildings",
                    value: "\(intelligence.totalBuildings)",
                    color: .blue
                )
            }
        }
    }
}

struct AlertsDetailView: View {
    let intelligence: PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            if intelligence.alertBuildings.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    
                    Text("No buildings require immediate attention")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(intelligence.alertBuildings.count) buildings need attention")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    if intelligence.overdueTasks > 0 {
                        Text("\(intelligence.overdueTasks) overdue tasks across portfolio")
                            .font(.caption)
                            .foregroundColor(.red)
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
            intelligence: PortfolioIntelligence(
                totalBuildings: 12,
                totalTasks: 156,
                completedTasks: 132,
                overdueTasks: 8,
                averageEfficiency: 0.87,
                topPerformingBuildings: [],
                alertBuildings: [],
                lastUpdated: Date()
            )
        )
        .preferredColorScheme(.dark)
    }
}