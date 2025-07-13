//
//  IntelligenceInsightsView.swift
//  FrancoSphere
//
//  🎯 PHASE 4: INTELLIGENCE INSIGHTS COMPONENT
//  ✅ AI-powered insights and recommendations
//  ✅ Actionable intelligence for decision-making
//  ✅ Performance optimization suggestions
//  ✅ Predictive maintenance alerts
//

import SwiftUI

struct IntelligenceInsightsView: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let onInsightAction: ((CoreTypes.IntelligenceInsight) -> Void)?
    let onRefreshInsights: (() async -> Void)?
    
    @State private var selectedFilter: LocalInsightFilter = .all
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    @State private var showingDetailSheet = false
    @State private var showingActionSheet = false
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
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Cards
                    insightsSummaryCards
                    
                    // Filter Section
                    filterSection
                    
                    // Insights List
                    insightsList
                }
                .padding()
            }
            .navigationTitle("Intelligence Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshInsights) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
            }
            .sheet(isPresented: $showingDetailSheet) {
                if let insight = selectedInsight {
                    InsightDetailSheet(
                        insight: insight,
                        onAction: onInsightAction,
                        isPresented: $showingDetailSheet
                    )
                }
            }
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Summary Cards
    
    private var insightsSummaryCards: some View {
        HStack {
            SummaryInsightCard(
                title: "Total Insights",
                value: "\(filteredInsights.count)",
                icon: "lightbulb",
                color: .blue
            )
            
            Spacer()
            
            SummaryInsightCard(
                title: "High Priority",
                value: "\(highPriorityCount)",
                icon: "exclamationmark.triangle",
                color: .red
            )
            
            Spacer()
            
            SummaryInsightCard(
                title: "Actionable",
                value: "\(actionableCount)",
                icon: "hand.tap",
                color: .green
            )
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LocalInsightFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getFilterCount(filter),
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Insights List
    
    private var insightsList: some View {
        Group {
            if filteredInsights.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredInsights, id: \.id) { insight in
                        InsightCard(
                            insight: insight,
                            onTap: {
                                selectedInsight = insight
                                showingDetailSheet = true
                            },
                            onAction: {
                                if let onInsightAction = onInsightAction {
                                    onInsightAction(insight)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: selectedFilter.emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(selectedFilter.emptyStateTitle)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(selectedFilter.emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if selectedFilter != .all {
                Button("Show All Insights") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = .all
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var filteredInsights: [CoreTypes.IntelligenceInsight] {
        switch selectedFilter {
        case .all:
            return insights.sorted(by: { $0.priority.priorityValue > $1.priority.priorityValue })
        case .priority:
            return insights.filter { $0.priority == .high || $0.priority == .critical }
                          .sorted(by: { $0.priority.priorityValue > $1.priority.priorityValue })
        case .actionable:
            return insights.filter { $0.actionRequired }
                          .sorted(by: { $0.priority.priorityValue > $1.priority.priorityValue })
        case .type(let type):
            return insights.filter { $0.type == type }
                          .sorted(by: { $0.priority.priorityValue > $1.priority.priorityValue })
        }
    }
    
    private var highPriorityCount: Int {
        insights.filter { $0.priority == .high || $0.priority == .critical }.count
    }
    
    private var actionableCount: Int {
        insights.filter { $0.actionRequired }.count
    }
    
    private func getFilterCount(_ filter: LocalInsightFilter) -> Int {
        switch filter {
        case .all:
            return insights.count
        case .priority:
            return highPriorityCount
        case .actionable:
            return actionableCount
        case .type(let type):
            return insights.filter { $0.type == type }.count
        }
    }
    
    // MARK: - Actions
    
    private func refreshInsights() {
        guard let onRefreshInsights = onRefreshInsights else { return }
        
        Task {
            isRefreshing = true
            await onRefreshInsights()
            isRefreshing = false
        }
    }
}

// MARK: - Supporting Components

struct SummaryInsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
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

struct FilterButton: View {
    let filter: LocalInsightFilter
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.3))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? filter.color : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightCard: View {
    let insight: CoreTypes.IntelligenceInsight
    let onTap: () -> Void
    let onAction: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: insight.type.icon)
                    .font(.title2)
                    .foregroundColor(insight.type.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(insight.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(isExpanded ? nil : 2)
                        
                        Spacer()
                        
                        PriorityBadge(priority: insight.priority)
                    }
                    
                    Text(insight.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(isExpanded ? nil : 3)
                .multilineTextAlignment(.leading)
            
            // Expand/Collapse Button
            if insight.description.count > 100 {
                Button(isExpanded ? "Show Less" : "Show More") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Recent")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if insight.actionRequired {
                    Button("Take Action") {
                        onAction()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Button(action: onTap) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insight.priority == .high || insight.priority == .critical ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct PriorityBadge: View {
    let priority: CoreTypes.InsightPriority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor, in: Capsule())
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
}

// MARK: - Insight Detail Sheet

struct InsightDetailSheet: View {
    let insight: CoreTypes.IntelligenceInsight
    let onAction: ((CoreTypes.IntelligenceInsight) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingActionConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    insightHeader
                    
                    // Description
                    insightDescription
                    
                    // Details
                    insightDetails
                    
                    // Affected Buildings
                    if !insight.affectedBuildings.isEmpty {
                        affectedBuildingsSection
                    }
                    
                    // Action Button (if actionable)
                    if insight.actionRequired {
                        actionButton
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .confirmationDialog(
            "Take Action",
            isPresented: $showingActionConfirmation,
            titleVisibility: .visible
        ) {
            Button("Proceed") {
                onAction?(insight)
                isPresented = false
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will initiate the recommended action for this insight.")
        }
    }
    
    private var insightHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: insight.type.icon)
                    .font(.largeTitle)
                    .foregroundColor(insight.type.color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(insight.type.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        PriorityBadge(priority: insight.priority)
                    }
                }
            }
            
            if insight.actionRequired {
                Label("Action Required", systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.1), in: Capsule())
            }
        }
    }
    
    private var insightDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var insightDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                DetailRow(
                    title: "Type",
                    value: insight.type.rawValue,
                    icon: insight.type.icon
                )
                
                DetailRow(
                    title: "Priority",
                    value: insight.priority.rawValue,
                    icon: "flag"
                )
                
                DetailRow(
                    title: "Action Required",
                    value: insight.actionRequired ? "Yes" : "No",
                    icon: "hand.tap"
                )
                
                DetailRow(
                    title: "Buildings Affected",
                    value: "\(insight.affectedBuildings.count)",
                    icon: "building.2"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var affectedBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Affected Buildings")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(insight.affectedBuildings, id: \.self) { buildingId in
                    HStack {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Building \(buildingId)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var actionButton: some View {
        Button("Take Action") {
            showingActionConfirmation = true
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Extensions for Missing Properties

extension CoreTypes.InsightType {
    var icon: String {
        switch self {
        case .performance: return "chart.line.uptrend.xyaxis"
        case .maintenance: return "wrench.and.screwdriver"
        case .compliance: return "checkmark.shield"
        case .efficiency: return "speedometer"
        case .cost: return "dollarsign.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .performance: return .blue
        case .maintenance: return .orange
        case .compliance: return .green
        case .efficiency: return .purple
        case .cost: return .yellow
        }
    }
}

// MARK: - Local Filter Types (to avoid conflicts with CoreTypes)

enum LocalInsightFilter: Hashable, CaseIterable {
    case all
    case priority
    case actionable
    case type(CoreTypes.InsightType)
    
    static var allCases: [LocalInsightFilter] {
        var cases: [LocalInsightFilter] = [.all, .priority, .actionable]
        cases.append(contentsOf: CoreTypes.InsightType.allCases.map { .type($0) })
        return cases
    }
    
    var title: String {
        switch self {
        case .all: return "All"
        case .priority: return "High Priority"
        case .actionable: return "Action Required"
        case .type(let type): return type.rawValue
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .priority: return "exclamationmark.triangle"
        case .actionable: return "hand.tap"
        case .type(let type): return type.icon
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .priority: return .red
        case .actionable: return .orange
        case .type(let type): return type.color
        }
    }
    
    var emptyStateIcon: String {
        switch self {
        case .all: return "lightbulb"
        case .priority: return "exclamationmark.triangle"
        case .actionable: return "hand.tap"
        case .type(let type): return type.icon
        }
    }
    
    var emptyStateTitle: String {
        switch self {
        case .all: return "No Insights Available"
        case .priority: return "No High Priority Insights"
        case .actionable: return "No Action Required"
        case .type(let type): return "No \(type.rawValue) Insights"
        }
    }
    
    var emptyStateMessage: String {
        switch self {
        case .all: return "Intelligence insights will appear here as they become available."
        case .priority: return "No high priority insights require immediate attention."
        case .actionable: return "No insights currently require action."
        case .type(let type): return "No \(type.rawValue.lowercased()) insights are available at this time."
        }
    }
}

// MARK: - Preview

struct IntelligenceInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        IntelligenceInsightsView(
            insights: [
                CoreTypes.IntelligenceInsight(
                    title: "High Portfolio Efficiency",
                    description: "8 out of 12 buildings are performing at >90% efficiency across all key metrics including task completion rates, worker productivity, and maintenance schedules. This represents a significant improvement over the previous quarter.",
                    type: .performance,
                    priority: .medium,
                    actionRequired: false,
                    affectedBuildings: ["14", "15", "16"]
                ),
                CoreTypes.IntelligenceInsight(
                    title: "Maintenance Priority Alert",
                    description: "3 buildings require immediate maintenance attention based on predictive analytics and current task backlogs.",
                    type: .maintenance,
                    priority: .high,
                    actionRequired: true,
                    affectedBuildings: ["12", "18", "20"]
                )
            ]
        )
        .preferredColorScheme(.dark)
    }
}
