//
//  WeatherTasksSection.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ Corrected WeatherDataAdapter usage and method calls
//  ✅ Fixed TaskCategory enum values and MaintenanceTask constructor
//  ✅ Proper WeatherData property access
//

import SwiftUI

struct WeatherTasksSection: View {
    let building: NamedCoordinate
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: "cloud.sun.rain")
                    .foregroundColor(.blue)
                Text("Weather-Related Tasks")
                    .font(.headline)
                Spacer()
            }
            
            if let currentWeather = weatherAdapter.currentWeather {
                if currentWeather.isHazardous {
                    weatherWarningCard(for: currentWeather)
                }
                
                weatherTasksList(for: currentWeather)
            } else {
                Text("Loading weather data...")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .task {
            // ✅ FIXED: Use correct WeatherDataAdapter method
            await weatherAdapter.fetchWeatherForBuildingAsync(building)
        }
    }
    
    private func weatherWarningCard(for weather: WeatherData) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather Advisory")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(weatherWarningMessage(for: weather))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func weatherTasksList(for weather: WeatherData) -> some View {
        VStack(spacing: 8) {
            ForEach(generateWeatherTasks(for: weather), id: \.id) { task in
                weatherTaskRow(task)
            }
        }
    }
    
    private func weatherTaskRow(_ task: MaintenanceTask) -> some View {
        HStack {
            Image(systemName: task.category.icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if let dueDate = task.dueDate {
                Text(formatDueDate(dueDate))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func weatherWarningMessage(for weather: WeatherData) -> String {
        if weather.temperature < 32 {
            return "Freezing temperatures may affect outdoor tasks"
        } else if weather.temperature > 90 {
            return "High heat may require task rescheduling"
        } else if weather.windSpeed > 25 {
            return "High winds may impact outdoor work"
        // ✅ FIXED: WeatherData DOES have precipitation property
        } else if weather.precipitation > 0.5 {
            return "Heavy precipitation expected"
        }
        return "Weather conditions may affect operations"
    }
    
    private func generateWeatherTasks(for weather: WeatherData) -> [MaintenanceTask] {
        var tasks: [MaintenanceTask] = []
        
        if weather.temperature < 32 {
            // ✅ FIXED: Use minimal MaintenanceTask constructor pattern from WeatherDataAdapter
            tasks.append(MaintenanceTask(
                title: "Freeze Protection Check",
                description: "Inspect and protect pipes from freezing",
                category: .maintenance,
                urgency: .high,
                buildingId: building.id,
                dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
            ))
        }
        
        // ✅ FIXED: WeatherData DOES have condition property
        if weather.condition == .rainy && weather.precipitation > 0.25 {
            tasks.append(MaintenanceTask(
                title: "Check Drainage Systems",
                description: "Ensure proper water drainage",
                category: .maintenance,
                urgency: .medium,
                buildingId: building.id,
                dueDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            ))
        }
        
        if weather.windSpeed > 20 {
            tasks.append(MaintenanceTask(
                title: "Secure Outdoor Items",
                description: "Check and secure loose outdoor equipment",
                category: .maintenance,
                urgency: .medium,
                buildingId: building.id,
                dueDate: Date()
            ))
        }
        
        return tasks
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    WeatherTasksSection(building: NamedCoordinate.allBuildings.first!)
        .padding()
        .background(Color.black)
}
