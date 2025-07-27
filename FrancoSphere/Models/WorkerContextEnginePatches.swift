//
//  WorkerContextEnginePatches.swift
//  FrancoSphere
//

import Foundation

extension WorkerContextEngine {
    var currentWorkerProfile: WorkerProfile? {
        guard let worker = currentWorker else { return nil }
        
        // FIX: Use correct WorkerProfile properties and constructor
        return WorkerProfile(
            id: worker.id,           // FIX: Use 'id' instead of 'workerId'
            name: worker.name,       // FIX: Use 'name' instead of 'workerName'
            email: worker.email,
            phoneNumber: worker.phoneNumber,
            role: worker.role,       // FIX: Already a UserRole, no conversion needed
            skills: worker.skills,
            certifications: worker.certifications,  // FIX: Added required parameter
            hireDate: worker.hireDate,             // FIX: Added required parameter
            isActive: worker.isActive,
            profileImageUrl: worker.profileImageUrl
        )
    }
    
    func getAssignedBuildings(_ workerId: String? = nil) -> [NamedCoordinate] {
        return assignedBuildings
    }
    
    func setAssignedBuildings(_ buildings: [NamedCoordinate]) {
        self.objectWillChange.send()
        self.assignedBuildings = buildings
    }
}

// FIX: Remove the User extension if workerId already exists
// If you need to add a computed property, use a different name
extension User {
    // Only add this if User doesn't already have a workerId property
    // and you need this specific computed property
    var workerIdentifier: String {
        return id
    }
}
