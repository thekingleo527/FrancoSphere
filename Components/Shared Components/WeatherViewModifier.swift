import SwiftUI

struct WeatherViewModifier: ViewModifier {
    @State private var currentWeather: WeatherData?
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
        if let weather = currentWeather {
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
    
    private func getWeatherIcon(for condition: FrancoSphere.WeatherCondition) -> String {
        switch condition {
        case .clear, .sunny:
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
        }
    }
    
    private func getWeatherColor(for condition: FrancoSphere.WeatherCondition) -> Color {
        switch condition {
        case .clear, .sunny:
            return .yellow
        case .cloudy:
            return .gray
        case .rainy:
            return .blue
        case .snowy:
            return .white
        case .stormy:
            return .purple
        case .foggy:
            return .gray
        case .windy:
            return .mint
        }
    }
    
    private var weatherAlertMessage: String {
        guard let weather = currentWeather else { return "No weather data available" }
        
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
        default:
            return "Current weather conditions are favorable"
        }
    }
    
    private func loadCurrentWeather() {
        // Mock weather data - replace with real weather service
        currentWeather = WeatherData(
            temperature: 72.0,
            humidity: 60,
            windSpeed: 8.0,
            conditions: "partly cloudy",
            precipitation: 0.0,
            condition: .cloudy
        )
    }
    
    private func checkWeatherAlerts() {
        guard let weather = currentWeather else { return }
        
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
