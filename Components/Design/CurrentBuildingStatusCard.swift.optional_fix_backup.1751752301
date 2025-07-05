// UPDATED: Using centralized TypeRegistry for all types
///  CurrentBuildingStatusCard.swift
//  FrancoSphere
//
//  Super minimal version - removes ALL potential type conversion issues
//
import MapKit
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Essential Extensions Only
extension String {
    func toInt64Safe() -> Int64? {
        return Int64(self)
    }
    
    func toIntSafe() -> Int? {
        return Int(self)
    }
}

// MARK: - Current Building Status Card
struct CurrentBuildingStatusCard: View {
    let buildingName: String
    
    var body: some View {
        GlassCard(intensity: .regular) {
            HStack(spacing: 16) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 2)
                        )
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                // Building info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Currently at")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(buildingName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Active since 8:30 AM")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Quick actions
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
            if let image = UIImage(named: building.imageAssetName) {
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
            
            // Building info
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if isClockedIn {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if taskCount > 0 {
                        Text("\(taskCount) tasks")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            if isClockedIn {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isClockedIn ? 0.1 : 0.05))
        )
    }
}

// MARK: - Task Summary Item (Simplified)
struct TaskSummaryItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Minimal Preview (No extensions, no complex types)
struct CurrentBuildingStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        CurrentBuildingStatusCard(buildingName: "Rubin Museum")
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.2, green: 0.1, blue: 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .preferredColorScheme(.dark)
    }
}
