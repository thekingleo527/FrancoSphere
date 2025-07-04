//
///
//  TaskTimelineRow.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Task Timeline Row Component
struct TaskTimelineRow: View {
    let task: ContextualTask
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Timeline indicator
                VStack {
                    Circle()
                        .fill(timelineColor)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(timelineColor.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
                
                // Task content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(task.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(task.startTime) - \(task.endTime)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(task.buildingName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    if task.urgencyLevel != "Normal" {
                        Text(task.urgencyLevel)
                            .font(.caption)
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
}

// MARK: - Preview Provider
struct TaskTimelineRow_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
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
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
