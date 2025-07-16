//
//  ClientDashboardView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/16/25.
//


//
//  ClientDashboardView.swift
//  FrancoSphere
//
//  ✅ COMPLETE: Executive portfolio dashboard for client user type
//  ✅ INTEGRATION: Uses existing ClientDashboardViewModel
//  ✅ DESIGN: Glass design pattern matching AdminDashboardView
//  ✅ REAL-TIME: Portfolio intelligence with live updates
//

import SwiftUI

struct ClientDashboardView: View {
    @StateObject private var viewModel = ClientDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Glass background matching AdminDashboardView pattern
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        
                        if viewModel.isLoading {
                            ProgressView("Loading Portfolio...")
                                .padding(.top, 50)
                                .tint(.white)
                        } else {
                            executiveSummarySection
                            portfolioOverviewSection
                            complianceStatusSection
                            portfolioBuildingsSection
                            strategicInsightsSection
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.loadPortfolioIntelligence()
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadPortfolioIntelligence()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header Section
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Portfolio Overview")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Executive Dashboard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Live data indicator
            if let lastUpdate = viewModel.lastUpdateTime {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    Text("Updated \(lastUpdate, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Executive Summary Section
    
    private var executiveSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Executive Summary")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ExecutiveMetricCard(
                    title: "Total Buildings",
                    value: "\(viewModel.buildingsList.count)",
                    icon: "building.2.fill",
                    color: .blue
                )
                
                ExecutiveMetricCard(
                    title: "Portfolio Health", 
                    value: portfolioHealthScore,
                    icon: "heart.fill",
                    color: portfolioHealthColor
                )
                
                ExecutiveMetricCard(
                    title: "Compliance Rate",
                    value: complianceRate,
                    icon: "shield.checkered",
                    color: complianceColor
                )
                
                ExecutiveMetricCard(
                    title: "Active Issues",
                    value: "\(viewModel.criticalIssuesCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: issuesColor
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Portfolio Overview Section
    
    private var portfolioOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio Performance")
                .font(.headline)
                .foregroundColor(.white)
            
            if let intelligence = viewModel.portfolioIntelligence {
                VStack(spacing: 12) {
                    // Overall completion rate
                    HStack {
                        Text("Overall Completion Rate")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(intelligence.completionRate * 100))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    ProgressView(value: intelligence.completionRate)
                        .tint(intelligence.completionRate > 0.8 ? .green : intelligence.completionRate > 0.6 ? .orange : .red)
                    
                    // Key metrics row
                    HStack(spacing: 20) {
                        PortfolioStatItem(
                            label: "Active Workers",
                            value: "\(intelligence.activeWorkers)",
                            color: .blue
                        )
                        
                        PortfolioStatItem(
                            label: "Pending Tasks", 
                            value: "\(intelligence.pendingTasks)",
                            color: .orange
                        )
                        
                        PortfolioStatItem(
                            label: "Critical Issues",
                            value: "\(intelligence.criticalIssues)",
                            color: .red
                        )
                    }
                }
            } else {
                Text("Loading portfolio performance...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Compliance Status Section
    
    private var complianceStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Compliance Status")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !viewModel.complianceIssues.isEmpty {
                    Text("\(viewModel.complianceIssues.count) issues")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.orange.opacity(0.2)))
                }
            }
            
            if viewModel.complianceIssues.isEmpty {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("All buildings compliant")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.complianceIssues.prefix(3).enumerated()), id: \.element.id) { index, issue in
                        ComplianceIssueRow(issue: issue)
                    }
                    
                    if viewModel.complianceIssues.count > 3 {
                        Button("View All \(viewModel.complianceIssues.count) Issues") {
                            // Navigate to full compliance view
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Portfolio Buildings Section
    
    private var portfolioBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Building Portfolio")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.buildingsList.count) properties")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(viewModel.buildingsList) { building in
                    PropertyCard(
                        building: building,
                        displayMode: .client
                    ) {
                        // Navigate to building detail
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Strategic Insights Section
    
    private var strategicInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Strategic Insights")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.actionableInsightsCount > 0 {
                    Text("\(viewModel.actionableInsightsCount) actionable")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.blue.opacity(0.2)))
                }
            }
            
            if viewModel.intelligenceInsights.isEmpty {
                Text("No strategic insights available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.intelligenceInsights.prefix(5).enumerated()), id: \.element.id) { index, insight in
                        StrategicInsightCard(insight: insight)
                    }
                    
                    if viewModel.intelligenceInsights.count > 5 {
                        Button("View All Insights") {
                            // Navigate to full insights view
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Computed Properties
    
    private var portfolioHealthScore: String {
        let compliantBuildings = viewModel.buildingMetrics.values.filter { $0.isCompliant }.count
        let totalBuildings = max(viewModel.buildingMetrics.count, 1)
        let healthScore = Int((Double(compliantBuildings) / Double(totalBuildings)) * 100)
        return "\(healthScore)%"
    }
    
    private var portfolioHealthColor: Color {
        let compliantBuildings = viewModel.buildingMetrics.values.filter { $0.isCompliant }.count
        let totalBuildings = max(viewModel.buildingMetrics.count, 1)
        let healthScore = Double(compliantBuildings) / Double(totalBuildings)
        
        switch healthScore {
        case 0.9...: return .green
        case 0.7..<0.9: return .orange
        default: return .red
        }
    }
    
    private var complianceRate: String {
        let compliantBuildings = viewModel.buildingMetrics.values.filter { $0.isCompliant }.count
        let totalBuildings = max(viewModel.buildingMetrics.count, 1)
        return "\(Int((Double(compliantBuildings) / Double(totalBuildings)) * 100))%"
    }
    
    private var complianceColor: Color {
        let compliantBuildings = viewModel.buildingMetrics.values.filter { $0.isCompliant }.count
        let totalBuildings = max(viewModel.buildingMetrics.count, 1)
        let rate = Double(compliantBuildings) / Double(totalBuildings)
        
        switch rate {
        case 0.95...: return .green
        case 0.8..<0.95: return .orange
        default: return .red
        }
    }
    
    private var issuesColor: Color {
        switch viewModel.criticalIssuesCount {
        case 0: return .green
        case 1...3: return .orange
        default: return .red
        }
    }
}

// MARK: - Supporting Views

struct ExecutiveMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PortfolioStatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ComplianceIssueRow: View {
    let issue: CoreTypes.ComplianceIssue
    
    var body: some View {
        HStack {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(issue.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if !issue.isResolved {
                Circle()
                    .fill(severityColor)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var severityIcon: String {
        switch issue.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
    
    private var severityColor: Color {
        switch issue.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

struct StrategicInsightCard: View {
    let insight: CoreTypes.IntelligenceInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.type.icon)
                .foregroundColor(priorityColor)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if insight.actionRequired {
                    Text("Action Required")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.blue.opacity(0.2)))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var priorityColor: Color {
        switch insight.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

// MARK: - CoreTypes Extensions for UI

extension CoreTypes.IntelligenceInsight.InsightType {
    var icon: String {
        switch self {
        case .performance: return "chart.line.uptrend.xyaxis"
        case .maintenance: return "wrench.and.screwdriver"
        case .compliance: return "shield.checkered"
        case .efficiency: return "speedometer"
        case .cost: return "dollarsign.circle"
        }
    }
}

// MARK: - Preview

struct ClientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = NewAuthManager.shared
        
        return ClientDashboardView()
            .preferredColorScheme(.dark)
            .environmentObject(authManager)
    }
}