//
//  CoreTypes.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//

import Foundation

// MARK: - TaskUrgency Extension
extension CoreTypes.TaskUrgency {
    var numericValue: Int {
        switch self {
        case .critical: return 4
        case .urgent: return 3
        case .normal: return 2
        case .low: return 1
        }
    }
}
