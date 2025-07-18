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
                if let imageAssetName = building.imageAssetName,
                   let image = UIImage(named: imageAssetName) {
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
                            Image(systemName: "building.2")
                                .foregroundColor(.gray)
                                .font(.title2)
                        )
                }
                
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
}
