//
//  WeatherDashboardComponent.swift
//  FrancoSphere
//

import SwiftUI
import CoreLocation

struct WeatherDashboardComponent: View {
    let building: NamedCoordinate
    let weather: WeatherData
    let tasks: [ContextualTask]
    let onTaskTap: (ContextualTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let address = building.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Weather Display
                HStack(spacing: 8) {
                    Image(systemName: weatherIcon)
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .trailing) {
                        Text("\(Int(weather.temperature))°F")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(weather.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Tasks Section
            if !tasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Tasks")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    LazyVStack(spacing: 4) {
                        ForEach(tasks, id: \.id) { task in
                            Button(action: { onTaskTap(task) }) {
                                HStack {
                                    Circle()
                                        .fill(task.status == "completed" ? Color.green : Color.gray)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(task.title)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(task.urgencyLevel.capitalized)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
    
    private var weatherIcon: String {
        switch weather.condition {
        case .sunny: return "sun.max"
        case .cloudy: return "cloud"
        case .rainy: return "cloud.rain"
        case .snowy: return "cloud.snow"
        default: return "cloud"
        }
    }
}

// MARK: - Preview

struct WeatherDashboardComponent_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            coordinate: CLLocationCoordinate2D(latitude: 40.7402, longitude: -73.9980),
            address: "150 W 17th St, New York, NY 10011"
        )
        
        let sampleWeather = WeatherData(
            condition: .sunny,
            temperature: 72,
            humidity: 65,
            windSpeed: 8.5,
            description: "Sunny and clear"
        )
        
        let sampleTasks: [ContextualTask] = [
            ContextualTask(
                id: "1",
                name: "Window Cleaning",
                description: "Clean exterior windows",
                buildingId: "14",
                buildingName: "Rubin Museum",
                category: "cleaning",
                status: "pending"
            ),
            ContextualTask(
                id: "2",
                name: "HVAC Check",
                description: "Check HVAC system",
                buildingId: "14",
                buildingName: "Rubin Museum",
                category: "maintenance",
                status: "completed"
            )
        ]
        
        WeatherDashboardComponent(
            building: sampleBuilding,
            weather: sampleWeather,
            tasks: sampleTasks,
            onTaskTap: { task in
                print("Tapped task: \(task.title)")
            }
        )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
