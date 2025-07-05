import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


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
                Image(systemName: "cloud.rain")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            } else {
                EmptyView()
            }
        }
    }
    
    private var affectedByWeather: Bool {
        // Use the WeatherDataAdapter instead of WeatherService
        return weatherAdapter.shouldRescheduleTask(task)
    }
    
    private var weatherBackgroundColor: Color {
        affectedByWeather ? .blue : .clear
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
                    Image(systemName: currentWeather.condition.icon)
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
    
    // Helper function to handle weather condition color
    private func weatherIconColor(for condition: WeatherCondition) -> Color {
        switch condition {
        case .clear:
            return .yellow
        case .cloudy:
            return .gray
        case .rain:
            return .blue
        case .snow:
            return .cyan
        case .thunderstorm:
            return .purple
        case .fog:
            return .gray
        case .other:
            return .red
        default:
            break
        }
    }
}

// Extension to make it easier to apply the modifier
extension View {
    func withWeatherStatus(for building: NamedCoordinate) -> some View {
        self.modifier(WeatherStatusBuildingModifier(building: building))
    }
}
