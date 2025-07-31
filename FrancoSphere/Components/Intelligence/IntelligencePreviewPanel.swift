//
//  IntelligencePreviewPanel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Changed .performance to .efficiency
//  ✅ ALIGNED: With actual CoreTypes.IntelligenceInsight structure
//  ✅ ENHANCED: Real-time intelligence display with proper data
//  ✅ COMPATIBLE: Works with existing three-dashboard system
//  ✅ UPDATED: Uses FrancoSphereDesign.EnumColors for all color references
//  ✅ FIXED: Removed invalid @Environment property wrapper.
//

import SwiftUI

struct IntelligencePreviewPanel: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let onInsightTap: ((CoreTypes.IntelligenceInsight) -> Void)?
    let onRefresh: (() async -> Void)?
    
    @State private var isRefreshing = false
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    @State private var showingDetail = false
    
    init(
        insights: [CoreTypes.IntelligenceInsight],
        onInsightTap: ((CoreTypes.IntelligenceInsight) -> Void)? = nil,
        onRefresh: (() async -> Void)? = nil
    ) {
        self.insights = insights
        self.onInsightTap = onInsightTap
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            if insights.isEmpty {
                emptyState
            } else {
                insightMetrics
                insightsList
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
    }
    
    // MARK: - Header with Nova Integration
    
    private var header: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                
                // Assuming AIAssistantImageLoader is defined elsewhere
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.white)
                    .symbolEffect(.pulse.wholeSymbol, isActive: !insights.isEmpty)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Nova Intelligence")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !insights.isEmpty {
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Text("Updated \(Date(), style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let onRefresh = onRefresh {
                Button(action: {
                    Task {
                        isRefreshing = true
                        await onRefresh()
                        isRefreshing = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(.linear(duration: 1).repeatCount(isRefreshing ? .max : 0, autoreverses: false), value: isRefreshing)
                }
                .disabled(isRefreshing)
            }
        }
    }
    
    // MARK: - Metrics Overview
    
    private var insightMetrics: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                metricCard(
                    title: "Total Insights",
                    value: "\(insights.count)",
                    icon: "lightbulb.fill",
                    color: .blue
                )
                
                metricCard(
                    title: "Critical",
                    value: "\(criticalInsightsCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                metricCard(
                    title: "High Priority",
                    value: "\(highPriorityInsightsCount)",
                    icon: "flag.fill",
                    color: .orange
                )
                
                metricCard(
                    title: "Action Required",
                    value: "\(actionableInsightsCount)",
                    icon: "hand.tap.fill",
                    color: .green
                )
            }
            .padding(.horizontal, 1)
        }
    }
    
    // MARK: - Insights List
    
    private var insightsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Latest Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if insights.count > 3 {
                    Text("+\(insights.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(insights.prefix(3)) { insight in
                    InsightRowView(insight: insight) {
                        selectedInsight = insight
                        showingDetail = true
                        onInsightTap?(insight)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("No Intelligence Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Nova is analyzing your building data...")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    // MARK: - Metric Card
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 100)
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var criticalInsightsCount: Int {
        insights.filter { $0.priority == .critical }.count
    }
    
    private var highPriorityInsightsCount: Int {
        insights.filter { $0.priority == .high }.count
    }
    
    private var actionableInsightsCount: Int {
        insights.filter { $0.actionRequired }.count
    }
}

// MARK: - Insight Row View

struct InsightRowView: View {
    let insight: CoreTypes.IntelligenceInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(priorityColor(for: insight.priority))
                    .frame(width: 8, height: 8)
                
                Image(systemName: insight.type.icon)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.EnumColors.insightCategory(insight.type))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(insight.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if insight.actionRequired {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.05))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func priorityColor(for priority: CoreTypes.AIPriority) -> Color {
        FrancoSphereDesign.EnumColors.aiPriority(priority)
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
    let insight: CoreTypes.IntelligenceInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: insight.type.icon)
                                .font(.title2)
                                .foregroundColor(FrancoSphereDesign.EnumColors.insightCategory(insight.type))
                            
                            Text(insight.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(insight.priority.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(priorityColor(for: insight.priority))
                                .cornerRadius(6)
                        }
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(insight.type.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Priority")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(insight.priority.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Action Required")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(insight.actionRequired ? "Yes" : "No")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    if !insight.affectedBuildings.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Affected Buildings")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(insight.affectedBuildings, id: \.self) { buildingId in
                                HStack {
                                    Image(systemName: "building.2")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .frame(width: 20)
                                    
                                    Text("Building ID: \(buildingId)")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Intelligence Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func priorityColor(for priority: CoreTypes.AIPriority) -> Color {
        FrancoSphereDesign.EnumColors.aiPriority(priority)
    }
}

// MARK: - Preview

struct IntelligencePreviewPanel_Previews: PreviewProvider {
    static var previews: some View {
        let sampleInsights: [CoreTypes.IntelligenceInsight] = [
            CoreTypes.IntelligenceInsight(
                title: "High Task Completion Rate",
                description: "Building has maintained 95% task completion rate this week",
                type: .efficiency, // ✅ FIXED: Changed from .performance to .efficiency
                priority: .medium,
                actionRequired: false,
                affectedBuildings: ["14"]
            ),
            CoreTypes.IntelligenceInsight(
                title: "Overdue Maintenance Tasks",
                description: "3 maintenance tasks are overdue and require immediate attention",
                type: .maintenance,
                priority: .critical,
                actionRequired: true,
                affectedBuildings: ["14", "7", "12"]
            )
        ]
        
        VStack(spacing: 20) {
            IntelligencePreviewPanel(insights: sampleInsights)
            
            IntelligencePreviewPanel(insights: [])
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
