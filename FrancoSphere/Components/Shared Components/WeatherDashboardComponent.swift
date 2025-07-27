//
//  WeatherDashboardComponent.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With current CoreTypes and Phase 2.1 implementation
//  ✅ ENHANCED: Compatible with three-dashboard system
//  ✅ GRDB: Real-time data integration ready
//

import SwiftUI
import CoreLocation

struct WeatherDashboardComponent: View {
    let building: NamedCoordinate
    let weather: CoreTypes.WeatherData
    let tasks: [ContextualTask]
    let onTaskTap: (ContextualTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            buildingHeader
            
            // Weather Display
            weatherSection
            
            // Tasks Section
            if !tasks.isEmpty {
                tasksSection
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
    
    // MARK: - Building Header
    
    private var buildingHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(building.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let address = building.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Weather Section
    
    private var weatherSection: some View {
        HStack(spacing: 12) {
            // Weather Icon
            Image(systemName: weatherIcon)
                .foregroundColor(weatherColor)
                .font(.title2)
            
            // Temperature and Conditions
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weather.temperature))°F")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(weather.condition)  // ✅ FIXED: Use 'condition' not 'conditions'
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Additional Weather Info
            VStack(alignment: .trailing, spacing: 2) {
                // Note: precipitation not in CoreTypes.WeatherData
                
                if weather.windSpeed > 10 {
                    HStack(spacing: 4) {
                        Image(systemName: "wind")
                            .foregroundColor(.gray)
                            .font(.caption2)
                        Text("\(Int(weather.windSpeed)) mph")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Humidity info if high
                if weather.humidity > 70 {
                    HStack(spacing: 4) {
                        Image(systemName: "humidity")
                            .foregroundColor(.blue)
                            .font(.caption2)
                        Text("\(Int(weather.humidity))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Tasks Section
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Tasks")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 4) {
                ForEach(tasks, id: \.id) { task in
                    TaskRowView(task: task, onTap: onTaskTap)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var weatherIcon: String {
        // ✅ FIXED: Properly convert string condition to enum
        let conditionEnum = CoreTypes.WeatherCondition(rawValue: weather.condition) ?? .clear
        
        switch conditionEnum {
        case .sunny, .clear: return "sun.max"
        case .cloudy, .overcast: return "cloud"
        case .partlyCloudy: return "cloud.sun"
        case .rainy: return "cloud.rain"
        case .snowy: return "cloud.snow"
        case .stormy: return "cloud.bolt"
        case .foggy: return "cloud.fog"
        case .windy: return "wind"
        case .hot: return "thermometer.sun"
        case .cold: return "thermometer.snowflake"
        }
    }
    
    private var weatherColor: Color {
        // ✅ FIXED: Properly convert string condition to enum
        let conditionEnum = CoreTypes.WeatherCondition(rawValue: weather.condition) ?? .clear
        
        switch conditionEnum {
        case .sunny, .clear: return .orange
        case .cloudy, .overcast, .partlyCloudy: return .gray
        case .rainy: return .blue
        case .snowy: return .cyan
        case .stormy: return .purple
        case .foggy: return .gray.opacity(0.7)
        case .windy: return .mint
        case .hot: return .red
        case .cold: return .blue
        }
    }
}

// MARK: - Task Row Component

struct TaskRowView: View {
    let task: ContextualTask
    let onTap: (ContextualTask) -> Void
    
    var body: some View {
        Button(action: { onTap(task) }) {
            HStack(spacing: 8) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                // Task title - ✅ FIXED: title is not optional
                Text(task.title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Urgency badge
                if let urgency = task.urgency {
                    Text(urgencyText(urgency))
                        .font(.caption2)
                        .foregroundColor(urgencyColor(urgency))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(urgencyColor(urgency).opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        task.isCompleted ? .green : .gray
    }
    
    private func urgencyText(_ urgency: CoreTypes.TaskUrgency) -> String {
        switch urgency {
        case .low: return "Low"
        case .medium: return "Med"
        case .high: return "High"
        case .critical: return "Critical"
        case .urgent: return "Urgent"
        case .emergency: return "Emergency"
        }
    }
    
    private func urgencyColor(_ urgency: CoreTypes.TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical, .urgent, .emergency: return .purple
        }
    }
}

// MARK: - Preview

struct WeatherDashboardComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Sample with tasks
            WeatherDashboardComponent(
                building: sampleBuilding,
                weather: sampleWeather,
                tasks: sampleTasks,
                onTaskTap: { task in
                    print("Tapped task: \(task.title)")
                }
            )
            
            // Sample without tasks
            WeatherDashboardComponent(
                building: sampleBuilding,
                weather: stormyWeather,
                tasks: [],
                onTaskTap: { _ in }
            )
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Sample Data
    
    static var sampleBuilding: NamedCoordinate {
        NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "150 W 17th St, New York, NY 10011",
            latitude: 40.7402,
            longitude: -73.9980,
            imageAssetName: "rubin_museum"
        )
    }
    
    static var sampleWeather: CoreTypes.WeatherData {
        CoreTypes.WeatherData(
            temperature: 72,
            condition: CoreTypes.WeatherCondition.sunny.rawValue,  // ✅ FIXED: Use enum rawValue
            humidity: 65,
            windSpeed: 8.5,
            outdoorWorkRisk: CoreTypes.OutdoorWorkRisk.low,  // ✅ FIXED: Added OutdoorWorkRisk
            timestamp: Date()
        )
    }
    
    static var stormyWeather: CoreTypes.WeatherData {
        CoreTypes.WeatherData(
            temperature: 58,
            condition: CoreTypes.WeatherCondition.stormy.rawValue,  // ✅ FIXED: Use enum rawValue
            humidity: 85,
            windSpeed: 25.0,
            outdoorWorkRisk: CoreTypes.OutdoorWorkRisk.extreme,  // ✅ FIXED: Added OutdoorWorkRisk
            timestamp: Date()
        )
    }
    
    static var sampleTasks: [ContextualTask] {
        [
            // ✅ FIXED: Provide all parameters in exact order expected
            ContextualTask(
                id: "1",
                title: "Window Cleaning",
                description: "Clean exterior windows",
                isCompleted: false,
                completedDate: nil,
                dueDate: nil,
                category: .cleaning,
                urgency: .medium,
                building: nil,  // NamedCoordinate?
                worker: nil,    // WorkerProfile?
                buildingId: "14",
                priority: .medium,
                buildingName: "Rubin Museum",
                assignedWorkerId: nil,
                assignedWorkerName: nil,
                estimatedDuration: 3600
            ),
            ContextualTask(
                id: "2",
                title: "HVAC Inspection",
                description: "Check HVAC system",
                isCompleted: true,
                completedDate: Date(),
                dueDate: nil,
                category: .maintenance,
                urgency: .high,
                building: nil,  // NamedCoordinate?
                worker: nil,    // WorkerProfile?
                buildingId: "14",
                priority: .high,
                buildingName: "Rubin Museum",
                assignedWorkerId: nil,
                assignedWorkerName: nil,
                estimatedDuration: 3600
            ),
            ContextualTask(
                id: "3",
                title: "Emergency Exit Check",
                description: "Verify emergency exit accessibility",
                isCompleted: false,
                completedDate: nil,
                dueDate: nil,
                category: .inspection,
                urgency: .critical,
                building: nil,  // NamedCoordinate?
                worker: nil,    // WorkerProfile?
                buildingId: "14",
                priority: .critical,
                buildingName: "Rubin Museum",
                assignedWorkerId: nil,
                assignedWorkerName: nil,
                estimatedDuration: 3600
            )
        ]
    }
}

// MARK: - 📝 COMPREHENSIVE FIX SUMMARY
/*
 ✅ ALL COMPILATION ERRORS FIXED:
 
 🔧 WEATHER DATA FIXES:
 - Changed weather.conditions to weather.condition (correct property name)
 - Added proper enum conversion for weather conditions
 - Removed precipitation references (not in CoreTypes.WeatherData)
 - Added outdoorWorkRisk parameter to WeatherData constructors
 
 🔧 TYPE FIXES:
 - Removed task.title nil coalescing (title is not optional)
 - Removed .normal case from TaskUrgency (doesn't exist)
 - Added proper CoreTypes prefix to all enum references
 
 🔧 CONTEXTUALTASK INITIALIZER FIXES:
 - Used the full initializer with ALL parameters in exact order
 - Parameters: id, title, description, isCompleted, completedDate, dueDate, category, urgency, building, worker, buildingId, priority, buildingName, assignedWorkerId, assignedWorkerName, estimatedDuration
 - Set building and worker to nil (they expect NamedCoordinate? and WorkerProfile? types)
 - buildingName is a separate String parameter, not part of building
 - Added all 16 parameters to match expected signature
 
 🔧 WEATHERDATA CONSTRUCTOR FIXES:
 - Added outdoorWorkRisk parameter (required by CoreTypes.WeatherData)
 - Used enum rawValue for condition string
 - Proper parameters: temperature, condition, humidity, windSpeed, outdoorWorkRisk, timestamp
 
 🔧 IMPROVEMENTS:
 - Separated complex views into computed properties
 - Added humidity display when > 70%
 - Fixed all enum references with proper prefixes
 - Used actual FrancoSphere v6.0 data structures
 - Maintained dark theme compatibility
 */
