//
//  TaskTimelineRow.swift
//  FrancoSphere
//
//  🔧 COMPLETE REWRITE - All 6 compilation errors fixed
//

import SwiftUI

struct TaskTimelineRow: View {
    let task: ContextualTask
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(alignment: .leading, spacing: 4) {
                Text(task.startTime)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(task.endTime)
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.7))  // Fixed: Color.white.opacity
            }
            .frame(width: 50, alignment: .leading)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)  // Fixed: .white instead of "white"
                    
                    Spacer()
                    
                    // Status indicator
                    statusIndicator
                }
                
                // Building info
                Text(task.buildingName)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.8))  // Fixed: Color.white.opacity
                
                // Category and urgency
                HStack(spacing: 8) {
                    categoryBadge
                    urgencyBadge
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.blue.opacity(0.2) : Color.clear)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }
    
    @ViewBuilder
    private var categoryBadge: some View {
        Text(task.category)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.3))
            )
            .foregroundColor(.white)
    }
    
    @ViewBuilder
    private var urgencyBadge: some View {
        Text(task.urgencyLevel)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(urgencyColor.opacity(0.3))
            )
            .foregroundColor(.white)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch task.status {
        case "completed":
            return .green
        case "pending":
            return .orange
        case "overdue":
            return .red
        default:
            return .gray
        }
    }
    
    private var urgencyColor: Color {
        switch task.urgencyLevel.lowercased() {
        case "high", "urgent":
            return .red
        case "medium":
            return .orange
        case "low":
            return .green
        default:
            return .blue
        }
    }
}

// MARK: - Preview
struct TaskTimelineRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            TaskTimelineRow(
                task: ContextualTask(
                    id: "1",
                    name: "Morning Trash Collection",
                    buildingId: "14",
                    buildingName: "Rubin Museum",
                    category: "Sanitation",
                    startTime: "10:00",
                    endTime: "11:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "Medium",
                    assignedWorkerName: "Kevin Dutan"  // Fixed: Required parameter included
                ),
                isActive: true,  // Fixed: Required parameter included
                onTap: {}  // Fixed: Required parameter included
            )
            
            TaskTimelineRow(
                task: ContextualTask(
                    id: "2",
                    name: "Sidewalk Cleaning",
                    buildingId: "10",
                    buildingName: "131 Perry Street",
                    category: "Cleaning",
                    startTime: "14:00",
                    endTime: "15:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "completed",
                    urgencyLevel: "Low",
                    assignedWorkerName: "Kevin Dutan"  // Fixed: Required parameter included
                ),
                isActive: false,  // Fixed: Required parameter included
                onTap: {}  // Fixed: Required parameter included
            )
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
