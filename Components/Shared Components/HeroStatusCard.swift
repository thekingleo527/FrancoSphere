//
//  HeroStatusCard.swift
import CoreLocation
//  FrancoSphere
//

import SwiftUI
import Foundation

struct HeroStatusCard: View {
    let workerId: String
    let currentBuilding: String?
    let weather: WeatherData?
    let progress: TaskProgress
    let onClockInTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with worker status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Worker ID: \(workerId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Weather info
                if let weather = weather {
                    weatherView(weather)
                }
            }
            
            // Progress Section
            VStack(spacing: 12) {
                HStack {
                    Text("Today's Progress")
                        .font(.headline)
                    Spacer()
                    Text("\(progress.completed)/\(progress.total)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: progress.percentage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                HStack {
                    Text("\(Int(progress.percentage))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if progress.overdueTasks > 0 {
                        Text("\(progress.overdueTasks) Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Current Building Status
            if let building = currentBuilding {
                buildingStatusView(building)
            } else {
                clockInPromptView()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    @ViewBuilder
    private func weatherView(_ weather: WeatherData) -> some View {
        HStack(spacing: 8) {
            Image(systemName: weatherIcon(for: weather.condition))
                .foregroundColor(weatherColor(for: weather.condition))
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(weather.temperature))°F")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(weather.condition.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func buildingStatusView(_ building: String) -> some View {
        HStack {
            Image(systemName: "building.2.fill")
                .foregroundColor(.blue)
            
            Text("Current: \(building)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button("Clock Out") {
                onClockInTap()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    @ViewBuilder
    private func clockInPromptView() -> some View {
        HStack {
            Image(systemName: "location.circle")
                .foregroundColor(.orange)
            
            Text("Ready to start your shift")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button("Clock In") {
                onClockInTap()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private func weatherIcon(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rain, .rainy:
            return "cloud.rain.fill"
        case .snow, .snowy:
            return "cloud.snow.fill"
        case .storm, .stormy:
            return "cloud.bolt.fill"
        case .fog, .foggy:
            return "cloud.fog.fill"
        case .windy:
            return "wind"
        }
    }
    
    private func weatherColor(for condition: WeatherCondition) -> Color {
        switch condition {
        case .clear, .sunny:
            return .yellow
        case .cloudy:
            return .gray
        case .rain, .rainy:
            return .blue
        case .snow, .snowy:
            return .cyan
        case .storm, .stormy:
            return .purple
        case .fog, .foggy:
            return .gray
        case .windy:
            return .green
        }
    }
}

// MARK: - Preview (Technically Correct)
#Preview {
    HeroStatusCard(
        workerId: "kevin",
        currentBuilding: "Rubin Museum",
        weather: WeatherData(
            condition: .sunny,
            temperature: 72.0,
            humidity: 65,
            windSpeed: 8.5,
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
