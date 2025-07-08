import Foundation
import Combine

@MainActor
class BuildingMetricsService: ObservableObject {
    static let shared = BuildingMetricsService()
    
    @Published var buildingMetrics: [String: BuildingMetrics] = [:]
    @Published var isLoading = false
    
    private let buildingService = BuildingService.shared
    
    private init() {}
    
    func getMetrics(for buildingId: String) async -> BuildingMetrics? {
        guard let analytics = try? await buildingService.getBuildingAnalytics(buildingId) else {
            return nil
        }
        
        let metrics = BuildingMetrics.calculate(from: analytics)
        buildingMetrics[buildingId] = metrics
        return metrics
    }
}
