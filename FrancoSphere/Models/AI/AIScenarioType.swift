import Foundation
import SwiftUI

public enum AIScenarioType: String, Codable, CaseIterable {
    case taskOptimization = "Task Optimization"
    case routePlanning = "Route Planning"
    case emergencyResponse = "Emergency Response"
    case compliance = "Compliance"
    case maintenance = "Maintenance"
    
    public var icon: String {
        switch self {
        case .taskOptimization: return "checkmark.circle"
        case .routePlanning: return "map"
        case .emergencyResponse: return "exclamationmark.triangle"
        case .compliance: return "doc.text"
        case .maintenance: return "wrench"
        }
    }
    
    public var displayTitle: String { rawValue }
}
