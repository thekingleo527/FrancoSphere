//
//  BuildingFeatureConfiguration.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  BuildingConfigurationManager.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 3.2 - Configuration-Driven Rollout
//  ✅ Allows for enabling intelligence features on a per-building basis.
//  ✅ Manages different configurations for pilot vs. production environments.
//

import Foundation

/// Defines the different feature configurations available for a building.
enum BuildingFeatureConfiguration: String, Codable {
    case standard       // Standard features only
    case pilot          // Standard features + pilot intelligence features
    case production     // All features enabled
}

/// An actor that safely manages the feature configurations for all buildings.
/// This provides a centralized way to control the rollout of new features like
/// the building intelligence dashboards.
actor BuildingConfigurationManager {
    static let shared = BuildingConfigurationManager()

    // The dictionary holds the configuration for each building ID.
    private var buildingConfigurations: [CoreTypes.BuildingID: BuildingFeatureConfiguration] = [:]
    
    // Use UserDefaults for simple persistence of configurations.
    private let persistenceKey = "BuildingFeatureConfigurations"

    private init() {
        Task { await loadConfigurations() }
        print("⚙️ BuildingConfigurationManager initialized with \(buildingConfigurations.count) custom configs.")
    }

    /// Enables a specific feature configuration for a given building.
    func enableIntelligence(for buildingId: CoreTypes.BuildingID, configuration: BuildingFeatureConfiguration) {
        print("🔧 Setting config for building \(buildingId) to: \(configuration.rawValue)")
        buildingConfigurations[buildingId] = configuration
        saveConfigurations()
    }

    /// Retrieves the current feature configuration for a building.
    /// If no specific configuration is set, it defaults to `.standard`.
    func getConfiguration(for buildingId: CoreTypes.BuildingID) -> BuildingFeatureConfiguration {
        return buildingConfigurations[buildingId] ?? .standard
    }
    
    /// A convenience method to set up the initial pilot program.
    /// This would be called from a debug menu or on first launch for testing.
    func enablePilotProgram() {
        print("🚀 Enabling pilot program for select buildings...")
        // As per the plan, enable for Rubin Museum and 136 W 17th Street
        enableIntelligence(for: "14", configuration: .pilot)
        enableIntelligence(for: "7", configuration: .pilot)
    }
    
    /// Enables the full production feature set for all buildings.
    func enableProductionRollout(allBuildingIds: [CoreTypes.BuildingID]) {
        print("🚀 Enabling production rollout for all buildings...")
        for id in allBuildingIds {
            enableIntelligence(for: id, configuration: .production)
        }
    }

    // MARK: - Persistence
    
    private func saveConfigurations() {
        do {
            let data = try JSONEncoder().encode(buildingConfigurations)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("🚨 Failed to save building configurations: \(error)")
        }
    }
    
    private func Task { await loadConfigurations() } {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        do {
            buildingConfigurations = try JSONDecoder().decode([CoreTypes.BuildingID: BuildingFeatureConfiguration].self, from: data)
        } catch {
            print("🚨 Failed to load building configurations: \(error)")
        }
    }
}

// MARK: - Actor Isolation Fix
extension BuildingFeatureConfiguration {
    nonisolated convenience init() {
        self.init()
        Task {
            await self.Task { await loadConfigurations() }
        }
    }
}
