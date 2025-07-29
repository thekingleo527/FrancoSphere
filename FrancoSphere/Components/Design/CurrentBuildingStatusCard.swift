//
//  CurrentBuildingStatusCard.swift
//  FrancoSphere
//
//  ✅ FIXED: Works with NamedCoordinate structure (no imageAssetName)
//  ✅ ALIGNED: Uses building ID/name to determine image
//

import SwiftUI

struct CurrentBuildingStatusCard: View {
    let building: NamedCoordinate
    let isClockedIn: Bool
    let taskCount: Int
    let completedTasks: Int
    let pendingTasks: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with building info
            HStack {
                // Building image or icon
                buildingImage
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: isClockedIn ? "checkmark.circle.fill" : "clock")
                            .foregroundColor(isClockedIn ? .green : .orange)
                        Text(isClockedIn ? "Clocked In" : "Not Clocked In")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Task statistics
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("\(taskCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("\(completedTasks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("\(pendingTasks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Building Image
    
    @ViewBuilder
    private var buildingImage: some View {
        let imageName = getBuildingImageName()
        
        if let image = UIImage(named: imageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: getBuildingIcon())
                        .foregroundColor(.gray)
                        .font(.title2)
                )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Determine the image asset name based on building ID or name
    private func getBuildingImageName() -> String {
        // Map building IDs to their image assets
        switch building.id {
        case "14", "15":
            return "Rubin_Museum_142_148_West_17th_Street"
        case "1":
            return "building_12w18"
        case "2":
            return "building_29e20"
        case "3":
            return "building_133e15"
        case "4":
            return "building_104franklin"
        case "5":
            return "building_36walker"
        case "6":
            return "building_68perry"
        case "7":
            return "building_136w17"
        case "8":
            return "building_41elizabeth"
        case "9":
            return "building_117w17"
        case "10":
            return "building_123first"
        case "11":
            return "building_131perry"
        case "12":
            return "building_135w17"
        case "13":
            return "building_138w17"
        case "16":
            return "stuyvesant_park"
        default:
            // Try to create a name from the building name
            let cleanName = building.name
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "-", with: "_")
            return cleanName
        }
    }
    
    /// Get appropriate icon based on building type
    private func getBuildingIcon() -> String {
        let name = building.name.lowercased()
        
        if name.contains("museum") {
            return "building.columns"
        } else if name.contains("park") {
            return "leaf"
        } else if name.contains("perry") || name.contains("walker") {
            return "house"
        } else {
            return "building.2"
        }
    }
}

// MARK: - Preview

struct CurrentBuildingStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            CurrentBuildingStatusCard(
                building: NamedCoordinate(
                    id: "14",
                    name: "Rubin Museum",
                    address: "150 W 17th St, New York, NY 10011",
                    latitude: 40.7402,
                    longitude: -73.9980
                ),
                isClockedIn: true,
                taskCount: 12,
                completedTasks: 8,
                pendingTasks: 4
            )
            
            CurrentBuildingStatusCard(
                building: NamedCoordinate(
                    id: "1",
                    name: "12 West 18th Street",
                    address: "12 W 18th St, New York, NY 10011",
                    latitude: 40.7397,
                    longitude: -73.9944
                ),
                isClockedIn: false,
                taskCount: 6,
                completedTasks: 2,
                pendingTasks: 4
            )
        }
        .padding()
        .background(Color(.systemGray5))
    }
}
