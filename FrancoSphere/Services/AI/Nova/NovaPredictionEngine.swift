//
//  NovaPredictionEngine.swift
//  FrancoSphere v6.0
//
//  ✅ NEW: Connects aggregation and prompt generation
//  ✅ REAL DATA: Feeds Nova with GRDB-backed insights
//

import Foundation

/// High level interface combining data aggregation and prompt generation.
actor NovaPredictionEngine {
    static let shared = NovaPredictionEngine()

    private let aggregator = NovaDataAggregator.shared
    private let promptEngine = NovaPromptEngine.shared

    private init() {}

    /// Produce a portfolio summary prompt for Nova
    func portfolioPrediction() async throws -> String {
        let data = try await aggregator.aggregatePortfolioData()
        return promptEngine.generatePortfolioPrompt(from: data)
    }

    /// Produce a building summary prompt for Nova
    func buildingPrediction(for buildingId: CoreTypes.BuildingID) async throws -> String {
        let data = try await aggregator.aggregateBuildingData(for: buildingId)
        return promptEngine.generateBuildingPrompt(for: buildingId, data: data)
    }
}

