//
//  AssignedBuildingsView.swift
//  FrancoSphere v6.0 - DARK MODE FIXES
//
//  ✅ FIXED: Dark mode empty state styling
//  ✅ FIXED: Proper background colors
//  ✅ ADDED: Better empty state messaging
//  ✅ FIXED: Compilation errors (address property, getPrimaryBuilding)
//  ✅ UPDATED: Uses WorkerContextEngine directly
//  ✅ INTEGRATED: Uses BuildingConstants for image mapping
//

import SwiftUI
import Foundation

struct AssignedBuildingsView: View {
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    var assignedBuildings: [NamedCoordinate] {
        contextEngine.assignedBuildings
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                Group {
                    if assignedBuildings.isEmpty {
                        emptyState
                    } else {
                        buildingsList
                    }
                }
            }
            .navigationTitle("My Buildings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Buildings Assigned")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Contact your supervisor to get building assignments")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Contact Supervisor") {
                // Handle contact supervisor action
                if let url = URL(string: "mailto:shawn@francomanagementgroup.com?subject=Building%20Assignment%20Request") {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private var buildingsList: some View {
        List {
            ForEach(assignedBuildings, id: \.id) { building in
                AssignedBuildingRow(building: building)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
        .scrollContentBackground(.hidden)
    }
}

struct AssignedBuildingRow: View {
    let building: NamedCoordinate
    @StateObject private var contextEngine = WorkerContextEngine.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Building image
            buildingImage
            
            // Building info
            VStack(alignment: .leading, spacing: 6) {
                Text(building.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(building.fullAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    if isCurrentBuilding {
                        Label("CURRENT", systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if isPrimaryAssignment {
                        Label("PRIMARY", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    } else {
                        Label("Assigned", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Task count
                    let taskCount = contextEngine.getTasksForBuilding(building.id).count
                    if taskCount > 0 {
                        Text("\(taskCount) tasks")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .background(Color.black)
    }
    
    private var buildingImage: some View {
        Group {
            if let assetName = building.imageAssetName,
               let image = UIImage(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(building.buildingTypeColor.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: building.buildingIcon)
                            .font(.system(size: 20))
                            .foregroundColor(building.buildingTypeColor)
                    )
            }
        }
    }
    
    private var isCurrentBuilding: Bool {
        // Check if this is the building the worker is currently clocked into
        return contextEngine.clockInStatus.isClockedIn &&
               contextEngine.clockInStatus.building?.id == building.id
    }
    
    private var isPrimaryAssignment: Bool {
        // Check if this is the first assigned building (primary)
        return contextEngine.assignedBuildings.first?.id == building.id
    }
}

// MARK: - Preview
struct AssignedBuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        AssignedBuildingsView()
            .preferredColorScheme(.dark)
    }
}
