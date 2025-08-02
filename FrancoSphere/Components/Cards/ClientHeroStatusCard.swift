//
//  ClientHeroStatusCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 8/2/25.
//


//
//  ClientHeroStatusCard.swift
//  FrancoSphere v6.0
//
//  ✅ DYNAMIC: Real-time portfolio metrics from all sources
//  ✅ COMPREHENSIVE: Aggregates worker, compliance, and building data
//  ✅ INTELLIGENT: Shows actionable insights and trends
//  ✅ VISUAL: Rich animations and live status indicators
//  ✅ RESPONSIVE: Adapts to critical situations
//

import SwiftUI
import Charts

struct ClientHeroStatusCard: View {
    // MARK: - Properties
    let portfolioHealth: CoreTypes.PortfolioHealth
    let realtimeMetrics: CoreTypes.RealtimePortfolioMetrics
    let activeWorkers: CoreTypes.ActiveWorkerStatus
    let complianceStatus: CoreTypes.ComplianceOverview
    let criticalAlerts: [CoreTypes.ClientAlert]
    let buildingPerformance: [String: Double]
    let syncStatus: SyncStatus
    
    // Callbacks
    let onPortfolioTap: () -> Void
    let onComplianceTap: () -> Void
    let onWorkersTap: () -> Void
    let onAlertsTap: () -> Void
    let onSyncTap: () -> Void
    
    // Animation states
    @State private var animateMetrics = false
    @State private var pulseAnimation = false
    @State private var showDetailedView = false
    
    // MARK: - Enums
    enum SyncStatus {
        case synced
        case syncing(progress: Double)
        case error(String)
        case offline
    }
    
    // MARK: - Computed Properties
    private var hasCriticalSituation: Bool {
        portfolioHealth.criticalIssues > 0 ||
        complianceStatus.criticalViolations > 0 ||
        criticalAlerts.contains { $0.severity == .critical }
    }
    
    private var overallStatus: StatusLevel {
        if hasCriticalSituation {
            return .critical
        } else if portfolioHealth.overallScore < 0.7 || complianceStatus.overallScore < 0.8 {
            return .warning
        } else {
            return .healthy
        }
    }
    
    private var statusColor: Color {
        switch overallStatus {
        case .critical: return FrancoSphereDesign.DashboardColors.critical
        case .warning: return FrancoSphereDesign.DashboardColors.warning
        case .healthy: return FrancoSphereDesign.DashboardColors.success
        }
    }
    
    enum StatusLevel {
        case healthy, warning, critical
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            VStack(spacing: 20) {
                // Header with status
                headerSection
                
                // Real-time metrics grid
                metricsGrid
                
                // Live activity monitor
                liveActivitySection
                
                // Compliance and alerts bar
                complianceAlertsBar
                
                // Performance trend chart
                performanceTrendSection
                
                // Action buttons
                actionButtons
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: FrancoSphereDesign.DashboardColors.clientHeroGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.xl)
                            .stroke(statusColor.opacity(hasCriticalSituation ? 0.5 : 0.2), lineWidth: 2)
                            .blur(radius: hasCriticalSituation ? 4 : 0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: hasCriticalSituation)
                    )
            )
            .francoShadow(FrancoSphereDesign.Shadow.lg)
            
            // Sync status bar
            syncStatusBar
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                animateMetrics = true
            }
            if hasCriticalSituation {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    // Portfolio health score with animation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Portfolio Health")
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                        
                        HStack(baseline: .bottom, spacing: 4) {
                            Text("\(Int(portfolioHealth.overallScore * 100))")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(statusColor)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: portfolioHealth.overallScore)
                            
                            Text("%")
                                .font(.title3)
                                .foregroundColor(statusColor.opacity(0.8))
                        }
                    }
                    
                    // Trend indicator
                    VStack(alignment: .center, spacing: 4) {
                        Image(systemName: trendIcon)
                            .font(.title2)
                            .foregroundColor(trendColor)
                            .rotationEffect(.degrees(trendRotation))
                            .animation(.spring(), value: portfolioHealth.trend)
                        
                        Text(trendText)
                            .font(.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                }
                
                // Live status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(FrancoSphereDesign.DashboardColors.success)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(FrancoSphereDesign.DashboardColors.success.opacity(0.4), lineWidth: 6)
                                .scaleEffect(pulseAnimation ? 2 : 1)
                                .opacity(pulseAnimation ? 0 : 1)
                                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)
                        )
                    
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                    
                    Text("•")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    
                    Text("Updated \(realtimeMetrics.lastUpdateTime.formatted(.relative(presentation: .numeric)))")
                        .font(.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
            
            Spacer()
            
            // Critical alerts indicator
            if hasCriticalSituation {
                Button(action: onAlertsTap) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(FrancoSphereDesign.DashboardColors.critical)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        
                        Text("\(criticalAlerts.filter { $0.severity == .critical }.count) Critical")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            // Buildings metric
            MetricCard(
                icon: "building.2.fill",
                title: "Buildings",
                value: "\(portfolioHealth.totalBuildings)",
                subtitle: "\(portfolioHealth.activeBuildings) active",
                color: FrancoSphereDesign.DashboardColors.clientPrimary,
                progress: Double(portfolioHealth.activeBuildings) / Double(portfolioHealth.totalBuildings),
                onTap: onPortfolioTap
            )
            
            // Workers metric with real-time status
            MetricCard(
                icon: "person.3.fill",
                title: "Workers",
                value: "\(activeWorkers.totalActive)",
                subtitle: "\(Int(activeWorkers.utilizationRate * 100))% utilized",
                color: FrancoSphereDesign.DashboardColors.info,
                progress: activeWorkers.utilizationRate,
                isLive: true,
                onTap: onWorkersTap
            )
            
            // Compliance metric
            MetricCard(
                icon: "checkmark.shield.fill",
                title: "Compliance",
                value: "\(Int(complianceStatus.overallScore * 100))%",
                subtitle: complianceStatus.criticalViolations > 0 ? "\(complianceStatus.criticalViolations) violations" : "All clear",
                color: complianceScoreColor,
                progress: complianceStatus.overallScore,
                hasIssue: complianceStatus.criticalViolations > 0,
                onTap: onComplianceTap
            )
        }
        .opacity(animateMetrics ? 1 : 0)
        .offset(y: animateMetrics ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateMetrics)
    }
    
    // MARK: - Live Activity Section
    private var liveActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live Activity", systemImage: "dot.radiowaves.left.and.right")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                // Activity indicator
                HStack(spacing: 3) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(FrancoSphereDesign.DashboardColors.success)
                            .frame(width: 3, height: CGFloat.random(in: 8...16))
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                value: pulseAnimation
                            )
                    }
                }
            }
            
            // Real-time activity feed
            VStack(alignment: .leading, spacing: 8) {
                ForEach(realtimeMetrics.recentActivities.prefix(3), id: \.id) { activity in
                    ActivityRow(activity: activity)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .opacity(animateMetrics ? 1 : 0)
        .offset(y: animateMetrics ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateMetrics)
    }
    
    // MARK: - Compliance & Alerts Bar
    private var complianceAlertsBar: some View {
        HStack(spacing: 16) {
            // Compliance summary
            Button(action: onComplianceTap) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.title3)
                        .foregroundColor(complianceScoreColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Compliance")
                            .font(.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                        
                        HStack(spacing: 4) {
                            if complianceStatus.criticalViolations > 0 {
                                Text("\(complianceStatus.criticalViolations)")
                                    .fontWeight(.bold)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                                + Text(" critical")
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                            } else {
                                Text("All Clear")
                                    .fontWeight(.medium)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                            }
                        }
                        .font(.caption)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(complianceScoreColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(complianceScoreColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Alerts summary
            if !criticalAlerts.isEmpty {
                Button(action: onAlertsTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title3)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Alerts")
                                .font(.caption2)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                            
                            Text("\(criticalAlerts.count) active")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(FrancoSphereDesign.DashboardColors.warning.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(FrancoSphereDesign.DashboardColors.warning.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .opacity(animateMetrics ? 1 : 0)
        .offset(y: animateMetrics ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: animateMetrics)
    }
    
    // MARK: - Performance Trend Section
    private var performanceTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("7-Day Performance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Text("\(performanceChange > 0 ? "+" : "")\(performanceChange)%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(performanceChange > 0 ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.critical)
            }
            
            // Mini chart
            PerformanceTrendChart(data: realtimeMetrics.performanceTrend)
                .frame(height: 60)
        }
        .opacity(animateMetrics ? 1 : 0)
        .offset(y: animateMetrics ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.4), value: animateMetrics)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Quick actions based on context
            if hasCriticalSituation {
                Button(action: onAlertsTap) {
                    Label("View Critical Issues", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(style: .danger))
            } else {
                Button(action: onPortfolioTap) {
                    Label("Portfolio Analysis", systemImage: "chart.pie")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(style: .primary))
            }
            
            // Secondary action
            Button(action: {
                showDetailedView = true
            }) {
                Image(systemName: showDetailedView ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.title3)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .opacity(animateMetrics ? 1 : 0)
        .offset(y: animateMetrics ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.5), value: animateMetrics)
    }
    
    // MARK: - Sync Status Bar
    private var syncStatusBar: some View {
        HStack(spacing: 8) {
            // Status icon
            Image(systemName: syncStatusIcon)
                .font(.caption)
                .foregroundColor(syncStatusColor)
                .animation(.easeInOut(duration: 0.5), value: syncStatus)
            
            // Status text
            Text(syncStatusText)
                .font(.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            // Sync button
            Button(action: onSyncTap) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
                    .rotationEffect(.degrees(isSyncing ? 360 : 0))
                    .animation(isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSyncing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.02))
        )
    }
    
    // MARK: - Helper Properties
    
    private var trendIcon: String {
        switch portfolioHealth.trend {
        case .up, .improving: return "arrow.up.circle.fill"
        case .down, .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch portfolioHealth.trend {
        case .up, .improving: return FrancoSphereDesign.DashboardColors.success
        case .down, .declining: return FrancoSphereDesign.DashboardColors.critical
        case .stable: return FrancoSphereDesign.DashboardColors.info
        case .unknown: return FrancoSphereDesign.DashboardColors.inactive
        }
    }
    
    private var trendRotation: Double {
        switch portfolioHealth.trend {
        case .up, .improving: return -45
        case .down, .declining: return 45
        case .stable, .unknown: return 0
        }
    }
    
    private var trendText: String {
        switch portfolioHealth.trend {
        case .up: return "Up"
        case .down: return "Down"
        case .stable: return "Stable"
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .unknown: return "Unknown"
        }
    }
    
    private var complianceScoreColor: Color {
        if complianceStatus.overallScore >= 0.9 {
            return FrancoSphereDesign.DashboardColors.compliant
        } else if complianceStatus.overallScore >= 0.7 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.violation
        }
    }
    
    private var performanceChange: Int {
        guard let firstValue = realtimeMetrics.performanceTrend.first,
              let lastValue = realtimeMetrics.performanceTrend.last else { return 0 }
        
        let change = ((lastValue - firstValue) / firstValue) * 100
        return Int(change)
    }
    
    private var syncStatusIcon: String {
        switch syncStatus {
        case .synced: return "checkmark.circle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.triangle.fill"
        case .offline: return "wifi.slash"
        }
    }
    
    private var syncStatusColor: Color {
        switch syncStatus {
        case .synced: return FrancoSphereDesign.DashboardColors.success
        case .syncing: return FrancoSphereDesign.DashboardColors.info
        case .error: return FrancoSphereDesign.DashboardColors.critical
        case .offline: return FrancoSphereDesign.DashboardColors.inactive
        }
    }
    
    private var syncStatusText: String {
        switch syncStatus {
        case .synced: return "All data synced"
        case .syncing(let progress): return "Syncing... \(Int(progress * 100))%"
        case .error(let message): return message
        case .offline: return "Offline mode"
        }
    }
    
    private var isSyncing: Bool {
        if case .syncing = syncStatus { return true }
        return false
    }
}

// MARK: - Supporting Components

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let progress: Double
    var isLive: Bool = false
    var hasIssue: Bool = false
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if isLive {
                        Circle()
                            .fill(FrancoSphereDesign.DashboardColors.success)
                            .frame(width: 4, height: 4)
                    }
                    
                    if hasIssue {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                    }
                }
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 3)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    .lineLimit(1)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct ActivityRow: View {
    let activity: CoreTypes.RealtimeActivity
    
    var body: some View {
        HStack(spacing: 8) {
            // Activity type icon
            Image(systemName: activityIcon)
                .font(.caption2)
                .foregroundColor(activityColor)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(activityColor.opacity(0.2))
                )
            
            // Activity description
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let worker = activity.workerName {
                        Text(worker)
                            .font(.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                    }
                    
                    if let building = activity.buildingName {
                        Text("•")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                        Text(building)
                            .font(.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            // Time
            Text(activity.timestamp.formatted(.relative(presentation: .numeric)))
                .font(.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
        }
    }
    
    private var activityIcon: String {
        switch activity.type {
        case .taskCompleted: return "checkmark.circle.fill"
        case .workerClockIn: return "person.crop.circle.badge.checkmark"
        case .workerClockOut: return "person.crop.circle.badge.xmark"
        case .issueReported: return "exclamationmark.bubble"
        case .complianceUpdate: return "shield.lefthalf.filled"
        case .buildingUpdate: return "building.2"
        }
    }
    
    private var activityColor: Color {
        switch activity.type {
        case .taskCompleted: return FrancoSphereDesign.DashboardColors.success
        case .workerClockIn, .workerClockOut: return FrancoSphereDesign.DashboardColors.info
        case .issueReported: return FrancoSphereDesign.DashboardColors.warning
        case .complianceUpdate: return FrancoSphereDesign.DashboardColors.compliant
        case .buildingUpdate: return FrancoSphereDesign.DashboardColors.clientPrimary
        }
    }
}

struct PerformanceTrendChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let maxValue = data.max() ?? 1
                let minValue = data.min() ?? 0
                let range = maxValue - minValue
                
                for (index, value) in data.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(data.count - 1)
                    let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                    let y = height * (1 - normalizedValue)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [
                        FrancoSphereDesign.DashboardColors.clientPrimary,
                        FrancoSphereDesign.DashboardColors.clientSecondary
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            
            // Add gradient fill
            Path { path in
                guard data.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let maxValue = data.max() ?? 1
                let minValue = data.min() ?? 0
                let range = maxValue - minValue
                
                path.move(to: CGPoint(x: 0, y: height))
                
                for (index, value) in data.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(data.count - 1)
                    let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                    let y = height * (1 - normalizedValue)
                    
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        FrancoSphereDesign.DashboardColors.clientPrimary.opacity(0.3),
                        FrancoSphereDesign.DashboardColors.clientPrimary.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Client Hero Card - Healthy") {
    ClientHeroStatusCard(
        portfolioHealth: .preview,
        realtimeMetrics: .preview,
        activeWorkers: .preview,
        complianceStatus: .previewHealthy,
        criticalAlerts: [],
        buildingPerformance: [
            "building1": 0.92,
            "building2": 0.85,
            "building3": 0.78
        ],
        syncStatus: .synced,
        onPortfolioTap: {},
        onComplianceTap: {},
        onWorkersTap: {},
        onAlertsTap: {},
        onSyncTap: {}
    )
    .padding()
    .background(FrancoSphereDesign.DashboardColors.baseBackground)
    .preferredColorScheme(.dark)
}

#Preview("Client Hero Card - Critical") {
    ClientHeroStatusCard(
        portfolioHealth: .previewCritical,
        realtimeMetrics: .previewWithAlerts,
        activeWorkers: .previewLowUtilization,
        complianceStatus: .previewWithViolations,
        criticalAlerts: CoreTypes.ClientAlert.previewCritical,
        buildingPerformance: [
            "building1": 0.65,
            "building2": 0.45,
            "building3": 0.72
        ],
        syncStatus: .syncing(progress: 0.67),
        onPortfolioTap: {},
        onComplianceTap: {},
        onWorkersTap: {},
        onAlertsTap: {},
        onSyncTap: {}
    )
    .padding()
    .background(FrancoSphereDesign.DashboardColors.baseBackground)
    .preferredColorScheme(.dark)
}