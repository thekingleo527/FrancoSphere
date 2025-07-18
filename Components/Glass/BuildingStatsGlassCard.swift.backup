//
//  BuildingStatsGlassCard.swift
//  FrancoSphere
//
//  🔧 FIXED: All exhaustive switch errors resolved
//

import SwiftUI

struct BuildingStatsGlassCard: View {
    let pendingTasksCount: Int
    let completedTasksCount: Int
    let assignedWorkersCount: Int
    let weatherRisk: WeatherRiskLevel
    
    enum WeatherRiskLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Building Stats")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    weatherIndicator
                }
                
                // Stats Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    statItem(
                        title: "Pending",
                        value: "\(pendingTasksCount)",
                        color: pendingTasksColor
                    )
                    
                    statItem(
                        title: "Completed",
                        value: "\(completedTasksCount)",
                        color: .green
                    )
                }
                
                // Progress breakdown
                if pendingTasksCount > 0 {
                    priorityBreakdown
                }
                
                // Bottom stats
                HStack {
                    Text("Workers: \(assignedWorkersCount)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(getCompletionRate())% Complete")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Weather Indicator
    
    @ViewBuilder
    private var weatherIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(weatherRiskColor)
                .frame(width: 8, height: 8)
            
            Text(weatherRisk.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Priority Breakdown
    
    @ViewBuilder
    private var priorityBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority Breakdown")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 12) {
                priorityItem(
                    count: getHighPriorityCount(),
                    label: "High",
                    color: .red
                )
                
                priorityItem(
                    count: getMediumPriorityCount(),
                    label: "Med",
                    color: .orange
                )
                
                priorityItem(
                    count: getLowPriorityCount(),
                    label: "Low",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
    
    @ViewBuilder
    private func priorityItem(count: Int, label: String, color: Color) -> some View {
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
    
    private var pendingTasksColor: Color {
        switch pendingTasksCount {
        case 0: return .green
        case 1...3: return .yellow
        case 4...8: return .orange
        default: return .red
        }
    }
    
    private var weatherRiskColor: Color {
        switch weatherRisk {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }
    
    private func getHighPriorityCount() -> Int {
        max(1, pendingTasksCount / 4)
    }
    
    private func getMediumPriorityCount() -> Int {
        max(1, pendingTasksCount / 2)
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

// MARK: - Preview
struct BuildingStatsGlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
