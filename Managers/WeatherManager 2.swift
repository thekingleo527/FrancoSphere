//
//  WeatherManager 2.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/4/25.
//


//
//  WeatherManager.swift
//  FrancoSphere
//
//  Complete weather management system for FrancoSphere
//  Provides real-time weather data, forecasts, and task impact analysis
//  Supports both mock data (for development) and real API integration
//

import Foundation
import Combine
import CoreLocation
import SwiftUI

@MainActor
public class WeatherManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = WeatherManager()
    
    // MARK: - Published Properties
    @Published public var currentWeather: FrancoSphere.WeatherData?
    @Published public var forecast: [FrancoSphere.WeatherData] = []
    @Published public var isLoading = false
    @Published public var error: WeatherError?
    @Published public var lastUpdate: Date?
    
    // MARK: - Configuration
    private let apiKey = "your_weather_api_key" // Replace with real API key
    private let updateInterval: TimeInterval = 300 // 5 minutes
    private var cancellables = Set<AnyCancellable>()
    private var locationUpdateTimer: Timer?
    
    // MARK: - NYC Coordinates (FrancoSphere operational area)
    private let nycCoordinate = CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
    private let operationalRadius: CLLocationDistance = 5000 // 5km radius
    
    // MARK: - Initialization
    private init() {
        setupInitialWeather()
        startPeriodicUpdates()
    }
    
    // MARK: - Public Interface
    
    /// Updates weather for a specific location (building)
    public func updateWeatherForLocation(_ coordinate: CLLocationCoordinate2D) async {
        await performWeatherUpdate(for: coordinate)
    }
    
    /// Updates weather for all operational buildings
    public func updateWeatherForAllBuildings() async {
        await performWeatherUpdate(for: nycCoordinate)
    }
    
    /// Gets weather impact assessment for tasks
    public func getWeatherImpact(for tasks: [ContextualTask]) -> FrancoSphere.WeatherImpact? {
        guard let weather = currentWeather else { return nil }
        
        let affectedTasks = tasks.filter { task in
            isTaskAffectedByWeather(task, weather: weather)
        }
        
        let recommendation = generateWeatherRecommendation(weather: weather, affectedTasks: affectedTasks)
        
        return FrancoSphere.WeatherImpact(
            condition: weather.condition,
            temperature: weather.temperature,
            affectedTasks: affectedTasks,
            recommendation: recommendation
        )
    }
    
    /// Force refresh weather data
    public func forceRefresh() async {
        lastUpdate = nil
        await updateWeatherForAllBuildings()
    }
    
    // MARK: - Private Implementation
    
    private func setupInitialWeather() {
        // Initialize with realistic NYC weather
        currentWeather = createMockWeatherData()
        lastUpdate = Date()
        
        // Generate 5-day forecast
        forecast = generateMockForecast()
    }
    
    private func startPeriodicUpdates() {
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateWeatherForAllBuildings()
            }
        }
    }
    
    private func performWeatherUpdate(for coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        error = nil
        
        do {
            // Check if we need to update (don't spam API)
            if let lastUpdate = lastUpdate,
               Date().timeIntervalSince(lastUpdate) < updateInterval {
                isLoading = false
                return
            }
            
            // Try real API first, fall back to mock data
            let weatherData = try await fetchWeatherData(for: coordinate)
            
            currentWeather = weatherData
            lastUpdate = Date()
            
            // Update forecast as well
            forecast = try await fetchForecastData(for: coordinate)
            
            print("✅ Weather updated: \(weatherData.condition.rawValue), \(Int(weatherData.temperature))°F")
            
        } catch {
            self.error = error as? WeatherError ?? .unknown(error)
            print("❌ Weather update failed: \(error)")
            
            // Fall back to mock data if API fails
            if currentWeather == nil {
                currentWeather = createMockWeatherData()
                forecast = generateMockForecast()
            }
        }
        
        isLoading = false
    }
    
    private func fetchWeatherData(for coordinate: CLLocationCoordinate2D) async throws -> FrancoSphere.WeatherData {
        // For now, use mock data. Replace with real API call:
        // let url = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=imperial"
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Return realistic mock data based on current time/season
        return createRealisticWeatherData()
    }
    
    private func fetchForecastData(for coordinate: CLLocationCoordinate2D) async throws -> [FrancoSphere.WeatherData] {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return generateRealisticForecast()
    }
    
    // MARK: - Mock Data Generation
    
    private func createMockWeatherData() -> FrancoSphere.WeatherData {
        return FrancoSphere.WeatherData(
            date: Date(),
            temperature: 72,
            feelsLike: 75,
            humidity: 65,
            windSpeed: 5,
            windDirection: 180,
            precipitation: 0,
            snow: 0,
            visibility: 10,
            pressure: 1013,
            condition: .clear,
            icon: "sun.max.fill"
        )
    }
    
    private func createRealisticWeatherData() -> FrancoSphere.WeatherData {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        // Seasonal temperature ranges
        let (tempRange, conditions): (ClosedRange<Double>, [FrancoSphere.WeatherCondition]) = {
            switch currentMonth {
            case 12, 1, 2: // Winter
                return (25...45, [.clear, .cloudy, .snow, .fog])
            case 3, 4, 5: // Spring
                return (45...70, [.clear, .cloudy, .rain])
            case 6, 7, 8: // Summer
                return (70...85, [.clear, .cloudy, .thunderstorm])
            case 9, 10, 11: // Fall
                return (50...70, [.clear, .cloudy, .rain, .fog])
            default:
                return (60...75, [.clear, .cloudy])
            }
        }()
        
        let baseTemp = Double.random(in: tempRange)
        let condition = conditions.randomElement() ?? .clear
        let humidity = Int.random(in: 40...80)
        let windSpeed = Double.random(in: 0...15)
        let precipitation = condition == .rain ? Double.random(in: 0.1...2.0) : 0
        let snow = condition == .snow ? Double.random(in: 0.5...8.0) : 0
        
        // Adjust temperature for time of day
        let timeAdjustment: Double = {
            switch currentHour {
            case 6..<10: return -5 // Early morning cooler
            case 10..<16: return 3 // Midday warmer
            case 16..<20: return 0 // Evening normal
            default: return -8 // Night cooler
            }
        }()
        
        let actualTemp = baseTemp + timeAdjustment
        let feelsLike = actualTemp + Double.random(in: -3...5)
        
        return FrancoSphere.WeatherData(
            date: Date(),
            temperature: actualTemp,
            feelsLike: feelsLike,
            humidity: humidity,
            windSpeed: windSpeed,
            windDirection: Int.random(in: 0...360),
            precipitation: precipitation,
            snow: snow,
            visibility: condition == .fog ? Int.random(in: 2...5) : 10,
            pressure: Int.random(in: 995...1025),
            condition: condition,
            icon: condition.icon
        )
    }
    
    private func generateMockForecast() -> [FrancoSphere.WeatherData] {
        var forecast: [FrancoSphere.WeatherData] = []
        
        for dayOffset in 1...5 {
            let futureDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
            let baseTemp = Double.random(in: 60...80)
            let condition = FrancoSphere.WeatherCondition.allCases.randomElement() ?? .clear
            
            let dayWeather = FrancoSphere.WeatherData(
                date: futureDate,
                temperature: baseTemp,
                feelsLike: baseTemp + Double.random(in: -2...4),
                humidity: Int.random(in: 40...75),
                windSpeed: Double.random(in: 2...12),
                windDirection: Int.random(in: 0...360),
                precipitation: condition == .rain ? Double.random(in: 0...1.5) : 0,
                snow: condition == .snow ? Double.random(in: 0...5) : 0,
                visibility: 10,
                pressure: 1013,
                condition: condition,
                icon: condition.icon
            )
            
            forecast.append(dayWeather)
        }
        
        return forecast
    }
    
    private func generateRealisticForecast() -> [FrancoSphere.WeatherData] {
        // Generate more realistic forecast with weather patterns
        return generateMockForecast() // For now, same as mock
    }
    
    // MARK: - Weather Impact Analysis
    
    private func isTaskAffectedByWeather(_ task: ContextualTask, weather: FrancoSphere.WeatherData) -> Bool {
        let taskName = task.name.lowercased()
        let category = task.category.lowercased()
        
        // Rain affects outdoor tasks
        if weather.condition == .rain {
            return taskName.contains("sidewalk") ||
                   taskName.contains("sweep") ||
                   taskName.contains("hose") ||
                   category.contains("cleaning") ||
                   category.contains("maintenance")
        }
        
        // Snow affects all outdoor tasks heavily
        if weather.condition == .snow {
            return taskName.contains("sidewalk") ||
                   taskName.contains("trash") ||
                   taskName.contains("dsny") ||
                   category.contains("sanitation")
        }
        
        // Extreme temperatures affect all outdoor work
        if weather.temperature < 20 || weather.temperature > 90 {
            return !category.contains("indoor")
        }
        
        // High winds affect specific tasks
        if weather.windSpeed > 20 {
            return taskName.contains("dsny") ||
                   taskName.contains("trash") ||
                   taskName.contains("debris")
        }
        
        return false
    }
    
    private func generateWeatherRecommendation(weather: FrancoSphere.WeatherData, affectedTasks: [ContextualTask]) -> String {
        if affectedTasks.isEmpty {
            return "Weather conditions are favorable for all scheduled tasks."
        }
        
        switch weather.condition {
        case .rain:
            return "Rain detected. Consider postponing outdoor cleaning tasks and focus on indoor work first."
        case .snow:
            return "Snow conditions require extra time for sidewalk clearing and trash area maintenance. Start outdoor tasks early."
        case .thunderstorm:
            return "Thunderstorm warning. Postpone all outdoor work until conditions improve."
        case .fog:
            return "Low visibility due to fog. Exercise extra caution during outdoor tasks."
        default:
            if weather.temperature < 20 {
                return "Extreme cold conditions. Take frequent warming breaks and prioritize urgent outdoor tasks."
            } else if weather.temperature > 90 {
                return "High temperature alert. Stay hydrated, take shade breaks, and complete outdoor work early in the day."
            } else if weather.windSpeed > 20 {
                return "High winds detected. Secure loose items and be extra careful with trash handling."
            } else {
                return "Weather conditions require attention for \(affectedTasks.count) tasks. Adjust timing as needed."
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        locationUpdateTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Weather Error Types

public enum WeatherError: LocalizedError {
    case networkError
    case invalidAPIKey
    case locationNotFound
    case dataParsingError
    case rateLimitExceeded
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect to weather service"
        case .invalidAPIKey:
            return "Invalid weather API key"
        case .locationNotFound:
            return "Location not found"
        case .dataParsingError:
            return "Unable to parse weather data"
        case .rateLimitExceeded:
            return "Weather API rate limit exceeded"
        case .unknown(let error):
            return "Weather error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Weather Extensions for UI

extension FrancoSphere.WeatherCondition {
    
    /// Color representation for UI elements
    public var backgroundColor: Color {
        switch self {
        case .clear:
            return Color.blue.opacity(0.1)
        case .cloudy:
            return Color.gray.opacity(0.2)
        case .rain:
            return Color.blue.opacity(0.3)
        case .snow:
            return Color.cyan.opacity(0.2)
        case .thunderstorm:
            return Color.purple.opacity(0.2)
        case .fog:
            return Color.gray.opacity(0.3)
        case .other:
            return Color.secondary.opacity(0.1)
        }
    }
    
    /// Text color for readability
    public var textColor: Color {
        switch self {
        case .clear:
            return .primary
        case .cloudy, .fog:
            return .secondary
        case .rain, .snow:
            return .blue
        case .thunderstorm:
            return .purple
        case .other:
            return .primary
        }
    }
}

extension FrancoSphere.WeatherData {
    
    /// Human-readable temperature string
    public var temperatureString: String {
        return "\(Int(temperature.rounded()))°F"
    }
    
    /// Human-readable feels like string
    public var feelsLikeString: String {
        return "Feels like \(Int(feelsLike.rounded()))°F"
    }
    
    /// Detailed weather description
    public var detailedDescription: String {
        var components: [String] = [condition.rawValue]
        
        if precipitation > 0 {
            components.append("\(precipitation.formatted(.number.precision(.fractionLength(1))))\" rain")
        }
        
        if snow > 0 {
            components.append("\(snow.formatted(.number.precision(.fractionLength(1))))\" snow")
        }
        
        if windSpeed > 10 {
            components.append("\(Int(windSpeed)) mph winds")
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Weather alert level for task planning
    public var alertLevel: WeatherAlertLevel {
        if condition == .thunderstorm {
            return .severe
        }
        
        if condition == .snow || precipitation > 1.0 || temperature < 15 || temperature > 95 {
            return .high
        }
        
        if condition == .rain || temperature < 25 || temperature > 85 || windSpeed > 15 {
            return .moderate
        }
        
        return .low
    }
}

public enum WeatherAlertLevel: CaseIterable {
    case low
    case moderate
    case high
    case severe
    
    public var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
    
    public var description: String {
        switch self {
        case .low: return "Favorable conditions"
        case .moderate: return "Some impact on outdoor tasks"
        case .high: return "Significant impact on operations"
        case .severe: return "Outdoor work not recommended"
        }
    }
}