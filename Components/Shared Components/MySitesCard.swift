//
//  MySitesCard.swift
//  FrancoSphere
//
//  ✅ V6.0: Consolidated, reusable component for the worker dashboard.
//  ✅ Replaces the private struct previously inside WorkerDashboardView.
//  ✅ Includes enhanced image loading fallbacks.
//

import SwiftUI

struct MySitesCard: View {
    let building: NamedCoordinate
    // In the future, we can pass in live task counts.
    // let taskCount: Int
    // let completedCount: Int

    var body: some View {
        VStack(spacing: 0) {
            // Building Image with Fallbacks
            buildingImageLoader(for: building)
                .frame(height: 80)
                .clipped()

            // Building Name
            VStack {
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 35, alignment: .top) // Ensure consistent height
            }
            .padding(8)
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    /// Enhanced building image loader with multiple fallback strategies
    /// to ensure an image is always displayed.
    @ViewBuilder
    private func buildingImageLoader(for building: NamedCoordinate) -> some View {
        // 1. Try the primary image asset name from the model
        if let primaryImage = UIImage(named: building.imageAssetName) {
            Image(uiImage: primaryImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        // 2. Fallback: Try a sanitized version of the building name
        else if let nameImage = UIImage(named: building.name.sanitizedForImageAsset()) {
            Image(uiImage: nameImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        // 3. Final Fallback: Use a generic system icon
        else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.8))
                )
        }
    }
}

// Helper extension to create a safe name for image assets
fileprivate extension String {
    func sanitizedForImageAsset() -> String {
        self.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
}

struct MySitesCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum of Art",
            latitude: 40.7402,
            longitude: -73.9980,
            imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
        )
        
        MySitesCard(building: sampleBuilding)
            .padding()
            .background(Color.black)
            .previewLayout(.fixed(width: 200, height: 150))
    }
}
