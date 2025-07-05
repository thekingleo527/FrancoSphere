#!/bin/bash

echo "🔧 Comprehensive Weather & Dashboard Fix"
echo "======================================="

# Create backup
BACKUP_DIR="weather_fix_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r Components/ Views/ "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Backup created: $BACKUP_DIR"

# Step 1: Complete rewrite of WeatherDashboardComponent.swift to fix all issues
echo "🔧 Step 1: Completely rewriting WeatherDashboardComponent.swift..."

cat > "Components/Shared Components/WeatherDashboardComponent.swift" << 'WEATHER_EOF'
//
//  WeatherDashboardComponent.swift
//  FrancoSphere
//
//  Complete rewrite to fix all compilation errors
//

import SwiftUI
import CoreLocation

struct WeatherDashboardComponent: View {
    let building: FrancoSphere.NamedCoordinate
    let weather: FrancoSphere.WeatherData?
    let tasks: [ContextualTask]
    let onTaskTap: (ContextualTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Weather Header
            weatherHeaderView
            
            // Weather Impact Section
            if let weather = weather {
                weatherImpactView(weather)
            }
            
            // Weather-Affected Tasks
            if !weatherAffectedTasks.isEmpty {
                weatherTasksSection
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Weather Header
    @ViewBuilder
    private var weatherHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather Conditions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let weather = weather {
                    Text("Last updated: \(formatTime(weather.timestamp))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Weather data unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let weather = weather {
                weatherIconView(weather)
            }
        }
    }
    
    // MARK: - Weather Icon View
    @ViewBuilder
    private func weatherIconView(_ weather: FrancoSphere.WeatherData) -> some View {
        VStack(spacing: 4) {
            Image(systemName: getWeatherIcon(for: weather.condition))
                .font(.title2)
                .foregroundColor(getWeatherColor(for: weather.condition))
            
            Text("\(Int(weather.temperature))°F")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(weather.condition.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Weather Impact View
    @ViewBuilder
    private func weatherImpactView(_ weather: FrancoSphere.WeatherData) -> some View {
        let risk = calculateOutdoorWorkRisk(weather)
        
        HStack {
            Image(systemName: getRiskIcon(for: risk))
                .foregroundColor(getRiskColor(for: risk))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Outdoor Work Risk: \(getRiskLevel(for: risk))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(getRiskDescription(for: risk))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(getRiskColor(for: risk).opacity(0.1))
        )
    }
    
    // MARK: - Weather Tasks Section
    @ViewBuilder
    private var weatherTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather-Affected Tasks")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(weatherAffectedTasks) { task in
                weatherTaskRow(task)
            }
        }
    }
    
    @ViewBuilder
    private func weatherTaskRow(_ task: ContextualTask) -> some View {
        Button {
            onTaskTap(task)
        } label: {
            HStack {
                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Category: \(task.category)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Weather impact indicator
                if let weather = weather {
                    weatherImpactIndicator(for: task, weather: weather)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func weatherImpactIndicator(for task: ContextualTask, weather: FrancoSphere.WeatherData) -> some View {
        let impact = getTaskWeatherImpact(task, weather: weather)
        
        VStack(spacing: 2) {
            Image(systemName: impact.icon)
                .foregroundColor(impact.color)
            
            Text(impact.text)
                .font(.caption2)
                .foregroundColor(impact.color)
        }
    }
    
    // MARK: - Computed Properties
    private var weatherAffectedTasks: [ContextualTask] {
        guard let weather = weather else { return [] }
        
        return tasks.filter { task in
            isTaskAffectedByWeather(task, weather: weather)
        }
    }
    
    // MARK: - Helper Functions
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func getWeatherIcon(for condition: FrancoSphere.WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .fog: return "cloud.fog.fill"
        case .storm: return "cloud.bolt.fill"
        }
    }
    
    private func getWeatherColor(for condition: FrancoSphere.WeatherCondition) -> Color {
        switch condition {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .fog: return .gray
        case .storm: return .purple
        }
    }
    
    private func calculateOutdoorWorkRisk(_ weather: FrancoSphere.WeatherData) -> FrancoSphere.OutdoorWorkRisk {
        switch weather.condition {
        case .clear, .cloudy:
            return weather.temperature < 32 ? .medium : .low
        case .rain, .snow:
            return .high
        case .storm:
            return .extreme
        case .fog:
            return .medium
        }
    }
    
    private func getRiskIcon(for risk: FrancoSphere.OutdoorWorkRisk) -> String {
        switch risk {
        case .low: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.circle.fill"
        case .extreme: return "exclamationmark.octagon.fill"
        }
    }
    
    private func getRiskColor(for risk: FrancoSphere.OutdoorWorkRisk) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }
    
    private func getRiskLevel(for risk: FrancoSphere.OutdoorWorkRisk) -> String {
        switch risk {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .extreme: return "Extreme"
        }
    }
    
    private func getRiskDescription(for risk: FrancoSphere.OutdoorWorkRisk) -> String {
        switch risk {
        case .low: return "Safe for outdoor work"
        case .medium: return "Use caution outdoors"
        case .high: return "Limited outdoor work recommended"
        case .extreme: return "Avoid outdoor work"
        }
    }
    
    private func isTaskAffectedByWeather(_ task: ContextualTask, weather: FrancoSphere.WeatherData) -> Bool {
        let outdoorCategories = ["sanitation", "cleaning", "maintenance"]
        let taskCategory = task.category.lowercased()
        
        // Check if task is outdoor-related
        guard outdoorCategories.contains(taskCategory) || 
              task.name.lowercased().contains("sidewalk") ||
              task.name.lowercased().contains("trash") ||
              task.name.lowercased().contains("hose") else {
            return false
        }
        
        // Check if weather conditions affect outdoor work
        switch weather.condition {
        case .rain, .snow, .storm:
            return true
        case .clear, .cloudy, .fog:
            return weather.temperature < 32 || weather.temperature > 90
        }
    }
    
    private func getTaskWeatherImpact(_ task: ContextualTask, weather: FrancoSphere.WeatherData) -> (icon: String, color: Color, text: String) {
        let risk = calculateOutdoorWorkRisk(weather)
        
        switch risk {
        case .low:
            return ("checkmark", .green, "Safe")
        case .medium:
            return ("exclamationmark.triangle", .yellow, "Caution")
        case .high:
            return ("xmark", .orange, "Limited")
        case .extreme:
            return ("exclamationmark.octagon", .red, "Avoid")
        }
    }
}

// MARK: - Preview
#Preview {
    WeatherDashboardComponent(
        building: FrancoSphere.NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            latitude: 40.7402,
            longitude: -73.9980,
            imageAssetName: "rubin_museum"
        ),
        weather: FrancoSphere.WeatherData(
            temperature: 45,
            condition: .rain,
            humidity: 80,
            windSpeed: 15,
            timestamp: Date()
        ),
        tasks: [
            ContextualTask(
                id: "1",
                name: "Sidewalk Cleaning",
                buildingId: "14",
                buildingName: "Rubin Museum",
                category: "Cleaning",
                startTime: "10:00",
                endTime: "11:00",
                recurrence: "Daily",
                skillLevel: "Basic",
                status: "pending",
                urgencyLevel: "Medium",
                assignedWorkerName: "Kevin Dutan"
            )
        ]
    ) { task in
        print("Tapped task: \(task.name)")
    }
    .padding()
}
WEATHER_EOF

echo "   ✅ Completely rewrote WeatherDashboardComponent.swift"

# Step 2: Fix WorkerDashboardView.swift duplicate contextEngine
echo "🔧 Step 2: Fixing WorkerDashboardView.swift duplicate contextEngine..."

# Read the file and fix the duplicate declarations
python3 << 'PYTHON_EOF'
import re

# Read the file
with open('Views/Main/WorkerDashboardView.swift', 'r') as f:
    content = f.read()

# Remove duplicate @StateObject contextEngine declarations
# Keep only the first occurrence
lines = content.split('\n')
seen_context_engine = False
filtered_lines = []

for line in lines:
    if '@StateObject' in line and 'contextEngine' in line:
        if not seen_context_engine:
            filtered_lines.append(line)
            seen_context_engine = True
        # Skip duplicate lines
    else:
        filtered_lines.append(line)

# Write back the fixed content
with open('Views/Main/WorkerDashboardView.swift', 'w') as f:
    f.write('\n'.join(filtered_lines))

print("Fixed WorkerDashboardView.swift duplicate contextEngine")
PYTHON_EOF

echo "   ✅ Fixed WorkerDashboardView.swift"

# Step 3: Ensure WeatherCondition extension exists for icon property
echo "🔧 Step 3: Adding WeatherCondition icon extension..."

# Add icon extension to ModelColorsExtensions.swift if it doesn't exist
if ! grep -q "var icon:" Components/Design/ModelColorsExtensions.swift; then
    cat >> Components/Design/ModelColorsExtensions.swift << 'ICON_EOF'

extension FrancoSphere.WeatherCondition {
    var icon: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .fog: return "cloud.fog.fill"
        case .storm: return "cloud.bolt.fill"
        }
    }
}
ICON_EOF
    echo "   ✅ Added WeatherCondition icon extension"
else
    echo "   ✅ WeatherCondition icon extension already exists"
fi

# Step 4: Fix ContextualTask constructor to remove address parameter
echo "🔧 Step 4: Ensuring ContextualTask constructor compatibility..."

# Make sure ContextualTask doesn't expect an address parameter
if grep -q "address:" Models/ContextualTask.swift 2>/dev/null; then
    sed -i.bak 's/, address: String?//g' Models/ContextualTask.swift
    sed -i.bak 's/address: String?, //g' Models/ContextualTask.swift
    echo "   ✅ Fixed ContextualTask constructor"
fi

echo ""
echo "🎯 COMPREHENSIVE FIX COMPLETE!"
echo "============================="
echo ""
echo "📋 Fixed Issues:"
echo "   1. ✅ WeatherDashboardComponent.swift - Complete rewrite"
echo "      • Fixed .date → .timestamp"
echo "      • Added weather icon helpers"
echo "      • Fixed OutdoorWorkRisk references"
echo "      • Removed ambiguous type references"
echo "      • Fixed enum case references"
echo "      • Removed Task conflicts"
echo "   2. ✅ WorkerDashboardView.swift - Removed duplicate contextEngine"
echo "   3. ✅ WeatherCondition icon extension added"
echo "   4. ✅ ContextualTask constructor compatibility"
echo ""
echo "🚀 All 25+ errors should now be resolved!"
echo ""
echo "🔨 Next Steps:"
echo "   1. Clean build: xcodebuild clean build -project FrancoSphere.xcodeproj"
echo "   2. Test Kevin login → Rubin Museum assignment"
echo "   3. Verify weather dashboard functionality"
echo "   4. Test task completion workflow"
echo ""
echo "💾 Backup available at: $BACKUP_DIR"
echo "🎉 Ready for final validation and Phase 3 implementation!"
