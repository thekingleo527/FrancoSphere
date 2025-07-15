//
//  NovaPromptEngine.swift
//  FrancoSphere v6.0
//
//  ✅ NEW: Prompt generation for Nova models
//  ✅ UTILIZES: Aggregated GRDB data
//

import Foundation

/// Generates text prompts from aggregated Nova data.
actor NovaPromptEngine {
    static let shared = NovaPromptEngine()

    private init() {}

    /// Create a portfolio level prompt
    func generatePortfolioPrompt(from data: NovaAggregatedData) -> String {
        "Portfolio has \(data.buildingCount) buildings, \(data.workerCount) active workers and \(data.taskCount) tasks today."
    }

    /// Create a building specific prompt
    func generateBuildingPrompt(for buildingId: CoreTypes.BuildingID, data: NovaAggregatedData) -> String {
        "Building \(buildingId) has \(data.workerCount) active workers and \(data.taskCount) tasks scheduled."
    }
}

