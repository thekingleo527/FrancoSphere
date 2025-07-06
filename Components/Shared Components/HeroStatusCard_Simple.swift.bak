//
//  HeroStatusCard_Simple.swift
//  FrancoSphere
//

import SwiftUI
import CoreLocation

struct HeroStatusCard: View {
    let workerId: String
    let currentBuilding: NamedCoordinate
    let weather: WeatherData
    let progress: TaskProgress
    let completedTasks: Int
    let totalTasks: Int
    let onClockInTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hero Status Card")
                .font(.headline)
            
            Text("Worker: \(workerId)")
                .font(.subheadline)
            
            Text("Building: \(currentBuilding.name)")
                .font(.subheadline)
            
            Text("Tasks: \(completedTasks)/\(totalTasks)")
                .font(.subheadline)
            
            Button("Clock In", action: onClockInTap)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Ultra-simple preview with no complex constructors
struct HeroStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        Text("HeroStatusCard Preview")
            .padding()
    }
}
