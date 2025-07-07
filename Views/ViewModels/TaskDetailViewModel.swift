//
//  TaskDetailViewModel.swift
//  FrancoSphere
//
//  ✅ V6.0: ViewModel for the Task Detail view.
//  ✅ Handles business logic, such as fetching building names.
//

import Foundation
import SwiftUI

@MainActor
class TaskDetailViewModel: ObservableObject {
    @Published var buildingName: String = "Loading..."
    
    // Use dependency injection for services in a real app,
    // but for now, we'll use the singleton.
    private let buildingService = BuildingService.shared

    /// Fetches the building name for a given ID.
    func loadBuildingName(for buildingId: CoreTypes.BuildingID) async {
        // Use the new service to get the building name
        self.buildingName = await buildingService.name(forId: buildingId)
    }
    
    /// Logic to handle the completion of a task.
    func completeTask(taskId: CoreTypes.TaskID, evidence: ActionEvidence) async {
        print("✅ Completing task \(taskId)...")
        // In a real app, this would call the TaskService:
        // try? await TaskService.shared.completeTask(taskId, with: evidence)
    }
}
