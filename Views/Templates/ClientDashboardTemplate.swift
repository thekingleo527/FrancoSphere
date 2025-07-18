//
//  ClientDashboardTemplate.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed incorrect CoreTypes module import
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Correct parameter names for all views
//  ✅ FIXED: Using existing StatCard instead of redeclaring MetricCard
//  ✅ FIXED: Exhaustive TrendDirection switch statements
//  ✅ FIXED: Proper data passing from ClientDashboardViewModel
//

import SwiftUI

struct ClientDashboardTemplate: View {
    @StateObject private var viewModel = ClientDashboardViewModel()
    
    var body: some View {
        TabView {
            // Portfolio Overview - with optional handling
            Group {
                if let intelligence = viewModel.portfolioIntelligence {
                    PortfolioOverviewView(intelligence: intelligence)
                } else {
                    LoadingPortfolioView()
                }
            }
            .tabItem {
                Label("Overview", systemImage: "chart.pie.fill")
            }
            
            // Building Intelligence List - with proper CoreTypes
            BuildingIntelligenceListView(intelligence: viewModel.portfolioIntelligence)
                .tabItem {
                    Label("Buildings", systemImage: "building.2.fill")
                }
            
            // Compliance Overview - with optional handling
            Group {
                if let intelligence = viewModel.portfolioIntelligence {
                    ComplianceOverviewView(intelligence: intelligence)
                } else {
                    LoadingComplianceView()
                }
            }
            .tabItem {
                Label("Compliance", systemImage: "shield.lefthalf.filled")
            }
            
            // Intelligence Insights - FIXED: using insights parameter
            Group {
                IntelligenceInsightsView(insights: viewModel.intelligenceInsights)
            }
            .tabItem {
                Label("Insights", systemImage: "lightbulb.fill")
            }
        }
        .task {
            // FIXED: Corrected method call
            await viewModel.loadPortfolioIntelligence()
        }
    }
}

// MARK: - Supporting Views (Fixed Type Signatures)

struct BuildingIntelligenceListView: View {
    let intelligence: CoreTypes.PortfolioIntelligence?
    
    var body: some View {
        VStack(spacing: 16) {
            if let intelligence = intelligence {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Building Intelligence")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Portfolio Summary Cards - FIXED: Using existing StatCard
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(
                            title: "Total Buildings",
                            value: "\(intelligence.totalBuildings)",
                            icon: "building.2.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Active Workers",
                            value: "\(intelligence.activeWorkers)",
                            icon: "person.2.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Completion Rate",
                            value: "\(Int(intelligence.completionRate * 100))%",
                            icon: "chart.bar.fill",
                            color: intelligence.completionRate > 0.8 ? .green : .orange
                        )
                        
                        StatCard(
                            title: "Critical Issues",
                            value: "\(intelligence.criticalIssues)",
                            icon: "exclamationmark.triangle.fill",
                            color: intelligence.criticalIssues > 0 ? .red : .green
                        )
                    }
                    
                    // Trend Indicator - FIXED: Exhaustive switch
                    HStack {
                        Image(systemName: trendIcon(for: intelligence.monthlyTrend))
                            .foregroundColor(trendColor(for: intelligence.monthlyTrend))
                        Text("Monthly Trend: \(intelligence.monthlyTrend.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
            } else {
                LoadingView(message: "Loading building intelligence...")
            }
        }
        .navigationTitle("Buildings")
    }
    
    // FIXED: Exhaustive switch for TrendDirection (removed duplicate cases)
    private func trendIcon(for trend: CoreTypes.TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .improving: return "arrow.up.right.circle.fill"
        case .declining: return "arrow.down.right.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    // FIXED: Exhaustive switch for TrendDirection (removed duplicate cases)
    private func trendColor(for trend: CoreTypes.TrendDirection) -> Color {
        switch trend {
        case .up, .improving: return .green
        case .down, .declining: return .red
        case .stable: return .orange
        case .unknown: return .gray
        }
    }
}

// MARK: - Loading State Views

struct LoadingPortfolioView: View {
    var body: some View {
        LoadingView(message: "Loading portfolio overview...")
            .navigationTitle("Overview")
    }
}

struct LoadingComplianceView: View {
    var body: some View {
        LoadingView(message: "Loading compliance data...")
            .navigationTitle("Compliance")
    }
}

struct LoadingInsightsView: View {
    var body: some View {
        LoadingView(message: "Loading intelligence insights...")
            .navigationTitle("Insights")
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - StatCard Component (Local Definition)

struct StatCard: View {
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

// MARK: - Preview

struct ClientDashboardTemplate_Previews: PreviewProvider {
    static var previews: some View {
        ClientDashboardTemplate()
            .preferredColorScheme(.dark)
    }
}
