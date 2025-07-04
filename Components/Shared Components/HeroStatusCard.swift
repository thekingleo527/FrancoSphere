//
//  HeroStatusCard.swift
//  FrancoSphere
//
//  ✅ REMOVED duplicate TaskProgress struct
//  ✅ Uses TimeBasedTaskFilter.TaskProgress (single source of truth)
//  ✅ Fixed parameter order and nil context issues
//  ✅ Custom progress bar instead of missing TimelineProgressBar
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct HeroStatusCard: View {
    let clockedInStatus: (isClockedIn: Bool, buildingId: Int64?)
    let currentBuildingName: String
    let currentWeather: WeatherData?
    let taskProgress: TimeBasedTaskFilter.TaskProgress  // ✅ FIXED: Use centralized definition
    let nextTask: ContextualTask?
    let elapsedTime: String
    let onClockToggle: () -> Void
    
    // MARK: - State
    @State private var showClockAnimation = false
    @State private var currentTime = Date()
    
    // Timer for real-time updates
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            // Clock In/Out Button (48pt height)
            clockToggleButton
            
            // Context section (only when clocked in)
            if clockedInStatus.isClockedIn {
                contextSection
            }
            
            // Task progress timeline
            taskProgressSection
            
            // Next task highlight
            if let nextTask = nextTask {
                nextTaskSection(nextTask)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Clock Toggle Button
    
    private var clockToggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showClockAnimation.toggle()
            }
            onClockToggle()
        }) {
            HStack(spacing: 12) {
                // Status icon
                Image(systemName: clockedInStatus.isClockedIn ? "location.fill" : "location")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(showClockAnimation ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: showClockAnimation)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(clockedInStatus.isClockedIn ? "Clock Out" : "Clock In")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    if clockedInStatus.isClockedIn {
                        Text("Currently at \(currentBuildingName)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Select a building to start")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Time indicator
                if clockedInStatus.isClockedIn && !elapsedTime.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(elapsedTime)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("elapsed")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 48)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(clockedInStatus.isClockedIn ?
                          LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Context Section (Weather + Building)
    
    private var contextSection: some View {
        HStack(spacing: 16) {
            // Building info
            HStack(spacing: 8) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Location")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text(currentBuildingName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Weather info (if available)
            if let weather = currentWeather {
                weatherInfo(weather)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func weatherInfo(_ weather: WeatherData) -> some View {
        HStack(spacing: 8) {
            Image(systemName: weatherIconName(for: weather.condition))
                .font(.system(size: 16))
                .foregroundColor(weatherIconColor(for: weather.condition))
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(weather.formattedTemperature)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Text(weather.condition.rawValue)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Task Progress Section
    
    private var taskProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(taskProgress.completedTasks)/\(taskProgress.totalTasks) tasks")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // ✅ FIXED: Custom progress bar instead of missing TimelineProgressBar
            customProgressBar
            
            // Progress stats
            HStack(spacing: 20) {
                progressStat(
                    label: "Completed",
                    count: taskProgress.completedTasks,
                    color: .green
                )
                
                progressStat(
                    label: "Total",
                    count: taskProgress.totalTasks,
                    color: .blue
                )
                
                progressStat(
                    label: "Remaining",
                    count: max(0, taskProgress.totalTasks - taskProgress.completedTasks),
                    color: .orange
                )
                
                Spacer()
            }
        }
    }
    
    // ✅ FIXED: Custom progress bar implementation
    private var customProgressBar: some View {
        GeometryReader { geometry in
            let progress = taskProgress.totalTasks > 0 ?
                Double(taskProgress.completedTasks) / Double(taskProgress.totalTasks) : 0.0
            let progressWidth = geometry.size.width * progress
            
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth, height: 8)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 8)
    }
    
    private func progressStat(label: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    // MARK: - Next Task Section
    
    private func nextTaskSection(_ task: ContextualTask) -> some View {
        HStack(spacing: 12) {
            // Urgency indicator
            Image(systemName: isTaskUrgent(task) ? "exclamationmark.triangle.fill" : "clock")
                .font(.system(size: 16))
                .foregroundColor(isTaskUrgent(task) ? .orange : .blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Task")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(task.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(task.buildingName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    if let startTime = task.startTime {
                        Text("• \(TimeBasedTaskFilter.formatTimeString(startTime))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            // Countdown or status
            VStack(alignment: .trailing, spacing: 2) {
                if let timeUntil = timeUntilTask(task) {
                    Text(timeUntil)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isTaskUrgent(task) ? .orange : .blue)
                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("Ready")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Helper Methods
    
    private func weatherIconName(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    private func weatherIconColor(for condition: WeatherCondition) -> Color {
        switch condition {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .fog: return .gray.opacity(0.7)
        case .other: return .gray
        }
    }
    
    private func isTaskUrgent(_ task: ContextualTask) -> Bool {
        return task.urgencyLevel.lowercased() == "urgent" ||
               task.urgencyLevel.lowercased() == "high"
    }
    
    private func timeUntilTask(_ task: ContextualTask) -> String? {
        return TimeBasedTaskFilter.timeUntilTask(task)
    }
}

// MARK: - Preview Provider

struct HeroStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Clocked Out State
            HeroStatusCard(
                clockedInStatus: (false, nil),
                currentBuildingName: "",
                currentWeather: nil as WeatherData?,  // ✅ FIXED: Explicit type context
                taskProgress: TimeBasedTaskFilter.TaskProgress(  // ✅ FIXED: Correct parameter order
                    hourlyDistribution: [8: 2, 10: 3, 14: 1],
                    completedHours: [8, 9, 10],
                    currentHour: Calendar.current.component(.hour, from: Date()),
                    totalTasks: 6,
                    completedTasks: 3
                ),
                nextTask: ContextualTask(
                    id: "1",
                    name: "HVAC Filter Replacement",
                    buildingId: "12",
                    buildingName: "12 West 18th Street",
                    category: "Maintenance",
                    startTime: "14:30",
                    endTime: "16:00",
                    recurrence: "Monthly",
                    skillLevel: "Intermediate",
                    status: "pending",
                    urgencyLevel: "High"
                ),
                elapsedTime: "",
                onClockToggle: { print("Clock toggle") }
            )
            
            // Clocked In State
            HeroStatusCard(
                clockedInStatus: (true, 12),
                currentBuildingName: "12 West 18th Street",
                currentWeather: WeatherData(
                    date: Date(),
                    temperature: 72.0,
                    feelsLike: 68.0,
                    humidity: 65,
                    windSpeed: 8.0,
                    windDirection: 180,
                    precipitation: 0.0,
                    snow: 0.0,
                    visibility: Int(10.0),
                    pressure: Int(1013.0),
                    condition: .clear,
                    icon: "01d"
                ),
                taskProgress: TimeBasedTaskFilter.TaskProgress(
                    hourlyDistribution: [8: 2, 10: 3, 14: 1],
                    completedHours: [8, 9, 10],
                    currentHour: Calendar.current.component(.hour, from: Date()),
                    totalTasks: 13,
                    completedTasks: 8
                ),
                nextTask: ContextualTask(
                    id: "2",
                    name: "Lobby Glass Cleaning",
                    buildingId: "12",
                    buildingName: "12 West 18th Street",
                    category: "Cleaning",
                    startTime: "15:30",
                    endTime: "16:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "Medium"
                ),
                elapsedTime: "3h 25m",
                onClockToggle: { print("Clock toggle") }
            )
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.dark)
    }
}
