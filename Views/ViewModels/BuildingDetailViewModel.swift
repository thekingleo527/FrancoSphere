//
//  BuildingDetailViewModel.swift
//  FrancoSphere
//
//  Fixed constructor calls for BuildingStatistics and BuildingInsight
//

import Foundation
import SwiftUI

class BuildingDetailViewModel: ObservableObject {
    @Published var buildingStats: BuildingStatistics = BuildingStatistics(completionRate: 85.0, totalTasks: 20, completedTasks: 17)
    
    @Published var insights: [BuildingInsight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let building: NamedCoordinate
    
    init(building: NamedCoordinate) {
        self.building = building
        loadBuildingData()
    }
    
    private func loadBuildingData() {
        isLoading = true
        errorMessage = nil
        
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.buildingStats = BuildingStatistics(completionRate: 85.0, totalTasks: 20, completedTasks: 17)
            
            self.insights = [
                BuildingInsight(
                    id: "1",
                    title: "High Efficiency",
                    description: "Building maintenance is performing well",
                    priority: 1
                ),
                BuildingInsight(
                    id: "2", 
                    title: "Scheduled Maintenance",
                    description: "HVAC system due for quarterly check",
                    priority: 2
            ]
            
            self.isLoading = false
        }
    }
    
    func refreshData() {
        loadBuildingData()
    }
}
