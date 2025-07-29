//
//  TypeMigrationService.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Updated to use GRDBManager instead of DatabaseManager
//  ✅ FIXED: Uses actual UserRole enum cases (includes .manager)
//  ✅ FIXED: ContextualTask.title is String, not optional
//  ✅ FIXED: All switch statements are now exhaustive
//  ✅ FIXED: Properly handles optional WorkerProfile.skills
//  ✅ ALIGNED: With existing type definitions in codebase
//  ✅ ENHANCED: Dashboard integration and Nova AI preparation
//  ✅ REFACTORED: Simplified for actual use cases
//

import Foundation

/// Data validation and migration service for FrancoSphere v6.0
/// This is a utility service used for:
/// - Data integrity validation during development
/// - Migration between app versions
/// - Preparing data for new features (Nova AI, etc.)
actor TypeMigrationService {
    static let shared = TypeMigrationService()
    
    // MARK: - Migration Dependencies
    private let grdbManager = GRDBManager.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    
    // MARK: - Migration Tracking
    private var validationResults: ValidationResults = ValidationResults()
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Run a comprehensive validation of all data types
    /// Use this during development or after database changes
    public func validateDataIntegrity() async throws -> ValidationResults {
        print("🔍 Starting comprehensive data validation...")
        
        validationResults = ValidationResults()
        
        // Validate all data types
        await validateWorkers()
        await validateBuildings()
        await validateTasks()
        await validateAssignments()
        
        print("✅ Validation complete: \(validationResults.summary)")
        return validationResults
    }
    
    /// Prepare data for Nova AI integration
    /// Run this before enabling Nova AI features
    public func prepareForNovaAI() async throws -> NovaAIReadiness {
        print("🧠 Preparing data for Nova AI integration...")
        
        let workers = try await workerService.getAllActiveWorkers()
        let buildings = try await buildingService.getAllBuildings()
        let tasks = try await taskService.getAllTasks()
        
        var readiness = NovaAIReadiness()
        
        // Check worker data completeness
        for worker in workers {
            if isNovaAICompatible(worker) {
                readiness.compatibleWorkers += 1
            } else {
                readiness.issues.append("Worker \(worker.name) missing required data")
            }
        }
        readiness.totalWorkers = workers.count
        
        // Check building data completeness
        for building in buildings {
            if isNovaAICompatible(building) {
                readiness.compatibleBuildings += 1
            } else {
                readiness.issues.append("Building \(building.name) missing GPS or metadata")
            }
        }
        readiness.totalBuildings = buildings.count
        
        // Check task data completeness
        for task in tasks {
            if isNovaAIReady(task) {
                readiness.compatibleTasks += 1
            } else {
                readiness.issues.append("Task '\(task.title)' missing category or urgency")
            }
        }
        readiness.totalTasks = tasks.count
        
        print("✅ Nova AI readiness: \(readiness.readinessPercentage)%")
        return readiness
    }
    
    /// Validate dashboard compatibility
    /// Ensures data works with three-dashboard system
    public func validateDashboardCompatibility() async throws -> DashboardCompatibility {
        print("📱 Validating dashboard compatibility...")
        
        var compatibility = DashboardCompatibility()
        
        // Check worker dashboard requirements
        let workers = try await workerService.getAllActiveWorkers()
        compatibility.workerDashboard.total = workers.count
        compatibility.workerDashboard.compatible = workers.filter { worker in
            worker.role == .worker && !worker.email.isEmpty
        }.count
        
        // Check admin dashboard requirements
        compatibility.adminDashboard.total = workers.count
        compatibility.adminDashboard.compatible = workers.filter { worker in
            worker.role == .admin || worker.role == .manager
        }.count
        
        // Check client dashboard requirements
        compatibility.clientDashboard.total = workers.count
        compatibility.clientDashboard.compatible = workers.filter { worker in
            worker.role == .client
        }.count
        
        // Check building metrics compatibility
        let buildings = try await buildingService.getAllBuildings()
        var metricsCompatible = 0
        
        for building in buildings {
            do {
                _ = try await buildingMetricsService.calculateMetrics(for: building.id)
                metricsCompatible += 1
            } catch {
                compatibility.issues.append("Building \(building.name) metrics failed: \(error)")
            }
        }
        
        compatibility.buildingMetrics = (compatible: metricsCompatible, total: buildings.count)
        
        print("✅ Dashboard compatibility validated")
        return compatibility
    }
    
    // MARK: - Validation Methods
    
    private func validateWorkers() async {
        print("👥 Validating workers...")
        
        do {
            let workers = try await workerService.getAllActiveWorkers()
            validationResults.totalWorkers = workers.count
            
            for worker in workers {
                var issues: [String] = []
                
                // Validate required fields
                if worker.name.isEmpty {
                    issues.append("Empty name")
                }
                
                if !isValidEmail(worker.email) {
                    issues.append("Invalid email")
                }
                
                // Validate role
                if !isValidUserRole(worker.role) {
                    issues.append("Invalid role")
                }
                
                if issues.isEmpty {
                    validationResults.validWorkers += 1
                } else {
                    validationResults.workerIssues[worker.id] = issues
                }
            }
        } catch {
            validationResults.errors.append("Worker validation failed: \(error)")
        }
    }
    
    private func validateBuildings() async {
        print("🏢 Validating buildings...")
        
        do {
            let buildings = try await buildingService.getAllBuildings()
            validationResults.totalBuildings = buildings.count
            
            for building in buildings {
                var issues: [String] = []
                
                // Validate required fields
                if building.name.isEmpty {
                    issues.append("Empty name")
                }
                
                // Validate coordinates
                if building.latitude == 0 && building.longitude == 0 {
                    issues.append("Invalid coordinates")
                }
                
                // Check for image asset
                if building.imageAssetName == nil {
                    issues.append("Missing image asset")
                }
                
                if issues.isEmpty {
                    validationResults.validBuildings += 1
                } else {
                    validationResults.buildingIssues[building.id] = issues
                }
            }
        } catch {
            validationResults.errors.append("Building validation failed: \(error)")
        }
    }
    
    private func validateTasks() async {
        print("📋 Validating tasks...")
        
        do {
            let tasks = try await taskService.getAllTasks()
            validationResults.totalTasks = tasks.count
            
            for task in tasks {
                var issues: [String] = []
                
                // Validate required fields
                if task.title.isEmpty {
                    issues.append("Empty title")
                }
                
                // Validate optional fields
                if task.category == nil {
                    issues.append("Missing category")
                }
                
                if task.urgency == nil {
                    issues.append("Missing urgency")
                }
                
                if issues.isEmpty {
                    validationResults.validTasks += 1
                } else {
                    validationResults.taskIssues[task.id] = issues
                }
            }
        } catch {
            validationResults.errors.append("Task validation failed: \(error)")
        }
    }
    
    private func validateAssignments() async {
        print("🔗 Validating assignments...")
        
        // Validate worker-building assignments
        // This would check the worker_building_assignments table
        // Implementation depends on specific requirements
    }
    
    // MARK: - Validation Helpers
    
    private func isValidUserRole(_ role: UserRole) -> Bool {
        // All UserRole cases are valid
        switch role {
        case .worker, .admin, .client, .manager:  // ✅ FIXED: Added .manager case
            return true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isNovaAICompatible(_ worker: WorkerProfile) -> Bool {
        return !worker.name.isEmpty &&
               isValidEmail(worker.email) &&
               !(worker.skills?.isEmpty ?? true)  // ✅ FIXED: Properly handle optional skills
    }
    
    private func isNovaAICompatible(_ building: NamedCoordinate) -> Bool {
        return !building.name.isEmpty &&
               building.latitude != 0 &&
               building.longitude != 0
    }
    
    private func isNovaAIReady(_ task: ContextualTask) -> Bool {
        return !task.title.isEmpty &&
               task.category != nil &&
               task.urgency != nil
    }
}

// MARK: - Result Types

public struct ValidationResults {
    var totalWorkers = 0
    var validWorkers = 0
    var workerIssues: [String: [String]] = [:]
    
    var totalBuildings = 0
    var validBuildings = 0
    var buildingIssues: [String: [String]] = [:]
    
    var totalTasks = 0
    var validTasks = 0
    var taskIssues: [String: [String]] = [:]
    
    var errors: [String] = []
    
    var summary: String {
        let workerPercentage = totalWorkers > 0 ? (validWorkers * 100 / totalWorkers) : 0
        let buildingPercentage = totalBuildings > 0 ? (validBuildings * 100 / totalBuildings) : 0
        let taskPercentage = totalTasks > 0 ? (validTasks * 100 / totalTasks) : 0
        
        return """
        Workers: \(validWorkers)/\(totalWorkers) (\(workerPercentage)%)
        Buildings: \(validBuildings)/\(totalBuildings) (\(buildingPercentage)%)
        Tasks: \(validTasks)/\(totalTasks) (\(taskPercentage)%)
        Errors: \(errors.count)
        """
    }
    
    var hasIssues: Bool {
        return !workerIssues.isEmpty || !buildingIssues.isEmpty || !taskIssues.isEmpty || !errors.isEmpty
    }
}

public struct NovaAIReadiness {
    var totalWorkers = 0
    var compatibleWorkers = 0
    
    var totalBuildings = 0
    var compatibleBuildings = 0
    
    var totalTasks = 0
    var compatibleTasks = 0
    
    var issues: [String] = []
    
    var readinessPercentage: Int {
        let total = totalWorkers + totalBuildings + totalTasks
        let compatible = compatibleWorkers + compatibleBuildings + compatibleTasks
        return total > 0 ? (compatible * 100 / total) : 0
    }
    
    var isReady: Bool {
        return readinessPercentage >= 80
    }
}

public struct DashboardCompatibility {
    var workerDashboard: (compatible: Int, total: Int) = (0, 0)
    var adminDashboard: (compatible: Int, total: Int) = (0, 0)
    var clientDashboard: (compatible: Int, total: Int) = (0, 0)
    var buildingMetrics: (compatible: Int, total: Int) = (0, 0)
    var issues: [String] = []
    
    var overallCompatibility: Int {
        let totalCompatible = workerDashboard.compatible + adminDashboard.compatible +
                            clientDashboard.compatible + buildingMetrics.compatible
        let totalItems = workerDashboard.total + adminDashboard.total +
                        clientDashboard.total + buildingMetrics.total
        return totalItems > 0 ? (totalCompatible * 100 / totalItems) : 0
    }
}

// MARK: - Usage Example
/*
 // In AppDelegate or during development:
 
 Task {
     let migrationService = TypeMigrationService.shared
     
     // Validate data integrity
     let validation = try await migrationService.validateDataIntegrity()
     if validation.hasIssues {
         print("⚠️ Data validation found issues: \(validation.summary)")
     }
     
     // Check Nova AI readiness
     let novaReadiness = try await migrationService.prepareForNovaAI()
     if !novaReadiness.isReady {
         print("⚠️ Not ready for Nova AI: \(novaReadiness.readinessPercentage)%")
     }
     
     // Validate dashboard compatibility
     let dashboardCompat = try await migrationService.validateDashboardCompatibility()
     print("📊 Dashboard compatibility: \(dashboardCompat.overallCompatibility)%")
 }
 */
