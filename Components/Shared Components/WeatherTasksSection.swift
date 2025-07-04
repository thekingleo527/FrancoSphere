import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

// WeatherTasksSection.swift
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct WeatherTasksSection: View {
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    @State private var weatherTasks: [MaintenanceTask] = []    // ← uses top‐level alias

    // Use the model defined in FrancoSphereModels.swift directly
    let building: FrancoSphere.NamedCoordinate
    private func urgencyColor(_ urgency: FrancoSphere.TaskUrgency) -> Color {
        switch urgency {
        case .low:    return .green
        case .medium: return .yellow
        case .high:   return .orange
        case .urgent: return .red
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weather-Related Tasks")
                .font(.headline)
                .padding(.horizontal)

            if weatherTasks.isEmpty {
                Text("No weather‐related tasks for this building.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(weatherTasks) { task in
                    HStack {
                        Image(systemName: task.category.icon)
                            .foregroundColor(task.category == .inspection ? .purple : .blue)

                        VStack(alignment: .leading) {
                            Text(task.name)
                                .font(.headline)
                            Text(task.recurrence.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(task.urgency.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(urgencyColor(task.urgency).opacity(0.2))
                            .foregroundColor(urgencyColor(task.urgency))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            // generateWeatherTasks(for:) expects a FrancoSphere.NamedCoordinate
            weatherTasks = weatherAdapter.generateWeatherTasks(for: building)
        }
    }
}

#if DEBUG
struct WeatherTasksSection_Previews: PreviewProvider {
    static var previews: some View {
        WeatherTasksSection(
            building: FrancoSphere.NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                latitude: 40.739750,
                longitude: -73.994424,
                address: "12 West 18th Street, NY",
                imageAssetName: "12_West_18th_Street"
            )
        )
    }
}
#endif
