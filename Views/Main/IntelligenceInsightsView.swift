//
//  IntelligenceInsightsView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ NOVA: AI integration with AIAssistant.png
//  ✅ ALIGNED: With CoreTypes.InsightPriority structure
//  ✅ ENHANCED: Single clean implementation
//

import SwiftUI

struct IntelligenceInsightsView: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let onInsightAction: ((CoreTypes.IntelligenceInsight) -> Void)?
    let onRefreshInsights: (() async -> Void)?
    
    // Nova AI integration
    @StateObject private var novaCore = NovaCore.shared
    @State private var showNovaAssistant = false
    @State private var novaHasNewInsights = false
    
    @State private var selectedFilter: InsightFilterType = .all
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    @State private var showingDetailSheet = false
    @State private var isRefreshing = false
    
    init(insights: [CoreTypes.IntelligenceInsight],
         onInsightAction: ((CoreTypes.IntelligenceInsight) -> Void)? = nil,
         onRefreshInsights: (() async -> Void)? = nil) {
        self.insights = insights
        self.onInsightAction = onInsightAction
        self.onRefreshInsights = onRefreshInsights
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Nova AI integration
                headerSection
                
                // Filter controls
                filterSection
                
                // Insights list
                insightsList
            }
            .navigationTitle("Intelligence Insights")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshInsights()
            }
            .sheet(isPresented: $showNovaAssistant) {
                NovaAssistantView()
            }
            .sheet(item: $selectedInsight) { insight in
                InsightDetailView(insight: insight, onAction: onInsightAction)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI-Powered Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(filteredInsights.count) insights available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Nova AI Assistant Button
                Button(action: {
                    showNovaAssistant = true
                }) {
                    HStack(spacing: 8) {
                        Image("AIAssistant")
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        Text("Nova AI")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.1),
                                Color.purple.opacity(0.1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(novaHasNewInsights ? Color.green : Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .overlay(
                    // New insights indicator
                    novaHasNewInsights ?
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .offset(x: 15, y: -10)
                    : nil
                )
            }
            .padding(.horizontal)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightFilterType.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Text(filter.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedFilter == filter ?
                                Color.blue : Color(.systemGray6)
                            )
                            .foregroundColor(
                                selectedFilter == filter ?
                                .white : .primary
                            )
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var insightsList: some View {
        List {
            ForEach(filteredInsights) { insight in
                InsightRowView(insight: insight) {
                    selectedInsight = insight
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredInsights: [CoreTypes.IntelligenceInsight] {
        switch selectedFilter {
        case .all:
            return insights
        case .critical:
            return insights.filter { $0.priority == .critical }
        case .high:
            return insights.filter { $0.priority == .high }
        case .actionable:
            return insights.filter { $0.actionable }
        case .recent:
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return insights.filter { $0.createdAt > cutoffDate }
        }
    }
    
    private func refreshInsights() async {
        isRefreshing = true
        await onRefreshInsights?()
        isRefreshing = false
    }
}

// MARK: - Supporting Types and Views

enum InsightFilterType: String, CaseIterable {
    case all = "all"
    case critical = "critical"
    case high = "high"
    case actionable = "actionable"
    case recent = "recent"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .critical: return "Critical"
        case .high: return "High Priority"
        case .actionable: return "Actionable"
        case .recent: return "Recent"
        }
    }
}

struct InsightRowView: View {
    let insight: CoreTypes.IntelligenceInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(insight.title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    insight.priority.color
                        .frame(width: 8, height: 8)
                        .clipShape(Circle())
                }
                
                Text(insight.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Label(insight.category.displayName, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(insight.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightDetailView: View {
    let insight: CoreTypes.IntelligenceInsight
    let onAction: ((CoreTypes.IntelligenceInsight) -> Void)?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(insight.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            insight.priority.color
                                .frame(width: 12, height: 12)
                                .clipShape(Circle())
                            
                            Text(insight.priority.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("Confidence: \(Int(insight.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(insight.description)
                            .font(.body)
                        
                        if !insight.estimatedImpact.isEmpty {
                            Text("Estimated Impact")
                                .font(.headline)
                            
                            Text(insight.estimatedImpact)
                                .font(.body)
                        }
                        
                        Text("Details")
                            .font(.headline)
                        
                        InfoRow(label: "Category", value: insight.category.displayName)
                        InfoRow(label: "Source", value: insight.source.displayName)
                        InfoRow(label: "Created", value: insight.createdAt.formatted())
                        InfoRow(label: "Buildings", value: "\(insight.buildingIds.count)")
                        
                        if insight.actionable {
                            Button(action: {
                                onAction?(insight)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Take Action")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct NovaAssistantView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Image("AIAssistant")
                    .resizable()
                    .frame(width: 100, height: 100)
                
                Text("Nova AI Assistant")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("AI-powered insights and recommendations for your portfolio")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Nova AI")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Preview
struct IntelligenceInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        IntelligenceInsightsView(
            insights: [
                CoreTypes.IntelligenceInsight(
                    id: "1",
                    title: "Energy Efficiency Opportunity",
                    description: "HVAC optimization could reduce energy costs by 15%",
                    priority: .high,
                    category: .efficiency,
                    source: .ai,
                    confidence: 0.85,
                    buildingIds: ["1", "2"],
                    estimatedImpact: "15% reduction in energy costs"
                )
            ]
        )
    }
}
