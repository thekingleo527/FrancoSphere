//
//  WeatherAlert.swift
//  FrancoSphere
//
//  Clean rebuild - all syntax errors fixed
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
    
    // MARK: - Task Creation Methods
    
    private func createRainTask(for building: NamedCoordinate) -> ContextualTask {
        return ContextualTask(
            name: "Rain Preparation - \(building.name)",
            buildingId: building.id,
            buildingName: building.name,
            category: "Weather",
            startTime: "08:00",
            endTime: "09:00",
            recurrence: "One Time",
            skillLevel: "Basic",
            status: "pending",
            urgencyLevel: "High",
            assignedWorkerName: "Weather System",
            notes: "Check drainage and secure outdoor items due to rain"
        )
    }
    
    private func createSnowTask(for building: NamedCoordinate) -> ContextualTask {
        return ContextualTask(
            name: "Snow Management - \(building.name)",
            buildingId: building.id,
            buildingName: building.name,
            category: "Weather",
            startTime: "06:00",
            endTime: "08:00",
            recurrence: "One Time",
            skillLevel: "Basic",
            status: "pending",
            urgencyLevel: "High",
            assignedWorkerName: "Weather System",
            notes: "Clear walkways and apply salt for safety"
        )
    }
    
    private func createWindTask(for building: NamedCoordinate) -> ContextualTask {
        return ContextualTask(
            name: "Wind Damage Check - \(building.name)",
            buildingId: building.id,
            buildingName: building.name,
            category: "Weather",
            startTime: "09:00",
            endTime: "10:00",
            recurrence: "One Time",
            skillLevel: "Intermediate",
            status: "pending",
            urgencyLevel: "Medium",
            assignedWorkerName: "Weather System",
            notes: "Inspect for wind damage and secure loose items"
        )
    }
    
    private func createTemperatureTask(for building: NamedCoordinate, temperature: Double) -> ContextualTask {
        let taskName: String
        let notes: String
        
        if temperature < 32 {
            taskName = "Freeze Protection - \(building.name)"
            notes = "Check for frozen pipes and heating system operation"
        } else {
            taskName = "Heat Management - \(building.name)"
            notes = "Monitor cooling systems and check for heat-related issues"
        }
        
        return ContextualTask(
            name: taskName,
            buildingId: building.id,
            buildingName: building.name,
            category: "Weather",
            startTime: "10:00",
            endTime: "11:00",
            recurrence: "One Time",
            skillLevel: "Intermediate",
            status: "pending",
            urgencyLevel: "Medium",
            assignedWorkerName: "Weather System",
            notes: notes
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
