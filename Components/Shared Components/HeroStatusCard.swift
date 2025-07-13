//
//  HeroStatusCard.swift
//  FrancoSphere
//
//  ✅ FIXED: TaskProgress constructor in preview
//  ✅ CORRECTED: Proper CoreTypes.TaskProgress usage
//

import SwiftUI
import Foundation
import CoreLocation

struct HeroStatusCard: View {
    let workerId: String
    let currentBuilding: String?
    let weather: WeatherData?
    let progress: TaskProgress
    let onClockInTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with worker info
            headerView
            
            // Weather section
            if let weather = weather {
                weatherView(weather)
            }
            
            // Building status
            buildingStatusView
            
            // Task progress
            taskProgressView
            
            // Clock in prompt
            clockInPromptView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good Morning")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Worker \(workerId)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(progress.overdueTasks > 0 ? Color.orange : Color.green)
                .frame(width: 12, height: 12)
        }
    }
    
    private func weatherView(_ weather: WeatherData) -> some View {
        HStack {
            Image(systemName: weatherIcon(for: weather.condition))
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weather.temperature))°F")
                    .font(.headline)
                
                Text(weather.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if weather.precipitation > 0 {
                Label("\(Int(weather.precipitation * 100))%", systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var buildingStatusView: some View {
        HStack {
            Image(systemName: "building.2")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Building")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(currentBuilding ?? "Not assigned")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
    
    private var taskProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(progress.completed)/\(progress.total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    Rectangle()
                        .fill(progress.overdueTasks > 0 ? Color.orange : Color.green)
                        .frame(width: geometry.size.width * (progress.percentage / 100), height: 6)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
            
            // Status details
            HStack {
                if progress.overdueTasks > 0 {
                    Label("\(progress.overdueTasks) overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text("\(progress.remaining) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var clockInPromptView: some View {
        Button(action: onClockInTap) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .font(.headline)
                
                Text("Clock In")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.blue)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func weatherIcon(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .cloudy:
            return "cloud.fill"
        case .rain:
            return "cloud.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorm:
            return "cloud.bolt.fill"
        case .fog:
            return "cloud.fog.fill"
        default:
            return "sun.max.fill"
        }
    }
}

// MARK: - ✅ FIXED: Preview with correct TaskProgress constructor
#Preview {
    HeroStatusCard(
        workerId: "kevin",
        currentBuilding: "Rubin Museum",
        weather: WeatherData(
            id: UUID().uuidString,
            date: Date(),
            temperature: 72.0,
            feelsLike: 72.0,
            humidity: 65,
            windSpeed: 5.0,
            windDirection: 0,
            precipitation: 0,
            snow: 0,
            condition: .clear,
            uvIndex: 0,
            visibility: 10,
            description: "Clear skies"
        ),
        progress: TaskProgress(
            completed: 8,
            total: 12,
            remaining: 4,
            percentage: 66.7,
            overdueTasks: 1
        ),
        onClockInTap: { print("Clock in tapped") }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
