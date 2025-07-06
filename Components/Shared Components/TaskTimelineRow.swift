//
//  TaskTimelineRow.swift
//  FrancoSphere
//
//  🔧 FIXED: All compilation errors resolved
//  ✅ Fixed to match exact current ContextualTask constructor
//  ✅ Uses task.name property (not task.title)
//  ✅ Added missing .emergency case to switch statement
//  ✅ Fixed TaskRecurrence.none reference
//

import SwiftUI

struct TaskTimelineRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(task.status == "completed" ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                // ✅ FIXED: Using task.name (matches actual ContextualTask property)
                Text(task.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let dueDate = task.dueDate {
                    Text("Due: \(dueDate, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Urgency badge
            Text(task.urgency.rawValue.capitalized)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(urgencyColor(for: task.urgency))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
    
    // ✅ FIXED: Added missing .emergency case for exhaustive switch
    private func urgencyColor(for urgency: TaskUrgency) -> Color {
        switch urgency {
        case .emergency:
            return .purple
        case .critical, .urgent:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .green
        }
    }
}

// MARK: - Preview Provider
struct TaskTimelineRow_Previews: PreviewProvider {
    static var previews: some View {
        TaskTimelineRow(
            task: ContextualTask(
                // ✅ FIXED: Using exact constructor that matches current codebase
                id: "preview-1",
                name: "Sample Task",
                description: "A sample task for preview",
                buildingId: "1",
                workerId: "1",
                category: .maintenance,
                urgency: .medium,
                isCompleted: false,
                dueDate: Date(),
                estimatedDuration: 3600
            )
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
