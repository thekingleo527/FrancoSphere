//
//  DataBootstrapper.swift
//  FrancoSphere v6.0
//
//  ✅ SIMPLIFIED: Now just delegates to DatabaseStartupCoordinator
//  ✅ CLEAN: Removed redundant complexity and GRDBManager references
//  ✅ FOCUSED: Single responsibility - check if seeding needed
//  ✅ ORGANIZED: Clear separation of concerns
//  ✅ FIXED: Made runIfNeeded async to avoid Task issues
//

import Foundation

// MARK: - DataBootstrapper (Simplified Coordinator)
enum DataBootstrapper {

    /// Run once per fresh install; guarded by UserDefaults.
    /// Now delegates to DatabaseStartupCoordinator for clean architecture
    /// ✅ FIXED: Made this function async
    static func runIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: "SeedComplete") else {
            print("✅ Seed already completed, skipping DataBootstrapper")
            return
        }
        
        do {
            try await DatabaseStartupCoordinator.shared.initializeDatabase()
            
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: "SeedComplete")
            }
            
            print("✅ Data initialization finished via DataBootstrapper")
        } catch {
            print("🚨 Data initialization failed: \(error)")
        }
    }
    
    /// Legacy compatibility method - now simplified
    static func initializeRealData() async throws {
        try await DatabaseStartupCoordinator.shared.initializeDatabase()
    }
    
    /// Quick health check for development
    static func verifyDataIntegrity() async -> Bool {
        do {
            // Simple check: try to get buildings from the service
            _ = try await BuildingService.shared.getAllBuildings()
            return true
        } catch {
            print("❌ Data integrity check failed: \(error)")
            return false
        }
    }
}
