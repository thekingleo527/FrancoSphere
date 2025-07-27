//
//  WorkerContextEnginePatches.swift
//  FrancoSphere
//

import Foundation

extension WorkerContextEngine {
    var currentWorkerProfile: WorkerProfile? {
        guard let worker = currentWorker else { return nil }
        return WorkerProfile(
            id: worker.workerId,
            name: worker.workerName,
            email: worker.email,
            phoneNumber: "",
            role: UserRole(rawValue: worker.role) ?? .worker,
            hourlyRate: 25.0,
            skills: [],
            isActive: true
        )
    }
    
    func getAssignedBuildings(_ workerId: String? = nil) -> [NamedCoordinate] {
        return assignedBuildings
    }
    
    func setAssignedBuildings(_ buildings: [NamedCoordinate]) {
        self.objectWillChange.send()
    }
}

extension User {
    var workerId: String {
        return id
    }
}
