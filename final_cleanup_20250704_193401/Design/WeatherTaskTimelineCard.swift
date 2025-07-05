import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

//
//  WeatherTaskTimelineCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


// Components/Weather/WeatherTaskTimelineCard.swift
import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct WeatherTaskTimelineCard: View {
    let temperature: Int
    let condition: String
    let upcomingTasks: [MaintenanceTask]
    
    var body: some View {
        GlassCard(intensity: .regular) {
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
                                Text(nextTask.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                
                                Text("Due to forecasted conditions")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            if let startTime = nextTask.startTime {
                                Text(formatTime(startTime))
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