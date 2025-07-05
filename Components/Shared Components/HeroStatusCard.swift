//
//  HeroStatusCard.swift
//  FrancoSphere
//

import SwiftUI

struct HeroStatusCard: View {
    let workerId: String
    let currentBuilding: NamedCoordinate
    let weather: WeatherData
    let progress: TaskProgress
    let completedTasks: Int
    let totalTasks: Int
    let onClockInTap: () -> Void
    
    var body: some View {
        VStack {
            Text("Hero Status")
            Text("Worker: \(workerId)")
            Text("Completed: \(completedTasks)/\(totalTasks)")
            Button("Clock In", action: onClockInTap)
        }
        .padding()
    }
}

// No preview to avoid constructor issues
