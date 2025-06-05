// SharedComponents.swift
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––

import SwiftUI

/// Re‐usable colors palette
enum FrancoSphereColors {
    static let deepNavy      = Color(red: 0.10, green: 0.15, blue: 0.30)
    static let accentBlue    = Color.blue
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 0.9)
    static let cardBackground = Color.black.opacity(0.7)
}

/// Example status chip usage:
struct BuildingStatusChip: View {
    let status: BuildingStatus       // ← This now resolves, because we imported FrancoSphereModels.swift

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(status.color)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}
