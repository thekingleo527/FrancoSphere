//
//  IntelligenceInsightsView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


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
    let insights: [IntelligenceInsight]
    let onInsightAction: ((IntelligenceInsight) -> Void)?
    let onRefreshInsights: (() async -> Void)?
    
    @State private var selectedFilter: InsightFilter = .all
    @State private var selectedInsight: IntelligenceInsight?
    @State private var showingActionSheet = false
    @State private var isRefreshing = false
    
    init(insights: [IntelligenceInsight],
         onInsightAction: ((IntelligenceInsight) -> Void)? = nil,
         onRefreshInsights: (() async -> Void)? = nil) {
        self.insights = insights
        self.onInsightAction = onInsightAction
        self.onRefreshInsights = onRefreshInsights
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Filter Section
            filterSection
            
            // Insights List
            insightsList
        }
        .refreshable {
            if let onRefreshInsights = onRefreshInsights {
                isRefreshing = true
                await onRefreshInsights()
                isRefreshing = false
            }
        }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailSheet(
                insight: insight,
                onAction: onInsightAction
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Intelligence Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(action: {
                        Task {
                            if let onRefreshInsights = onRefreshInsights {
                                isRefreshing = true
                                await onRefreshInsights()
                                isRefreshing = false
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Insights Summary
            insightsSummaryCards
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
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
                ForEach(InsightFilter.allCases, id: \.self) { filter in
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredInsights, id: \.id) { insight in
                            InsightCard(
                                insight: insight,
                                onTap: {
                                    selectedInsight = insight
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
                    selectedFilter = .all
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var filteredInsights: [IntelligenceInsight] {
        switch selectedFilter {
        case .all:
            return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
        case .priority:
            return insights.filter { $0.priority == .high }.sorted { $0.createdAt > $1.createdAt }
        case .actionable:
            return insights.filter { $0.actionable }.sorted { $0.priority.rawValue > $1.priority.rawValue }
        case .type(let type):
            return insights.filter { $0.type == type }.sorted { $0.priority.rawValue > $1.priority.rawValue }
        }
    }
    
    private var highPriorityCount: Int {
        insights.filter { $0.priority == .high }.count
    }
    
    private var actionableCount: Int {
        insights.filter { $0.actionable }.count
    }
    
    private func getFilterCount(_ filter: InsightFilter) -> Int {
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
    let filter: InsightFilter
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
    let insight: IntelligenceInsight
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
                    
                    Text(formattedCreatedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if insight.actionable {
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
                .stroke(insight.priority == .high ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private var formattedCreatedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: insight.createdAt, relativeTo: Date())
    }
}

struct PriorityBadge: View {
    let priority: InsightPriority
    
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
        }
    }
}

// MARK: - Insight Detail Sheet

struct InsightDetailSheet: View {
    let insight: IntelligenceInsight
    let onAction: ((IntelligenceInsight) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingActionConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    insightHeader
                    
                    // Description
                    insightDescription
                    
                    // Details
                    insightDetails
                    
                    // Recommended Actions
                    if insight.actionable {
                        recommendedActions
                    }
                    
                    // Related Insights
                    relatedInsights
                }
                .padding()
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if insight.actionable {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Take Action") {
                            showingActionConfirmation = true
                        }
                        .fontWeight(.medium)
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
                dismiss()
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
            
            if insight.actionable {
                Label("Actionable Insight", systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1), in: Capsule())
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
                    title: "Created",
                    value: formattedFullDate(insight.createdAt),
                    icon: "clock"
                )
                
                DetailRow(
                    title: "Actionable",
                    value: insight.actionable ? "Yes" : "No",
                    icon: insight.actionable ? "checkmark.circle" : "xmark.circle"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var recommendedActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getRecommendedActions(), id: \.self) { action in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(width: 16)
                            .padding(.top, 2)
                        
                        Text(action)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var relatedInsights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Insights")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Similar insights and recommendations will appear here when available.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func formattedFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getRecommendedActions() -> [String] {
        switch insight.type {
        case .performance:
            return [
                "Review worker assignments and redistribute workload",
                "Implement performance monitoring tools",
                "Schedule team training sessions"
            ]
        case .maintenance:
            return [
                "Schedule immediate maintenance review",
                "Prioritize high-risk equipment inspection",
                "Update maintenance schedules"
            ]
        case .cost:
            return [
                "Analyze current resource allocation",
                "Consider worker optimization strategies",
                "Review vendor contracts and pricing"
            ]
        case .compliance:
            return [
                "Schedule compliance audit",
                "Update documentation and procedures",
                "Implement corrective measures"
            ]
        case .efficiency:
            return [
                "Optimize workflow processes",
                "Review and update task assignments",
                "Implement efficiency monitoring"
            ]
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Enums

enum InsightFilter: Hashable, CaseIterable {
    case all
    case priority
    case actionable
    case type(InsightType)
    
    static var allCases: [InsightFilter] {
        return [.all, .priority, .actionable] + InsightType.allCases.map { .type($0) }
    }
    
    var title: String {
        switch self {
        case .all: return "All"
        case .priority: return "High Priority"
        case .actionable: return "Actionable"
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
        case .actionable: return .green
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
        case .actionable: return "No Actionable Insights"
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
                IntelligenceInsight(
                    title: "High Portfolio Efficiency",
                    description: "8 out of 12 buildings are performing at >90% efficiency",
                    type: .performance,
                    priority: .medium,
                    actionable: false
                ),
                IntelligenceInsight(
                    title: "Maintenance Priority Alert",
                    description: "3 buildings require immediate maintenance attention",
                    type: .maintenance,
                    priority: .high,
                    actionable: true
                )
            ]
        )
        .preferredColorScheme(.dark)
    }
}
