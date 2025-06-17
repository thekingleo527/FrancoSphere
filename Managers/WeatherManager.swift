// FILE: Managers/WeatherManager.swift
//
//  WeatherManager.swift
//  FrancoSphere
//
//  🌦️ FIXED VERSION - Building type reference removed
//  ✅ Uses only FrancoSphere.NamedCoordinate (no Building type)
//  ✅ Implements fetchWithRetry() with exponential backoff
//  ✅ Enhanced error handling and surface loading states
//

import Foundation
import Combine
import SwiftUI

@MainActor
class WeatherManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = WeatherManager()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentWeather: FrancoSphere.WeatherData?
    @Published var buildingWeatherMap: [String: FrancoSphere.WeatherData] = [:]
    @Published var lastUpdateTime: Date?
    
    // MARK: - Private Properties
    private let maxRetries = 3
    private let baseDelaySeconds: Double = 2.0
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - 🚀 MISSING METHOD FIX: getWeatherForBuilding() for MySitesCard
    
    /// Gets weather data for a specific building by ID
    /// - Parameter buildingId: The building ID to look up
    /// - Returns: WeatherData if found, nil otherwise
    func getWeatherForBuilding(_ buildingId: String) -> FrancoSphere.WeatherData? {
        return buildingWeatherMap[buildingId]
    }
    
    // MARK: - 🚀 PRODUCTION METHOD: fetchWithRetry() with Exponential Backoff
    
    /// Enhanced weather fetch with exponential backoff retry logic (2→4→8s delays)
    /// - Parameters:
    ///   - coordinate: Building coordinate to fetch weather for
    ///   - buildingId: Optional building ID to store in weather map
    /// - Returns: WeatherData if successful, throws error if all retries fail
    func fetchWithRetry(for coordinate: FrancoSphere.NamedCoordinate, buildingId: String? = nil) async throws -> FrancoSphere.WeatherData {
        var lastError: Error?
        
        // Reset state for new fetch
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        for attempt in 0..<maxRetries {
            do {
                print("🌤️ Weather attempt \(attempt + 1)/\(maxRetries) for \(coordinate.name)")
                
                // Calculate timeout based on attempt (2s, 4s, 6s)
                let timeout = TimeInterval(baseDelaySeconds + (Double(attempt) * 2))
                
                // Fetch weather with current timeout
                let weather = try await fetchOpenMeteoWithValidation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    buildingName: coordinate.name,
                    timeout: timeout
                )
                
                // Success! Update state and return
                await MainActor.run {
                    self.isLoading = false
                    self.error = nil
                    self.lastUpdateTime = Date()
                    
                    // Store in building weather map if ID provided
                    if let buildingId = buildingId {
                        self.buildingWeatherMap[buildingId] = weather
                    }
                    
                    // Update current weather if this is the first successful fetch
                    if self.currentWeather == nil {
                        self.currentWeather = weather
                    }
                }
                
                print("✅ Weather success for \(coordinate.name): \(weather.formattedTemperature)")
                return weather
                
            } catch {
                lastError = error
                
                // If this isn't the last attempt, wait with exponential backoff
                if attempt < maxRetries - 1 {
                    let delaySeconds = pow(2.0, Double(attempt + 1)) // 2s, 4s, 8s delays
                    print("⚠️ Weather attempt \(attempt + 1) failed: \(error.localizedDescription)")
                    print("🔄 Retrying in \(delaySeconds)s...")
                    
                    try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                }
            }
        }
        
        // All retries failed - update state and throw error
        await MainActor.run {
            self.isLoading = false
            self.error = lastError
        }
        
        print("❌ Weather loading failed for \(coordinate.name) after \(maxRetries) attempts")
        throw WeatherManagerError.allRetriesFailed(lastError?.localizedDescription ?? "Unknown error")
    }
    
    // MARK: - Batch Loading with Retry Logic
    
    /// Load weather for multiple buildings with retry logic and rate limiting
    func loadWeatherForBuildings(_ buildings: [FrancoSphere.NamedCoordinate]) async {
        guard !buildings.isEmpty else {
            print("⚠️ No buildings to load weather for")
            return
        }
        
        print("🌤️ Loading weather for \(buildings.count) buildings with retry logic...")
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        var successCount = 0
        var errorCount = 0
        
        for building in buildings {
            do {
                let _ = try await fetchWithRetry(for: building, buildingId: building.id)
                successCount += 1
            } catch {
                errorCount += 1
                print("❌ Failed to load weather for \(building.name): \(error.localizedDescription)")
                
                // Store fallback weather data
                await MainActor.run {
                    self.buildingWeatherMap[building.id] = createFallbackWeatherData()
                }
            }
            
            // 500ms delay between buildings to avoid rate limiting
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        await MainActor.run {
            self.isLoading = false
            if errorCount > 0 && successCount == 0 {
                self.error = WeatherManagerError.allBuildingsFailed
            }
        }
        
        print("🌤️ Weather loading complete: \(successCount) success, \(errorCount) errors")
    }
    
    // MARK: - Enhanced OpenMeteo API Call
    
    private func fetchOpenMeteoWithValidation(
        latitude: Double,
        longitude: Double,
        buildingName: String,
        timeout: TimeInterval
    ) async throws -> FrancoSphere.WeatherData {
        
        // Validate coordinates first
        let lat = round(latitude * 10000) / 10000
        let lng = round(longitude * 10000) / 10000
        
        guard lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 else {
            throw WeatherManagerError.invalidCoordinates("Invalid coordinates: \(lat), \(lng)")
        }
        
        let urlString = "https://api.open-meteo.com/v1/forecast"
        var components = URLComponents(string: urlString)!
        
        // Minimal parameter set to avoid API errors
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", lat)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", lng)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1")
        ]
        
        guard let url = components.url else {
            throw WeatherManagerError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherManagerError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw WeatherManagerError.httpError(httpResponse.statusCode)
        }
        
        return try parseOpenMeteoResponseSafely(data, buildingName: buildingName)
    }
    
    // MARK: - Safe Response Parsing
    
    private func parseOpenMeteoResponseSafely(_ data: Data, buildingName: String) throws -> FrancoSphere.WeatherData {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json = json else {
                throw WeatherManagerError.jsonParsingFailed
            }
            
            guard let current = json["current"] as? [String: Any] else {
                print("⚠️ No current weather data in response for \(buildingName)")
                return createFallbackWeatherData()
            }
            
            let temperature = current["temperature_2m"] as? Double ?? 72.0
            let humidity = current["relative_humidity_2m"] as? Int ?? 50
            let windSpeed = current["wind_speed_10m"] as? Double ?? 5.0
            let weatherCode = current["weather_code"] as? Int ?? 0
            
            let condition = weatherCodeToCondition(weatherCode)
            
            return FrancoSphere.WeatherData(
                date: Date(),
                temperature: temperature,
                feelsLike: temperature + (humidity > 70 ? 2 : -2),
                humidity: humidity,
                windSpeed: windSpeed,
                windDirection: 180,
                precipitation: 0.0,
                snow: condition == .snow ? 0.1 : 0,
                visibility: 10000,
                pressure: 1013,
                condition: condition,
                icon: condition.icon
            )
            
        } catch {
            print("❌ Failed to parse weather response for \(buildingName): \(error)")
            throw WeatherManagerError.parsingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Fallback Weather Data
    
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
    
    // MARK: - Weather Code Mapping
    
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
    
    // MARK: - Utility Methods
    
    /// Retry weather loading for a specific building
    func retryWeatherForBuilding(_ building: FrancoSphere.NamedCoordinate) async {
        do {
            let _ = try await fetchWithRetry(for: building, buildingId: building.id)
        } catch {
            print("❌ Retry failed for \(building.name): \(error.localizedDescription)")
        }
    }
    
    /// Clear all cached weather data
    func clearCache() {
        buildingWeatherMap.removeAll()
        currentWeather = nil
        lastUpdateTime = nil
        error = nil
    }
    
    // MARK: - ✅ FIXED: Removed Building type references
    
    /// Load weather with fallback - now uses FrancoSphere.NamedCoordinate only
    func loadWeatherForBuildingsWithFallback(_ buildings: [FrancoSphere.NamedCoordinate]) async {
        print("🌤️ Loading weather with fallback for \(buildings.count) buildings...")
        
        // Use existing loadWeatherForBuildings method
        await loadWeatherForBuildings(buildings)
        
        // If all failed, try device location fallback
        if buildingWeatherMap.isEmpty {
            print("🌤️ All building weather failed, using device location fallback...")
            await loadDeviceLocationWeatherFallback()
        }
    }
    
    /// Convenience method for single building weather fetch
    func fetchWeather(latitude: Double, longitude: Double) async {
        let coordinate = FrancoSphere.NamedCoordinate(
            id: "temp",
            name: "Location",
            latitude: latitude,
            longitude: longitude,
            imageAssetName: "location"
        )
        
        do {
            let weather = try await fetchWithRetry(for: coordinate)
            await MainActor.run {
                self.currentWeather = weather
            }
        } catch {
            print("❌ Single location weather fetch failed: \(error)")
        }
    }
    
    /// Fallback weather using device location
    private func loadDeviceLocationWeatherFallback() async {
        // Create a fallback coordinate (NYC area)
        let fallbackCoordinate = FrancoSphere.NamedCoordinate(
            id: "fallback",
            name: "Current Location",
            latitude: 40.7590,
            longitude: -73.9845,
            imageAssetName: "location"
        )
        
        do {
            let fallbackWeather = try await fetchWithRetry(for: fallbackCoordinate)
            await MainActor.run {
                self.currentWeather = fallbackWeather
                print("✅ Device location fallback weather loaded")
            }
        } catch {
            print("❌ Device location fallback also failed: \(error)")
            // Use absolute fallback
            await MainActor.run {
                self.currentWeather = createAbsoluteFallbackWeather()
            }
        }
    }
    
    /// Last resort fallback weather data
    private func createAbsoluteFallbackWeather() -> FrancoSphere.WeatherData {
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
}

// MARK: - Weather Manager Error Types

enum WeatherManagerError: LocalizedError {
    case invalidCoordinates(String)
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case jsonParsingFailed
    case parsingFailed(String)
    case allRetriesFailed(String)
    case allBuildingsFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCoordinates(let message):
            return "Invalid coordinates: \(message)"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error \(code)"
        case .jsonParsingFailed:
            return "Failed to parse JSON response"
        case .parsingFailed(let message):
            return "Parsing failed: \(message)"
        case .allRetriesFailed(let message):
            return "All retries failed: \(message)"
        case .allBuildingsFailed:
            return "Failed to load weather for all buildings"
        }
    }
}
