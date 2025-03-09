import SwiftUI

struct WeatherTasksSection: View {
    @StateObject private var adapter = WeatherDataAdapter.shared  // Replace WeatherService with WeatherDataAdapter
    var tasks: [FrancoSphere.MaintenanceTask] // Use fully qualified type
    var onReschedule: (FrancoSphere.MaintenanceTask, Date) -> Void
    
    private var weatherAffectedTasks: [FrancoSphere.MaintenanceTask] {
        return tasks.filter { task in
            // Use adapter to check if task should be rescheduled
            return adapter.shouldRescheduleTask(task)
        }
    }
    
    var body: some View {
        if !weatherAffectedTasks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Weather Alert")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Spacer()
                }
                
                Text("The following tasks may be affected by current weather conditions:")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)  // Simplified color reference
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(weatherAffectedTasks) { task in
                            WeatherAffectedTaskCard(
                                task: task,
                                onReschedule: onReschedule
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct WeatherAffectedTaskCard: View {
    let task: FrancoSphere.MaintenanceTask // Use fully qualified type
    @StateObject private var adapter = WeatherDataAdapter.shared  // Use adapter instead of WeatherService
    var onReschedule: (FrancoSphere.MaintenanceTask, Date) -> Void
    
    @State private var isShowingDatePicker = false
    @State private var suggestedDate: Date? = nil // Initialize with nil
    @State private var selectedDate: Date = Date().addingTimeInterval(86400) // Tomorrow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: task.category.icon)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.orange)
                    .cornerRadius(8)
                
                Text(task.name)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            Text(getBuildingName(for: task.buildingID))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Due Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(task.dueDate))
                        .font(.callout)
                }
                
                Spacer()
                
                Button(action: {
                    // Get recommended reschedule date from adapter
                    suggestedDate = adapter.recommendedRescheduleDateForTask(task)
                    
                    if let date = suggestedDate {
                        selectedDate = date
                    } else {
                        selectedDate = Date().addingTimeInterval(86400 * 2) // Default to 2 days from now
                    }
                    
                    isShowingDatePicker = true
                }) {
                    Text("Reschedule")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(width: 220)
        .background(Color(UIColor.systemBackground))  // Simplified color reference
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $isShowingDatePicker) {
            VStack(spacing: 20) {
                Text("Reschedule Task")
                    .font(.headline)
                
                if let suggestedDate = suggestedDate {
                    VStack(alignment: .leading) {
                        Text("Suggested Date:")
                            .font(.subheadline)
                        
                        Text(formatDate(suggestedDate))
                            .font(.body)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                DatePicker(
                    "Select New Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                HStack {
                    Button("Cancel") {
                        isShowingDatePicker = false
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Confirm") {
                        onReschedule(task, selectedDate)
                        isShowingDatePicker = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .padding()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getBuildingName(for id: String) -> String {
        return FrancoSphere.NamedCoordinate.getBuilding(byId: id)?.name ?? "Unknown Building"
    }
}

struct WeatherTasksSection_Previews: PreviewProvider {
    static var previews: some View {
        // Use explicit FrancoSphere.MaintenanceTask type to avoid ambiguity
        let tasks: [FrancoSphere.MaintenanceTask] = [
            FrancoSphere.MaintenanceTask(
                id: "1",
                name: "Window Cleaning",
                buildingID: "1",
                description: "Clean exterior windows",
                dueDate: Date(),
                category: .cleaning,
                urgency: .medium,
                recurrence: .weekly,
                isComplete: false
            ),
            FrancoSphere.MaintenanceTask(
                id: "2",
                name: "Roof Inspection",
                buildingID: "2",
                description: "Inspect roof for damage",
                dueDate: Date(),
                category: .inspection,
                urgency: .high,
                recurrence: .monthly,
                isComplete: false
            )
        ]
        
        WeatherTasksSection(
            tasks: tasks,
            onReschedule: { _, _ in }
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
