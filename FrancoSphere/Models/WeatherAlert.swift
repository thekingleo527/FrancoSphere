//
//  WeatherAlert.swift
//  FrancoSphere
//
//  ✅ FIXED: ContextualTask initializer calls
//  ✅ FIXED: Switch statement exhaustiveness
//  ✅ FIXED: Type inference issues
//  ✅ FIXED: Removed extra 'scheduledDate' parameter
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Weather Alert System

/// Weather data structure for task generation and alerts
public struct FSWeatherData {
    public let temperature: Double
    public let condition: FrancoSphere.CoreTypes.WeatherCondition
    public let precipitation: Double
    public let windSpeed: Double
    public let humidity: Double
    public let date: Date
    public let temperatureHigh: Double
    public let temperatureLow: Double
    
    public init(temperature: Double, condition: FrancoSphere.CoreTypes.WeatherCondition, precipitation: Double, windSpeed: Double, humidity: Double, date: Date, temperatureHigh: Double, temperatureLow: Double) {
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
        case extreme = "Extreme Risk"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .yellow
            case .high: return .orange
            case .extreme: return .red
            }
        }
    }
    
    public var outdoorWorkRisk: OutdoorWorkRisk {
        // Simplified risk assessment
        if temperature > 95 || temperature < 20 || windSpeed > 25 {
            return .extreme
        } else if temperature > 85 || temperature < 32 || windSpeed > 15 {
            return .high
        } else if precipitation > 0.1 {
            return .moderate
        } else {
            return .low
        }
    }
}

// MARK: - Weather Alert Generation
public actor WeatherAlertSystem {
    public static let shared = WeatherAlertSystem()
    
    private init() {}
    
    public func generateWeatherAlerts(for buildings: [NamedCoordinate], weather: FSWeatherData) async -> [ContextualTask] {
        var alerts: [ContextualTask] = []
        
        for building in buildings {
            // Generate building-specific weather alerts
            if weather.outdoorWorkRisk == .high || weather.outdoorWorkRisk == .extreme {
                // ✅ FIXED: Removed 'scheduledDate' parameter as it's not part of ContextualTask initializer
                // Note: ContextualTask likely uses dueDate as its scheduled date
                let alert = ContextualTask(
                    id: UUID().uuidString,
                    title: "Weather Alert: \(weather.outdoorWorkRisk.rawValue)",
                    description: "Weather conditions require special precautions",
                    isCompleted: false,
                    dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
                    category: .emergency,
                    urgency: .high
                )
                alerts.append(alert)
            }
        }
        
        return alerts
    }
}
