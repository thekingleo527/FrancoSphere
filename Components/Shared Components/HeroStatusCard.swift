//
//  HeroStatusCard.swift
//  FrancoSphere
//
//  ✅ FIXED: TaskProgress constructor in preview
//

import SwiftUI
import Foundation
import CoreLocation

struct HeroStatusCard: View {
    let workerId: String
    let currentBuilding: String?
    let weather: WeatherData?
    let progress: TaskProgress
    let onClockInTap: () -> Void

    var body: some View { /* …your view code… */ }
    // weatherView, buildingStatusView, clockInPromptView, helpers…
}

// MARK: - ✅ FIXED: Preview with correct TaskProgress constructor
#Preview {
    HeroStatusCard(
        workerId: "kevin",
        currentBuilding: "Rubin Museum",
        weather: WeatherData(
            id: UUID().uuidString,
            date: Date(),
            temperature: 72.0,
            feelsLike: 72.0,
            humidity: 65,
            windSpeed: 5.0,
            windDirection: 0,
            precipitation: 0,
            snow: 0,
            condition: .clear,
            uvIndex: 0,
            visibility: 10,
            description: "Clear skies"
        ),
        progress: TaskProgress(
            workerId: "kevin",
            totalTasks: 12,
            completedTasks: 8,
            overdueTasks: 1,
            todayCompletedTasks: 8,
            weeklyTarget: 50,
            currentStreak: 3,
            lastCompletionDate: Date()
        ),
        onClockInTap: { print("Clock in tapped") }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
