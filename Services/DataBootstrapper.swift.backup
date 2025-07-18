//
//  DataBootstrapper.swift
//  FrancoSphere v6.0
//
//  ✅ SIMPLIFIED: Now just delegates to DatabaseStartupCoordinator
//  ✅ CLEAN: Removed redundant complexity and SQLiteManager references
//  ✅ FOCUSED: Single responsibility - check if seeding needed
//  ✅ ORGANIZED: Clear separation of concerns
//

import Foundation

// MARK: - DataBootstrapper (Simplified Coordinator)
enum DataBootstrapper {

    /// Run once per fresh install; guarded by UserDefaults.
    /// Now delegates to DatabaseStartupCoordinator for clean architecture
    static func runIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "SeedComplete") else {
            print("✅ Seed already completed, skipping DataBootstrapper")
            return
        }
        
        Task.detached {
            do {
                // Delegate to the clean startup coordinator
                try await DatabaseStartupCoordinator.shared.ensureDataIntegrity()
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "SeedComplete")
                }
                print("✅ Data initialization finished via DataBootstrapper")
            } catch {
                print("🚨 Data initialization failed: \(error)")
            }
        }
    }
    
    /// Legacy compatibility method - now simplified
    static func initializeRealData() async throws {
        try await DatabaseStartupCoordinator.shared.ensureDataIntegrity()
    }
    
    /// Quick health check for development
    static func verifyDataIntegrity() async -> Bool {
        return await DatabaseStartupCoordinator.shared.quickHealthCheck()
    }
}
