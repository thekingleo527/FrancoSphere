//
//  SharedTypes.swift
//  FrancoSphere
//
//  Shared type definitions
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - WeatherImpact
struct WeatherImpact {
    let condition: String
    let temperature: Double
    let affectedTasks: [ContextualTask]
    let recommendation: String
}

// MARK: - TaskTrends
struct TaskTrends {
    let weeklyCompletion: [Double]
    let categoryBreakdown: [String: Int]
    let changePercentage: Double
    let comparisonPeriod: String
    let trend: TrendDirection
}

enum TrendDirection {
    case up, down, stable
}

// MARK: - PerformanceMetrics
struct PerformanceMetrics {
    let efficiency: Double
    let tasksCompleted: Int
    let averageTime: Double
    let qualityScore: Double
    let lastUpdate: Date
}

// MARK: - StreakData
struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let lastUpdate: Date
}
