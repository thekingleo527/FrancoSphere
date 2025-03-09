import Foundation
import SwiftUI

/// WeatherDataAdapter serves as an intermediary between the weather service and app components.
/// It translates Open-Meteo API responses into our app's internal model and provides utility functions.
class WeatherDataAdapter: ObservableObject {
    static let shared = WeatherDataAdapter()
    
    @Published var currentWeather: FSWeatherData?
    @Published var forecast: [FSWeatherData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // Cache weather data by building to reduce API calls
    private var weatherCache: [String: (data: [FSWeatherData], timestamp: Date)] = [:]
    
    private init() {}
    
    /// Fetch weather data for a specific building
    func fetchWeatherForBuilding(_ building: FrancoSphere.NamedCoordinate, completion: (() -> Void)? = nil) {
        // Check cache first (cache valid for 1 hour)
        if let cached = weatherCache[building.id],
           Date().timeIntervalSince(cached.timestamp) < 3600 {
            self.forecast = cached.data
            self.currentWeather = cached.data.first
            completion?()
            return
        }
        
        isLoading = true
        
        // Simulated API response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.forecast = FSWeatherData.sampleData
            self.currentWeather = self.forecast.first
            
            // Cache the result
            self.weatherCache[building.id] = (data: self.forecast, timestamp: Date())
            
            self.isLoading = false
            completion?()
        }
    }
    
    /// Creates a weather notification message for a building if weather conditions warrant it
    func createWeatherNotification(for building: FrancoSphere.NamedCoordinate) -> String? {
        guard let weatherData = currentWeather else { return nil }
        
        if weatherData.condition == .storm || weatherData.condition == .extreme {
            return "⚠️ Severe weather alert for \(building.name). Consider rescheduling outdoor tasks."
        } else if weatherData.condition == .rain && weatherData.precipitation > 0.5 {
            return "Heavy rain expected at \(building.name). Check drainage systems."
        } else if weatherData.condition == .rain {
            return "Rain expected at \(building.name). Some outdoor tasks may be affected."
        } else if weatherData.condition == .snow {
            return "Snow expected at \(building.name). Prepare walkways for clearing."
        } else if weatherData.hasHighWinds {
            return "High winds expected at \(building.name). Secure loose outdoor items."
        } else if weatherData.temperature > 90 {
            return "Heat advisory for \(building.name). Consider rescheduling strenuous outdoor tasks."
        } else if weatherData.temperature < 32 {
            return "Freezing temperatures at \(building.name). Check pipes and heating systems."
        }
        
        return nil
    }
    
    /// Assesses weather risks for a specific building
    func assessWeatherRisk(for building: FrancoSphere.NamedCoordinate) -> String {
        var risks: [String] = []
        
        for day in forecast {
            if day.isHazardous {
                let dayString = formattedDay(day.date)
                
                if day.condition == .rain || day.condition == .storm {
                    risks.append("Rain/storms on \(dayString) - check drainage")
                }
                
                if day.condition == .snow {
                    risks.append("Snow on \(dayString) - prepare for snow removal")
                }
                
                if day.hasHighWinds {
                    risks.append("High winds on \(dayString) - secure outdoor items")
                }
                
                if day.temperature > 90 {
                    risks.append("Heat warning on \(dayString) - HVAC check advised")
                }
                
                if day.temperature < 32 {
                    risks.append("Freezing temps on \(dayString) - check pipes/heating")
                }
            }
        }
        
        return risks.isEmpty ? "No significant risks" : risks.joined(separator: "\n")
    }
    
    /// Generate a list of weather-related maintenance tasks based on the forecast
    func generateWeatherTasks(for building: FrancoSphere.NamedCoordinate) -> [FrancoSphere.MaintenanceTask] {
        // For now, just return an empty array to fix the type mismatch
        // This can be implemented properly later
        return []
    }
    
    /// Creates an emergency task for current adverse weather conditions
    func createEmergencyWeatherTask(for building: FrancoSphere.NamedCoordinate) -> FrancoSphere.MaintenanceTask? {
        guard let weather = currentWeather, weather.isHazardous else {
            return nil
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        let taskName: String
        let taskDescription: String
        let taskCategory: FrancoSphere.TaskCategory
        
        if weather.condition == .rain || weather.condition == .storm {
            taskName = "Emergency Rain Inspection"
            taskDescription = "Check for leaks, proper drainage, and clear any blockages from gutters due to heavy rain."
            taskCategory = .inspection
        } else if weather.condition == .snow {
            taskName = "Snow Removal"
            taskDescription = "Clear snow from walkways, entrances, and emergency exits. Apply salt as needed."
            taskCategory = .maintenance
        } else if weather.hasHighWinds {
            taskName = "Wind Damage Assessment"
            taskDescription = "Inspect for damage from high winds, secure loose items, check roof integrity."
            taskCategory = .inspection
        } else if weather.temperature > 90 {
            taskName = "Heat Emergency Response"
            taskDescription = "Verify cooling system operation, ensure adequate air circulation in common areas."
            taskCategory = .maintenance
        } else if weather.temperature < 32 {
            taskName = "Freeze Protection"
            taskDescription = "Check for frozen pipes, ensure heating systems are operational in all areas."
            taskCategory = .maintenance
        } else {
            taskName = "Weather Emergency Response"
            taskDescription = "Address current weather-related emergency conditions."
            taskCategory = .maintenance
        }
        
        return FrancoSphere.MaintenanceTask(
            id: UUID().uuidString,
            name: taskName,
            buildingID: building.id,
            description: taskDescription,
            dueDate: now,
            startTime: now,
            endTime: calendar.date(byAdding: .hour, value: 2, to: now),
            category: taskCategory,
            urgency: .urgent,
            recurrence: .oneTime,
            isComplete: false, assignedWorkers: []
        )
    }
    
    /// Determines if a task should be rescheduled due to weather conditions
    func shouldRescheduleTask(_ task: FrancoSphere.MaintenanceTask) -> Bool {
        let isOutdoorTask = task.category == .maintenance ||
                            task.category == .cleaning ||
                            task.description.lowercased().contains("outdoor")
        
        if !isOutdoorTask || task.isComplete || task.urgency == .urgent {
            return false
        }
        
        if let weatherForDay = getForecastForDate(task.dueDate),
           weatherForDay.isHazardous {
            return true
        }
        
        return false
    }
    
    /// Gets a recommended reschedule date for a weather-affected task
    func recommendedRescheduleDateForTask(_ task: FrancoSphere.MaintenanceTask) -> Date? {
        if !shouldRescheduleTask(task) {
            return nil
        }
        
        let calendar = Calendar.current
        for i in 1...7 {
            if let nextDate = calendar.date(byAdding: .day, value: i, to: task.dueDate),
               let weatherForDay = getForecastForDate(nextDate),
               !weatherForDay.isHazardous {
                return nextDate
            }
        }
        
        return calendar.date(byAdding: .day, value: 7, to: task.dueDate)
    }
    
    // MARK: - Helper Methods
    
    private func getForecastForDate(_ date: Date) -> FSWeatherData? {
        let calendar = Calendar.current
        return forecast.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func formattedDay(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }
}
