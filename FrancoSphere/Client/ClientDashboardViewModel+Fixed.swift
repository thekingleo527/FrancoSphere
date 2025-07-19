//
//  ClientDashboardViewModel+Fixed.swift
//  FrancoSphere v6.0
//
//  Minimal extension - only helper methods that work
//

import Foundation
import SwiftUI
import Combine

extension ClientDashboardViewModel {
    
    // Simple helper methods only
    func portfolioHealthSummary() -> String {
        guard let intelligence = portfolioIntelligence else {
            return "Portfolio data unavailable"
        }
        
        let health = intelligence.portfolioHealth
        switch health {
        case 0.9...: return "Excellent"
        case 0.8..<0.9: return "Good"
        case 0.7..<0.8: return "Fair"
        case 0.6..<0.7: return "Needs Attention"
        default: return "Critical"
        }
    }
    
    func criticalInsightsCount() -> Int {
        intelligenceInsights.filter { $0.priority == .critical }.count
    }
}
