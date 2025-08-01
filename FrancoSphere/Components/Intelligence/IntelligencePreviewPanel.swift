//
//  IntelligencePreviewPanel.swift
//  FrancoSphere v6.0
//
//  ✅ REFACTORED: Now supports both panel and compact bar modes
//  ✅ ELEGANT: Single component, two display modes
//  ✅ NAVIGATION: Compact mode acts as intelligent navigation
//  ✅ MAINTAINS: All existing functionality
//  ✅ PRODUCTION DATA: Uses real OperationalDataManager insights
//
//  Real-world operational context:
//  - 20 active buildings, 7 workers
//  - DSNY compliance: Set-out after 8 PM, pickup 6 AM - 12 PM
//  - Kevin Dutan: Rubin Museum specialist (38 tasks)
//  - Mercedes Inamagua: West 17th St glass cleaning circuit
//  - Edwin Lema: Stuyvesant Cove Park maintenance
//  - Angel Guiracocha: Evening DSNY operations
//

import SwiftUI

// MARK: - FrancoSphere Production Data Reference
// Building IDs from CanonicalIDs:
// - "14": Rubin Museum (142-148 W 17th) - Kevin's primary
// - "10": 131 Perry Street
// - "6": 68 Perry Street
// - "3": 135-139 West 17th Street
// - "5": 138 West 17th Street
// - "9": 117 West 17th Street
// - "13": 136 West 17th Street
// - "16": Stuyvesant Cove Park - Edwin's territory
// - "11": 123 1st Avenue
// Worker assignments:
// - Kevin Dutan (ID: 4): Museum specialist, expanded duties
// - Mercedes Inamagua (ID: 5): Glass cleaning circuit
// - Edwin Lema (ID: 2): Park and East side maintenance
// - Angel Guiracocha (ID: 7): Evening DSNY operations
// - Luis Lopez (ID: 6): Perry St and downtown maintenance

struct IntelligencePreviewPanel: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let onInsightTap: ((CoreTypes.IntelligenceInsight) -> Void)?
    let onRefresh: (() async -> Void)?
    var displayMode: DisplayMode = .panel
    var onNavigate: ((NavigationTarget) -> Void)?
    
    @State private var isRefreshing = false
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    @State private var showingDetail = false
    @State private var currentInsightIndex = 0
    @State private var rotationTimer: Timer?
    
    // Display modes
    enum DisplayMode {
        case panel      // Full panel (existing)
        case compact    // Bottom bar navigation
    }
    
    // Navigation targets from insights
    enum NavigationTarget {
        case tasks(urgent: Int)
        case buildings(affected: [String])
        case compliance(deadline: Date?)
        case maintenance(overdue: Int)
        case fullInsights
    }
    
    init(
        insights: [CoreTypes.IntelligenceInsight],
        onInsightTap: ((CoreTypes.IntelligenceInsight) -> Void)? = nil,
        onRefresh: (() async -> Void)? = nil,
        displayMode: DisplayMode = .panel,
        onNavigate: ((NavigationTarget) -> Void)? = nil
    ) {
        self.insights = insights
        self.onInsightTap = onInsightTap
        self.onRefresh = onRefresh
        self.displayMode = displayMode
        self.onNavigate = onNavigate
    }
    
    var body: some View {
        switch displayMode {
        case .panel:
            panelView
        case .compact:
            compactView
        }
    }
    
    // MARK: - Panel View (Original)
    
    private var panelView: some View {
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
    
    // MARK: - Compact Navigation Bar View
    
    private var compactView: some View {
        Button(action: handleCompactTap) {
            HStack(spacing: 0) {
                // Nova indicator with state
                compactNovaIndicator
                    .padding(.trailing, 12)
                
                // Dynamic content area
                Spacer(minLength: 0)
                
                compactContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 0)
                
                // Quick actions
                compactActions
                    .padding(.leading, 12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(compactBackground)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear { startInsightRotation() }
        .onDisappear { stopInsightRotation() }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
    }
    
    // MARK: - Compact View Components
    
    private var compactNovaIndicator: some View {
        ZStack {
            Circle()
                .fill(novaGradient)
                .frame(width: 36, height: 36)
            
            Image(systemName: "brain.head.profile")
                .font(.body)
                .foregroundColor(.white)
                .symbolEffect(.pulse.wholeSymbol, isActive: hasCritical)
            
            // Critical alert ring
            if hasCritical {
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .scaleEffect(hasCritical ? 1.2 : 1.0)
                    .opacity(hasCritical ? 0.6 : 0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: hasCritical)
            }
        }
        .overlay(alignment: .topTrailing) {
            if hasActionRequired {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 10, height: 10)
                    .offset(x: 2, y: -2)
            }
        }
    }
    
    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text("Nova Intelligence")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if !insights.isEmpty {
                    StatusPill(
                        text: hasCritical ? "CRITICAL" : "ACTIVE",
                        color: hasCritical ? .red : .green
                    )
                }
            }
            
            if !insights.isEmpty {
                Text(currentInsightText)
                    .font(.caption2)
                    .foregroundColor(currentInsightColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .animation(.easeInOut(duration: 0.3), value: currentInsightIndex)
            } else {
                Text("Analyzing operations...")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    private var compactActions: some View {
        HStack(spacing: 8) {
            // Navigation hints based on insights
            if let navHint = primaryNavigationHint {
                NavigationHintButton(hint: navHint) {
                    handleNavigationHint(navHint)
                }
            }
            
            // Insight count
            if insights.count > 0 {
                InsightCountBadge(
                    count: insights.count,
                    hasCritical: hasCritical
                )
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var compactBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Top edge indicator
            if hasCritical {
                VStack {
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 2)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Header (Panel Mode)
    
    private var header: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(novaGradient)
                    .frame(width: 40, height: 40)
                
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
                        StatusPill(text: "LIVE", color: .green)
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
    
    // MARK: - Metrics Overview (Panel Mode)
    
    private var insightMetrics: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                IntelligenceMetricCard(
                    title: "Total Insights",
                    value: "\(insights.count)",
                    icon: "lightbulb.fill",
                    color: .blue,
                    onTap: { onNavigate?(.fullInsights) }
                )
                
                IntelligenceMetricCard(
                    title: "Critical",
                    value: "\(criticalInsightsCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    onTap: { handleCriticalTap() }
                )
                
                IntelligenceMetricCard(
                    title: "High Priority",
                    value: "\(highPriorityInsightsCount)",
                    icon: "flag.fill",
                    color: .orange,
                    onTap: { handleHighPriorityTap() }
                )
                
                IntelligenceMetricCard(
                    title: "Action Required",
                    value: "\(actionableInsightsCount)",
                    icon: "hand.tap.fill",
                    color: .green,
                    onTap: { handleActionRequiredTap() }
                )
            }
            .padding(.horizontal, 1)
        }
    }
    
    // MARK: - Insights List (Panel Mode)
    
    private var insightsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Latest Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if insights.count > 3 {
                    Button(action: { onNavigate?(.fullInsights) }) {
                        Text("+\(insights.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
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
    
    // MARK: - Navigation Logic
    
    private var primaryNavigationHint: NavigationHint? {
        // Analyze insights to suggest navigation
        if let urgentCount = getUrgentTaskCount(), urgentCount > 0 {
            return NavigationHint(
                icon: "exclamationmark.triangle.fill",
                text: "\(urgentCount)",
                color: .orange,
                target: .tasks(urgent: urgentCount)
            )
        }
        
        if let maintenanceCount = getOverdueMaintenanceCount(), maintenanceCount > 0 {
            return NavigationHint(
                icon: "wrench.fill",
                text: "\(maintenanceCount)",
                color: .red,
                target: .maintenance(overdue: maintenanceCount)
            )
        }
        
        if hasComplianceDeadline {
            // DSNY compliance is time-critical (8 PM deadline)
            let dsnySummary = insights.filter { $0.type == .compliance && $0.description.contains("DSNY") }
                .compactMap { insight -> String? in
                    let buildingCount = insight.affectedBuildings.count
                    if buildingCount > 0 {
                        return "\(buildingCount)"
                    }
                    return nil
                }
                .first
            
            return NavigationHint(
                icon: "clock.fill",
                text: dsnySummary ?? "DSNY",
                color: .orange,
                target: .compliance(deadline: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()))
            )
        }
        
        return nil
    }
    
    private func handleNavigationHint(_ hint: NavigationHint) {
        onNavigate?(hint.target)
    }
    
    private func handleCompactTap() {
        if let critical = insights.first(where: { $0.priority == .critical }) {
            selectedInsight = critical
            showingDetail = true
        } else {
            onNavigate?(.fullInsights)
        }
    }
    
    private func handleCriticalTap() {
        if let critical = insights.first(where: { $0.priority == .critical }) {
            selectedInsight = critical
            showingDetail = true
        }
    }
    
    private func handleHighPriorityTap() {
        if let high = insights.first(where: { $0.priority == .high }) {
            selectedInsight = high
            showingDetail = true
        }
    }
    
    private func handleActionRequiredTap() {
        if let action = insights.first(where: { $0.actionRequired }) {
            selectedInsight = action
            showingDetail = true
        }
    }
    
    // MARK: - Helper Methods
    
    private var currentInsightText: String {
        guard !insights.isEmpty else { return "Analyzing..." }
        
        let sorted = insights.sorted { first, second in
            if first.priority == .critical && second.priority != .critical { return true }
            if first.actionRequired && !second.actionRequired { return true }
            return false
        }
        
        guard currentInsightIndex < sorted.count else {
            return sorted.first?.title ?? ""
        }
        
        return sorted[currentInsightIndex].title
    }
    
    private var currentInsightColor: Color {
        guard !insights.isEmpty,
              currentInsightIndex < insights.count else {
            return .white.opacity(0.6)
        }
        
        switch insights[currentInsightIndex].priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .white.opacity(0.8)
        }
    }
    
    private func startInsightRotation() {
        guard insights.count > 1, displayMode == .compact else { return }
        
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentInsightIndex = (currentInsightIndex + 1) % insights.count
            }
        }
    }
    
    private func stopInsightRotation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
    
    private func getUrgentTaskCount() -> Int? {
        // Extract from insights mentioning urgent tasks
        // Common patterns: "X urgent tasks", "X overdue", "X critical"
        for insight in insights {
            // Operations and maintenance types often contain task-related insights
            if insight.type == .operations || insight.type == .maintenance {
                // Match patterns like "3 urgent museum tasks" or "5 overdue Rubin tasks"
                if let match = insight.description.firstMatch(of: /(\d+)\s+(urgent|overdue|critical)/) {
                    return Int(match.1)
                }
            }
        }
        return nil
    }
    
    private func getOverdueMaintenanceCount() -> Int? {
        // Extract from maintenance insights
        // Matches real patterns like "power wash scheduled", "HVAC checks overdue"
        for insight in insights where insight.type == .maintenance {
            if let match = insight.description.firstMatch(of: /(\d+)\s+.*\s*(overdue|scheduled|pending)/) {
                return Int(match.1)
            }
        }
        return nil
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
    
    private var hasCritical: Bool {
        insights.contains { $0.priority == .critical }
    }
    
    private var hasActionRequired: Bool {
        insights.contains { $0.actionRequired }
    }
    
    private var hasComplianceDeadline: Bool {
        // Check for DSNY or other compliance deadlines
        insights.contains { insight in
            insight.type == .compliance &&
            (insight.priority == .critical || insight.priority == .high) &&
            (insight.description.contains("DSNY") || insight.description.contains("8:00 PM") || insight.description.contains("set-out"))
        }
    }
    
    private var novaGradient: LinearGradient {
        LinearGradient(
            colors: hasCritical ?
                [.red.opacity(0.8), .orange.opacity(0.8)] :
                [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Supporting Components

struct StatusPill: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(4)
    }
}

struct IntelligenceMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let onTap: (() -> Void)?
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
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
}

struct NavigationHintButton: View {
    let hint: NavigationHint
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: hint.icon)
                    .font(.caption2)
                    .foregroundColor(hint.color)
                
                Text(hint.text)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(hint.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(hint.color.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

struct InsightCountBadge: View {
    let count: Int
    let hasCritical: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(hasCritical ? .red : .blue)
                .frame(width: 20, height: 20)
            
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct NavigationHint {
    let icon: String
    let text: String
    let color: Color
    let target: IntelligencePreviewPanel.NavigationTarget
}

// MARK: - Insight Row View (unchanged)

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

// MARK: - Insight Detail View (unchanged)

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
        // Real-world insights based on OperationalDataManager data
        let productionInsights: [CoreTypes.IntelligenceInsight] = [
            // Kevin's Rubin Museum overdue tasks
            CoreTypes.IntelligenceInsight(
                title: "3 urgent museum tasks overdue",
                description: "Kevin's climate control check and security protocols at Rubin Museum require immediate attention",
                type: .operations,  // Operations covers task scheduling
                priority: .critical,
                actionRequired: true,
                affectedBuildings: ["14"] // Rubin Museum
            ),
            
            // DSNY compliance for West 17th Street corridor
            CoreTypes.IntelligenceInsight(
                title: "DSNY set-out deadline 8:00 PM",
                description: "Kevin must place trash for 136, 138 West 17th St and Rubin Museum. Pickup window: 6 AM - 12 PM",
                type: .compliance,
                priority: .high,
                actionRequired: true,
                affectedBuildings: ["13", "5", "14"] // 136 W 17th, 138 W 17th, Rubin
            ),
            
            // Mercedes' glass cleaning route optimization
            CoreTypes.IntelligenceInsight(
                title: "Glass circuit optimization available",
                description: "Mercedes can save 20 minutes by reordering: 117 → 135-139 → 136 → 138 West 17th",
                type: .routing,  // Routing for route optimization (now available in CoreTypes)
                priority: .medium,
                actionRequired: false,
                affectedBuildings: ["9", "3", "13", "5"] // West 17th corridor
            ),
            
            // Edwin's park maintenance
            CoreTypes.IntelligenceInsight(
                title: "Stuyvesant Cove power wash scheduled",
                description: "Monthly walkway cleaning due today. Edwin allocated 2 hours (7-9 AM)",
                type: .maintenance,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: ["16"] // Stuyvesant Cove Park
            ),
            
            // Building performance trend
            CoreTypes.IntelligenceInsight(
                title: "Perry Street showing 15% efficiency gain",
                description: "Luis' preventive maintenance reducing emergency calls at 131 & 68 Perry",
                type: .quality,  // Quality improvements from maintenance
                priority: .low,
                actionRequired: false,
                affectedBuildings: ["10", "6"] // Perry Street buildings
            )
        ]
        
        // Scenario-specific insights
        let urgentScenario: [CoreTypes.IntelligenceInsight] = [
            CoreTypes.IntelligenceInsight(
                title: "Kevin has 5 overdue Rubin tasks",
                description: "Museum deep clean, trash area maintenance, and HVAC checks critically overdue",
                type: .operations,  // Operations for critical task management
                priority: .critical,
                actionRequired: true,
                affectedBuildings: ["14"]
            ),
            CoreTypes.IntelligenceInsight(
                title: "Angel missing DSNY deadline",
                description: "123 1st Avenue trash not set out. Fine risk: $100-$300",
                type: .compliance,
                priority: .critical,
                actionRequired: true,
                affectedBuildings: ["11"]
            )
        ]
        
        VStack(spacing: 20) {
            // Panel mode with production data
            IntelligencePreviewPanel(
                insights: productionInsights,
                displayMode: .panel
            )
            
            Divider()
            
            // Compact mode - normal operations
            IntelligencePreviewPanel(
                insights: productionInsights,
                displayMode: .compact,
                onNavigate: { target in
                    print("Navigate to: \(target)")
                }
            )
            .frame(height: 60)
            
            // Compact mode - urgent scenario
            IntelligencePreviewPanel(
                insights: urgentScenario,
                displayMode: .compact,
                onNavigate: { target in
                    print("URGENT Navigate to: \(target)")
                }
            )
            .frame(height: 60)
            
            // Empty state compact
            IntelligencePreviewPanel(
                insights: [],
                displayMode: .compact
            )
            .frame(height: 60)
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
