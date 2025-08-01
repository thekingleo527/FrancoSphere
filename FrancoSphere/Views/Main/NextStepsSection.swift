//
//  NextStepsView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed non-existent properties and corrected syntax
//  ✅ RENAMED: Changed from NextStepsSection to NextStepsView to avoid conflicts
//  ✅ NEW: Smart task progression component
//  ✅ INTEGRATES: RoutineRepository for routine-based tasks
//  ✅ CONTEXT-AWARE: Shows tasks based on current location
//  ✅ INTELLIGENT: Prioritizes by location, urgency, and time
//

import SwiftUI
import CoreLocation

struct NextStepsView: View {
    // MARK: - Properties
    let currentTask: CoreTypes.ContextualTask?
    let upcomingTasks: [CoreTypes.ContextualTask]
    let currentBuilding: CoreTypes.NamedCoordinate?
    let onStartTask: (CoreTypes.ContextualTask) -> Void
    let onSeeAll: () -> Void
    
    @StateObject private var routineRepo = RoutineRepository.shared
    @State private var showLocationDetails = false
    
    // MARK: - Computed Properties
    
    private var tasksAtCurrentLocation: [CoreTypes.ContextualTask] {
        guard let buildingId = currentBuilding?.id else { return [] }
        return upcomingTasks.filter { $0.buildingId == buildingId }
    }
    
    private var tasksAtOtherLocations: [CoreTypes.ContextualTask] {
        guard let buildingId = currentBuilding?.id else { return upcomingTasks }
        return upcomingTasks.filter { $0.buildingId != buildingId }
    }
    
    private var nextRoutine: BuildingRoutine? {
        guard let buildingId = currentBuilding?.id else { return nil }
        return routineRepo.getRoutinesForBuilding(buildingId)
            .filter { !$0.isOverdue && $0.isDueToday }
            .sorted { $0.priority.rawValue > $1.priority.rawValue }
            .first
    }
    
    private var hasTimeSensitiveTasks: Bool {
        upcomingTasks.contains { task in
            task.urgency == .urgent ||
            task.urgency == .critical ||
            task.title.lowercased().contains("dsny") ||
            task.title.lowercased().contains("pickup")
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            sectionHeader
            
            // Content card
            VStack(spacing: 12) {
                // Current location context
                if let building = currentBuilding {
                    currentLocationCard(building)
                }
                
                // Current task (most prominent)
                if let task = currentTask {
                    NextStepsTaskCard(
                        task: task,
                        onStart: { onStartTask(task) }
                    )
                }
                
                // Time-sensitive alerts
                if hasTimeSensitiveTasks {
                    timeSensitiveAlert
                }
                
                // Tasks at current location
                if !tasksAtCurrentLocation.isEmpty && currentTask == nil {
                    locationTasksSection
                }
                
                // Routine reminder
                if let routine = nextRoutine {
                    routineReminderCard(routine)
                }
                
                // Next location preview
                if let nextLocation = getNextLocation() {
                    nextLocationPreview(nextLocation)
                }
                
                // Remaining tasks summary
                if upcomingTasks.count > 3 {
                    remainingTasksSummary
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Components
    
    private var sectionHeader: some View {
        HStack {
            Label("Next Steps", systemImage: "checklist")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onSeeAll) {
                HStack(spacing: 4) {
                    Text("All Tasks")
                    Image(systemName: "arrow.right")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    private func currentLocationCard(_ building: CoreTypes.NamedCoordinate) -> some View {
        HStack {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text("CURRENT LOCATION: \(building.name)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
            
            Spacer()
            
            if tasksAtCurrentLocation.count > 1 {
                Text("\(tasksAtCurrentLocation.count) tasks here")
                    .font(.caption2)
                    .foregroundColor(.green.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var timeSensitiveAlert: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.orange)
            
            Text(getTimeSensitiveMessage())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var locationTasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHILE YOU'RE HERE:")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
            
            ForEach(tasksAtCurrentLocation.prefix(2)) { task in
                NextStepsCompactTaskRow(task: task)
            }
            
            if tasksAtCurrentLocation.count > 2 {
                Text("+ \(tasksAtCurrentLocation.count - 2) more at this location")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 2)
            }
        }
        .padding(.top, 8)
    }
    
    private func routineReminderCard(_ routine: BuildingRoutine) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.body)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ROUTINE: \(routine.routineName)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
                
                Text(routine.displaySchedule)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("\(routine.estimatedDuration) min")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(12)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func nextLocationPreview(_ location: NextLocationInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.triangle.turn.up.right.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("NEXT STOP:")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.building.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("\(location.taskCount) tasks • \(location.estimatedTime)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: { showLocationDetails = true }) {
                    Text("View Route")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var remainingTasksSummary: some View {
        HStack {
            Image(systemName: "list.bullet.indent")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Text("\(upcomingTasks.count) tasks remaining today")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            // Estimated time
            Text(getEstimatedRemainingTime())
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    
    private func getTimeSensitiveMessage() -> String {
        if let dsnyTask = upcomingTasks.first(where: { $0.title.lowercased().contains("dsny") }) {
            if let dueTime = dsnyTask.dueDate {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "DSNY pickup by \(formatter.string(from: dueTime))"
            }
        }
        
        let urgentCount = upcomingTasks.filter { $0.urgency == .urgent || $0.urgency == .critical }.count
        if urgentCount > 0 {
            return "\(urgentCount) urgent task\(urgentCount > 1 ? "s" : "") require attention"
        }
        
        return "Time-sensitive tasks pending"
    }
    
    private func getNextLocation() -> NextLocationInfo? {
        // Group tasks by building
        let tasksByBuilding = Dictionary(grouping: tasksAtOtherLocations) { task in
            task.buildingId ?? "unknown"
        }
        
        // Find building with most tasks or highest priority
        let sortedBuildings = tasksByBuilding.sorted { (first, second) in
            let firstPriority = first.value.map { $0.urgency?.priorityValue ?? 0 }.max() ?? 0
            let secondPriority = second.value.map { $0.urgency?.priorityValue ?? 0 }.max() ?? 0
            
            if firstPriority != secondPriority {
                return firstPriority > secondPriority
            }
            return first.value.count > second.value.count
        }
        
        guard let nextBuildingId = sortedBuildings.first?.key,
              let tasks = sortedBuildings.first?.value,
              let building = tasks.first?.building else {
            return nil
        }
        
        let totalDuration = tasks.reduce(0) { $0 + ($1.estimatedDuration ?? 900) }
        let estimatedTime = formatDuration(totalDuration)
        
        return NextLocationInfo(
            building: building,
            taskCount: tasks.count,
            estimatedTime: estimatedTime
        )
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    private func getEstimatedRemainingTime() -> String {
        let totalSeconds = upcomingTasks.reduce(0) { $0 + ($1.estimatedDuration ?? 900) }
        return "~\(formatDuration(totalSeconds))"
    }
}

// MARK: - Supporting Types

struct NextLocationInfo {
    let building: CoreTypes.NamedCoordinate
    let taskCount: Int
    let estimatedTime: String
}

// MARK: - Task Card Component (Renamed to avoid conflict)

private struct NextStepsTaskCard: View {
    let task: CoreTypes.ContextualTask
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("NOW:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                // Urgency indicator
                if let urgency = task.urgency, urgency.priorityValue > 50 {
                    NextStepsUrgencyBadge(urgency: urgency)
                }
            }
            
            // Task details
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 16) {
                    // Show building name instead of location
                    if let building = task.building {
                        Label(building.name, systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if task.requiresPhoto == true {  // Fixed: Unwrap optional Bool
                        Label("Photo required", systemImage: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if let duration = task.estimatedDuration {
                        Label("\(Int(duration / 60)) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // Start button
            Button(action: onStart) {
                Text("START TASK")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Compact Task Row (Renamed to avoid conflict)

private struct NextStepsCompactTaskRow: View {
    let task: CoreTypes.ContextualTask
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 6, height: 6)
            
            Text(task.title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            
            Spacer()
            
            if let duration = task.estimatedDuration {
                Text("\(Int(duration / 60))m")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            if task.requiresPhoto == true {  // Fixed: Unwrap optional Bool
                Image(systemName: "camera.fill")
                    .font(.caption2)
                    .foregroundColor(.orange.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }
}

// MARK: - Urgency Badge (Renamed to avoid conflict)

private struct NextStepsUrgencyBadge: View {
    let urgency: CoreTypes.TaskUrgency
    
    var body: some View {
        Label(urgency.rawValue.capitalized, systemImage: "exclamationmark.triangle.fill")
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(urgencyColor.opacity(0.9))
            .cornerRadius(6)
    }
    
    private var urgencyColor: Color {
        switch urgency {
        case .emergency, .critical: return .red
        case .urgent, .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

// MARK: - TaskUrgency Extension for Priority Value

extension CoreTypes.TaskUrgency {
    var priorityValue: Int {
        switch self {
        case .emergency: return 100
        case .critical: return 90
        case .urgent: return 80
        case .high: return 70
        case .medium: return 50
        case .low: return 30
        }
    }
}

// MARK: - BuildingRoutine Extension (placeholder properties)

extension BuildingRoutine {
    var displaySchedule: String {
        "Daily at \(estimatedDuration) min"
    }
    
    var isOverdue: Bool {
        false // Placeholder
    }
    
    var isDueToday: Bool {
        true // Placeholder
    }
}

// MARK: - Preview

struct NextStepsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                NextStepsView(
                    currentTask: CoreTypes.ContextualTask(
                        id: "1",
                        title: "Clean Main Lobby",
                        urgency: .high,
                        building: CoreTypes.NamedCoordinate(
                            id: "14",
                            name: "Rubin Museum",
                            address: "150 W 17th St",
                            latitude: 40.7402,
                            longitude: -73.9980
                        ),
                        buildingId: "14",  // Fixed: building comes before buildingId
                        requiresPhoto: true,
                        estimatedDuration: 1200
                    ),
                    upcomingTasks: [
                        CoreTypes.ContextualTask(
                            id: "2",
                            title: "Empty Trash Bins",
                            urgency: .medium,
                            building: CoreTypes.NamedCoordinate(
                                id: "14",
                                name: "Rubin Museum",
                                address: "150 W 17th St",
                                latitude: 40.7402,
                                longitude: -73.9980
                            ),
                            buildingId: "14",  // Fixed: building comes before buildingId
                            requiresPhoto: false,
                            estimatedDuration: 900
                        )
                    ],
                    currentBuilding: CoreTypes.NamedCoordinate(
                        id: "14",
                        name: "Rubin Museum",
                        address: "150 W 17th St",
                        latitude: 40.7402,
                        longitude: -73.9980
                    ),
                    onStartTask: { _ in },
                    onSeeAll: { }
                )
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
