import Foundation
import Combine
import SwiftUI

class WeatherService: ObservableObject {
    static let shared = WeatherService()
    
    // Published properties for SwiftUI compatibility
    @Published var currentWeather: WeatherData?
    @Published var forecast: [WeatherData] = []
    @Published var isLoading: Bool = false
    
    // Private properties for internal use
    private var currentWeatherData: WeatherData?
    private var weatherForecast: [WeatherData] = []
    
    // MARK: - Fetch Simulated Weather Data
    
    func fetchWeather(latitude: Double, longitude: Double) {
        isLoading = true
        
        let temperature = Double.random(in: 30...95)
        let condition = generateRandomWeatherCondition()
        let precipitation = Double.random(in: 0...1)
        let windSpeed = Double.random(in: 0...35)
        
        let weatherData = WeatherData(
            date: Date(),
            temperature: temperature,
            temperatureHigh: temperature + 5,
            temperatureLow: temperature - 5,
            condition: condition,
            precipitation: precipitation,
            windSpeed: windSpeed,
            humidity: Double.random(in: 30...90),
            uvIndex: Int.random(in: 0...10)
        )
        
        currentWeatherData = weatherData
        currentWeather = weatherData
        
        weatherForecast = generateForecast(days: 7)
        forecast = weatherForecast
        
        isLoading = false
        
        NotificationCenter.default.post(
            name: Notification.Name("WeatherForecastUpdated"),
            object: nil,
            userInfo: ["latitude": latitude, "longitude": longitude]
        )
    }
    
    // MARK: - Task Logic
    
    func tasksNeedingRescheduling(_ tasks: [FrancoSphere.MaintenanceTask]) -> [FrancoSphere.MaintenanceTask] {
        guard let currentWeather = currentWeatherData else { return [] }
        
        return tasks.filter { task in
            let shouldReschedule = shouldRescheduleTask(task, due: task.dueDate, weather: currentWeather)
            return shouldReschedule && !task.isComplete && task.dueDate > Date() && task.dueDate < Date().addingTimeInterval(86400 * 3)
        }
    }
    
    func recommendedRescheduleDateForTask(_ task: FrancoSphere.MaintenanceTask) -> Date? {
        guard !weatherForecast.isEmpty else { return nil }
        
        for i in 0..<weatherForecast.count {
            let potentialDate = Date().addingTimeInterval(TimeInterval(i * 86400))
            let weatherForDay = weatherForecast[i]
            
            if !shouldRescheduleTask(task, due: potentialDate, weather: weatherForDay) {
                return potentialDate
            }
        }
        
        return Date().addingTimeInterval(86400 * 7)
    }
    
    func createWeatherEmergencyTask(for building: FrancoSphere.NamedCoordinate) -> FrancoSphere.MaintenanceTask? {
        guard let weather = currentWeatherData else { return nil }
        
        if weather.condition == .storm && weather.windSpeed > 30 {
            return EmergencyTaskManager.createStormDamageTask(for: building)
        } else if weather.condition == .rain && weather.precipitation > 0.8 {
            return EmergencyTaskManager.createFloodingTask(for: building)
        } else if weather.temperature > 95 || weather.temperature < 20 {
            return EmergencyTaskManager.createHVACEmergencyTask(for: building, highTemperature: weather.temperature > 95)
        }
        
        return nil
    }
    
    // Legacy version - renamed to avoid ambiguity
    func createLegacyEmergencyWeatherTask(for building: NamedCoordinate) -> FSLegacyTask {
        // Use our renamed method that returns an optional
        if let emergencyTask = createWeatherEmergencyTask(for: building as FrancoSphere.NamedCoordinate) {
            return FSLegacyTask.fromFrancoSphereTask(emergencyTask)
        } else {
            // Default legacy task if no emergency conditions are met
            return FSLegacyTask(
                id: UUID().uuidString,
                name: "Weather Preparation",
                buildingID: building.id,
                description: "General weather preparation for building safety.",
                dueDate: Date(),
                startTime: Date(),
                endTime: Date().addingTimeInterval(7200),
                category: .maintenance,
                urgency: .urgent,
                recurrence: .oneTime,
                assignedWorkers: []
            )
        }
    }
    
    func generateWeatherTasks(for building: FrancoSphere.NamedCoordinate) -> [FrancoSphere.MaintenanceTask] {
        guard let weather = currentWeatherData else { return [] }
        
        var tasks: [FrancoSphere.MaintenanceTask] = []
        
        if weather.condition == .storm || weather.windSpeed > 25 {
            if let emergencyTask = createWeatherEmergencyTask(for: building) {
                tasks.append(emergencyTask)
            }
        }
        
        if weather.temperature < 32 {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            tasks.append(FrancoSphere.MaintenanceTask(
                name: "Cold Weather: Pipe Inspection",
                buildingID: building.id,
                description: "Check all exposed pipes and ensure heating systems are functioning to prevent freezing.",
                dueDate: tomorrow,
                category: .inspection,
                urgency: .high,
                recurrence: .oneTime
            ))
        }
        
        if weather.condition == .rain && weather.precipitation > 0.6 {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            tasks.append(FrancoSphere.MaintenanceTask(
                name: "Heavy Rain: Drainage Check",
                buildingID: building.id,
                description: "Inspect all drainage systems, gutters, and downspouts to ensure proper water flow.",
                dueDate: tomorrow,
                category: .inspection,
                urgency: .medium,
                recurrence: .oneTime
            ))
        }
        
        return tasks
    }
    
    // MARK: - Rescheduling Logic
    
    private func shouldRescheduleTask(_ task: FrancoSphere.MaintenanceTask, due date: Date, weather: WeatherData) -> Bool {
        if task.name.contains("EMERGENCY") || task.urgency == .urgent {
            return false
        }
        
        let isOutdoorTask = task.name.localizedCaseInsensitiveContains("Exterior") ||
                            task.name.localizedCaseInsensitiveContains("Roof") ||
                            task.name.localizedCaseInsensitiveContains("Lawn") ||
                            task.name.localizedCaseInsensitiveContains("Garden") ||
                            task.description.localizedCaseInsensitiveContains("outdoor")
        
        if isOutdoorTask {
            if weather.condition == .storm ||
               weather.condition == .snow ||
               (weather.condition == .rain && weather.precipitation > 0.6) ||
               weather.windSpeed > 20 {
                return true
            }
        }
        
        if task.name.contains("HVAC") && (weather.temperature > 90 || weather.temperature < 32) {
            return true
        }
        
        return false
    }
    
    // MARK: - Forecast Generator
    
    private func generateForecast(days: Int) -> [WeatherData] {
        var forecast: [WeatherData] = []
        
        for i in 0..<days {
            let date = Date().addingTimeInterval(TimeInterval(i * 86400))
            let temperature = Double.random(in: 30...95)
            let condition = generateRandomWeatherCondition()
            let precipitation = Double.random(in: 0...1)
            let windSpeed = Double.random(in: 0...35)
            
            forecast.append(WeatherData(
                date: date,
                temperature: temperature,
                temperatureHigh: temperature + 5,
                temperatureLow: temperature - 5,
                condition: condition,
                precipitation: precipitation,
                windSpeed: windSpeed,
                humidity: Double.random(in: 30...90),
                uvIndex: Int.random(in: 0...10)
            ))
        }
        
        return forecast
    }
    
    private func generateRandomWeatherCondition() -> WeatherData.WeatherCondition {
        let options: [WeatherData.WeatherCondition] = [
            .clear, .partlyCloudy, .cloudy, .rain, .snow, .storm, .extreme
        ]
        return options.randomElement()!
    }
    
    // MARK: - Notification Methods
    
    /// Creates a weather notification message for a building based on current conditions.
    func createWeatherNotification(for building: NamedCoordinate) -> String? {
        guard let weather = currentWeatherData else { return nil }
        
        if weather.condition == .storm {
            return "Severe thunderstorm warning for \(building.name). Take precautions and ensure all outdoor equipment is secured."
        } else if weather.condition == .snow && weather.precipitation > 0.5 {
            return "Heavy snowfall expected at \(building.name). Prepare snow removal equipment and check heating systems."
        } else if weather.condition == .rain && weather.precipitation > 0.8 {
            return "Heavy rain alert for \(building.name). Check drainage systems and prepare for possible flooding."
        } else if weather.temperature > 95 {
            return "Extreme heat warning for \(building.name). Ensure cooling systems are functioning properly."
        } else if weather.temperature < 32 {
            return "Freezing conditions alert for \(building.name). Check pipes and heating systems."
        } else if weather.windSpeed > 30 {
            return "High wind warning for \(building.name). Secure all outdoor equipment and materials."
        }
        
        return nil
    }
    
    /// Determines if waste collection should be adjusted due to weather conditions.
    func shouldAdjustWasteCollection(for building: NamedCoordinate) -> (shouldAdjust: Bool, date: Date?) {
        guard let weather = currentWeatherData else { return (false, nil) }
        
        let severeConditions = weather.condition == .storm ||
                              weather.condition == .snow ||
                              (weather.condition == .rain && weather.precipitation > 0.7) ||
                              weather.windSpeed > 25
        
        if severeConditions {
            let calendar = Calendar.current
            var nextDate: Date?
            
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
            let tomorrowForecast = weatherForecast.first { calendar.isDate($0.date, inSameDayAs: tomorrow) }
            
            if let forecast = tomorrowForecast, isSuitableForWasteCollection(weather: forecast) {
                nextDate = tomorrow
            } else {
                let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: Date())!
                nextDate = dayAfterTomorrow
            }
            
            return (true, nextDate)
        }
        
        return (false, nil)
    }
    
    private func isSuitableForWasteCollection(weather: WeatherData) -> Bool {
        return weather.condition != .storm &&
               weather.condition != .snow &&
               !(weather.condition == .rain && weather.precipitation > 0.5) &&
               weather.windSpeed < 20
    }
    
    /// Assess weather risk for a specific building and returns a summary.
    func assessWeatherRisk(for building: NamedCoordinate) -> String {
        guard let weather = currentWeatherData else { return "No significant risks" }
        
        var risks: [String] = []
        
        if weather.condition == .storm {
            risks.append("Severe storm risk")
        }
        
        if weather.condition == .rain && weather.precipitation > 0.5 {
            risks.append("Flooding potential")
        }
        
        if weather.windSpeed > 25 {
            risks.append("High wind damage possible")
        }
        
        if weather.temperature < 32 {
            risks.append("Freezing conditions")
        }
        
        if weather.temperature > 90 {
            risks.append("Excessive heat")
        }
        
        return risks.isEmpty ? "No significant risks" : risks.joined(separator: ", ")
    }
}
extension WeatherService {
    // Add an alias method that matches the name expected by TaskSchedulerService
    func createEmergencyWeatherTask(for building: FrancoSphere.NamedCoordinate) -> Any? {
        // Simply call the existing method with the slightly different name
        return createWeatherEmergencyTask(for: building)
    }
}
