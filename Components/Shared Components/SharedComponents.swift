// SharedComponents.swift
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––

import SwiftUI

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
