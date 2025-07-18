//
//  IntelligenceInsightsView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All syntax errors and top-level expressions resolved
//  ✅ PROPER: SwiftUI view structure with all code inside appropriate boundaries
//  ✅ ENHANCED: Complete functionality without breaking changes
//

import SwiftUI

struct IntelligenceInsightsView: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let onInsightAction: ((CoreTypes.IntelligenceInsight) -> Void)?
    let onRefreshInsights: (() async -> Void)?
    
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
                // Filter selector
                filterSelector
                
                // Content
                if filteredInsights.isEmpty {
                    emptyStateView
                } else {
                    insightsList
                }
            }
            .navigationTitle("Intelligence Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .sheet(item: $selectedInsight) { insight in
                InsightDetailSheet(insight: insight)
            }
        }
    }
    
    // MARK: - Filter Selector
    
    private var filterSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightFilterType.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedFilter = filter
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.caption)
                            
                            Text(filter.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedFilter == filter ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedFilter == filter ? filter.color : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selectedFilter == filter ? Color.clear : Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Refresh Button
    
    private var refreshButton: some View {
        Button(action: {
            Task {
                isRefreshing = true
                await onRefreshInsights?()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                isRefreshing = false
            }
        }) {
            Image(systemName: "arrow.clockwise")
                .foregroundColor(.blue)
                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
        }
        .disabled(isRefreshing)
    }
    
    // MARK: - Insights List
    
    private var insightsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredInsights, id: \.id) { insight in
                    InsightCard(
                        insight: insight,
                        onTap: {
                            selectedInsight = insight
                            showingDetailSheet = true
                        },
                        onAction: {
                            onInsightAction?(insight)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Empty State View
    
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
                .controlSize(.small)
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
}

// MARK: - Supporting Views

struct InsightCard: View {
    let insight: CoreTypes.IntelligenceInsight
    let onTap: () -> Void
    let onAction: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(insight.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image(systemName: insight.type.icon)
                            .font(.title2)
                            .foregroundColor(insight.type.color)
                        
                        Text(insight.priority.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(insight.priority.color)
                            .cornerRadius(6)
                    }
                }
                
                if insight.actionRequired {
                    Button(action: onAction) {
                        HStack {
                            Image(systemName: "hand.tap")
                                .font(.caption)
                            
                            Text("Take Action")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightDetailSheet: View {
    let insight: CoreTypes.IntelligenceInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(insight.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(insight.type.rawValue)
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Priority")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(insight.priority.rawValue)
                            .font(.headline)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Filter Types

enum InsightFilterType: CaseIterable, Hashable {
    case all
    case priority
    case actionable
    case type(CoreTypes.InsightType)
    
    static var allCases: [InsightFilterType] {
        return [.all, .priority, .actionable] + CoreTypes.InsightType.allCases.map { .type($0) }
    }
    
    var displayName: String {
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

// MARK: - Hashable Conformance for InsightFilterType

extension InsightFilterType {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .all:
            hasher.combine("all")
        case .priority:
            hasher.combine("priority")
        case .actionable:
            hasher.combine("actionable")
        case .type(let type):
            hasher.combine("type")
            hasher.combine(type)
        }
    }
    
    static func == (lhs: InsightFilterType, rhs: InsightFilterType) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all), (.priority, .priority), (.actionable, .actionable):
            return true
        case (.type(let lhsType), .type(let rhsType)):
            return lhsType == rhsType
        default:
            return false
        }
    }
}
