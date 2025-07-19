//
//  TaskTimelineRow.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved for ACTUAL ContextualTask structure
//  ✅ Uses task.title property (from FrancoSphereModels.swift)
//  ✅ Fixed constructor to match actual ContextualTask init
//  ✅ Handles optional urgency properly
//  ✅ Uses isCompleted boolean instead of status string
//

import SwiftUI

// Type aliases for CoreTypes
typealias MaintenanceTask = CoreTypes.MaintenanceTask
typealias TaskCategory = CoreTypes.TaskCategory
typealias TaskUrgency = CoreTypes.TaskUrgency
typealias BuildingType = CoreTypes.BuildingType
typealias BuildingTab = CoreTypes.BuildingTab
typealias WeatherCondition = CoreTypes.WeatherCondition
typealias BuildingMetrics = CoreTypes.BuildingMetrics
typealias TaskProgress = CoreTypes.TaskProgress
typealias FrancoWorkerAssignment = CoreTypes.FrancoWorkerAssignment
typealias InventoryItem = CoreTypes.InventoryItem
typealias InventoryCategory = CoreTypes.InventoryCategory
typealias RestockStatus = CoreTypes.RestockStatus
typealias ComplianceStatus = CoreTypes.ComplianceStatus
typealias BuildingStatistics = CoreTypes.BuildingStatistics
typealias WorkerSkill = CoreTypes.WorkerSkill
typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
typealias ComplianceIssue = CoreTypes.ComplianceIssue


struct TaskTimelineRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(task.isCompleted ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                // ✅ FIXED: Using task.title (actual property from FrancoSphereModels)
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // ✅ FIXED: Safe unwrapping of optional description
                Text(task.description ?? "No description")
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
            
            // Urgency badge with safe handling of optional urgency
            if let urgency = task.urgency {
                Text(urgency.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(urgencyColor(for: urgency))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else {
                Text("Medium")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
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
                // ✅ FIXED: Using actual ContextualTask constructor from FrancoSphereModels.swift
                id: "preview-1",
                title: "Sample Task",                    // ✅ Correct parameter name
                description: "A sample task for preview",
                isCompleted: false,
                completedDate: nil,
                scheduledDate: Date(),
                dueDate: Date(),
                category: .maintenance,
                urgency: .medium,
                building: NamedCoordinate(              // ✅ Use NamedCoordinate object
                    id: "1",
                    name: "Sample Building",
                    latitude: 40.7128,
                    longitude: -74.0060
                ),
                worker: WorkerProfile(                  // ✅ Use WorkerProfile object
                    id: "1",
                    name: "Sample Worker",
                    email: "worker@test.com",
                    phoneNumber: "555-0123",
                    role: .worker,
                    skills: [],
                    certifications: [],
                    hireDate: Date()
                )
            )
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
