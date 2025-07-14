//
//  CurrentBuildingStatusCard.swift
//  FrancoSphere
//
//  ✅ FIXED: imageAssetName property reference corrected
//  ✅ Real building data integration maintained
//

import SwiftUI

struct CurrentBuildingStatusCard: View {
    let building: NamedCoordinate
    let isClockedIn: Bool
    let taskCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Building image with fallback
            buildingImage
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Building info
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(building.fullAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    clockInStatus
                    
                    if taskCount > 0 {
                        Text("\(taskCount) tasks")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "list.bullet")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Button(action: {}) {
                    Image(systemName: "camera")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var buildingImage: some View {
        Group {
            // ✅ FIXED: Use fallbackImageName instead of direct imageAssetName access
            if let imageName = building.imageAssetName,
               let image = UIImage(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                // Use fallback
                if let fallbackImage = UIImage(named: building.fallbackImageName) {
                    Image(uiImage: fallbackImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "building.2")
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }
    
    private var clockInStatus: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isClockedIn ? .green : .gray)
                .frame(width: 8, height: 8)
            
            Text(isClockedIn ? "Clocked In" : "Not Clocked In")
                .font(.caption)
                .foregroundColor(isClockedIn ? .green : .secondary)
        }
    }
}

// MARK: - Worker Building Row (Simplified)
struct WorkerBuildingRow: View {
    let building: NamedCoordinate
    let isClockedIn: Bool
    let taskCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Building image or icon
            if let imageAssetName = building.imageAssetName,
               let image = UIImage(named: imageAssetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "building.2")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.headline)
                
                Text(isClockedIn ? "Clocked In" : "Available")
                    .font(.caption)
                    .foregroundColor(isClockedIn ? .green : .secondary)
                
                if taskCount > 0 {
                    Text("\(taskCount) pending tasks")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CurrentBuildingStatusCard(
        building: NamedCoordinate.allBuildings.first!,
        isClockedIn: true,
        taskCount: 3
    )
    .padding()
    .background(Color.black)
}
