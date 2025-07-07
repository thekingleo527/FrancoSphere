//
//  QBConnectionStatus.swift
//  FrancoSphere
//
//  ✅ V6.0: This is the single, authoritative definition for the QuickBooks connection status.
//

import Foundation
import SwiftUI

public enum QBConnectionStatus: Equatable {
    case connected, disconnected, error
    
    public var icon: String {
        switch self {
        case .connected: return "checkmark.circle.fill"
        case .disconnected: return "xmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .connected: return .green
        case .disconnected: return .gray
        case .error: return .red
        }
    }
    
    public var displayText: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }
}
