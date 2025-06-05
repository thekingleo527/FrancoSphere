import SwiftUI

struct MaintenanceTaskView: View {
    let task: MaintenanceTask
    @Environment(\.presentationMode) private var presentationMode
    @State private var showCompleteConfirmation = false
    @State private var buildingName: String = "Loading..."
    @State private var isMarkingComplete = false

    private let buildingRepo = BuildingRepository.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Header
                HStack {
                    Text(task.name).font(.title).bold()
                    Spacer()
                    StatusBadge(isCompleted: task.isComplete, urgency: task.urgency)
                }

                // Building
                buildingInfoSection

                Divider()

                // Details
                taskDetailsSection

                Divider()

                // Timing
                timingSection

                Divider()

                // Assignments
                assignmentSection

                // Action buttons
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle("Maintenance Task")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // FIXED: Load building name asynchronously
            await loadBuildingName()
        }
        .alert(isPresented: $showCompleteConfirmation) {
            Alert(title: Text("Mark as Complete?"),
                  message: Text("Are you sure you want to mark this task as complete?"),
                  primaryButton: .default(Text("Yes"), action: {
                      // FIXED: Use Task wrapper for async call
                      Task {
                          await markTaskAsComplete()
                      }
                  }),
                  secondaryButton: .cancel())
        }
    }

    // MARK: – Sections
    private var buildingInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Building").font(.headline).foregroundColor(.secondary)
            HStack {
                Image(systemName: "building.2").foregroundColor(.blue)
                // FIXED: Use state variable instead of direct async call
                Text(buildingName).font(.body)
            }
        }
    }

    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details").font(.headline).foregroundColor(.secondary)

            HStack {
                Image(systemName: task.category.icon).foregroundColor(.blue)
                Text(task.category.rawValue).font(.subheadline)
            }

            Text(task.description).font(.body).padding(.top, 4)
        }
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timing").font(.headline).foregroundColor(.secondary)

            HStack {
                Image(systemName: "calendar").foregroundColor(.blue)
                Text("Due: \(formattedDate(task.dueDate))").font(.subheadline)
            }

            if let start = task.startTime {
                HStack {
                    Image(systemName: "clock").foregroundColor(.blue)
                    Text("Start: \(formattedTime(start))").font(.subheadline)
                }
            }

            if let end = task.endTime {
                HStack {
                    Image(systemName: "clock.arrow.circlepath").foregroundColor(.blue)
                    Text("End: \(formattedTime(end))").font(.subheadline)
                }
            }

            HStack {
                Image(systemName: "repeat").foregroundColor(.blue)
                Text("Recurrence: \(task.recurrence.rawValue)").font(.subheadline)
            }
        }
    }

    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assignments").font(.headline).foregroundColor(.secondary)

            if task.assignedWorkers.isEmpty {
                HStack {
                    Image(systemName: "person.badge.minus").foregroundColor(.orange)
                    Text("No workers assigned").font(.subheadline).foregroundColor(.secondary)
                }
            } else {
                ForEach(task.assignedWorkers, id: \.self) { workerId in
                    HStack {
                        Image(systemName: "person.fill").foregroundColor(.blue)
                        Text("Worker ID: \(workerId)").font(.subheadline)
                    }
                }
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button {
                showCompleteConfirmation = true
            } label: {
                HStack {
                    if isMarkingComplete {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: task.isComplete ? "arrow.uturn.left"
                                                          : "checkmark.circle")
                    }
                    Text(isMarkingComplete ? "Processing..." :
                         (task.isComplete ? "Mark as Pending" : "Mark as Complete"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(task.isComplete ? Color.orange : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isMarkingComplete)

            Button {
                // Add reassign logic here
                Task {
                    await reassignWorkers()
                }
            } label: {
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

    // MARK: – Async Helper Methods
    
    /// Load building name asynchronously
    private func loadBuildingName() async {
        let name = await buildingRepo.name(forId: task.buildingID)
        await MainActor.run {
            self.buildingName = name
        }
    }
    
    /// Mark task as complete asynchronously
    private func markTaskAsComplete() async {
        await MainActor.run {
            isMarkingComplete = true
        }
        
        // FIXED: Call async version of toggleTaskCompletion
        await TaskManager.shared.toggleTaskCompletionAsync(taskID: task.id, completedBy: "Current User")
        
        await MainActor.run {
            isMarkingComplete = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// Reassign workers (placeholder for future implementation)
    private func reassignWorkers() async {
        // TODO: Implement worker reassignment logic
        print("Reassigning workers for task: \(task.id)")
    }

    // MARK: – Helpers
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short;  return f.string(from: date)
    }
}

// MARK: – Status badge helper
struct StatusBadge: View {
    let isCompleted: Bool
    let urgency: TaskUrgency

    var body: some View {
        Text(isCompleted ? "Completed" : urgency.rawValue)
            .font(.caption).fontWeight(.bold)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(isCompleted ? Color.gray : urgency.color)
            .foregroundColor(.white)
            .cornerRadius(20)
    }
}
