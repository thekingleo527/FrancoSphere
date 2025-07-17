//
//  WorkerDashboardViewModel+Fixed.swift
//  FrancoSphere v6.0 - FIXED: Uses corrected WorkerContextEngine
//

import Foundation

extension WorkerDashboardViewModel {
    
    /// FIXED: Load data using corrected WorkerContextEngine
    func loadInitialDataFixed() async {
        guard let user = await authManager.getCurrentUser() else {
            await MainActor.run {
                errorMessage = "Not authenticated"
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Use the FIXED WorkerContextEngine that connects to OperationalDataManager
            try await contextEngine.loadContext(for: user.workerId)
            
            // Get data from fixed context engine
            let assignedBuildings = await contextEngine.getAssignedBuildings()
            let todaysTasks = await contextEngine.getTodaysTasks()
            let taskProgress = await contextEngine.getTaskProgress()
            let isClockedIn = await contextEngine.isWorkerClockedIn()
            let currentBuilding = await contextEngine.getCurrentBuilding()
            
            await MainActor.run {
                self.assignedBuildings = assignedBuildings
                self.todaysTasks = todaysTasks
                self.taskProgress = taskProgress
                self.isClockedIn = isClockedIn
                self.currentBuilding = currentBuilding
                self.errorMessage = nil
            }
            
            print("✅ FIXED worker dashboard loaded:")
            print("   Buildings: \(assignedBuildings.count)")
            print("   Tasks: \(todaysTasks.count)")
            print("   Progress: \(taskProgress?.formattedProgress ?? "0/0")")
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            print("❌ Fixed dashboard loading failed: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    /// FIXED: Clock in using corrected engine
    func clockInFixed(at building: NamedCoordinate) async {
        do {
            try await contextEngine.clockIn(at: building)
            
            await MainActor.run {
                self.isClockedIn = true
                self.currentBuilding = building
                self.errorMessage = nil
            }
            
            // Refresh data to get updated tasks
            await loadInitialDataFixed()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Clock-in failed: \(error.localizedDescription)"
            }
        }
    }
}
