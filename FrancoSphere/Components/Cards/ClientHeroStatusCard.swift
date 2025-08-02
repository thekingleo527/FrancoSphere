//
//  ClientHeroStatusCard.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All type conflicts resolved
//  ✅ NAMESPACED: Using CoreTypes for shared models
//  ✅ UNIQUE: Component names are prefixed to avoid conflicts
//

import SwiftUI
import MapKit

struct ClientHeroStatusCard: View {
    // Real-time data inputs using CoreTypes
    let routineMetrics: CoreTypes.RealtimeRoutineMetrics
    let activeWorkers: CoreTypes.ActiveWorkerStatus
    let complianceStatus: CoreTypes.ComplianceOverview
    let monthlyMetrics: CoreTypes.MonthlyMetrics
    
    // Callback for building tap
    let onBuildingTap: (CoreTypes.NamedCoordinate) -> Void
    
    // MARK: - Computed Properties
    
    private var overallStatus: OverallStatus {
        if routineMetrics.behindScheduleCount > 0 {
            return .behindSchedule
        } else if routineMetrics.overallCompletion > 0.9 {
            return .onTrack
        } else if routineMetrics.overallCompletion > 0.7 {
            return .inProgress
        } else {
            return .starting
        }
    }
    
    private var statusColor: Color {
        switch overallStatus {
        case .onTrack: return FrancoSphereDesign.DashboardColors.success
        case .inProgress: return FrancoSphereDesign.DashboardColors.info
        case .behindSchedule: return FrancoSphereDesign.DashboardColors.warning
        case .starting: return FrancoSphereDesign.DashboardColors.inactive
        }
    }
    
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Hello"
        }
    }
    
    private var priorityBuildings: [CoreTypes.BuildingRoutineStatus] {
        // Get buildings that need attention first
        routineMetrics.buildingStatuses.values
            .sorted { b1, b2 in
                // Priority order: behind schedule > low completion > alphabetical
                if b1.isBehindSchedule != b2.isBehindSchedule {
                    return b1.isBehindSchedule
                }
                return b1.completionRate < b2.completionRate
            }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with greeting and status
            headerSection
            
            // Real-time building status cards
            if !priorityBuildings.isEmpty {
                buildingStatusSection
            }
            
            // Overall metrics row
            metricsRow
            
            // Monthly budget indicator (if over threshold)
            if monthlyMetrics.budgetUtilization > 0.8 {
                budgetWarningRow
            }
            
            // Compliance status (if issues)
            if complianceStatus.criticalViolations > 0 {
                complianceAlertRow
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeOfDayGreeting)
                        .francoTypography(FrancoSphereDesign.Typography.headline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Text("Service Status Overview")
                        .francoTypography(FrancoSphereDesign.Typography.dashboardTitle)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .opacity(1)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: UUID())
                    
                    Text("LIVE")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            // Overall status pill
            HStack(spacing: 12) {
                ClientStatusPill(
                    label: overallStatus.displayText,
                    color: statusColor,
                    icon: overallStatus.icon
                )
                
                if routineMetrics.behindScheduleCount > 0 {
                    ClientStatusPill(
                        label: "\(routineMetrics.behindScheduleCount) behind schedule",
                        color: FrancoSphereDesign.DashboardColors.warning,
                        icon: "exclamationmark.triangle.fill"
                    )
                }
            }
        }
    }
    
    // MARK: - Building Status Section
    
    private var buildingStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Property Status")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Text("\(routineMetrics.buildingStatuses.count) Properties")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            
            ForEach(priorityBuildings, id: \.buildingId) { building in
                ClientBuildingStatusRow(
                    status: building,
                    onTap: {
                        if let coord = buildingToCoordinate(building.buildingId) {
                            onBuildingTap(coord)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Metrics Row
    
    private var metricsRow: some View {
        HStack(spacing: 12) {
            ClientMetricCard(
                value: "\(Int(routineMetrics.overallCompletion * 100))%",
                label: "Complete",
                color: completionColor,
                icon: "chart.pie.fill"
            )
            
            ClientMetricCard(
                value: "\(activeWorkers.totalActive)",
                label: "Active Workers",
                color: FrancoSphereDesign.DashboardColors.info,
                icon: "person.3.fill"
            )
            
            ClientMetricCard(
                value: "\(Int(complianceStatus.overallScore * 100))%",
                label: "Compliance",
                color: complianceColor,
                icon: "checkmark.shield.fill"
            )
        }
    }
    
    // MARK: - Budget Warning Row
    
    private var budgetWarningRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.title3)
                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Monthly Budget Alert")
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text("\(Int(monthlyMetrics.budgetUtilization * 100))% utilized • \(monthlyMetrics.daysRemaining) days remaining")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            Text("$\(String(format: "%.0f", monthlyMetrics.dailyBurnRate))/day")
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FrancoSphereDesign.DashboardColors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FrancoSphereDesign.DashboardColors.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Compliance Alert Row
    
    private var complianceAlertRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.title3)
                .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Compliance Issues Detected")
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text("\(complianceStatus.criticalViolations) critical • \(complianceStatus.pendingInspections) pending inspections")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FrancoSphereDesign.DashboardColors.critical.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FrancoSphereDesign.DashboardColors.critical.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func buildingToCoordinate(_ buildingId: String) -> CoreTypes.NamedCoordinate? {
        // This would be implemented based on your data source
        // For now, returning nil
        return nil
    }
    
    private var completionColor: Color {
        if routineMetrics.overallCompletion > 0.8 {
            return FrancoSphereDesign.DashboardColors.success
        } else if routineMetrics.overallCompletion > 0.6 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
    
    private var complianceColor: Color {
        if complianceStatus.overallScore >= 0.9 {
            return FrancoSphereDesign.DashboardColors.success
        } else if complianceStatus.overallScore >= 0.8 {
            return FrancoSphereDesign.DashboardColors.info
        } else if complianceStatus.overallScore >= 0.7 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
    
    // MARK: - Supporting Types
    
    enum OverallStatus {
        case onTrack
        case inProgress
        case behindSchedule
        case starting
        
        var displayText: String {
            switch self {
            case .onTrack: return "On Track"
            case .inProgress: return "In Progress"
            case .behindSchedule: return "Behind Schedule"
            case .starting: return "Starting"
            }
        }
        
        var icon: String {
            switch self {
            case .onTrack: return "checkmark.circle.fill"
            case .inProgress: return "clock.fill"
            case .behindSchedule: return "exclamationmark.triangle.fill"
            case .starting: return "play.circle.fill"
            }
        }
    }
}

// MARK: - Building Status Row Component (Prefixed)

struct ClientBuildingStatusRow: View {
    let status: CoreTypes.BuildingRoutineStatus
    let onTap: () -> Void
    
    private var timeBlockColor: Color {
        switch status.timeBlock {
        case .morning: return Color.orange
        case .afternoon: return Color.blue
        case .evening: return Color.purple
        case .overnight: return Color.indigo
        }
    }
    
    private var statusText: String {
        if status.isBehindSchedule {
            return "Behind Schedule"
        } else if status.completionRate >= 1.0 {
            return "Complete"
        } else if status.activeWorkerCount > 0 {
            return "In Progress"
        } else {
            return "Scheduled"
        }
    }
    
    private var statusColor: Color {
        if status.isBehindSchedule {
            return FrancoSphereDesign.DashboardColors.warning
        } else if status.completionRate >= 1.0 {
            return FrancoSphereDesign.DashboardColors.success
        } else if status.activeWorkerCount > 0 {
            return FrancoSphereDesign.DashboardColors.info
        } else {
            return FrancoSphereDesign.DashboardColors.inactive
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Building name and status
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.buildingName)
                            .francoTypography(FrancoSphereDesign.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        
                        HStack(spacing: 8) {
                            // Time block indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(timeBlockColor)
                                    .frame(width: 6, height: 6)
                                Text(status.timeBlock.rawValue.capitalized)
                                    .francoTypography(FrancoSphereDesign.Typography.caption)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                            }
                            
                            Text("•")
                                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                            
                            Text(statusText)
                                .francoTypography(FrancoSphereDesign.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(statusColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Worker count (anonymized)
                    if status.activeWorkerCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                            Text("\(status.activeWorkerCount)")
                                .francoTypography(FrancoSphereDesign.Typography.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(statusColor)
                            .frame(width: geometry.size.width * status.completionRate, height: 6)
                            .animation(.easeOut(duration: 0.5), value: status.completionRate)
                    }
                }
                .frame(height: 6)
                
                // Completion percentage and ETA
                HStack {
                    Text("\(Int(status.completionRate * 100))% Complete")
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    
                    Spacer()
                    
                    if let eta = status.estimatedCompletion {
                        Text("ETA: \(eta, style: .time)")
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Components (Prefixed to avoid conflicts)

struct ClientStatusPill: View {
    let label: String
    let color: Color
    let icon: String?
    
    init(label: String, color: Color, icon: String? = nil) {
        self.label = label
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(label)
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ClientMetricCard: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(label)
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

struct ClientHeroStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        ClientHeroStatusCard(
            routineMetrics: CoreTypes.RealtimeRoutineMetrics(
                overallCompletion: 0.72,
                activeWorkerCount: 5,
                behindScheduleCount: 1,
                buildingStatuses: [
                    "building1": CoreTypes.BuildingRoutineStatus(
                        buildingId: "building1",
                        buildingName: "123 Main St",
                        completionRate: 0.95,
                        activeWorkerCount: 2,
                        isOnSchedule: true
                    ),
                    "building2": CoreTypes.BuildingRoutineStatus(
                        buildingId: "building2",
                        buildingName: "456 Oak Ave",
                        completionRate: 0.60,
                        activeWorkerCount: 1,
                        isOnSchedule: false,
                        estimatedCompletion: Date().addingTimeInterval(7200)
                    ),
                    "building3": CoreTypes.BuildingRoutineStatus(
                        buildingId: "building3",
                        buildingName: "789 Park Pl",
                        completionRate: 0.0,
                        activeWorkerCount: 0,
                        isOnSchedule: true
                    )
                ]
            ),
            activeWorkers: CoreTypes.ActiveWorkerStatus(
                totalActive: 5,
                byBuilding: ["building1": 2, "building2": 1, "building3": 2],
                utilizationRate: 0.83
            ),
            complianceStatus: CoreTypes.ComplianceOverview(
                overallScore: 0.92,
                criticalViolations: 0,
                pendingInspections: 2
            ),
            monthlyMetrics: CoreTypes.MonthlyMetrics(
                currentSpend: 42000,
                monthlyBudget: 50000,
                projectedSpend: 48000,
                daysRemaining: 8
            ),
            onBuildingTap: { building in
                print("Tapped building: \(building.name)")
            }
        )
        .padding()
        .background(FrancoSphereDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}
