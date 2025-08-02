//
//  ClientHeroStatusCard.swift
//  FrancoSphere v6.0
//
//  Hero status card specifically designed for client dashboard
//  Shows real-time routine status across all client buildings
//

import SwiftUI
import MapKit

struct ClientHeroStatusCard: View {
    // Real-time data inputs
    let routineMetrics: RealtimeRoutineMetrics
    let activeWorkers: ActiveWorkerStatus
    let complianceStatus: ClientComplianceStatus  // Renamed to avoid ambiguity
    let monthlyMetrics: MonthlyMetrics
    
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
    
    private var priorityBuildings: [ClientBuildingRoutineStatus] {
        // Get buildings that need attention first
        routineMetrics.buildingStatuses.values
            .map { ClientBuildingRoutineStatus(from: $0) }
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
                StatusPill(
                    label: overallStatus.displayText,
                    color: statusColor,
                    icon: overallStatus.icon
                )
                
                if routineMetrics.behindScheduleCount > 0 {
                    StatusPill(
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
                BuildingStatusRow(
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
            MetricCard(
                value: "\(Int(routineMetrics.overallCompletion * 100))%",
                label: "Complete",
                color: completionColor,
                icon: "chart.pie.fill"
            )
            
            MetricCard(
                value: "\(activeWorkers.totalActive)",
                label: "Active Workers",
                color: FrancoSphereDesign.DashboardColors.info,
                icon: "person.3.fill"
            )
            
            MetricCard(
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
        // This would need to be implemented based on your data model
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

// MARK: - Building Status Row Component

struct BuildingStatusRow: View {
    let status: ClientBuildingRoutineStatus
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

// MARK: - Supporting Components

struct StatusPill: View {
    let label: String
    let color: Color
    let icon: String?
    
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

struct MetricCard: View {
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

// MARK: - Data Models (Client-specific to avoid ambiguity)

struct RealtimeRoutineMetrics {
    var overallCompletion: Double = 0.0
    var activeWorkerCount: Int = 0
    var behindScheduleCount: Int = 0
    var buildingStatuses: [String: ClientBuildingRoutineStatus] = [:]
    
    var hasActiveIssues: Bool {
        behindScheduleCount > 0 || buildingStatuses.contains { $0.value.hasIssue }
    }
}

struct ClientBuildingRoutineStatus {
    let buildingId: String
    let buildingName: String
    let completionRate: Double
    let timeBlock: TimeBlock
    let activeWorkerCount: Int
    let isOnSchedule: Bool
    let estimatedCompletion: Date?
    let hasIssue: Bool
    
    var isBehindSchedule: Bool {
        !isOnSchedule && completionRate < expectedCompletionForTime()
    }
    
    private func expectedCompletionForTime() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 7..<11: return 0.3  // Morning should be 30% done
        case 11..<15: return 0.6 // Afternoon should be 60% done
        case 15..<19: return 0.9 // Evening should be 90% done
        default: return 1.0
        }
    }
    
    init(from status: ClientBuildingRoutineStatus) {
        self.buildingId = status.buildingId
        self.buildingName = status.buildingName
        self.completionRate = status.completionRate
        self.timeBlock = status.timeBlock
        self.activeWorkerCount = status.activeWorkerCount
        self.isOnSchedule = status.isOnSchedule
        self.estimatedCompletion = status.estimatedCompletion
        self.hasIssue = status.hasIssue
    }
    
    init(
        buildingId: String,
        buildingName: String,
        completionRate: Double,
        activeWorkerCount: Int,
        isOnSchedule: Bool,
        estimatedCompletion: Date? = nil,
        hasIssue: Bool = false
    ) {
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.completionRate = completionRate
        self.timeBlock = TimeBlock.current
        self.activeWorkerCount = activeWorkerCount
        self.isOnSchedule = isOnSchedule
        self.estimatedCompletion = estimatedCompletion
        self.hasIssue = hasIssue
    }
    
    enum TimeBlock: String {
        case morning = "morning"
        case afternoon = "afternoon"
        case evening = "evening"
        case overnight = "overnight"
        
        static var current: TimeBlock {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 6..<12: return .morning
            case 12..<17: return .afternoon
            case 17..<22: return .evening
            default: return .overnight
            }
        }
    }
}

struct ActiveWorkerStatus {
    let totalActive: Int
    let byBuilding: [String: Int]
    let utilizationRate: Double
}

struct ClientComplianceStatus {
    let overallScore: Double
    let criticalViolations: Int
    let pendingInspections: Int
    let lastUpdated: Date
}

struct MonthlyMetrics {
    let currentSpend: Double
    let monthlyBudget: Double
    let projectedSpend: Double
    let daysRemaining: Int
    
    var budgetUtilization: Double {
        currentSpend / monthlyBudget
    }
    
    var isOverBudget: Bool {
        projectedSpend > monthlyBudget
    }
    
    var dailyBurnRate: Double {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        let daysPassed = daysInMonth - daysRemaining
        return daysPassed > 0 ? currentSpend / Double(daysPassed) : 0
    }
}

// MARK: - Preview

struct ClientHeroStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        ClientHeroStatusCard(
            routineMetrics: RealtimeRoutineMetrics(
                overallCompletion: 0.72,
                activeWorkerCount: 5,
                behindScheduleCount: 1,
                buildingStatuses: [
                    "building1": ClientBuildingRoutineStatus(
                        buildingId: "building1",
                        buildingName: "123 Main St",
                        completionRate: 0.95,
                        activeWorkerCount: 2,
                        isOnSchedule: true
                    ),
                    "building2": ClientBuildingRoutineStatus(
                        buildingId: "building2",
                        buildingName: "456 Oak Ave",
                        completionRate: 0.60,
                        activeWorkerCount: 1,
                        isOnSchedule: false,
                        estimatedCompletion: Date().addingTimeInterval(7200)
                    ),
                    "building3": ClientBuildingRoutineStatus(
                        buildingId: "building3",
                        buildingName: "789 Park Pl",
                        completionRate: 0.0,
                        activeWorkerCount: 0,
                        isOnSchedule: true
                    )
                ]
            ),
            activeWorkers: ActiveWorkerStatus(
                totalActive: 5,
                byBuilding: ["building1": 2, "building2": 1, "building3": 2],
                utilizationRate: 0.83
            ),
            complianceStatus: ClientComplianceStatus(
                overallScore: 0.92,
                criticalViolations: 0,
                pendingInspections: 2,
                lastUpdated: Date()
            ),
            monthlyMetrics: MonthlyMetrics(
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
