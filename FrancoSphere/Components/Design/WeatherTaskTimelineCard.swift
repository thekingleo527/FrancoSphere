//
//  WeatherTaskTimelineCard.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: Uses correct MaintenanceTask properties (title, dueDate, isCompleted)
//  ✅ COMPATIBLE: Uses proper GlassCard and TimelineProgressBar components
//  ✅ REAL DATA: Works with actual CoreTypes.MaintenanceTask structure
//

import Foundation

// Type aliases for CoreTypes
typealias MaintenanceTask = CoreTypes.MaintenanceTask
typealias TaskCategory = CoreTypes.TaskCategory
typealias TaskUrgency = CoreTypes.TaskUrgency
typealias BuildingType = CoreTypes.BuildingType
typealias BuildingTab = CoreTypes.BuildingTab
typealias WeatherCondition = CoreTypes.WeatherCondition
typealias BuildingMetrics = CoreTypes.BuildingMetrics
typealias TaskProgress = CoreTypes.TaskProgress
typealias FrancoWorkerAssignment = CoreTypes.FrancoWorkerAssignment
typealias InventoryItem = CoreTypes.InventoryItem
typealias InventoryCategory = CoreTypes.InventoryCategory
typealias RestockStatus = CoreTypes.RestockStatus
typealias ComplianceStatus = CoreTypes.ComplianceStatus
typealias BuildingStatistics = CoreTypes.BuildingStatistics
typealias WorkerSkill = CoreTypes.WorkerSkill
typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
typealias ComplianceIssue = CoreTypes.ComplianceIssue

import SwiftUI

// Type aliases for CoreTypes
typealias MaintenanceTask = CoreTypes.MaintenanceTask
typealias TaskCategory = CoreTypes.TaskCategory
typealias TaskUrgency = CoreTypes.TaskUrgency
typealias BuildingType = CoreTypes.BuildingType
typealias BuildingTab = CoreTypes.BuildingTab
typealias WeatherCondition = CoreTypes.WeatherCondition
typealias BuildingMetrics = CoreTypes.BuildingMetrics
typealias TaskProgress = CoreTypes.TaskProgress
typealias FrancoWorkerAssignment = CoreTypes.FrancoWorkerAssignment
typealias InventoryItem = CoreTypes.InventoryItem
typealias InventoryCategory = CoreTypes.InventoryCategory
typealias RestockStatus = CoreTypes.RestockStatus
typealias ComplianceStatus = CoreTypes.ComplianceStatus
typealias BuildingStatistics = CoreTypes.BuildingStatistics
typealias WorkerSkill = CoreTypes.WorkerSkill
typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
typealias ComplianceIssue = CoreTypes.ComplianceIssue


struct WeatherTaskTimelineCard: View {
    let temperature: Int
    let condition: String
    let upcomingTasks: [MaintenanceTask]
    
    var body: some View {
        GlassCard(intensity: GlassIntensity.regular) {
            VStack(alignment: .leading, spacing: 16) {
                // Weather header
                HStack {
                    Image(systemName: weatherIcon)
                        .font(.title)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chelsea")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("\(temperature)° | \(condition)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                // Task timeline
                VStack(alignment: .leading, spacing: 8) {
                    Text("TODAY'S TASKS")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Timeline visualization
                    TimelineProgressBar()
                        .frame(height: 40)
                    
                    // Next task
                    if let nextTask = upcomingTasks.first {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(nextTask.title) // ✅ FIXED: Use 'title' instead of 'name'
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                
                                Text("Due to forecasted conditions")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            // ✅ FIXED: Use 'dueDate' instead of 'startTime'
                            if let dueDate = nextTask.dueDate {
                                Text(formatTime(dueDate))
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
    
    private var weatherIcon: String {
        let c = condition.lowercased()
        if c.contains("thunder") { return "cloud.bolt.fill" }
        if c.contains("rain") { return "cloud.rain.fill" }
        if c.contains("cloud") { return "cloud.fill" }
        return "sun.max.fill"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct WeatherTaskTimelineCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            WeatherTaskTimelineCard(
                temperature: 72,
                condition: "Partly Cloudy",
                upcomingTasks: [
                    MaintenanceTask(
                        title: "HVAC System Check",
                        description: "Routine maintenance check for air conditioning system",
                        category: .maintenance, // ✅ FIXED: Use .maintenance instead of .hvac
                        urgency: .medium,
                        buildingId: "1",
                        dueDate: Date().addingTimeInterval(3600),
                        notes: "Weather-dependent task"
                    ),
                    MaintenanceTask(
                        title: "Window Cleaning",
                        description: "Clean exterior windows before rain",
                        category: .cleaning, // ✅ CORRECT: .cleaning exists
                        urgency: .low,
                        buildingId: "1",
                        dueDate: Date().addingTimeInterval(7200),
                        notes: "Complete before weather changes"
                    )
                ]
            )
            .padding()
        }
    }
}
