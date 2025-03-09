//
//  DashboardTaskDetailView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/2/25.
//

import SwiftUI

struct DashboardTaskDetailView: View {
    let task: MaintenanceTask
    @State private var isComplete: Bool
    @State private var buildingName: String = "Unknown Building"
    
    init(task: MaintenanceTask) {
        self.task = task
        self._isComplete = State(initialValue: task.isComplete)
        
        // Get the building name if possible
        if let building = NamedCoordinate.allBuildings.first(where: { $0.id == task.buildingID }) {
            self._buildingName = State(initialValue: building.name)
        }
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
            
            Divider()
            
            // Task description
            Text("Task Description:")
                .font(.headline)
            
            Text(task.description)
                .padding(.bottom)
            
            // Due date
            Text("Due: \(task.dueDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Complete button
            Button {
                // Toggle the completion state
                isComplete.toggle()
                
                // Update in database
                TaskManager.shared.toggleTaskCompletion(taskID: task.id)
            } label: {
                Label(
                    isComplete ? "Completed" : "Mark as Complete",
                    systemImage: isComplete ? "checkmark.circle.fill" : "circle"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(isComplete ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundColor(isComplete ? .green : .blue)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isComplete ? Color.green : Color.blue, lineWidth: 1)
                )
            }
        }
        .padding()
        .navigationTitle("Task Details")
        .onAppear {
            // Get the most up-to-date status from database
            updateBuildingInfo()
        }
    }
    
    private func updateBuildingInfo() {
        // In a real app, you'd fetch the building info from your database
        if let buildingId = Int64(task.buildingID) {
            do {
                guard let db = SQLiteManager.shared.db else { return }
                
                let query = "SELECT name FROM buildings WHERE id = ?"
                let rows = try db.prepare(query, [buildingId])
                
                if let row = rows.next() {
                    buildingName = row[0] as! String
                }
            } catch {
                print("Error fetching building info: \(error)")
            }
        }
    }
}

// Preview
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
    }
}
