//
//  DashboardTaskDetailView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/2/25.
//

import SwiftUI

private func getUrgencyColor(_ urgency: TaskUrgency) -> Color {
    switch urgency {
    case .low:    return .green
    case .medium: return .yellow
    case .high:   return .red
    case .urgent: return .purple
    }
}

struct DashboardTaskDetailView: View {
    let task: MaintenanceTask
    @State private var isComplete: Bool
    @State private var buildingName: String = "Unknown Building"
    @State private var isUpdatingStatus = false
    
    init(task: MaintenanceTask) {
        self.task = task
        self._isComplete = State(initialValue: task.isComplete)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Task header
            Text(task.name)
                .font(.title2)
                .bold()
            
            // Building and status info
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.blue)
                
                Text(buildingName)
                    .font(.headline)
            }
            
            // Task status badge
            HStack {
                Circle()
                    .fill(task.statusColor)
                    .frame(width: 12, height: 12)
                
                Text(task.statusText)
                    .font(.subheadline)
                    .foregroundColor(task.statusColor)
                
                Spacer()
                
                // Task category badge
                Text(task.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.category == .maintenance ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Divider()
            
            // Task description
            VStack(alignment: .leading, spacing: 8) {
                Text("Task Description:")
                    .font(.headline)
                
                Text(task.description)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Due date and timing info
            VStack(alignment: .leading, spacing: 8) {
                Text("Schedule:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Due: \(task.dueDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                    }
                    
                    if let startTime = task.startTime {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.green)
                            Text("Start: \(startTime.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline)
                        }
                    }
                    
                    if let endTime = task.endTime {
                        HStack {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(.orange)
                            Text("End: \(endTime.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline)
                        }
                    }
                    
                    if task.recurrence != .oneTime {
                        HStack {
                            Image(systemName: "repeat")
                                .foregroundColor(.purple)
                            Text("Recurrence: \(task.recurrence.rawValue)")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Urgency level
            HStack {
                Text("Priority:")
                    .font(.headline)
                
                Spacer()
                
                HStack {
                    Circle()
                        .fill(getUrgencyColor(task.urgency))  // ✅ Use helper function
                        .frame(width: 10, height: 10)
                    
                    Text(task.urgency.rawValue)
                        .font(.subheadline)
                        .foregroundColor(getUrgencyColor(task.urgency))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(getUrgencyColor(task.urgency))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Complete button
            Button {
                toggleTaskCompletion()
            } label: {
                HStack {
                    if isUpdatingStatus {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    }
                    
                    Text(isComplete ? "Task Completed" : "Mark as Complete")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isComplete ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isUpdatingStatus)
            .animation(.easeInOut(duration: 0.2), value: isComplete)
        }
        .padding()
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBuildingInfo()
        }
    }
    
    // MARK: - Private Methods
    
    private func toggleTaskCompletion() {
        guard !isUpdatingStatus else { return }
        
        isUpdatingStatus = true
        
        Task {
                    // Update the completion state
                    await TaskManager.shared.toggleTaskCompletionAsync(taskID: task.id, completedBy: "Current User")
                    
                    await MainActor.run {
                        isComplete.toggle()
                        isUpdatingStatus = false
                    }
                }
            }
        }
    
    private func loadBuildingInfo() async {
        do {
            // Use BuildingRepository to get building name
            let buildingName = await BuildingRepository.shared.name(forId: task.buildingID)
            
            await MainActor.run {
                self.buildingName = buildingName
            }
        }
    }

// MARK: - Preview

struct DashboardTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardTaskDetailView(
                task: MaintenanceTask(
                    id: "sample-1",
                    name: "Fix HVAC System",
                    buildingID: "1",
                    description: "The HVAC system in the lobby needs maintenance. Check filters and coolant levels.",
                    dueDate: Date(),
                    startTime: Date().addingTimeInterval(3600),
                    endTime: Date().addingTimeInterval(7200),
                    category: .maintenance,
                    urgency: .medium,
                    recurrence: .oneTime,
                    isComplete: false
                )
            )
        }
        .preferredColorScheme(.dark)
    }
}
