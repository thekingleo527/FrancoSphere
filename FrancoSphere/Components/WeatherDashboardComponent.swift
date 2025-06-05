// WeatherDashboardComponent.swift
// Fixed to use FrancoSphere.NamedCoordinate and WeatherData instead of FSWeatherData

import SwiftUI

struct WeatherDashboardComponent: View {
    let building: FrancoSphere.NamedCoordinate  // Use fully qualified type

    // Store the adapter as a regular property
    private let adapter = WeatherDataAdapter.shared

    @State private var isExpanded = false
    @State private var showWeatherTasks = false
    @State private var currentWeather: WeatherData?         // Was FSWeatherData?
    @State private var forecast: [WeatherData] = []         // Was [FSWeatherData]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Weather header
            HStack {
                Text("🌦 Weather Forecast")
                    .font(.headline)

                Spacer()

                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }

            if isExpanded {
                // Current weather
                if let currentWeather = currentWeather {
                    currentWeatherView(currentWeather)
                }

                Divider()

                // Forecast
                ScrollView(.horizontal, showsIndicators: false) {
                                 HStack(spacing: 12) {
                                      ForEach(forecast, id: \.date) { day in
                                          dailyForecastView(day)
                                     }
                                   }
                                  .padding(.vertical, 4)
                               }

                // Weather alerts
                weatherAlertsView()

                // Weather-related tasks button
                Button(action: {
                    showWeatherTasks = true
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 14))

                        Text("Generate Weather Tasks")
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            } else {
                // Collapsed view - just show current weather
                if let currentWeather = currentWeather {
                    HStack {
                        Image(systemName: currentWeather.condition.icon)
                            .foregroundColor(currentWeather.condition.color)

                        Text(currentWeather.formattedTemperature)
                            .font(.subheadline)

                        Text(currentWeather.condition.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if currentWeather.outdoorWorkRisk == .extreme {
                            // If you still want to check "isHazardous", make sure WeatherData has that property.
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                } else {
                    Text("Loading weather data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            // Fetch weather data and update local state
            adapter.fetchWeatherForBuilding(building)
            currentWeather = adapter.currentWeather       // adapter.currentWeather should now match WeatherData?
            forecast = adapter.forecast                     // adapter.forecast should now be [WeatherData]
        }
        .sheet(isPresented: $showWeatherTasks) {
            weatherTasksSheet()
        }
    }

    // Current weather view component – uses WeatherData
    private func currentWeatherView(_ weather: WeatherData) -> some View {
        HStack(spacing: 15) {
            // Weather icon and temperature
            VStack(alignment: .center, spacing: 5) {
                Image(systemName: weather.condition.icon)
                    .font(.system(size: 34))
                    .foregroundColor(weather.condition.color)

                Text(weather.formattedTemperature)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(weather.formattedHighLow)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 90)

            Divider()
                .frame(height: 70)

            // Weather details
            VStack(alignment: .leading, spacing: 6) {
                Text("Today: \(weather.condition.rawValue)")
                    .font(.headline)

                HStack(spacing: 15) {
                    weatherDetailItem(icon: "drop.fill", value: "\(Int(weather.humidity))%", label: "Humidity")

                    weatherDetailItem(icon: "wind", value: "\(Int(weather.windSpeed)) mph", label: "Wind")

                    if weather.precipitation > 0 {
                        weatherDetailItem(icon: "umbrella.fill", value: "\(weather.precipitation)\"", label: "Rain")
                    }
                }

                Text("Outdoor work: \(weather.outdoorWorkRisk.rawValue)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(weather.outdoorWorkRisk.color.opacity(0.1))
                    .foregroundColor(weather.outdoorWorkRisk.color)
                    .cornerRadius(8)
            }
        }
    }

    // Weather detail item
    private func weatherDetailItem(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.blue)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // Daily forecast view component – uses WeatherData
    private func dailyForecastView(_ weather: WeatherData) -> some View {
        VStack(spacing: 6) {
            Text(dayOfWeek(from: weather.date))
                .font(.caption)
                .foregroundColor(.secondary)

            Image(systemName: weather.condition.icon)
                .font(.system(size: 22))
                .foregroundColor(weather.condition.color)

            Text(weather.formattedTemperature)
                .font(.caption)
                .fontWeight(.medium)

            if weather.outdoorWorkRisk == .extreme {
                // Again, if “isHazardous” is defined in adapter’s type, replace this check accordingly
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
            }
        }
        .frame(width: 60, height: 90)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(weather.outdoorWorkRisk == .extreme ? Color.red.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }

    // Weather alerts view
    private func weatherAlertsView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let notification = adapter.createWeatherNotification(for: building) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text(notification)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            let riskAssessment = adapter.assessWeatherRisk(for: building)
            if riskAssessment != "No significant risks" {
                Text("Weather Risks:")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text(riskAssessment)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Task rescheduling info – check if any forecast items have high risk
            let hazardousDays = forecast.filter { $0.outdoorWorkRisk == .extreme }
            if !hazardousDays.isEmpty {
                Text("Some outdoor tasks may need rescheduling")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }

    // Weather tasks sheet
    private func weatherTasksSheet() -> some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Weather-Related Tasks")) {
                        let tasks = adapter.generateWeatherTasks(for: building)

                        if tasks.isEmpty {
                            Text("No weather-related tasks needed at this time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(tasks, id: \.id) { task in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: task.category.icon)
                                            .foregroundColor(task.urgency.color)

                                        Text(task.name)
                                            .font(.headline)
                                    }

                                    Text(task.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Label(formatDate(task.dueDate), systemImage: "calendar")
                                            .font(.caption)

                                        Spacer()

                                        Text(task.urgency.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(task.urgency.color.opacity(0.1))
                                            .foregroundColor(task.urgency.color)
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    Section(header: Text("Emergency Task")) {
                        Button(action: {
                            _ = adapter.createEmergencyWeatherTask(for: building)
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)

                                Text("Create Emergency Weather Task")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Button(action: {
                    let tasks = adapter.generateWeatherTasks(for: building)
                    TaskManager.shared.createWeatherBasedTasks(
                        for: building.id,
                        tasks: tasks
                    )
                    showWeatherTasks = false
                }) {
                    Text("Generate All Tasks")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding()
                }
            }
            .navigationTitle("Weather Tasks")
            .navigationBarItems(trailing: Button("Done") {
                showWeatherTasks = false
            })
        }
    }

    // MARK: - Helper Methods

    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct WeatherDashboardComponent_Previews: PreviewProvider {
    static var previews: some View {
        WeatherDashboardComponent(
            building: FrancoSphere.NamedCoordinate(
                id: "preview-building",
                name: "Sample Building",
                latitude: 40.7128,
                longitude: -74.0060,
                address: "123 Main St",
                imageAssetName: "building1"
            )
        )
        .padding()
        .previewLayout(.fixed(width: 400, height: 300))
    }
}
