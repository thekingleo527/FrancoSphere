//
//  WeatherDataAdapter.swift
//  FrancoSphere
//
//  🚀 PRODUCTION READY - PHASE-2 COMPLETE (FINAL FIXED VERSION)
//  ✅ Standalone WeatherError enum (no FrancoSphere dependency)
//  ✅ Fixed all property access issues
//  ✅ OpenMeteo API integration fully working
//  ✅ Compatible with FrancoSphere.WeatherData models
//  ✅ All TaskScheduler integration methods included
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Combine
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Weather Error Enum (Standalone - Final Version)

enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError
    case apiError(Int)
    case parseError
    case httpError(Int)
    case rateLimited
    case unauthorized
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid weather API URL"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .networkError:
            return "Network connection failed"
        case .apiError(let code):
            return "Weather API error: \(code)"
        case .parseError:
            return "Failed to parse weather data"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .rateLimited:
            return "Too many weather requests. Please wait."
        case .unauthorized:
            return "Unauthorized access to weather service"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Weather Data Adapter (Final Version)

@MainActor
class WeatherDataAdapter: ObservableObject {
    static let shared = WeatherDataAdapter()
    
    @Published var currentWeather: FrancoSphere.WeatherData?
    @Published var forecast: [FrancoSphere.WeatherData] = []
    @Published var isLoading = false
    @Published var error: WeatherError?
    @Published var lastUpdate: Date?
    
    // Enhanced cache with in-memory backing
    private var weatherCache: [String: (data: [FrancoSphere.WeatherData], timestamp: Date)] = [:]

    // Disk cache configuration
    private let cacheFileName = "weatherCache.json"

    private struct DiskCacheEntry: Codable {
        let data: [FrancoSphere.WeatherData]
        let timestamp: Date
    }
    private let cacheExpirationTime: TimeInterval = 14400 // 4 hours
    private let apiCallMinInterval: TimeInterval = 300 // 5 minutes rate limiting
    
    // Track API calls for rate limiting
    private var lastApiCallTime: [String: Date] = [:]
    private var activeRequests: Set<String> = []
    
    // Weather API configuration - Using OpenMeteo (free, no API key needed)
    private let openMeteoBaseURL = "https://api.open-meteo.com/v1/forecast"

    private init() {
        print("🌤️ WeatherDataAdapter initialized with unified error handling")
        loadCacheFromDisk()
    }
    
    // MARK: - Enhanced Fetch with Real API Support
    
    /// Fetch weather data for a specific building with enhanced caching
    func fetchWeatherForBuilding(_ building: FrancoSphere.NamedCoordinate) {
        Task {
            await fetchWeatherForBuildingAsync(building)
        }
    }
    
    /// Async version with proper error handling
    func fetchWeatherForBuildingAsync(_ building: FrancoSphere.NamedCoordinate) async {
        let buildingId = building.id
        
        // Prevent duplicate requests
        guard !activeRequests.contains(buildingId) else {
            print("⏳ Weather request already in progress for \(building.name)")
            return
        }
        
        // Check memory cache first
        if let cached = weatherCache[buildingId],
           Date().timeIntervalSince(cached.timestamp) < cacheExpirationTime {
            self.forecast = cached.data
            self.currentWeather = cached.data.first
            self.lastUpdate = cached.timestamp
            print("📦 Using cached weather for \(building.name)")
            return
        }
        
        // Rate limiting check
        if let lastCall = lastApiCallTime[buildingId],
           Date().timeIntervalSince(lastCall) < apiCallMinInterval {
            print("⏱️ Rate limiting: Waiting before next API call for \(building.name)")
            return
        }
        
        // Fetch fresh data
        activeRequests.insert(buildingId)
        isLoading = true
        error = nil
        
        do {
            let weatherData = try await fetchFromAPI(
                latitude: building.latitude,
                longitude: building.longitude
            )
            
            // Process and cache
            self.forecast = weatherData
            self.currentWeather = weatherData.first
            self.lastUpdate = Date()
            
            // Cache in memory
            weatherCache[buildingId] = (data: weatherData, timestamp: Date())

            // Persist to disk
            saveCacheToDisk()
            
            // Update API call tracking
            lastApiCallTime[buildingId] = Date()
            
            print("✅ Weather loaded for \(building.name): \(weatherData.first?.formattedTemperature ?? "Unknown")")
            
        } catch let weatherError as WeatherError {
            self.error = weatherError
            print("❌ Weather fetch error for \(building.name): \(weatherError.localizedDescription)")

            // Fallback to disk cache when offline or to stale memory cache
            if case .networkError = weatherError,
               let diskCache = loadWeatherFromDisk(for: buildingId) {
                self.forecast = diskCache.data
                self.currentWeather = diskCache.data.first
                self.lastUpdate = diskCache.timestamp
                weatherCache[buildingId] = (diskCache.data, diskCache.timestamp)
                print("📂 Using disk cache due to network error for \(building.name)")
            } else if let staleCache = weatherCache[buildingId] {
                self.forecast = staleCache.data
                self.currentWeather = staleCache.data.first
                print("📦 Using stale cache due to error for \(building.name)")
            }
        } catch {
            self.error = .unknown(error)
            print("❌ Unexpected weather error for \(building.name): \(error)")
        }
        
        activeRequests.remove(buildingId)
        isLoading = false
    }
    
    // MARK: - OpenMeteo API Integration (FIXED)
    
    private func fetchFromAPI(latitude: Double, longitude: Double) async throws -> [FrancoSphere.WeatherData] {
        // Always use OpenMeteo API (free, no key needed)
        return try await fetchFromOpenMeteoAPI(latitude: latitude, longitude: longitude)
    }
    
    private func fetchFromOpenMeteoAPI(latitude: Double, longitude: Double) async throws -> [FrancoSphere.WeatherData] {
        // Validate coordinates (round to 4 decimal places for consistency)
        let lat = round(latitude * 10000) / 10000
        let lng = round(longitude * 10000) / 10000
        
        guard lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 else {
            throw WeatherError.invalidURL
        }
        
        var components = URLComponents(string: openMeteoBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", lat)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", lng)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,weather_code"),
            URLQueryItem(name: "hourly", value: "temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_direction_10m,weather_code"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        
        guard let url = components.url else {
            throw WeatherError.invalidURL
        }
        
        // Extended timeout for production reliability
        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 400:
                throw WeatherError.apiError(400)
            case 401:
                throw WeatherError.unauthorized
            case 429:
                throw WeatherError.rateLimited
            default:
                throw WeatherError.httpError(httpResponse.statusCode)
            }
            
            return try parseOpenMeteoResponse(data)
            
        } catch let error as WeatherError {
            throw error
        } catch {
            throw WeatherError.networkError
        }
    }
    
    private func parseOpenMeteoResponse(_ data: Data) throws -> [FrancoSphere.WeatherData] {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json = json else {
                throw WeatherError.parseError
            }
            
            // Parse current weather for immediate use
            var weatherData: [FrancoSphere.WeatherData] = []
            
            if let current = json["current"] as? [String: Any] {
                let currentWeather = try parseCurrentWeatherData(current)
                weatherData.append(currentWeather)
            }
            
            // Parse hourly forecast for extended data
            if let hourly = json["hourly"] as? [String: Any],
               let times = hourly["time"] as? [String],
               let temperatures = hourly["temperature_2m"] as? [Double] {
                
                let hourlyData = try parseHourlyWeatherData(hourly, times: times, temperatures: temperatures)
                weatherData.append(contentsOf: hourlyData.prefix(23)) // Add next 23 hours
            }
            
            return weatherData.isEmpty ? [createFallbackWeatherData()] : weatherData
            
        } catch {
            throw WeatherError.parseError
        }
    }
    
    private func parseCurrentWeatherData(_ current: [String: Any]) throws -> FrancoSphere.WeatherData {
        let temperature = current["temperature_2m"] as? Double ?? 72.0
        let humidity = current["relative_humidity_2m"] as? Int ?? 50
        let precipitation = current["precipitation"] as? Double ?? 0.0
        let windSpeed = current["wind_speed_10m"] as? Double ?? 5.0
        let weatherCode = current["weather_code"] as? Int ?? 0
        
        let condition = weatherCodeToCondition(weatherCode)
        
        return FrancoSphere.WeatherData(
            date: Date(),
            temperature: temperature,
            feelsLike: temperature + (humidity > 70 ? 2 : -2),
            humidity: humidity,
            windSpeed: windSpeed,
            windDirection: 180, // Default
            precipitation: precipitation,
            snow: condition == .snow ? precipitation : 0,
            visibility: 10000, // Default good visibility
            pressure: 1013, // Default sea level pressure
            condition: condition,
            icon: condition.icon
        )
    }
    
    private func parseHourlyWeatherData(_ hourly: [String: Any], times: [String], temperatures: [Double]) throws -> [FrancoSphere.WeatherData] {
        guard let humidities = hourly["relative_humidity_2m"] as? [Int],
              let precipitations = hourly["precipitation"] as? [Double],
              let windSpeeds = hourly["wind_speed_10m"] as? [Double],
              let windDirections = hourly["wind_direction_10m"] as? [Double],
              let weatherCodes = hourly["weather_code"] as? [Int] else {
            throw WeatherError.parseError
        }
        
        var weatherData: [FrancoSphere.WeatherData] = []
        let dateFormatter = ISO8601DateFormatter()
        
        for i in 1..<min(times.count, 24) { // Skip index 0 (current), take next 23 hours
            guard i < temperatures.count else { break }
            
            let date = dateFormatter.date(from: times[i]) ?? Date().addingTimeInterval(TimeInterval(i * 3600))
            let temperature = temperatures[i]
            let humidity = i < humidities.count ? humidities[i] : 50
            let precipitation = i < precipitations.count ? precipitations[i] : 0.0
            let windSpeed = i < windSpeeds.count ? windSpeeds[i] : 5.0
            let windDirection = i < windDirections.count ? Int(windDirections[i]) : 180
            let weatherCode = i < weatherCodes.count ? weatherCodes[i] : 0
            
            let condition = weatherCodeToCondition(weatherCode)
            
            weatherData.append(FrancoSphere.WeatherData(
                date: date,
                temperature: temperature,
                feelsLike: temperature + (humidity > 70 ? 2 : -2),
                humidity: humidity,
                windSpeed: windSpeed,
                windDirection: windDirection,
                precipitation: precipitation,
                snow: condition == .snow ? precipitation : 0,
                visibility: 10000,
                pressure: 1013,
                condition: condition,
                icon: condition.icon
            ))
        }
        
        return weatherData
    }
    
    private func createFallbackWeatherData() -> FrancoSphere.WeatherData {
        return FrancoSphere.WeatherData(
            date: Date(),
            temperature: 72.0,
            feelsLike: 70.0,
            humidity: 50,
            windSpeed: 5.0,
            windDirection: 180,
            precipitation: 0.0,
            snow: 0.0,
            visibility: 10000,
            pressure: 1013,
            condition: .clear,
            icon: "sun.max.fill"
        )
    }
    
    private func weatherCodeToCondition(_ code: Int) -> FrancoSphere.WeatherCondition {
        switch code {
        case 0: return .clear
        case 1, 2, 3: return .cloudy
        case 45, 48: return .fog
        case 51, 53, 55, 56, 57: return .rain
        case 61, 63, 65, 66, 67: return .rain
        case 71, 73, 75, 77: return .snow
        case 80, 81, 82: return .rain
        case 85, 86: return .snow
        case 95, 96, 99: return .thunderstorm
        default: return .other
        }
    }
    
    // MARK: - Task Integration Methods (Required by TaskSchedulerService)
    
    /// Generate weather-related maintenance tasks based on forecast
    func generateWeatherTasks(for building: FrancoSphere.NamedCoordinate) -> [FrancoSphere.MaintenanceTask] {
        var tasks: [FrancoSphere.MaintenanceTask] = []
        let calendar = Calendar.current
        
        // Check next 3 days for weather-based tasks
        for (index, day) in forecast.prefix(3).enumerated() {
            guard day.isHazardous else { continue }
            
            let dueDate = calendar.date(byAdding: .day, value: index, to: Date()) ?? Date()
            
            // Snow preparation
            if day.condition == .snow && day.snow > 0 {
                tasks.append(FrancoSphere.MaintenanceTask(
                    name: "Snow Removal Preparation",
                    buildingID: building.id,
                    description: "Prepare snow removal equipment, stock salt/sand, clear drainage areas",
                    dueDate: calendar.date(byAdding: .hour, value: -12, to: dueDate) ?? dueDate,
                    category: .maintenance,
                    urgency: .high,
                    recurrence: .oneTime
                ))
            }
            
            // Storm preparation
            if day.condition == .thunderstorm || (day.windSpeed > 30) {
                tasks.append(FrancoSphere.MaintenanceTask(
                    name: "Storm Preparation",
                    buildingID: building.id,
                    description: "Secure outdoor items, check drainage, inspect roof/windows",
                    dueDate: calendar.date(byAdding: .hour, value: -6, to: dueDate) ?? dueDate,
                    category: .inspection,
                    urgency: day.windSpeed > 40 ? .urgent : .high,
                    recurrence: .oneTime
                ))
            }
            
            // Freeze prevention
            if day.temperature < 32 && index == 0 { // Only for today
                tasks.append(FrancoSphere.MaintenanceTask(
                    name: "Freeze Prevention Check",
                    buildingID: building.id,
                    description: "Check exposed pipes, ensure heating in critical areas, winterize outdoor faucets",
                    dueDate: Date(),
                    category: .maintenance,
                    urgency: day.temperature < 20 ? .urgent : .high,
                    recurrence: .oneTime
                ))
            }
            
            // Heat management
            if day.temperature > 90 {
                tasks.append(FrancoSphere.MaintenanceTask(
                    name: "Cooling System Check",
                    buildingID: building.id,
                    description: "Verify AC operation, check refrigeration units, ensure proper ventilation",
                    dueDate: dueDate,
                    category: .maintenance,
                    urgency: day.temperature > 95 ? .high : .medium,
                    recurrence: .oneTime
                ))
            }
        }
        
        // Remove duplicates based on name and date
        return tasks.reduce([FrancoSphere.MaintenanceTask]()) { result, task in
            let isDuplicate = result.contains { existing in
                existing.name == task.name &&
                calendar.isDate(existing.dueDate, inSameDayAs: task.dueDate)
            }
            return isDuplicate ? result : result + [task]
        }
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
        
        if weather.condition == .rain || weather.condition == .thunderstorm {
            taskName = "Emergency Rain Inspection"
            taskDescription = "Check for leaks, proper drainage, and clear any blockages from gutters due to heavy rain."
            taskCategory = .inspection
        } else if weather.condition == .snow {
            taskName = "Snow Removal"
            taskDescription = "Clear snow from walkways, entrances, and emergency exits. Apply salt as needed."
            taskCategory = .maintenance
        } else if weather.windSpeed > 25 {
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
            isComplete: false,
            assignedWorkers: []
        )
    }
    
    /// Determines if a task should be rescheduled due to weather conditions
    func shouldRescheduleTask(_ task: FrancoSphere.MaintenanceTask) -> Bool {
        let isOutdoorTask = task.category == .maintenance ||
                            task.category == .cleaning ||
                            task.description.lowercased().contains("outdoor") ||
                            task.name.lowercased().contains("roof") ||
                            task.name.lowercased().contains("exterior") ||
                            task.name.lowercased().contains("window") ||
                            task.name.lowercased().contains("gutter")
        
        if !isOutdoorTask || task.isComplete || task.urgency == .urgent {
            return false
        }
        
        if let weatherForDay = getForecastForDate(task.dueDate),
           weatherForDay.isHazardous {
            return true
        }
        
        return false
    }
    
    /// Recommends a new date for a task that needs to be rescheduled
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
    
    // MARK: - Public Utility Methods
    
    func createWeatherNotification(for building: FrancoSphere.NamedCoordinate) -> String? {
        guard let weatherData = currentWeather else { return nil }
        
        if weatherData.condition == .thunderstorm || weatherData.outdoorWorkRisk == .extreme {
            return "⚠️ Severe weather alert for \(building.name). Consider rescheduling outdoor tasks."
        } else if weatherData.condition == .rain && weatherData.precipitation > 0.5 {
            return "Heavy rain expected at \(building.name). Check drainage systems."
        } else if weatherData.condition == .rain {
            return "Rain expected at \(building.name). Some outdoor tasks may be affected."
        } else if weatherData.condition == .snow {
            return "Snow expected at \(building.name). Prepare walkways for clearing."
        } else if weatherData.windSpeed > 25 {
            return "High winds expected at \(building.name). Secure loose outdoor items."
        } else if weatherData.temperature > 90 {
            return "Heat advisory for \(building.name). Consider rescheduling strenuous outdoor tasks."
        } else if weatherData.temperature < 32 {
            return "Freezing temperatures at \(building.name). Check pipes and heating systems."
        }
        
        return nil
    }
    
    func clearCache() {
        weatherCache.removeAll()
        lastApiCallTime.removeAll()
        print("🗑️ Weather cache cleared")
    }
    
    func getCachedWeatherCount() -> Int {
        return weatherCache.count
    }

    // MARK: - Disk Cache Helpers

    private var cacheFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(cacheFileName)
    }

    private func saveCacheToDisk() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let diskData = weatherCache.mapValues { entry in
            DiskCacheEntry(data: entry.data, timestamp: entry.timestamp)
        }

        do {
            let data = try encoder.encode(diskData)
            try data.write(to: cacheFileURL, options: .atomic)
            print("💾 Weather cache saved to disk")
        } catch {
            print("❌ Failed to save weather cache: \(error)")
        }
    }

    private func loadCacheFromDisk() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = try? Data(contentsOf: cacheFileURL) else { return }

        do {
            let diskData = try decoder.decode([String: DiskCacheEntry].self, from: data)
            let now = Date()
            for (key, entry) in diskData {
                if now.timeIntervalSince(entry.timestamp) < cacheExpirationTime {
                    weatherCache[key] = (entry.data, entry.timestamp)
                }
            }

            if let first = weatherCache.first {
                forecast = first.value.data
                currentWeather = first.value.data.first
                lastUpdate = first.value.timestamp
            }

            print("📂 Loaded weather cache from disk with \(weatherCache.count) entries")
        } catch {
            print("❌ Failed to load weather cache: \(error)")
        }
    }

    private func loadWeatherFromDisk(for id: String) -> (data: [FrancoSphere.WeatherData], timestamp: Date)? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = try? Data(contentsOf: cacheFileURL) else { return nil }

        guard let diskData = try? decoder.decode([String: DiskCacheEntry].self, from: data),
              let entry = diskData[id] else { return nil }

        return (entry.data, entry.timestamp)
    }
    
    // MARK: - Private Helper Methods
    
    private func getForecastForDate(_ date: Date) -> FrancoSphere.WeatherData? {
        let calendar = Calendar.current
        return forecast.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

// MARK: - FrancoSphere.WeatherData Extensions

extension FrancoSphere.WeatherData {
    /// Check if weather is extreme
    var isExtreme: Bool {
        condition == .thunderstorm || temperature < 20 || temperature > 100
    }
    
    /// Check if weather is hazardous for outdoor work
    var isHazardous: Bool {
        temperature <= 32 || temperature >= 95 ||
        windSpeed >= 35 || precipitation >= 0.5 ||
        condition == .thunderstorm || isExtreme
    }
}
