//
//  BuildingStatsGlassCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


//
//  BuildingStatsGlassCard.swift
//  FrancoSphere
//
//  Glass card displaying building statistics and metrics
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct BuildingStatsGlassCard: View {
    let pendingTasksCount: Int
    let completedTasksCount: Int
    let assignedWorkersCount: Int
    let weatherRisk: WeatherRiskLevel?
    
    enum WeatherRiskLevel {
        case low, moderate, high, extreme
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .extreme: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "sun.max"
            case .medium: return "cloud"
            case .high: return "cloud.rain"
            case .extreme: return "exclamationmark.triangle"
            }
        }
        
        var title: String {
            switch self {
            case .low: return "Low Risk"
            case .medium: return "Moderate"
            case .high: return "High Risk"
            case .extreme: return "Extreme"
            }
        }
    }
    
    var body: some View {
        GlassCard(intensity: .thin) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Building Overview")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let risk = weatherRisk {
                        weatherRiskBadge(risk)
                    }
                }
                
                // Stats grid
                HStack(spacing: 0) {
                    statItem(
                        count: pendingTasksCount,
                        label: "Pending",
                        subLabel: "Tasks",
                        icon: "clock.circle",
                        color: pendingTasksCount > 5 ? .orange : .blue,
                        isFirst: true
                    )
                    
                    statDivider()
                    
                    statItem(
                        count: completedTasksCount,
                        label: "Completed",
                        subLabel: "Today",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    statDivider()
                    
                    statItem(
                        count: assignedWorkersCount,
                        label: "Workers",
                        subLabel: "Assigned",
                        icon: "person.2.circle",
                        color: .purple,
                        isLast: true
                    )
                }
                
                // Additional metrics row
                if pendingTasksCount > 0 {
                    taskBreakdownRow
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Sub-components
    
    private func statItem(
        count: Int,
        label: String,
        subLabel: String,
        icon: String,
        color: Color,
        isFirst: Bool = false,
        isLast: Bool = false
    ) -> some View {
        VStack(spacing: 8) {
            // Icon and count
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Labels
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subLabel)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isFirst || isLast ? 0 : 8)
    }
    
    private func statDivider() -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 1, height: 60)
    }
    
    private func weatherRiskBadge(_ risk: WeatherRiskLevel) -> some View {
        HStack(spacing: 6) {
            Image(systemName: risk.icon)
                .font(.caption)
                .foregroundColor(risk.color)
            
            Text(risk.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(risk.color.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(risk.color.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(16)
    }
    
    private var taskBreakdownRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Task Breakdown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("Priority Distribution")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Priority breakdown (mock data for now)
            HStack(spacing: 12) {
                priorityIndicator(count: getHighPriorityCount(), label: "High", color: .red)
                priorityIndicator(count: getMediumPriorityCount(), label: "Medium", color: .orange)
                priorityIndicator(count: getLowPriorityCount(), label: "Low", color: .green)
                
                Spacer()
                
                // Completion rate
                HStack(spacing: 6) {
                    Text("\(getCompletionRate())%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("complete")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.top, 8)
    }
    
    private func priorityIndicator(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Computed Properties
    
    private func getHighPriorityCount() -> Int {
        max(1, pendingTasksCount / 4) // Mock calculation
    }
    
    private func getMediumPriorityCount() -> Int {
        max(1, pendingTasksCount / 2) // Mock calculation
    }
    
    private func getLowPriorityCount() -> Int {
        pendingTasksCount - getHighPriorityCount() - getMediumPriorityCount()
    }
    
    private func getCompletionRate() -> Int {
        let total = pendingTasksCount + completedTasksCount
        guard total > 0 else { return 0 }
        return Int((Double(completedTasksCount) / Double(total)) * 100)
    }
}

// MARK: - Extension for Weather Integration

extension BuildingStatsGlassCard.WeatherRiskLevel {
    init?(from weatherData: WeatherData) {
        switch weatherData.outdoorWorkRisk {
        case .low:
            self = .low
        case .medium:
            self = .medium
        case .high:
            self = .high
        case .extreme:
            self = .extreme
        }
    }
}

// MARK: - Preview

struct BuildingStatsGlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            FrancoSphereColors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                BuildingStatsGlassCard(
                    pendingTasksCount: 8,
                    completedTasksCount: 12,
                    assignedWorkersCount: 3,
                    weatherRisk: .medium
                )
                
                BuildingStatsGlassCard(
                    pendingTasksCount: 2,
                    completedTasksCount: 15,
                    assignedWorkersCount: 1,
                    weatherRisk: .low
                )
                
                BuildingStatsGlassCard(
                    pendingTasksCount: 15,
                    completedTasksCount: 5,
                    assignedWorkersCount: 4,
                    weatherRisk: .high
                )
                
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}