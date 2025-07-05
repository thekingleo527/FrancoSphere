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


// MARK: - FSWeatherAlert
struct FSWeatherAlert: Identifiable {
    let id: String
    let buildingId: String
    let buildingName: String
    let title: String
    let message: String
    let icon: String
    let color: Color
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - FSOpenMeteoData
struct FSOpenMeteoData: Codable {
    let latitude, longitude: Double?
    let generationtimeMs: Double?
    let utcOffsetSeconds: Int?
    let timezone, timezoneAbbreviation: String?
    let elevation: Double?
    let hourly: HourlyData?
    let daily: DailyData?
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
        case generationtimeMs = "generationtime_ms"
        case utcOffsetSeconds = "utc_offset_seconds"
        case timezone
        case timezoneAbbreviation = "timezone_abbreviation"
        case elevation
        case hourly, daily
    }
}

struct HourlyData: Codable {
    let time: [String]?
    let temperature2m: [Double]?
    let precipitation: [Double]?
    let weathercode: [Int]?
    let windspeed10m: [Double]?
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case precipitation, weathercode
        case windspeed10m = "windspeed_10m"
    }
}

struct DailyData: Codable {
    let time: [String]?
    let weathercode: [Int]?
    let temperature2mMax, temperature2mMin: [Double]?
    let precipitationSum: [Double]?
    
    enum CodingKeys: String, CodingKey {
        case time, weathercode
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
    }
}

// MARK: - FSWeatherData
struct FSWeatherData: Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let temperatureHigh: Double
    let temperatureLow: Double
    let condition: WeatherCondition
    let precipitation: Double
    let windSpeed: Double
    let humidity: Double
    let uvIndex: Int
    
    enum WeatherCondition: String, CaseIterable {
        case clear = "Clear"
        case partlyCloudy = "Partly Cloudy"
        case cloudy = "Cloudy"
        case rain = "Rain"
        case snow = "Snow"
        case storm = "Storm"
        case extreme = "Extreme"
        
        var icon: String {
            switch self {
            case .clear: return "sun.max.fill"
            case .partlyCloudy: return "cloud.sun.fill"
            case .cloudy: return "cloud.fill"
            case .rain: return "cloud.rain.fill"
            case .snow: return "cloud.snow.fill"
            case .storm: return "cloud.bolt.rain.fill"
            case .extreme: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .clear: return .yellow
            case .partlyCloudy: return .orange
            case .cloudy: return .gray
            case .rain: return .blue
            case .snow: return .cyan
            case .storm: return .purple
            case .extreme: return .red
            }
        }
    }
    
    enum OutdoorWorkRisk: String {
        case low = "Low Risk"
        case moderate = "Moderate Risk"
        case high = "High Risk"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .orange
            case .high: return .red
            }
        }
    }
    
    var hasPrecipitation: Bool {
        return precipitation > 0.1
        || condition == .rain
        || condition == .snow
        || condition == .storm
    }
    
    var hasHighWinds: Bool {
        return windSpeed > 15.0
    }
    
    var isHazardous: Bool {
        return hasPrecipitation || hasHighWinds || condition == .extreme
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedTemperature: String {
        return "\(Int(temperature))°F"
    }
    
    var formattedHighLow: String {
        return "H: \(Int(temperatureHigh))° L: \(Int(temperatureLow))°"
    }
    
    var outdoorWorkRisk: OutdoorWorkRisk {
        if isHazardous || temperature > 90 || temperature < 32 {
            return .high
        } else if hasHighWinds || precipitation > 0.05 || temperature > 85 || temperature < 40 {
            return .moderate
        } else {
            return .low
        }
    }
    
    // MARK: - Sample Data
    
    static var sampleData: [FSWeatherData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return [
            FSWeatherData(
                date: today,
                temperature: 72,
                temperatureHigh: 78,
                temperatureLow: 65,
                condition: .clear,
                precipitation: 0,
                windSpeed: 5,
                humidity: 45,
                uvIndex: 6
            ),
            FSWeatherData(
                date: calendar.date(byAdding: .day, value: 1, to: today)!,
                temperature: 68,
                temperatureHigh: 74,
                temperatureLow: 62,
                condition: .partlyCloudy,
                precipitation: 0,
                windSpeed: 8,
                humidity: 50,
                uvIndex: 5
            ),
            FSWeatherData(
                date: calendar.date(byAdding: .day, value: 2, to: today)!,
                temperature: 65,
                temperatureHigh: 70,
                temperatureLow: 58,
                condition: .rain,
                precipitation: 0.35,
                windSpeed: 12,
                humidity: 75,
                uvIndex: 2
            ),
            FSWeatherData(
                date: calendar.date(byAdding: .day, value: 3, to: today)!,
                temperature: 60,
                temperatureHigh: 65,
                temperatureLow: 55,
                condition: .rain,
                precipitation: 0.65,
                windSpeed: 18,
                humidity: 85,
                uvIndex: 1
            ),
            FSWeatherData(
                date: calendar.date(byAdding: .day, value: 4, to: today)!,
                temperature: 63,
                temperatureHigh: 68,
                temperatureLow: 57,
                condition: .cloudy,
                precipitation: 0.1,
                windSpeed: 10,
                humidity: 70,
                uvIndex: 3
            ),
            FSWeatherData(
                date: calendar.date(byAdding: .day, value: 5, to: today)!,
                temperature: 67,
                temperatureHigh: 72,
                temperatureLow: 60,
                condition: .partlyCloudy,
                precipitation: 0,
                windSpeed: 7,
                humidity: 55,
                uvIndex: 4
            ),
            FSWeatherData(
                date: calendar.date(byAdding: .day, value: 6, to: today)!,
                temperature: 70,
                temperatureHigh: 75,
                temperatureLow: 63,
                condition: .clear,
                precipitation: 0,
                windSpeed: 5,
                humidity: 48,
                uvIndex: 6
            )
        ]
    }
    
    // Fixed Task Creation Code with Proper Variable Scope
    
    static func generateWeatherRelatedTasks(forBuilding buildingId: String) -> [MaintenanceTask] {
        var weatherTasks: [MaintenanceTask] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Sample tasks based on the forecast
        if let rainDay = sampleData.first(where: { $0.condition == .rain || $0.condition == .storm }) {
            let rainDate = calendar.date(byAdding: .day, value: -1, to: rainDay.date)!
            
            // Pre-rain check task
            weatherTasks.append(MaintenanceTask(
                id: UUID().uuidString,
                name: "Check Rain Gutters & Drainage",
                buildingID: buildingId,
                description: "Inspect and clear all gutters, downspouts, and drainage areas before expected rain.",
                dueDate: rainDate,
                startTime: nil,
                endTime: nil,
                category: .maintenance,
                urgency: .medium,
                recurrence: .none,
                isComplete: false,
                assignedWorkers: []
            ))
        }
        
        // Check for high temperature days
        if let hotDay = sampleData.first(where: { $0.temperature > 85 }) {
            // HVAC check task
            weatherTasks.append(MaintenanceTask(
                id: UUID().uuidString,
                name: "HVAC System Check for Heat Wave",
                buildingID: buildingId,
                description: "Inspect and ensure all cooling systems are functioning properly before high temperatures.",
                dueDate: calendar.date(byAdding: .day, value: -1, to: hotDay.date)!,
                startTime: nil,
                endTime: nil,
                category: .maintenance,
                urgency: .high,
                recurrence: .none,
                isComplete: false,
                assignedWorkers: []
            ))
        }
        
        // Check for freezing temperature days
        if let coldDay = sampleData.first(where: { $0.temperatureLow < 32 }) {
            // Pipe insulation check task
            weatherTasks.append(MaintenanceTask(
                id: UUID().uuidString,
                name: "Freeze Prevention Check",
                buildingID: buildingId,
                description: "Inspect pipe insulation and heating systems before freezing temperatures.",
                dueDate: calendar.date(byAdding: .day, value: -1, to: coldDay.date)!,
                startTime: nil,
                endTime: nil,
                category: .maintenance,
                urgency: .high,
                recurrence: .none,
                isComplete: false,
                assignedWorkers: []
            ))
        }
        
        // High wind task
        if let windyDay = sampleData.first(where: { $0.windSpeed > 20 }) {
            // Secure loose items task
            weatherTasks.append(MaintenanceTask(
                id: UUID().uuidString,
                name: "Secure Outdoor Items",
                buildingID: buildingId,
                description: "Secure or remove loose items from roof and outdoor areas before high winds.",
                dueDate: calendar.date(byAdding: .day, value: -1, to: windyDay.date)!,
                startTime: nil,
                endTime: nil,
                category: .maintenance,
                urgency: .medium,
                recurrence: .none,
                isComplete: false,
                assignedWorkers: []
            ))
        }
        
        // Always add a general weather preparedness task
        weatherTasks.append(MaintenanceTask(
            id: UUID().uuidString,
            name: "Weekly Weather Preparedness Check",
            buildingID: buildingId,
            description: "Conduct general weather preparedness inspection of the building.",
            dueDate: tomorrow,
            startTime: nil,
            endTime: nil,
            category: .inspection,
            urgency: .low,
            recurrence: .weekly,
            isComplete: false,
            assignedWorkers: []
        ))
        
        return weatherTasks
    }
}
