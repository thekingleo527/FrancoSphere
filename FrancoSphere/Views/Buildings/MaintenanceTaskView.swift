//
//  MaintenanceTaskView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/14/25.
//


import SwiftUI

struct MaintenanceTaskView: View {
    let task: MaintenanceTask
    @Environment(\.presentationMode) var presentationMode
    @State private var showCompleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with status badge
                HStack {
                    Text(task.name)
                        .font(.title)
                        .bold()
                    
                    Spacer()
                    
                    StatusBadge(isCompleted: task.isComplete, urgency: task.urgency)
                }
                
                // Building information
                buildingInfoSection
                
                Divider()
                
                // Task details
                taskDetailsSection
                
                Divider()
                
                // Timing information
                timingSection
                
                Divider()
                
                // Assignment information
                assignmentSection
                
                // Action buttons
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle("Maintenance Task")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showCompleteConfirmation) {
            Alert(
                title: Text("Mark as Complete?"),
                message: Text("Are you sure you want to mark this task as complete?"),
                primaryButton: .default(Text("Yes"), action: {
                    markTaskAsComplete()
                }),
                secondaryButton: .cancel()
            )
        }
    }
    
    private var buildingInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Building")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
                Text(BuildingRepository.shared.getBuildingName(forId: task.buildingID))
                    .font(.body)
            }
        }
    }
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: task.category.icon)
                    .foregroundColor(.blue)
                Text(task.category.rawValue)
                    .font(.subheadline)
            }
            
            Text(task.description)
                .font(.body)
                .padding(.top, 4)
        }
    }
    
    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timing")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Due: \(formattedDate(task.dueDate))")
                    .font(.subheadline)
            }
            
            if let startTime = task.startTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("Start: \(formattedTime(startTime))")
                        .font(.subheadline)
                }
            }
            
            if let endTime = task.endTime {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                    Text("End: \(formattedTime(endTime))")
                        .font(.subheadline)
                }
            }
            
            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(.blue)
                Text("Recurrence: \(task.recurrence.rawValue)")
                    .font(.subheadline)
            }
        }
    }
    
    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assignments")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if task.assignedWorkers.isEmpty {
                HStack {
                    Image(systemName: "person.badge.minus")
                        .foregroundColor(.orange)
                    Text("No workers assigned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(task.assignedWorkers, id: \.self) { workerId in
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                        Text("Worker ID: \(workerId)")
                            .font(.subheadline)
                    }
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showCompleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: task.isComplete ? "arrow.uturn.left" : "checkmark.circle")
                    Text(task.isComplete ? "Mark as Pending" : "Mark as Complete")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(task.isComplete ? Color.orange : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(false) // You can add logic to disable this button based on permissions
            
            Button(action: {
                // Add reassign logic here
            }) {
                HStack {
                    Image(systemName: "person.2.badge.gearshape")
                    Text("Reassign Workers")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(.top, 20)
    }
    
    // Helper methods
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func markTaskAsComplete() {
        // Call TaskManager to toggle completion status
        TaskManager.shared.toggleTaskCompletion(taskID: task.id)
        
        // Pop the view or refresh as needed
        presentationMode.wrappedValue.dismiss()
    }
}

// Helper view for status badge
struct StatusBadge: View {
    let isCompleted: Bool
    let urgency: TaskUrgency
    
    var body: some View {
        Text(isCompleted ? "Completed" : urgency.rawValue)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isCompleted ? Color.gray : urgency.color)
            .foregroundColor(.white)
            .cornerRadius(20)
    }
}