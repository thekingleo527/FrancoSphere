//
//  WeatherViewModifier.swift
//  FrancoSphere
//
//  ✅ FIXED: Added missing switch cases for exhaustive pattern matching
//  ✅ FIXED: Uses proper WeatherData.condition property
//

import Foundation
import SwiftUI

// A ViewModifier to add weather-sensitive styling to task views
struct WeatherSensitiveTaskModifier: ViewModifier {
    let task: MaintenanceTask
    // Use StateObject for singleton access instead of ObservedObject to avoid conformance issues
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                weatherOverlay
                    .padding(8)
                    .background(weatherBackgroundColor.opacity(0.8))
                    .cornerRadius(8)
                    .padding(6),
                alignment: .topTrailing
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(weatherBorderColor, lineWidth: affectedByWeather ? 2 : 0)
            )
    }
    
    private var weatherOverlay: some View {
        Group {
            if affectedByWeather {
                Image(systemName: weatherIconName)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            } else {
                EmptyView()
            }
        }
    }
    
    private var affectedByWeather: Bool {
        return weatherAdapter.shouldRescheduleTask(task)
    }
    
    private var weatherIconName: String {
        guard let currentWeather = weatherAdapter.currentWeather else {
            return "cloud.rain"
        }
        
        // ✅ FIXED: Added exhaustive switch cases
        switch currentWeather.condition {
        case .clear, .sunny:
            return "sun.max"
        case .cloudy:
            return "cloud"
        case .rainy:
            return "cloud.rain"
        case .snowy:
            return "cloud.snow"
        case .stormy:
            return "cloud.bolt"
        case .foggy:
            return "cloud.fog"
        case .windy:
            return "wind"
        }
    }
    
    private var weatherBackgroundColor: Color {
        guard let currentWeather = weatherAdapter.currentWeather else {
            return .clear
        }
        
        // ✅ FIXED: Added exhaustive switch cases
        switch currentWeather.condition {
        case .clear, .sunny:
            return .yellow
        case .cloudy:
            return .gray
        case .rainy:
            return .blue
        case .snowy:
            return .cyan
        case .stormy:
            return .purple
        case .foggy:
            return .gray
        case .windy:
            return .orange
        }
    }
    
    private var weatherBorderColor: Color {
        affectedByWeather ? .blue : .clear
    }
}

// Extension to make it easier to apply the modifier
extension View {
    func weatherSensitive(for task: MaintenanceTask) -> some View {
        self.modifier(WeatherSensitiveTaskModifier(task: task))
    }
}

// A ViewModifier to add weather status information to building views
struct WeatherStatusBuildingModifier: ViewModifier {
    let building: NamedCoordinate
    // Use StateObject for singleton access instead of ObservedObject
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                weatherIndicator
                    .padding(6),
                alignment: .topTrailing
            )
    }
    
    private var weatherIndicator: some View {
        Group {
            if let currentWeather = weatherAdapter.currentWeather {
                HStack(spacing: 4) {
                    Image(systemName: weatherIconName(for: currentWeather.condition))
                        .foregroundColor(weatherIconColor(for: currentWeather.condition))
                        .font(.system(size: 12))
                    
                    Text(currentWeather.formattedTemperature)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(4)
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(8)
            } else {
                EmptyView()
            }
        }
    }
    
    // Helper function to handle weather condition icon
    private func weatherIconName(for condition: WeatherCondition) -> String {
        // ✅ FIXED: Added exhaustive switch cases
        switch condition {
        case .clear, .sunny:
            return "sun.max"
        case .cloudy:
            return "cloud"
        case .rainy:
            return "cloud.rain"
        case .snowy:
            return "cloud.snow"
        case .stormy:
            return "cloud.bolt"
        case .foggy:
            return "cloud.fog"
        case .windy:
            return "wind"
        }
    }
    
    // Helper function to handle weather condition color
    private func weatherIconColor(for condition: WeatherCondition) -> Color {
        // ✅ FIXED: Added exhaustive switch cases
        switch condition {
        case .clear, .sunny:
            return .yellow
        case .cloudy:
            return .gray
        case .rainy:
            return .blue
        case .snowy:
            return .cyan
        case .stormy:
            return .purple
        case .foggy:
            return .gray.opacity(0.7)
        case .windy:
            return .orange
        }
    }
}

// Extension to make it easier to apply the modifier
extension View {
    func withWeatherStatus(for building: NamedCoordinate) -> some View {
        self.modifier(WeatherStatusBuildingModifier(building: building))
    }
}
