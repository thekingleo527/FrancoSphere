//
//  WeatherAlert.swift
//  FrancoSphere
//
//  🔧 FIXED: Updated to use correct ContextualTask initializer
//  ✅ Fixed all compilation errors
//  ✅ Updated to match current FrancoSphereModels structure
//  ✅ Maintained weather alert functionality
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Weather Alert System

public struct FSWeatherData {
    public let temperature: Double
    public let condition: WeatherCondition
    public let precipitation: Double
    public let windSpeed: Double
    public let humidity: Double
    public let date: Date
    public let temperatureHigh: Double
    public let temperatureLow: Double
    
    public init(temperature: Double, condition: WeatherCondition, precipitation: Double, windSpeed: Double, humidity: Double, date: Date, temperatureHigh: Double, temperatureLow: Double) {
        self.temperature = temperature
        self.condition = condition
        self.precipitation = precipitation
        self.windSpeed = windSpeed
        self.humidity = humidity
        self.date = date
        self.temperatureHigh = temperatureHigh
        self.temperatureLow = temperatureLow
    }
    
    // MARK: - Weather Condition Enum
    public enum WeatherCondition: String, CaseIterable {
        case clear = "clear"
        case cloudy = "cloudy"
        case rain = "rain"
        case snow = "snow"
        case fog = "fog"
        case storm = "storm"
        case extreme = "extreme"
        
        public var color: Color {
            switch self {
            case .clear: return .yellow
            case .cloudy: return .gray
            case .rain: return .blue
            case .snow: return .cyan
            case .fog: return .gray
            case .storm: return .purple
            case .extreme: return .red
            }
        }
    }
    
    // MARK: - Outdoor Work Risk
    public enum OutdoorWorkRisk: String {
        case low = "Low Risk"
        case moderate = "Moderate Risk"
        case high = "High Risk"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .orange
            case .high: return .red
            }
        }
    }
    
    // MARK: - Weather Computed Properties
    public var hasPrecipitation: Bool {
        return precipitation > 0.1 || condition == .rain || condition == .snow || condition == .storm
    }
    
    public var hasHighWinds: Bool {
        return windSpeed > 15.0
    }
    
    public var isHazardous: Bool {
        return hasPrecipitation || hasHighWinds || condition == .extreme
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    public var formattedTemperature: String {
        return "\(Int(temperature))°F"
    }
    
    public var formattedHighLow: String {
        return "H: \(Int(temperatureHigh))° L: \(Int(temperatureLow))°"
    }
    
    public var outdoorWorkRisk: OutdoorWorkRisk {
        if isHazardous || temperature > 90 || temperature < 32 {
            return .high
        } else if hasHighWinds || precipitation > 0.05 || temperature > 85 || temperature < 40 {
            return .moderate
        } else {
            return .low
        }
    }
}

// MARK: - Weather Alert Manager

public class WeatherAlertManager {
    public static let shared = WeatherAlertManager()
    
    private init() {}
    
    // MARK: - Weather-Based Task Generation
    
    public func generateWeatherTasks(for building: NamedCoordinate, weather: FSWeatherData) -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        // Rain-related tasks
        if weather.condition == .rain || weather.precipitation > 0.1 {
            tasks.append(createRainTask(for: building))
        }
        
        // Snow-related tasks
        if weather.condition == .snow {
            tasks.append(createSnowTask(for: building))
        }
        
        // Wind-related tasks
        if weather.hasHighWinds {
            tasks.append(createWindTask(for: building))
        }
        
        // Extreme temperature tasks
        if weather.temperature < 32 || weather.temperature > 90 {
            tasks.append(createTemperatureTask(for: building, temperature: weather.temperature))
        }
        
        return tasks
    }
    
    // MARK: - Task Creation Methods (Fixed to use correct ContextualTask initializer)
    
    private func createRainTask(for building: NamedCoordinate) -> ContextualTask {
        return ContextualTask(
            name: "Rain Preparation - \(building.name)",
            description: "Check drainage and secure outdoor items due to rain. Ensure all water management systems are functional.",
            buildingId: building.id,
            workerId: "weather_system", // Default weather system worker ID
            category: .maintenance,
            urgency: .high,
            isCompleted: false,
            dueDate: Date().addingTimeInterval(3600), // Due in 1 hour
            estimatedDuration: 3600 // 1 hour
        )
    }
    
    private func createSnowTask(for building: NamedCoordinate) -> ContextualTask {
        return ContextualTask(
            name: "Snow Management - \(building.name)",
            description: "Clear walkways and apply salt for safety. Remove snow accumulation from critical areas.",
            buildingId: building.id,
            workerId: "weather_system", // Default weather system worker ID
            category: .maintenance,
            urgency: .high,
            isCompleted: false,
            dueDate: Date().addingTimeInterval(1800), // Due in 30 minutes
            estimatedDuration: 7200 // 2 hours
        )
    }
    
    private func createWindTask(for building: NamedCoordinate) -> ContextualTask {
        return ContextualTask(
            name: "Wind Damage Check - \(building.name)",
            description: "Inspect for wind damage and secure loose items. Check building exterior for any weather-related issues.",
            buildingId: building.id,
            workerId: "weather_system", // Default weather system worker ID
            category: .inspection,
            urgency: .medium,
            isCompleted: false,
            dueDate: Date().addingTimeInterval(5400), // Due in 1.5 hours
            estimatedDuration: 3600 // 1 hour
        )
    }
    
    private func createTemperatureTask(for building: NamedCoordinate, temperature: Double) -> ContextualTask {
        let taskName: String
        let description: String
        
        if temperature < 32 {
            taskName = "Freeze Protection - \(building.name)"
            description = "Check for frozen pipes and heating system operation. Ensure all weather protection measures are in place."
        } else {
            taskName = "Heat Management - \(building.name)"
            description = "Monitor cooling systems and check for heat-related issues. Ensure proper ventilation and temperature control."
        }
        
        return ContextualTask(
            name: taskName,
            description: description,
            buildingId: building.id,
            workerId: "weather_system", // Default weather system worker ID
            category: .maintenance,
            urgency: .medium,
            isCompleted: false,
            dueDate: Date().addingTimeInterval(7200), // Due in 2 hours
            estimatedDuration: 3600 // 1 hour
        )
    }
    
    // MARK: - Weather Impact Assessment
    
    public func assessWeatherImpact(weather: FSWeatherData) -> String {
        if weather.isHazardous {
            return "High weather impact - exercise caution with outdoor tasks"
        } else if weather.outdoorWorkRisk == .moderate {
            return "Moderate weather impact - monitor conditions closely"
        } else {
            return "Low weather impact - normal operations can proceed"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get appropriate task category for weather conditions
    private func getCategoryForWeather(_ condition: FSWeatherData.WeatherCondition) -> TaskCategory {
        switch condition {
        case .rain, .snow, .storm:
            return .emergency
        case .extreme:
            return .emergency
        case .fog, .cloudy:
            return .inspection
        case .clear:
            return .maintenance
        }
    }
    
    /// Get appropriate urgency for weather conditions
    private func getUrgencyForWeather(_ condition: FSWeatherData.WeatherCondition, temperature: Double) -> TaskUrgency {
        switch condition {
        case .storm, .extreme:
            return .urgent
        case .rain, .snow:
            return .high
        case .fog:
            return .medium
        case .cloudy, .clear:
            if temperature < 20 || temperature > 95 {
                return .high
            } else {
                return .low
            }
        }
    }
    
    /// Create weather-specific tasks with worker assignment
    public func createWeatherTasksForWorker(workerId: String, building: NamedCoordinate, weather: FSWeatherData) -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        // Create tasks based on weather conditions
        if weather.hasPrecipitation {
            let precipitationTask = ContextualTask(
                name: "Weather Response - \(building.name)",
                description: "Address precipitation-related building maintenance and safety concerns.",
                buildingId: building.id,
                workerId: workerId,
                category: getCategoryForWeather(weather.condition),
                urgency: getUrgencyForWeather(weather.condition, temperature: weather.temperature),
                isCompleted: false,
                dueDate: Date().addingTimeInterval(3600),
                estimatedDuration: 3600
            )
            tasks.append(precipitationTask)
        }
        
        if weather.hasHighWinds {
            let windTask = ContextualTask(
                name: "Wind Safety Check - \(building.name)",
                description: "Perform safety inspection due to high wind conditions.",
                buildingId: building.id,
                workerId: workerId,
                category: .inspection,
                urgency: .medium,
                isCompleted: false,
                dueDate: Date().addingTimeInterval(5400),
                estimatedDuration: 1800
            )
            tasks.append(windTask)
        }
        
        return tasks
    }
}

// MARK: - Sample Data

extension FSWeatherData {
    public static var sampleData: [FSWeatherData] {
        return [
            FSWeatherData(
                temperature: 72,
                condition: .clear,
                precipitation: 0.0,
                windSpeed: 5.0,
                humidity: 45,
                date: Date(),
                temperatureHigh: 78,
                temperatureLow: 65
            ),
            FSWeatherData(
                temperature: 45,
                condition: .rain,
                precipitation: 0.8,
                windSpeed: 12.0,
                humidity: 85,
                date: Date().addingTimeInterval(86400),
                temperatureHigh: 52,
                temperatureLow: 38
            ),
            FSWeatherData(
                temperature: 28,
                condition: .snow,
                precipitation: 1.2,
                windSpeed: 18.0,
                humidity: 90,
                date: Date().addingTimeInterval(172800),
                temperatureHigh: 35,
                temperatureLow: 22
            )
        ]
    }
}
