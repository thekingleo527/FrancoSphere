//
//  AssignedBuildingsView.swift
//  FrancoSphere v6.0 - DARK MODE FIXES
//
//  ✅ FIXED: Dark mode empty state styling
//  ✅ FIXED: Proper background colors
//  ✅ ADDED: Better empty state messaging
//

import SwiftUI
// COMPILATION FIX: Add missing imports
import Foundation


struct AssignedBuildingsView: View {
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @Environment(\.dismiss) private var dismiss
    
    var assignedBuildings: [NamedCoordinate] {
        contextAdapter.assignedBuildings
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
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Building image
            buildingImage
            
            // Building info
            VStack(alignment: .leading, spacing: 6) {
                Text(building.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(building.address ?? "No address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    if isPrimaryBuilding {
                        Label("PRIMARY", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    } else {
                        Label("Assigned", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    // Task count
                    let taskCount = contextAdapter.getTasksForBuilding(building.id).count
                    if taskCount > 0 {
                        Text("\(taskCount) tasks")
                            .font(.caption)
                            .foregroundColor(.blue)
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
            if let image = UIImage(named: buildingImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        }
    }
    
    private var isPrimaryBuilding: Bool {
        building.id == contextAdapter.getPrimaryBuilding()?.id
    }
    
    private var buildingImageName: String {
        switch building.id {
        case "1": return "12_West_18th_Street"
        case "3": return "135West17thStreet"
        case "4": return "104_Franklin_Street"
        case "5": return "138West17thStreet"
        case "6": return "68_Perry_Street"
        case "7": return "112_West_18th_Street"
        case "8": return "41_Elizabeth_Street"
        case "9": return "117_West_17th_Street"
        case "10": return "131_Perry_Street"
        case "13": return "136_West_17th_Street"
        case "14": return "Rubin_Museum_142_148_West_17th_Street"
        case "15": return "133_East_15th_Street"
        case "16": return "Stuyvesant_Cove_Park"
        case "17": return "178_Spring_Street"
        case "18": return "36_Walker_Street"
        case "20": return "FrancoSphere_HQ"
        default: return "building_placeholder"
        }
    }
}

struct AssignedBuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        AssignedBuildingsView()
            .preferredColorScheme(.dark)
    }
}
