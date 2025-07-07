//
//  MySitesCard.swift
//  FrancoSphere
//
//  ✅ V6.0: This is the single, authoritative definition for MySitesCard.
//

import SwiftUI

struct MySitesCard: View {
    let building: NamedCoordinate

    var body: some View {
        VStack(spacing: 0) {
            // Placeholder for an image
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 80)
                .overlay(Image(systemName: "building.2.fill").foregroundColor(.white))
            
            Text(building.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(8)
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}
