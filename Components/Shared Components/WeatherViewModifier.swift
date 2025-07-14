//
//  WeatherViewModifier.swift
//  FrancoSphere
//
//  ✅ V6.0 FIXED: Exhaustive switch statements with all WeatherCondition cases
//  ✅ INTEGRATION: Uses existing WeatherDataAdapter properly
//  ✅ COMPATIBILITY: Fixed StateObject access patterns
//

import SwiftUI

struct WeatherViewModifier: ViewModifier {
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    @State private var showWeatherAlert = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                weatherOverlay,
                alignment: .topTrailing
            )
            .alert("Weather Alert", isPresented: $showWeatherAlert) {
                Button("OK") {}
            } message: {
                Text(weatherAlertMessage)
            }
            .onAppear {
                loadCurrentWeather()
            }
    }
    
    @ViewBuilder
    private var weatherOverlay: some View {
        if let weather = weatherAdapter.currentWeather {
            HStack(spacing: 8) {
                Image(systemName: getWeatherIcon(for: weather.condition))
                    .foregroundColor(getWeatherColor(for: weather.condition))
                
                Text(weather.formattedTemperature)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.8))
            .clipShape(Capsule())
            .shadow(radius: 2)
            .padding()
            .onTapGesture {
                checkWeatherAlerts()
            }
        }
    }
    
    private func getWeatherIcon(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sun.max"
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .snowy:
            return "cloud.snow.fill"
        case .stormy:
            return "cloud.bolt.fill"
        case .foggy:
            return "cloud.fog.fill"
        case .windy:
            return "wind"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .overcast:
            return "cloud.fill"
        }
    }
    
    private func getWeatherColor(for condition: WeatherCondition) -> Color {
        switch condition {
        case .clear:
            return .yellow
        case .sunny:
            return .orange
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
            return .mint
        case .partlyCloudy:
            return .gray
        case .overcast:
            return .gray
        }
    }
    
    private var weatherAlertMessage: String {
        guard let weather = weatherAdapter.currentWeather else {
            return "No weather data available"
        }
        
        switch weather.condition {
        case .stormy:
            return "Severe weather alert: Storm conditions detected"
        case .rainy:
            if weather.precipitation > 0.5 {
                return "Heavy rain alert: Consider indoor tasks"
            } else {
                return "Rain detected: Monitor outdoor conditions"
            }
        case .snowy:
            return "Snow alert: Use caution for outdoor work"
        case .foggy:
            return "Fog alert: Reduced visibility conditions"
        case .windy:
            if weather.windSpeed > 25 {
                return "High wind alert: Secure outdoor materials"
            } else {
                return "Windy conditions detected"
            }
        case .clear, .sunny:
            return "Current weather conditions are favorable"
        case .cloudy, .partlyCloudy, .overcast:
            return "Cloudy conditions - good for most outdoor work"
        }
    }
    
    private func loadCurrentWeather() {
        // Weather data is managed by WeatherDataAdapter.shared
        // No manual loading needed - other components will populate the shared instance
        // If needed, this could trigger loading for a default location
        print("ℹ️ WeatherViewModifier: Weather data will be loaded by other components")
    }
    
    private func checkWeatherAlerts() {
        guard let weather = weatherAdapter.currentWeather else { return }
        
        if weather.condition == .stormy ||
           weather.precipitation > 0.3 ||
           weather.windSpeed > 20 {
            showWeatherAlert = true
        }
    }
}

extension View {
    func weatherAware() -> some View {
        self.modifier(WeatherViewModifier())
    }
}
