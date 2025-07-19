//
//  TaskDetailViewModel.swift
//  FrancoSphere
//
//  ✅ V6.0: ViewModel for the Task Detail view.
//

import Foundation

@MainActor
class TaskDetailViewModel: ObservableObject {
    @Published var buildingName: String = "Loading..."
    private let buildingService = BuildingService.shared

    func loadBuildingName(for buildingId: CoreTypes.BuildingID) async {
        self.buildingName = await buildingService.name(forId: buildingId)
    }

    func completeTask(taskId: CoreTypes.TaskID, evidence: ActionEvidence) async {
        print("✅ Completing task \(taskId)...")
    }
}
