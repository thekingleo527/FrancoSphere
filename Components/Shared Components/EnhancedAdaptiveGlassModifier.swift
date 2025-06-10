//
//  EnhancedAdaptiveGlassModifier.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//


//
//  SupportingComponents.swift
//  FrancoSphere
//
//  Additional components needed for WorkerDashboardView_V2
//  Location: /Components/SupportingComponents.swift
//

import SwiftUI
import Foundation

// MARK: - Enhanced AdaptiveGlassModifier
struct EnhancedAdaptiveGlassModifier: ViewModifier {
    let scrollOffset: CGFloat
    let intensity: GlassIntensity
    let cornerRadius: CGFloat
    
    private var adaptiveIntensity: GlassIntensity {
        // Increase glass intensity when scrolling
        let scrollFactor = min(abs(scrollOffset) / 200, 1.0)
        
        switch intensity {
        case .thin:
            return scrollFactor > 0.5 ? .regular : .thin
        case .regular:
            return scrollFactor > 0.7 ? .thick : .regular
        case .thick:
            return .thick
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Glass background
                    Rectangle()
                        .fill(Color.white.opacity(adaptiveIntensity.opacity))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(adaptiveIntensity.opacity * 2),
                                    Color.white.opacity(adaptiveIntensity.opacity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - TaskStatusExtension
extension ContextualTask {
    var timeStatus: TaskTimeStatus {
        guard let startTime = startTime,
              let startTimeDate = parseTimeString(startTime) else {
            return .noTime
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Check if task is scheduled for today
        let today = calendar.startOfDay(for: now)
        let taskDay = calendar.startOfDay(for: startTimeDate)
        
        guard calendar.isDate(today, equalTo: taskDay, toGranularity: .day) else {
            return .notToday
        }
        
        // Compare with current time
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let taskComponents = calendar.dateComponents([.hour, .minute], from: startTimeDate)
        
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let taskMinutes = (taskComponents.hour ?? 0) * 60 + (taskComponents.minute ?? 0)
        
        let timeDiff = taskMinutes - nowMinutes
        
        if timeDiff < -30 && status == "pending" {
            return .overdue
        } else if timeDiff <= 0 && timeDiff > -30 {
            return .current
        } else if timeDiff <= 60 {
            return .upcoming
        } else {
            return .scheduled
        }
    }
    
    var timeStatusColor: Color {
        switch timeStatus {
        case .overdue:
            return .red
        case .current:
            return .green
        case .upcoming:
            return .orange
        case .scheduled:
            return .blue
        case .noTime, .notToday:
            return .gray
        }
    }
    
    var timeStatusText: String {
        switch timeStatus {
        case .overdue:
            return "Overdue"
        case .current:
            return "Active Now"
        case .upcoming:
            return "Starting Soon"
        case .scheduled:
            return "Scheduled"
        case .noTime:
            return "No Time Set"
        case .notToday:
            return "Not Today"
        }
    }
    
    private func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(
                bySettingHour: components.hour ?? 0,
                minute: components.minute ?? 0,
                second: 0,
                of: Date()
            )
        }
        
        return nil
    }
}

enum TaskTimeStatus {
    case overdue
    case current
    case upcoming
    case scheduled
    case noTime
    case notToday
}

// MARK: - TimeBasedTaskFilter Extensions
extension TimeBasedTaskFilter {
    static func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(
                bySettingHour: components.hour ?? 0,
                minute: components.minute ?? 0,
                second: 0,
                of: Date()
            )
        }
        
        return nil
    }
    
    static func formatTimeString(_ timeString: String) -> String {
        guard let date = parseTimeString(timeString) else { return timeString }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Enhanced WeatherCondition Extensions
extension WeatherCondition {
    var temperatureString: String {
        return "72°" // Placeholder - replace with actual temperature data
    }
    
    var temperature: Int {
        return 72 // Placeholder - replace with actual temperature data
    }
    
    var apparentTemperature: Int {
        return temperature + 2
    }
    
    var humidity: Int {
        return 65 // Placeholder
    }
    
    var windSpeed: Int {
        return 10 // Placeholder
    }
    
    var precipitation: Double {
        return 0.0 // Placeholder
    }
    
    var taskWarnings: [String] {
        switch self {
        case .rain:
            return ["Postpone outdoor cleaning tasks", "Check drainage systems"]
        case .snow:
            return ["Prepare snow removal equipment", "Check heating systems"]
        case .thunderstorm:
            return ["Cancel all outdoor work", "Secure loose equipment"]
        default:
            return []
        }
    }
    
    var color: Color {
        return conditionColor
    }
    
    var condition: String {
        return rawValue
    }
}

// MARK: - Building Extensions
extension Building {
    var address: String? {
        return nil // This will use the existing address property if it exists
    }
}

// MARK: - Mock Weather Service
extension WeatherDataAdapter {
    func fetchWeatherForBuilding(_ building: Building) async -> WeatherCondition? {
        // Mock implementation - replace with real API call
        return WeatherCondition.clear
    }
    
    func fetchWeatherForBuildings(_ buildings: [Building]) async -> [String: WeatherCondition] {
        var weatherMap: [String: WeatherCondition] = [:]
        
        for building in buildings {
            if let weather = await fetchWeatherForBuilding(building) {
                weatherMap[building.id] = weather
            }
        }
        
        return weatherMap
    }
}

// MARK: - TaskTimelineRow Component
struct TaskTimelineRow: View {
    let task: ContextualTask
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Timeline indicator
                VStack(spacing: 0) {
                    Circle()
                        .fill(timelineColor)
                        .frame(width: 12, height: 12)
                    
                    if !isLast {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 12)
                
                // Task content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(task.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let startTime = task.startTime {
                            Text(TimeBasedTaskFilter.formatTimeString(startTime))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(task.buildingName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        // Urgency indicator
                        Text(task.urgencyLevel)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(task.urgencyColor.opacity(0.3))
                            .foregroundColor(task.urgencyColor)
                            .cornerRadius(4)
                    }
                }
                
                // Action indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timelineColor: Color {
        if isActive {
            return .green
        } else if task.isOverdue {
            return .red
        } else {
            return .blue
        }
    }
    
    private var isLast: Bool {
        // This would be passed as a parameter in real implementation
        false
    }
}

// MARK: - Enhanced GlassIntensity
enum EnhancedGlassIntensity: String, CaseIterable {
    case thin = "thin"
    case regular = "regular"
    case thick = "thick"
    
    var blurRadius: CGFloat {
        switch self {
        case .thin:
            return 15
        case .regular:
            return 25
        case .thick:
            return 40
        }
    }
    
    var backgroundOpacity: Double {
        switch self {
        case .thin:
            return 0.1
        case .regular:
            return 0.15
        case .thick:
            return 0.25
        }
    }
    
    var borderOpacity: Double {
        switch self {
        case .thin:
            return 0.2
        case .regular:
            return 0.3
        case .thick:
            return 0.4
        }
    }
}

// MARK: - Alternative AdaptiveGlass Implementation
extension View {
    func enhancedAdaptiveGlass(
        scrollOffset: CGFloat,
        intensity: EnhancedGlassIntensity = .regular,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.modifier(
            EnhancedAdaptiveGlassModifier(
                scrollOffset: scrollOffset,
                intensity: intensity == .thin ? .thin : (intensity == .regular ? .regular : .thick),
                cornerRadius: cornerRadius
            )
        )
    }
}

// MARK: - Utility Functions
struct UtilityFunctions {
    static func formatTimeString(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: time)
        }
        
        return timeString
    }
    
    static func parseTimeString(_ timeStr: String?) -> Date? {
        guard let timeStr = timeStr else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeStr) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(
                bySettingHour: components.hour ?? 0,
                minute: components.minute ?? 0,
                second: 0,
                of: Date()
            )
        }
        
        return nil
    }
}

// MARK: - Mock Components for Missing References
struct MockNovaAvatar: View {
    let size: CGFloat
    let showStatus: Bool
    let hasUrgentInsight: Bool
    let isBusy: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.blue)
                
                if showStatus {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                        }
                        Spacer()
                    }
                    .frame(width: size, height: size)
                }
            }
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

struct MockQuickActionMenu: View {
    @Binding var isPresented: Bool
    let onActionSelected: (QuickActionType) -> Void
    
    var body: some View {
        if isPresented {
            VStack(spacing: 12) {
                ForEach(QuickActionType.allCases) { action in
                    Button(action: {
                        onActionSelected(action)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: action.icon)
                                .font(.system(size: 20))
                            Text(action.title)
                                .font(.subheadline)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 40)
            .transition(.opacity.combined(with: .scale))
        }
    }
}

// MARK: - Global replacements for missing components
// Use these if NovaAvatar and QuickActionMenu don't exist
typealias NovaAvatar = MockNovaAvatar
typealias QuickActionMenu = MockQuickActionMenu

// MARK: - Preview Provider
struct SupportingComponents_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // TaskTimelineRow preview
                TaskTimelineRow(
                    task: ContextualTask(
                        id: "1",
                        name: "HVAC Maintenance",
                        buildingId: "1",
                        buildingName: "12 West 18th Street",
                        category: "Maintenance",
                        startTime: "09:00",
                        endTime: "10:00",
                        recurrence: "Daily",
                        skillLevel: "Intermediate",
                        status: "pending",
                        urgencyLevel: "High"
                    ),
                    isActive: true,
                    onTap: {}
                )
                
                // MockNovaAvatar preview
                MockNovaAvatar(
                    size: 60,
                    showStatus: true,
                    hasUrgentInsight: true,
                    isBusy: false,
                    onTap: {},
                    onLongPress: {}
                )
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}