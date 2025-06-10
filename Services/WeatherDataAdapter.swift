// WeatherDataAdapter.swift
// FrancoSphere v1.1 - Fixed version without SQLiteManager weather methods

import Foundation
import SwiftUI
import Combine

// MARK: - Weather Data Adapter

@MainActor
class WeatherDataAdapter: ObservableObject {
    static let shared = WeatherDataAdapter()
    
    @Published var currentWeather: FrancoSphere.WeatherData?
    @Published var forecast: [FrancoSphere.WeatherData] = []
    @Published var isLoading = false
    @Published var error: WeatherError?
    @Published var lastUpdate: Date?
    
    // Enhanced cache with SQLite backing
    private var weatherCache: [String: (data: [FrancoSphere.WeatherData], timestamp: Date)] = [:]
    private let cacheExpirationTime: TimeInterval = 14400 // 4 hours
    private let apiCallMinInterval: TimeInterval = 300 // 5 minutes rate limiting
    
    // Track API calls for rate limiting
    private var lastApiCallTime: [String: Date] = [:]
    private var activeRequests: Set<String> = []
    
    // SQLite manager instance
    private var sqliteManager: SQLiteManager?
    
    // Weather API configuration - Using OpenMeteo (free, no API key needed)
    private let openMeteoBaseURL = "https://api.open-meteo.com/v1/forecast"
    
    private init() {
        // Initialize SQLite manager
        Task {
            do {
                self.sqliteManager = try await SQLiteManager.start()
                await loadCachedData()
            } catch {
                print("❌ Failed to initialize SQLiteManager: \(error)")
            }
        }
    }
    
    // MARK: - Enhanced Fetch with Real API Support
    
    /// Fetch weather data for a specific building with enhanced caching
    func fetchWeatherForBuilding(_ building: FrancoSphere.NamedCoordinate) {
        // Use actor-safe async version
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
        
        // Check memory cache first (faster than SQLite)
        if let cached = weatherCache[buildingId],
           Date().timeIntervalSince(cached.timestamp) < cacheExpirationTime {
            self.forecast = cached.data
            self.currentWeather = cached.data.first
            self.lastUpdate = cached.timestamp
            return
        }
        
        // Rate limiting check
        if let lastCall = lastApiCallTime[buildingId],
           Date().timeIntervalSince(lastCall) < apiCallMinInterval {
            print("⏱️ Rate limiting: Waiting before next API call")
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
            
            // Update API call tracking
            lastApiCallTime[buildingId] = Date()
            
            // Generate weather-based tasks if needed
            await generateAutomatedTasks(for: building, weather: weatherData)
            
        } catch {
            self.error = error as? WeatherError ?? .unknown(error)
            print("❌ Weather fetch error: \(error)")
            
            // Fallback to stale cache if available
            if let staleCache = weatherCache[buildingId] {
                self.forecast = staleCache.data
                self.currentWeather = staleCache.data.first
                print("📦 Using stale cache due to error")
            }
        }
        
        activeRequests.remove(buildingId)
        isLoading = false
    }
    
    // MARK: - API Integration (OpenMeteo - no API key needed)
    
    private func fetchFromAPI(latitude: Double, longitude: Double) async throws -> [FrancoSphere.WeatherData] {
        // Always use OpenMeteo API (free, no key needed)
        return try await fetchFromOpenMeteoAPI(latitude: latitude, longitude: longitude)
    }
    
    private func fetchFromOpenMeteoAPI(latitude: Double, longitude: Double) async throws -> [FrancoSphere.WeatherData] {
        var components = URLComponents(string: openMeteoBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "hourly", value: "temperature_2m,relativehumidity_2m,precipitation,windspeed_10m,winddirection_10m,weathercode,snow_depth,visibility,pressure_msl"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "windspeed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "America/New_York"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        
        guard let url = components.url else {
            throw WeatherError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw WeatherError.httpError(httpResponse.statusCode)
        }
        
        return try parseOpenMeteoResponse(data)
    }
    
    private func parseOpenMeteoResponse(_ data: Data) throws -> [FrancoSphere.WeatherData] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(OpenMeteoResponse.self, from: data)
        
        var weatherData: [FrancoSphere.WeatherData] = []
        
        // Convert hourly data to WeatherData
        for i in 0..<min(response.hourly.time.count, 168) { // Max 7 days
            guard i < response.hourly.temperature_2m.count else { break }
            
            // Parse ISO8601 date
            let dateFormatter = ISO8601DateFormatter()
            let date = dateFormatter.date(from: response.hourly.time[i]) ?? Date()
            
            // Extract values with defaults
            let temperature = response.hourly.temperature_2m[i]
            let humidity = response.hourly.relativehumidity_2m[i]
            let windSpeed = response.hourly.windspeed_10m[i]
            let windDirection = Int(response.hourly.winddirection_10m?[i] ?? 0)
            let precipitation = response.hourly.precipitation[i]
            let snow = response.hourly.snow_depth?[i] ?? 0
            let visibility = Int(response.hourly.visibility?[i] ?? 10000)
            let pressure = Int(response.hourly.pressure_msl?[i] ?? 1013)
            
            // Map weather code to condition
            let weatherCode = response.hourly.weathercode[i]
            let condition = mapWeatherCode(weatherCode)
            
            // Create icon based on condition
            let icon = mapConditionToIcon(condition)
            
            weatherData.append(FrancoSphere.WeatherData(
                date: date,
                temperature: temperature,
                feelsLike: temperature - 2, // Simple approximation
                humidity: humidity,
                windSpeed: windSpeed,
                windDirection: windDirection,
                precipitation: precipitation,
                snow: snow,
                visibility: visibility,
                pressure: pressure,
                condition: condition,
                icon: icon
            ))
        }
        
        return weatherData
    }
    
    // MARK: - Mock Data Creation
    
    private func createMockWeatherData() -> [FrancoSphere.WeatherData] {
        var weatherData: [FrancoSphere.WeatherData] = []
        let calendar = Calendar.current
        
        // Create 24 hours of mock data
        for hour in 0..<24 {
            let date = calendar.date(byAdding: .hour, value: hour, to: Date()) ?? Date()
            
            // Vary conditions throughout the day
            let condition: FrancoSphere.WeatherCondition = {
                switch hour {
                case 0...6: return .clear
                case 7...12: return .cloudy
                case 13...15: return .rain
                case 16...18: return .cloudy
                default: return .clear
                }
            }()
            
            let temperature = 65.0 + Double(hour) * 0.5 + Double.random(in: -5...5)
            let precipitation = condition == .rain ? Double.random(in: 0.1...0.5) : 0
            
            weatherData.append(FrancoSphere.WeatherData(
                date: date,
                temperature: temperature,
                feelsLike: temperature - 2,
                humidity: Int.random(in: 40...80),
                windSpeed: Double.random(in: 5...20),
                windDirection: Int.random(in: 0...360),
                precipitation: precipitation,
                snow: 0,
                visibility: condition == .fog ? 1000 : 10000,
                pressure: Int.random(in: 1010...1020),
                condition: condition,
                icon: mapConditionToIcon(condition)
            ))
        }
        
        return weatherData
    }
    
    // MARK: - Cache Management (Memory Only for now)
    
    private func loadCachedData() async {
        // Since SQLite weather cache methods aren't available,
        // we'll just use memory cache for now
        print("📦 Using memory-only cache for weather data")
    }
    
    // MARK: - Enhanced Risk Assessment
    
    /// Assesses weather risks for a specific building with more detail
    func assessWeatherRisk(for building: FrancoSphere.NamedCoordinate) -> String {
        var risks: [String] = []
        
        for day in forecast.prefix(7) { // Check 7 days instead of all
            if day.isHazardous {
                let dayString = formattedDay(day.date)
                let risk = assessDayRisk(day, dayString: dayString)
                if !risk.isEmpty {
                    risks.append(risk)
                }
            }
        }
        
        // Add building-specific risks
        if building.name.contains("Cove Park") && currentWeather?.windSpeed ?? 0 > 20 {
            risks.insert("⚠️ Park location: Extra vulnerable to wind damage", at: 0)
        }
        
        if risks.isEmpty {
            return "✅ No significant weather risks for the next 7 days"
        }
        
        // Prioritize critical risks
        let sortedRisks = risks.sorted { risk1, risk2 in
            let priority1 = risk1.contains("⚠️") || risk1.contains("🚨") ? 0 : 1
            let priority2 = risk2.contains("⚠️") || risk2.contains("🚨") ? 0 : 1
            return priority1 < priority2
        }
        
        return sortedRisks.prefix(5).joined(separator: "\n")
    }
    
    private func assessDayRisk(_ day: FrancoSphere.WeatherData, dayString: String) -> String {
        var risks: [String] = []
        
        // Temperature extremes
        if day.temperature < 20 {
            risks.append("🚨 Extreme cold")
        } else if day.temperature < 32 {
            risks.append("❄️ Freezing temps")
        } else if day.temperature > 95 {
            risks.append("🔥 Extreme heat")
        } else if day.temperature > 85 {
            risks.append("☀️ High heat")
        }
        
        // Precipitation
        if day.condition == .thunderstorm || (day.condition == .rain && day.precipitation > 0.5) {
            risks.append("⛈️ Heavy rain/storms")
        } else if day.condition == .snow {
            risks.append("🌨️ Snow")
        } else if day.condition == .rain {
            risks.append("🌧️ Rain")
        }
        
        // Wind
        if day.windSpeed > 35 {
            risks.append("💨 Dangerous winds")
        } else if day.windSpeed > 20 {
            risks.append("🌬️ High winds")
        }
        
        if risks.isEmpty {
            return ""
        }
        
        return "\(dayString): \(risks.joined(separator: ", "))"
    }
    
    // MARK: - Task Generation
    
    /// Generate weather-related maintenance tasks based on the forecast
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
    
    // MARK: - Automated Task Generation
    
    private func generateAutomatedTasks(for building: FrancoSphere.NamedCoordinate, weather: [FrancoSphere.WeatherData]) async {
        guard let current = weather.first else { return }
        
        // Only auto-generate for severe conditions
        guard current.isHazardous && (
            current.condition == .thunderstorm ||
            current.temperature < 25 ||
            current.temperature > 95 ||
            current.windSpeed > 35
        ) else { return }
        
        // Check if we already have weather tasks for today
        let existingTasks = await TaskManager.shared.fetchTasks(
            forBuilding: building.id,
            includePastTasks: false
        )
        
        let hasWeatherTask = existingTasks.contains { task in
            task.name.contains("Weather") || task.name.contains("Emergency")
        }
        
        if !hasWeatherTask {
            // Create emergency task
            if let emergencyTask = createEmergencyWeatherTask(for: building) {
                _ = await TaskManager.shared.createTask(emergencyTask)
                print("🚨 Auto-generated emergency weather task for \(building.name)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateOverallRiskScore(for weatherData: [FrancoSphere.WeatherData]) -> Double {
        guard !weatherData.isEmpty else { return 0 }
        
        let riskScores = weatherData.prefix(24).map { data -> Double in
            var score = 0.0
            
            // Temperature risk
            if data.temperature < 32 { score += 0.3 }
            if data.temperature < 20 { score += 0.5 }
            if data.temperature > 90 { score += 0.3 }
            if data.temperature > 95 { score += 0.5 }
            
            // Precipitation risk
            if data.condition == .rain { score += 0.2 }
            if data.condition == .snow { score += 0.4 }
            if data.condition == .thunderstorm { score += 0.6 }
            if data.precipitation > 0.5 { score += 0.3 }
            
            // Wind risk
            if data.windSpeed > 20 { score += 0.3 }
            if data.windSpeed > 35 { score += 0.5 }
            
            return min(score, 1.0)
        }
        
        return riskScores.max() ?? 0
    }
    
    private func mapWeatherCode(_ code: Int) -> FrancoSphere.WeatherCondition {
        switch code {
        case 0...1: return .clear
        case 2...48: return .cloudy
        case 51...67, 80...82: return .rain
        case 71...77, 85...86: return .snow
        case 95...99: return .thunderstorm
        case 45...48: return .fog
        default: return .other
        }
    }
    
    private func mapConditionToIcon(_ condition: FrancoSphere.WeatherCondition) -> String {
        switch condition {
        case .clear: return "01d"
        case .cloudy: return "03d"
        case .rain: return "10d"
        case .snow: return "13d"
        case .thunderstorm: return "11d"
        case .fog: return "50d"
        case .other: return "01d"
        }
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
    
    // MARK: - Public Methods
    
    func createWeatherNotification(for building: FrancoSphere.NamedCoordinate) -> String? {
        guard let weatherData = currentWeather else { return nil }
        
        if weatherData.condition == .thunderstorm || weatherData.isExtreme {
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
    
    private func getForecastForDate(_ date: Date) -> FrancoSphere.WeatherData? {
        let calendar = Calendar.current
        return forecast.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

// MARK: - Weather Errors

enum WeatherError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case rateLimited
    case unauthorized
    case httpError(Int)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Weather API key not configured"
        case .invalidURL:
            return "Invalid weather API URL"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .rateLimited:
            return "Too many weather requests. Please wait."
        case .unauthorized:
            return "Invalid API key"
        case .httpError(let code):
            return "Weather service error: \(code)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - OpenMeteo Response Models

private struct OpenMeteoResponse: Codable {
    let hourly: HourlyData
    
    struct HourlyData: Codable {
        let time: [String]
        let temperature_2m: [Double]
        let relativehumidity_2m: [Int]
        let precipitation: [Double]
        let windspeed_10m: [Double]
        let winddirection_10m: [Double]?
        let weathercode: [Int]
        let snow_depth: [Double]?
        let visibility: [Double]?
        let pressure_msl: [Double]?
    }
}

// MARK: - WeatherData Extensions

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
