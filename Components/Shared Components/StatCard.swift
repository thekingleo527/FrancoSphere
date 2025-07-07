//
//  StatCard.swift
//  FrancoSphere
//
//  ✅ V6.0: Consolidated, reusable component for displaying dashboard statistics.
//  ✅ Replaces all previous redeclarations to fix build errors.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        StatCard(title: "Active Workers", value: "7", icon: "person.2.fill", color: .green)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
