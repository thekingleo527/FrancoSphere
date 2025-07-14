import SwiftUI

struct WeatherTasksSection: View {
    let building: NamedCoordinate
    @State private var weatherTasks: [MaintenanceTask] = []
    
    // Mock weather adapter for now
    private let weatherAdapter = WeatherDataAdapter.shared
    
    private func urgencyColor(_ urgency: FrancoSphere.TaskUrgency) -> Color {
        return urgency.color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather-Related Tasks")
                .font(.headline)
                .padding(.horizontal)
            
            if weatherTasks.isEmpty {
                Text("No weather-related tasks at this time.")
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
                            Text(task.title)
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
            // Generate mock weather tasks
            weatherTasks = generateMockWeatherTasks()
        }
    }
    
    // Mock weather task generation
    private func generateMockWeatherTasks() -> [MaintenanceTask] {
        // Mock implementation - replace with real weather adapter
        let mockWeatherData = WeatherData(
            temperature: 45.0,
            humidity: 75,
            windSpeed: 12.0,
            conditions: "rainy",
            precipitation: 0.25,
            condition: .rainy
        )
        
        if mockWeatherData.precipitation > 0.1 && mockWeatherData.condition == .rainy {
            return [
                MaintenanceTask(
                    title: "Check Drainage Systems",
                    description: "Inspect and clear drainage due to rain forecast",
                    category: .maintenance,
                    urgency: .medium,
                    buildingId: building.id,
                    dueDate: Date().addingTimeInterval(3600)
                )
            ]
        }
        
        return []
    }
}
