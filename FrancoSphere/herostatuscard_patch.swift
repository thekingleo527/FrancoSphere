// Add this to fix HeroStatusCard.swift initialization issues:

// Line 214 fix:
let weather = CoreTypes.WeatherData(
    temperature: 72.0,
    condition: .clear,
    humidity: 45.0,
    windSpeed: 10.0,
    outdoorWorkRisk: .low,
    timestamp: Date()
)

// Line 221 fix:
let progress = CoreTypes.TaskProgress(
    totalTasks: 10,
    completedTasks: 5
)

// Line 232 fix - replace Environment usage:
// Remove: @Environment(\.colorScheme) var colorScheme
// Use: Color.primary instead
