import Foundation
// Import for OutdoorWorkRisk extension
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

// WeatherDashboardComponent.swift
// Fixed to use proper FrancoSphere models and WeatherDataAdapter

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct WeatherDashboardComponent: View {
    let building: NamedCoordinate  // Using the correct model
    
    @State private var isExpanded = false
    @State private var showWeatherTasks = false
    @State private var currentWeather: WeatherData?
    @State private var forecast: [WeatherData] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Weather header
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
                
                Text("Weather Forecast")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14))
                }
            }
            .padding()
            .background(FrancoSphereColors.cardBackground)
            .cornerRadius(12)
            
            if isExpanded {
                VStack(spacing: 16) {
                    // Current weather
                    if let weather = currentWeather {
                        currentWeatherView(weather)
                    } else if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Loading weather...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                        }
                        .padding()
                    }
                    
                    // 5-Day Forecast
                    if !forecast.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("5-Day Forecast")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(forecast, id: \.date) { day in
                                        dailyForecastCard(day)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Weather alerts and actions
                    weatherActionsSection
                }
                .padding()
                .background(FrancoSphereColors.cardBackground)
                .cornerRadius(12)
                .transition(.opacity)
            }
        }
        .onAppear {
            loadWeatherData()
        }
        .sheet(isPresented: $showWeatherTasks) {
            WeatherTasksSheet(building: building)
                .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Current Weather View
    private func currentWeatherView(_ weather: WeatherData) -> some View {
        HStack(spacing: 20) {
            // Temperature and icon
            VStack(spacing: 8) {
                Image(systemName: weather.condition.icon)
                    .font(.system(size: 50))
                    .foregroundColor(getWeatherColor(weather.condition))
                
                Text(weather.formattedTemperature)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
                
                Text(weather.condition.rawValue)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Divider()
                .frame(height: 80)
                .background(Color.white.opacity(0.2))
            
            // Weather details
            VStack(alignment: .leading, spacing: 12) {
                WeatherDetailRow(
                    icon: "humidity",
                    label: "Humidity",
                    value: "\(weather.humidity)%"
                )
                
                WeatherDetailRow(
                    icon: "wind",
                    label: "Wind",
                    value: "\(Int(weather.windSpeed)) mph"
                )
                
                if weather.precipitation > 0 {
                    WeatherDetailRow(
                        icon: "drop.fill",
                        label: "Precipitation",
                        value: String(format: "%.1f\"", weather.precipitation)
                    )
                }
                
                // Risk assessment
                HStack(spacing: 6) {
                    Circle()
                        .fill(getRiskColor(FrancoSphere.OutdoorWorkRisk.low))
                        .frame(width: 8, height: 8)
                    
                    Text(FrancoSphere.OutdoorWorkRisk.low.rawValue)
                        .font(.caption)
                        .foregroundColor(getRiskColor(FrancoSphere.OutdoorWorkRisk.low))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
    
    // MARK: - Daily Forecast Card
    private func dailyForecastCard(_ weather: WeatherData) -> some View {
        VStack(spacing: 8) {
            Text(dayOfWeek(from: weather.date))
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Image(systemName: weather.condition.icon)
                .font(.system(size: 24))
                .foregroundColor(getWeatherColor(weather.condition))
            
            Text(weather.formattedTemperature)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            // Risk indicator
            Circle()
                .fill(getRiskColor(FrancoSphere.OutdoorWorkRisk.low))
                .frame(width: 6, height: 6)
        }
        .frame(width: 70, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            FrancoSphere.OutdoorWorkRisk.low == .extreme ? Color.red.opacity(0.5) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
    }
    
    // MARK: - Weather Actions Section
    private var weatherActionsSection: some View {
        VStack(spacing: 12) {
            // Weather notifications
            if let notification = generateWeatherNotification() {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                    
                    Text(notification)
                        .font(.caption)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Generate weather tasks button
            Button(action: { showWeatherTasks = true }) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 16))
                    
                    Text("View Weather-Related Tasks")
                        .font(.subheadline.bold())
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(FrancoSphereColors.accentBlue)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadWeatherData() {
        isLoading = true
        
        // Simulate weather data loading
        // In production, this would call the actual WeatherDataAdapter
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Mock current weather
            currentWeather = WeatherData(
                date: Date(),
                temperature: 72,
                feelsLike: 68,
                humidity: 65,
                windSpeed: 12,
                windDirection: 180,
                precipitation: 0,
                snow: 0,
                visibility: 10,
                pressure: 1013,
                condition: .cloudy,
                icon: "cloud.fill"
            )
            
            // Mock forecast
            forecast = (1...5).map { dayOffset in
                WeatherData(
                    date: Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!,
                    temperature: Double.random(in: 60...80),
                    feelsLike: Double.random(in: 58...78),
                    humidity: Int.random(in: 50...80),
                    windSpeed: Double.random(in: 5...20),
                    windDirection: Int.random(in: 0...360),
                    precipitation: Double.random(in: 0...2),
                    snow: 0,
                    visibility: 10,
                    pressure: 1013,
                    condition: [.clear, .cloudy, .rain][Int.random(in: 0...2)],
                    icon: "cloud.sun.fill"
                )
            }
            
            isLoading = false
        }
    }
    
    private func generateWeatherNotification() -> String? {
        guard let weather = currentWeather else { return nil }
        
        switch FrancoSphere.OutdoorWorkRisk.low {
        case .extreme:
            return "Extreme weather conditions. Consider rescheduling outdoor tasks."
        case .high:
            return "High-risk weather conditions. Take extra precautions for outdoor work."
        case .moderate:
            return "Moderate weather conditions. Monitor throughout the day."
        case .low:
            return nil
        }
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    // MARK: - Color Helper Methods
    
    private func getWeatherColor(_ condition: WeatherCondition) -> Color {
        switch condition {
        case .clear:        return .yellow
        case .cloudy:       return .gray
        case .rain:         return .blue
        case .snow:         return .cyan
        case .thunderstorm: return .purple
        case .fog:          return .gray
        case .other:        return .gray
        }
    }
    
    private func getUrgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low:    return .green
        case .medium: return .yellow
        case .high:   return .red
        case .urgent: return .purple
        }
    }
    
    private func getRiskColor(_ risk: WeatherData.OutdoorWorkRisk) -> Color {
        switch risk {
        case .low:      return .green
        case .moderate: return .yellow
        case .high:     return .orange
        case .extreme:  return .red
        }
    }
}

// MARK: - Supporting Views

struct WeatherDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }
}

// MARK: - Weather Tasks Sheet
struct WeatherTasksSheet: View {
    let building: NamedCoordinate
    @Environment(\.presentationMode) var presentationMode
    
    @State private var weatherTasks: [MaintenanceTask] = []
    @State private var selectedCategory: TaskCategory? = nil
    
    var filteredTasks: [MaintenanceTask] {
        if let category = selectedCategory {
            return weatherTasks.filter { $0.category == category }
        }
        return weatherTasks
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FrancoSphereColors.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(TaskCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Task List
                    if filteredTasks.isEmpty {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.seal")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            Text("No weather-related tasks")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("All systems are operating normally")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredTasks) { task in
                                    WeatherTaskRow(task: task)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Generate Tasks Button
                    Button(action: generateWeatherTasks) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Generate Weather Tasks")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(FrancoSphereColors.accentBlue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Weather Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadWeatherTasks()
        }
    }
    
    private func loadWeatherTasks() {
        // Mock weather-related tasks
        weatherTasks = [
            MaintenanceTask(
                name: "Check Roof Drainage",
                buildingID: building.id,
                description: "Inspect and clear roof drains before rain",
                dueDate: Date(),
                category: .maintenance,
                urgency: .high,
                recurrence: .oneTime
            ),
            MaintenanceTask(
                name: "Secure Outdoor Equipment",
                buildingID: building.id,
                description: "Move or secure loose items before high winds",
                dueDate: Date(),
                category: .maintenance,
                urgency: .medium,
                recurrence: .oneTime
            )
        ]
    }
    
    private func generateWeatherTasks() {
        // This would call TaskManager to create actual tasks
        presentationMode.wrappedValue.dismiss()
    }
}

struct CategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundColor(isSelected ? FrancoSphereColors.primaryBackground : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(20)
        }
    }
}

struct WeatherTaskRow: View {
    let task: MaintenanceTask
    
    // Local helper function for urgency colors
    private func getUrgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low:    return .green
        case .medium: return .yellow
        case .high:   return .red
        case .urgent: return .purple
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Task Icon
            Image(systemName: task.category.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(getUrgencyColor(task.urgency))
                .cornerRadius(10)
            
            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Urgency Badge
            Text(task.urgency.rawValue)
                .font(.caption.bold())
                .foregroundColor(getUrgencyColor(task.urgency))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(getUrgencyColor(task.urgency).opacity(0.2))
                .cornerRadius(6)
        }
        .padding()
        .background(FrancoSphereColors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct WeatherDashboardComponent_Previews: PreviewProvider {
    static var previews: some View {
        WeatherDashboardComponent(
            building: NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                latitude: 40.7390,
                longitude: -73.9930,
                address: "12 W 18th St, New York, NY",
                imageAssetName: "12_West_18th_Street"
            )
        )
        .padding()
        .background(FrancoSphereColors.primaryBackground)
        .preferredColorScheme(.dark)
    }
}

