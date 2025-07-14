//
//  WeatherAlert.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Updated for new ContextualTask structure and actor architecture
//  ✅ Uses correct ContextualTask initializer with title, buildingName, etc.
//  ✅ Integrates with CoreTypes and established FrancoSphere.WeatherCondition from FrancoSphereModels
//  ✅ Follows actor-based architecture patterns
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Weather Alert System

/// Weather data structure for task generation and alerts
public struct FSWeatherData {
    public let temperature: Double
    public let condition: FrancoSphere.WeatherCondition  // Use existing FrancoSphere.WeatherCondition from FrancoSphereModels
    public let precipitation: Double
    public let windSpeed: Double
    public let humidity: Double
    public let date: Date
    public let temperatureHigh: Double
    public let temperatureLow: Double
    
    public init(temperature: Double, condition: FrancoSphere.WeatherCondition, precipitation: Double, windSpeed: Double, humidity: Double, date: Date, temperatureHigh: Double, temperatureLow: Double) {
        self.temperature = temperature
        self.condition = condition
        self.precipitation = precipitation
        self.windSpeed = windSpeed
        self.humidity = humidity
        self.date = date
        self.temperatureHigh = temperatureHigh
        self.temperatureLow = temperatureLow
    }
    
    // MARK: - Outdoor Work Risk Assessment
    public enum OutdoorWorkRisk: String, CaseIterable {
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
        return precipitation > 0.1 || condition == .rainy || condition == .snowy || condition == .stormy
    }
    
    public var hasHighWinds: Bool {
        return windSpeed > 15.0
    }
    
    public var isHazardous: Bool {
        return hasPrecipitation || hasHighWinds || condition == .stormy
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

// MARK: - Weather Alert Manager (Actor for Thread Safety)

public actor WeatherAlertManager {
    public static let shared = WeatherAlertManager()
    
    private init() {}
    
    // MARK: - Weather-Based Task Generation
    
    /// Generate weather-related tasks for a building based on current conditions
    public func generateWeatherTasks(for building: NamedCoordinate, weather: FSWeatherData) async -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        // Rain-related tasks
        if weather.condition == .rainy || weather.precipitation > 0.1 {
            tasks.append(createRainTask(for: building))
        }
        
        // Snow-related tasks
        if weather.condition == .snowy {
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
    
    // MARK: - Task Creation Methods (Using Correct ContextualTask V6.0 Structure)
    
    private func createRainTask(for building: NamedCoordinate) -> ContextualTask {
        return ContextualTask(
            title: "Rain Preparation",
            description: "Check drainage and secure outdoor items due to rain. Ensure all water management systems are functional.",
            category: .maintenance,
            urgency: .high,
            buildingId: building.id,
            buildingName: building.name,
            assignedWorkerId: nil, // Will be assigned by TaskService
            assignedWorkerName: nil,
            isCompleted: false,
            completedDate: nil,
            dueDate: Date().addingTimeInterval(3600), // Due in 1 hour
            estimatedDuration: 3600, // 1 hour
            recurrence: .none,
            notes: "Weather-generated task due to rain conditions"
        )
    }
    
    private func createSnowTask(for building: NamedCoordinate) -> ContextualTask {
        return ContextualTask(
            title: "Snow Management",
            description: "Clear walkways and apply salt for safety. Remove snow accumulation from critical areas.",
            category: .maintenance,
            urgency: .urgent,
            buildingId: building.id,
            buildingName: building.name,
            assignedWorkerId: nil,
            assignedWorkerName: nil,
            isCompleted: false,
            completedDate: nil,
            dueDate: Date().addingTimeInterval(1800), // Due in 30 minutes
            estimatedDuration: 7200, // 2 hours
            recurrence: .none,
            notes: "Weather-generated task due to snow conditions"
        )
    }
    
    private func createWindTask(for building: NamedCoordinate) -> ContextualTask {
        return ContextualTask(
            title: "Wind Damage Check",
            description: "Inspect for wind damage and secure loose items. Check building exterior for any weather-related issues.",
            category: .inspection,
            urgency: .medium,
            buildingId: building.id,
            buildingName: building.name,
            assignedWorkerId: nil,
            assignedWorkerName: nil,
            isCompleted: false,
            completedDate: nil,
            dueDate: Date().addingTimeInterval(5400), // Due in 1.5 hours
            estimatedDuration: 3600, // 1 hour
            recurrence: .none,
            notes: "Weather-generated task due to high wind conditions"
        )
    }
    
    private func createTemperatureTask(for building: NamedCoordinate, temperature: Double) -> ContextualTask {
        let taskTitle: String
        let description: String
        let notes: String
        
        if temperature < 32 {
            taskTitle = "Freeze Protection"
            description = "Check for frozen pipes and heating system operation. Ensure all weather protection measures are in place."
            notes = "Weather-generated task due to freezing temperatures (\(Int(temperature))°F)"
        } else {
            taskTitle = "Heat Management"
            description = "Monitor cooling systems and check for heat-related issues. Ensure proper ventilation and temperature control."
            notes = "Weather-generated task due to extreme heat (\(Int(temperature))°F)"
        }
        
        return ContextualTask(
            title: taskTitle,
            description: description,
            category: .maintenance,
            urgency: .medium,
            buildingId: building.id,
            buildingName: building.name,
            assignedWorkerId: nil,
            assignedWorkerName: nil,
            isCompleted: false,
            completedDate: nil,
            dueDate: Date().addingTimeInterval(7200), // Due in 2 hours
            estimatedDuration: 3600, // 1 hour
            recurrence: .none,
            notes: notes
        )
    }
    
    // MARK: - Weather Impact Assessment
    
    /// Assess the overall impact of weather conditions on operations
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
    private func getCategoryForWeather(_ condition: FrancoSphere.WeatherCondition) -> FrancoSphere.TaskCategory {
        switch condition {
        case .rainy, .snowy, .stormy:
            return .emergency
        case .foggy:
            return .inspection
        case .clear, .sunny, .cloudy, .windy:
            return .maintenance
        }
    }
    
    /// Get appropriate urgency for weather conditions
    private func getUrgencyForWeather(_ condition: FrancoSphere.WeatherCondition, temperature: Double) -> FrancoSphere.TaskUrgency {
        switch condition {
        case .stormy:
            return .urgent
        case .rainy, .snowy:
            return .high
        case .foggy:
            return .medium
        case .cloudy, .clear, .sunny, .windy:
            if temperature < 20 || temperature > 95 {
                return .high
            } else {
                return .low
            }
        }
    }
    
    /// Create weather-specific tasks with worker assignment
    public func createWeatherTasksForWorker(
        workerId: CoreTypes.WorkerID,
        workerName: String,
        building: NamedCoordinate,
        weather: FSWeatherData
    ) async -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        // Create tasks based on weather conditions
        if weather.hasPrecipitation {
            let precipitationTask = ContextualTask(
                title: "Weather Response",
                description: "Address precipitation-related building maintenance and safety concerns.",
                category: getCategoryForWeather(weather.condition),
                urgency: getUrgencyForWeather(weather.condition, temperature: weather.temperature),
                buildingId: building.id,
                buildingName: building.name,
                assignedWorkerId: workerId,
                assignedWorkerName: workerName,
                isCompleted: false,
                completedDate: nil,
                dueDate: Date().addingTimeInterval(3600),
                estimatedDuration: 3600,
                recurrence: .none,
                notes: "Assigned weather response task due to \(weather.condition.rawValue) conditions"
            )
            tasks.append(precipitationTask)
        }
        
        if weather.hasHighWinds {
            let windTask = ContextualTask(
                title: "Wind Safety Check",
                description: "Perform safety inspection due to high wind conditions.",
                category: .inspection,
                urgency: .medium,
                buildingId: building.id,
                buildingName: building.name,
                assignedWorkerId: workerId,
                assignedWorkerName: workerName,
                isCompleted: false,
                completedDate: nil,
                dueDate: Date().addingTimeInterval(5400),
                estimatedDuration: 1800,
                recurrence: .none,
                notes: "Wind safety inspection - wind speed: \(weather.windSpeed) mph"
            )
            tasks.append(windTask)
        }
        
        return tasks
    }
    
    /// Integration with TaskService for automatic task creation
    internal func processWeatherAlert(
        for buildings: [NamedCoordinate],
        weather: FSWeatherData,
        taskService: TaskService
    ) async throws {
        guard weather.isHazardous else { return }
        
        print("🌦️ Processing weather alert for \(buildings.count) buildings")
        
        for building in buildings {
            let weatherTasks = await generateWeatherTasks(for: building, weather: weather)
            
            for task in weatherTasks {
                do {
                    // Create task through TaskService for proper integration
                    try await taskService.createTask(task)
                    print("✅ Created weather task: \(task.title) for \(building.name)")
                } catch {
                    print("❌ Failed to create weather task for \(building.name): \(error)")
                }
            }
        }
    }
}

// MARK: - Sample Data for Testing

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
                condition: .rainy,
                precipitation: 0.8,
                windSpeed: 12.0,
                humidity: 85,
                date: Date().addingTimeInterval(86400),
                temperatureHigh: 52,
                temperatureLow: 38
            ),
            FSWeatherData(
                temperature: 28,
                condition: .snowy,
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

// MARK: - Integration with Real-Time System

extension WeatherAlertManager {
    /// Schedule weather monitoring for all buildings
    public func startWeatherMonitoring() async {
        print("🌦️ Starting weather monitoring system")
        // Integration point for real weather API
        // This would connect to actual weather services in production
    }
    
    /// Stop weather monitoring
    public func stopWeatherMonitoring() async {
        print("🌦️ Stopping weather monitoring system")
    }
}
