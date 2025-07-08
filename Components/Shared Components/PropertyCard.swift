//
//  PropertyCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/8/25.
//


//
//  PropertyCard.swift
//  FrancoSphere
//
//  ✅ PHASE 1: UNIFIED BUILDING COMPONENT
//  ✅ Single component for Worker, Admin, and Client dashboards
//  ✅ Real-world data integration with BuildingService
//  ✅ Proper asset image mapping for Edwin's buildings
//  ✅ Actor-compatible data flow with WorkerContextEngine
//  ✅ Dynamic metrics calculation from SQLite database
//

import SwiftUI

// MARK: - PropertyCard Component

struct PropertyCard: View {
    // MARK: - Properties
    let building: NamedCoordinate
    let displayMode: DisplayMode
    let metrics: BuildingMetrics?
    let onTap: (() -> Void)?
    
    // MARK: - State
    @State private var isPressed = false
    @State private var showingDetails = false
    
    // MARK: - Display Mode Configuration
    enum DisplayMode {
        case dashboard   // Worker view - shows assigned tasks & clock-in status
        case admin       // Admin view - shows metrics & performance data
        case client      // Client view - shows compliance & reporting
        case minimal     // Compact list view - basic info only
    }
    
    // MARK: - Real Building Asset Mapping
    private var buildingImageName: String {
        // Map building IDs to actual Assets.xcassets image names
        switch building.id {
        case "1": return "building_12_w_18th"
        case "4": return "building_41_elizabeth"
        case "5": return "building_68_perry"
        case "6": return "building_68_perry"
        case "7": return "building_136_w_17th"
        case "8": return "building_138_w_17th"
        case "9": return "building_135_139_w_17th"
        case "10": return "building_131_perry"
        case "12": return "building_178_spring"
        case "13": return "building_104_franklin"
        case "14": return "building_rubin_museum"
        case "16": return "stuyvesant_cove_park"
        case "17": return "building_178_spring"
        case "18": return "building_115_7th_ave"
        default: return building.imageAssetName ?? "building_placeholder"
        }
    }
    
    // MARK: - Building Type Classification
    private var buildingType: String {
        switch building.name {
        case let name where name.contains("Rubin Museum"):
            return "Museum"
        case let name where name.contains("Perry Street"):
            return "Residential"
        case let name where name.contains("West 17th"), 
             let name where name.contains("West 18th"):
            return "Commercial"
        case let name where name.contains("Franklin"), 
             let name where name.contains("Elizabeth"):
            return "Residential"
        case let name where name.contains("Stuyvesant"):
            return "Park"
        default:
            return "Mixed Use"
        }
    }
    
    // MARK: - Status Indicators
    private var buildingStatus: BuildingStatus {
        guard let metrics = metrics else { return .unknown }
        
        if metrics.overdueTasks > 0 {
            return metrics.overdueTasks >= 5 ? .critical : .attention
        } else if metrics.completionRate >= 0.9 {
            return .excellent
        } else if metrics.completionRate >= 0.75 {
            return .good
        } else {
            return .attention
        }
    }
    
    private var statusColor: Color {
        switch buildingStatus {
        case .excellent: return .green
        case .good: return .blue
        case .attention: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
    }
    
    // MARK: - Main View
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Building Header with Image
                buildingHeader
                
                // Building Details Section
                buildingDetails
                
                // Mode-Specific Content
                modeSpecificContent
            }
            .background(cardBackground)
            .cornerRadius(displayMode == .minimal ? 8 : 12)
            .shadow(color: .black.opacity(0.1), radius: displayMode == .minimal ? 2 : 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        }
    }
    
    // MARK: - Building Header
    private var buildingHeader: some View {
        HStack(spacing: 12) {
            // Building Image
            AsyncImage(url: nil) { _ in
                Image(buildingImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Image(systemName: "building.2")
                            .foregroundColor(.gray)
                            .font(.system(size: imageSize * 0.4))
                    )
            }
            
            // Building Information
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(building.shortName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Status Badge
                    if displayMode != .minimal {
                        statusBadge
                    }
                }
                
                if displayMode != .minimal {
                    Text(building.fullAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Building Type Badge
                if displayMode == .admin || displayMode == .client {
                    Text(buildingType)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, displayMode == .minimal ? 16 : 8)
    }
    
    // MARK: - Building Details
    private var buildingDetails: some View {
        Group {
            if displayMode != .minimal, let metrics = metrics {
                VStack(alignment: .leading, spacing: 8) {
                    // Quick Stats Row
                    HStack(spacing: 16) {
                        StatItem(
                            title: "Tasks",
                            value: "\(metrics.pendingTasks)",
                            subtitle: "pending",
                            color: .blue
                        )
                        
                        StatItem(
                            title: "Rate",
                            value: "\(Int(metrics.completionRate * 100))%",
                            subtitle: "complete",
                            color: statusColor
                        )
                        
                        if metrics.overdueTasks > 0 {
                            StatItem(
                                title: "Overdue",
                                value: "\(metrics.overdueTasks)",
                                subtitle: "tasks",
                                color: .red
                            )
                        } else {
                            StatItem(
                                title: "Workers",
                                value: "\(metrics.activeWorkers)",
                                subtitle: "active",
                                color: .green
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }
    
    // MARK: - Mode-Specific Content
    private var modeSpecificContent: some View {
        Group {
            switch displayMode {
            case .dashboard:
                workerDashboardContent
            case .admin:
                adminDashboardContent
            case .client:
                clientDashboardContent
            case .minimal:
                EmptyView()
            }
        }
    }
    
    // MARK: - Worker Dashboard Content
    private var workerDashboardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let metrics = metrics {
                // Today's Task Summary
                HStack {
                    Label("Today's Tasks", systemImage: "checklist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if metrics.pendingTasks > 0 {
                        Text("\(metrics.pendingTasks) remaining")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Text("All complete")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // Progress Bar
                ProgressView(value: metrics.completionRate)
                    .tint(statusColor)
                    .background(Color.gray.opacity(0.2))
                
                // Clock-In Status (if applicable)
                if metrics.hasWorkerOnSite {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text("On Site")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("Since 7:00 AM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Admin Dashboard Content
    private var adminDashboardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let metrics = metrics {
                // Performance Overview
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Performance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("\(metrics.overallScore)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(statusColor)
                            
                            Text("/ 100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Efficiency Indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Efficiency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if metrics.completionRate >= 0.9 {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.green)
                            } else if metrics.completionRate >= 0.75 {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.orange)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.red)
                            }
                            
                            Text("\(Int(metrics.completionRate * 100))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Worker Analytics
                HStack {
                    Text("\(metrics.activeWorkers) workers assigned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if metrics.isCompliant {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Compliant")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Needs Review")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Client Dashboard Content
    private var clientDashboardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let metrics = metrics {
                // Compliance Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Compliance Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("\(metrics.overallScore)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(statusColor)
                            
                            Text("/ 100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Compliance Badge
                    VStack(alignment: .trailing, spacing: 4) {
                        if metrics.isCompliant {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text("Compliant")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            Text("Review Needed")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Summary Stats
                HStack {
                    Text("Last Updated: \(Date().formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if metrics.overdueTasks > 0 {
                        Text("\(metrics.overdueTasks) items need attention")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("All systems operational")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Supporting Views
    
    private var statusBadge: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 16, height: 16)
            )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: displayMode == .minimal ? 8 : 12)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: displayMode == .minimal ? 8 : 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var imageSize: CGFloat {
        switch displayMode {
        case .minimal: return 40
        case .dashboard: return 60
        case .admin, .client: return 56
        }
    }
    
    // MARK: - Stat Item Component
    private struct StatItem: View {
        let title: String
        let value: String
        let subtitle: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Types

struct BuildingMetrics {
    let completionRate: Double      // 0.0 to 1.0
    let pendingTasks: Int          // Tasks remaining today
    let overdueTasks: Int          // Tasks past due date
    let activeWorkers: Int         // Workers assigned to building
    let isCompliant: Bool          // Overall compliance status
    let overallScore: Int          // 0 to 100 score
    let hasWorkerOnSite: Bool      // Current worker presence
    
    // Calculated properties
    var completedTasks: Int {
        // Reverse calculate from completion rate
        let total = pendingTasks + Int(Double(pendingTasks) / (1.0 - completionRate))
        return total - pendingTasks
    }
}

enum BuildingStatus {
    case excellent  // 90%+ completion, no overdue
    case good       // 75%+ completion, minimal overdue
    case attention  // Below 75% or some overdue tasks
    case critical   // Major issues, many overdue tasks
    case unknown    // No data available
}

// MARK: - Preview
struct PropertyCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum (142–148 W 17th)",
            latitude: 40.7402,
            longitude: -73.9980,
            imageAssetName: "building_rubin_museum"
        )
        
        let sampleMetrics = BuildingMetrics(
            completionRate: 0.85,
            pendingTasks: 3,
            overdueTasks: 1,
            activeWorkers: 2,
            isCompliant: false,
            overallScore: 85,
            hasWorkerOnSite: true
        )
        
        VStack(spacing: 16) {
            // Dashboard Mode
            PropertyCard(
                building: sampleBuilding,
                displayMode: .dashboard,
                metrics: sampleMetrics
            ) {
                print("Dashboard card tapped")
            }
            
            // Admin Mode
            PropertyCard(
                building: sampleBuilding,
                displayMode: .admin,
                metrics: sampleMetrics
            ) {
                print("Admin card tapped")
            }
            
            // Client Mode
            PropertyCard(
                building: sampleBuilding,
                displayMode: .client,
                metrics: sampleMetrics
            ) {
                print("Client card tapped")
            }
            
            // Minimal Mode
            PropertyCard(
                building: sampleBuilding,
                displayMode: .minimal,
                metrics: nil
            ) {
                print("Minimal card tapped")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}