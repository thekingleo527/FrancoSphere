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
        let feelsLike = temperature  // Placeholder: feelsLike equals current temperature
        let condition = generateRandomWeatherCondition()
        let precipitation = Double.random(in: 0...1)
        let windSpeed = Double.random(in: 0...35)
        let humidity = Int.random(in: 30...90)
        let windDirection = Int.random(in: 0...360)
        let snow = (condition == .snow ? Double.random(in: 0...5) : 0)
        let visibility = Int.random(in: 1...10)
        let pressure = Int.random(in: 980...1050)
        
        let weatherData = WeatherData(
            date: Date(),
            temperature: temperature,
            feelsLike: feelsLike,
            humidity: humidity,
            windSpeed: windSpeed,
            windDirection: windDirection,
            precipitation: precipitation,
            snow: snow,
            visibility: visibility,
            pressure: pressure,
            condition: condition,
            icon: "" // Placeholder: no icon string
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
    
    func tasksNeedingRescheduling(_ tasks: [MaintenanceTask]) -> [MaintenanceTask] {
        guard let currentWeather = currentWeatherData else { return [] }
        
        return tasks.filter { task in
            let shouldReschedule = shouldRescheduleTask(task, due: task.dueDate, weather: currentWeather)
            return shouldReschedule
                && !task.isComplete
                && task.dueDate > Date()
                && task.dueDate < Date().addingTimeInterval(86400 * 3)
        }
    }
    
    func recommendedRescheduleDateForTask(_ task: MaintenanceTask) -> Date? {
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
    
    /// Creates an emergency task based on severe weather conditions.
    /// Replace stubbed return with real EmergencyTaskManager integration.
    func createWeatherEmergencyTask(for building: FrancoSphere.NamedCoordinate) -> MaintenanceTask? {
        guard let weather = currentWeatherData else { return nil }
        
        if weather.condition == .thunderstorm && weather.windSpeed > 30 {
            // Example stub; replace with:
            // return EmergencyTaskManager.createStormDamageTask(for: building)
            return nil
        } else if weather.condition == .rain && weather.precipitation > 0.8 {
            // Example stub; replace with:
            // return EmergencyTaskManager.createFloodingTask(for: building)
            return nil
        } else if weather.temperature > 95 || weather.temperature < 20 {
            // Example stub; replace with:
            // return EmergencyTaskManager.createHVACEmergencyTask(for: building, highTemperature: weather.temperature > 95)
            return nil
        }
        
        return nil
    }
    
    /// Creates a non-emergency weather-related task based on current conditions.
    func createLegacyWeatherTask(for building: FrancoSphere.NamedCoordinate) -> MaintenanceTask? {
        guard let weather = currentWeatherData else { return nil }
        
        var tasks: [MaintenanceTask] = []
        
        if weather.condition == .thunderstorm || weather.windSpeed > 25 {
            if let emergencyTask = createWeatherEmergencyTask(for: building) {
                tasks.append(emergencyTask)
            }
        }
        
        if weather.temperature < 32 {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            tasks.append(MaintenanceTask(
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
            tasks.append(MaintenanceTask(
                name: "Heavy Rain: Drainage Check",
                buildingID: building.id,
                description: "Inspect all drainage systems, gutters, and downspouts to ensure proper water flow.",
                dueDate: tomorrow,
                category: .inspection,
                urgency: .medium,
                recurrence: .oneTime
            ))
        }
        
        return tasks.first
    }
    
    // MARK: - Rescheduling Logic
    
    private func shouldRescheduleTask(
        _ task: MaintenanceTask,
        due date: Date,
        weather: WeatherData
    ) -> Bool {
        // Do not reschedule urgent or emergency tasks
        if task.name.localizedCaseInsensitiveContains("EMERGENCY")
            || task.urgency == .urgent {
            return false
        }
        
        // Identify if this is an outdoor task by keywords
        let isOutdoorTask =
            task.name.localizedCaseInsensitiveContains("Exterior")
            || task.name.localizedCaseInsensitiveContains("Roof")
            || task.name.localizedCaseInsensitiveContains("Lawn")
            || task.name.localizedCaseInsensitiveContains("Garden")
            || task.description.localizedCaseInsensitiveContains("outdoor")
        
        if isOutdoorTask {
            if weather.condition == .thunderstorm
                || weather.condition == .snow
                || (weather.condition == .rain && weather.precipitation > 0.6)
                || weather.windSpeed > 20 {
                return true
            }
        }
        
        // HVAC-related tasks
        if task.name.localizedCaseInsensitiveContains("HVAC")
            && (weather.temperature > 90 || weather.temperature < 32) {
            return true
        }
        
        return false
    }
    
    // MARK: - Forecast Generator
    
    private func generateForecast(days: Int) -> [WeatherData] {
        var generated: [WeatherData] = []
        
        for i in 0..<days {
            let date = Date().addingTimeInterval(TimeInterval(i * 86400))
            let temperature = Double.random(in: 30...95)
            let feelsLike = temperature
            let condition = generateRandomWeatherCondition()
            let precipitation = Double.random(in: 0...1)
            let windSpeed = Double.random(in: 0...35)
            let humidity = Int.random(in: 30...90)
            let windDirection = Int.random(in: 0...360)
            let snow = (condition == .snow ? Double.random(in: 0...5) : 0)
            let visibility = Int.random(in: 1...10)
            let pressure = Int.random(in: 980...1050)
            
            let dayWeather = WeatherData(
                date: date,
                temperature: temperature,
                feelsLike: feelsLike,
                humidity: humidity,
                windSpeed: windSpeed,
                windDirection: windDirection,
                precipitation: precipitation,
                snow: snow,
                visibility: visibility,
                pressure: pressure,
                condition: condition,
                icon: ""
            )
            
            generated.append(dayWeather)
        }
        
        return generated
    }
    
    private func generateRandomWeatherCondition() -> WeatherCondition {
        let options: [WeatherCondition] = [
            .clear,
            .cloudy,
            .rain,
            .snow,
            .thunderstorm,
            .fog,
            .other
        ]
        return options.randomElement()!
    }
    
    // MARK: - Notification Methods
    
    /// Creates a weather notification message for a building based on current conditions.
    func createWeatherNotification(for building: FrancoSphere.NamedCoordinate) -> String? {
        guard let weather = currentWeatherData else { return nil }
        
        if weather.condition == .thunderstorm {
            return "Severe thunderstorm warning for \(building.name). Take precautions and ensure all outdoor equipment is secured."
        } else if weather.condition == .snow && weather.snow > 0.5 {
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
    func shouldAdjustWasteCollection(for building: FrancoSphere.NamedCoordinate) -> (shouldAdjust: Bool, date: Date?) {
        guard let weather = currentWeatherData else { return (false, nil) }
        
        let severeConditions =
            weather.condition == .thunderstorm
            || weather.condition == .snow
            || (weather.condition == .rain && weather.precipitation > 0.7)
            || weather.windSpeed > 25
        
        if severeConditions {
            let calendar = Calendar.current
            var nextDate: Date?
            
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
            let tomorrowForecast = weatherForecast.first {
                calendar.isDate($0.date, inSameDayAs: tomorrow)
            }
            
            if let forecast = tomorrowForecast,
               isSuitableForWasteCollection(weather: forecast) {
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
        return weather.condition != .thunderstorm
            && weather.condition != .snow
            && !(weather.condition == .rain && weather.precipitation > 0.5)
            && weather.windSpeed < 20
    }
    
    /// Assess weather risk for a specific building and returns a summary.
    func assessWeatherRisk(for building: FrancoSphere.NamedCoordinate) -> String {
        guard let weather = currentWeatherData else { return "No significant risks" }
        
        var risks: [String] = []
        
        if weather.condition == .thunderstorm {
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
    // Alias method matching the name expected by TaskSchedulerService
    func fetchWeather(for building: FrancoSphere.NamedCoordinate) async -> Any? {
        return createWeatherEmergencyTask(for: building)
    }
}
