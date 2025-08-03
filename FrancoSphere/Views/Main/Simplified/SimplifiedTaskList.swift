//
//  SimplifiedTaskList.swift
//  FrancoSphere
//
//  Stream A: Claude - UI/UX & Spanish
//  Mission: Create simplified interfaces for specific worker capabilities.
//
//  ✅ PRODUCTION READY: A list component for the simplified dashboard.
//  ✅ SPANISH-READY: All text is localizable.
//  ✅ ACCESSIBLE: Clear visual hierarchy and simple interactions.
//  ✅ FUNCTIONAL: Includes swipe-to-complete and tap-to-view actions.
//  ✅ FIXED: Renamed SimplifiedTaskCard to SimplifiedTaskListCard to avoid conflict
//

import SwiftUI

struct SimplifiedTaskList: View {
    let tasks: [ContextualTask]
    
    // Callbacks for parent view to handle actions
    var onTaskTap: (ContextualTask) -> Void
    var onTaskComplete: (ContextualTask) -> Void
    
    var body: some View {
        if tasks.isEmpty {
            noTasksView
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(tasks) { task in
                        SimplifiedTaskListCard(  // RENAMED from SimplifiedTaskCard
                            task: task,
                            onTap: { onTaskTap(task) },
                            onComplete: { onTaskComplete(task) }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - No Tasks View
    
    private var noTasksView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            Text("All tasks complete!", bundle: .main)
                .font(.title)
                .fontWeight(.bold)
            Text("Great job. You are all caught up for today.", bundle: .main)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Simplified Task List Card (Sub-view) - RENAMED

fileprivate struct SimplifiedTaskListCard: View {  // RENAMED from SimplifiedTaskCard
    let task: ContextualTask
    let onTap: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Urgency Indicator
                Rectangle()
                    .fill(urgencyColor)
                    .frame(width: 8)
                
                // Task Content
                HStack(spacing: 12) {
                    // Task Icon
                    Image(systemName: task.category?.icon ?? "hammer")
                        .font(.title)
                        .foregroundColor(urgencyColor)
                        .frame(width: 40)
                    
                    // Task Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey(task.title))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack {
                            Image(systemName: "building.2")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(LocalizedStringKey(task.buildingName ?? "Unknown Building"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding()
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onComplete) {
                Label("Complete", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
    }
    
    private var urgencyColor: Color {
        switch task.urgency {
        case .critical, .emergency, .urgent:
            return .red
        case .high:
            return .orange
        case .medium:
            return .blue
        case .low:
            return .green
        default:
            return .gray
        }
    }
}


// MARK: - Preview

struct SimplifiedTaskList_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock tasks for the preview
        let mockTasks: [ContextualTask] = [
            .init(id: "1", title: "Limpiar vestíbulo", status: .pending, category: .cleaning, urgency: .high, buildingName: "Rubin Museum"),
            .init(id: "2", title: "Revisar HVAC en el techo", status: .pending, category: .maintenance, urgency: .critical, buildingName: "112 West 18th Street"),
            .init(id: "3", title: "Sacar la basura", status: .pending, category: .sanitation, urgency: .medium, buildingName: "68 Perry Street"),
            .init(id: "4", title: "Inspección de seguridad", status: .pending, category: .security, urgency: .low, buildingName: "131 Perry Street")
        ]
        
        NavigationView {
            SimplifiedTaskList(
                tasks: mockTasks,
                onTaskTap: { task in
                    print("Tapped on task: \(task.title)")
                },
                onTaskComplete: { task in
                    print("Completed task by swiping: \(task.title)")
                }
            )
            .navigationTitle("Mis Tareas") // "My Tasks"
            .preferredColorScheme(.light) // Test in light mode for contrast
        }
    }
}
