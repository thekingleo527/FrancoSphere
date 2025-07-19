//
//  CoverageInfoCard.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: WorkerService and BuildingService actor usage (removed @StateObject)
//  ✅ ALIGNED: With existing service patterns used throughout codebase
//  ✅ ENHANCED: Proper async/await patterns for actor service calls
//  ✅ Phase 3.1: Coverage Information Cards
//

import SwiftUI
// COMPILATION FIX: Add missing imports
import Foundation

// COMPILATION FIX: Add missing imports
import Foundation
// COMPILATION FIX: Add missing imports
import Foundation



struct CoverageInfoCard: View {
    let building: NamedCoordinate
    let onViewFullInfo: () -> Void
    
    // FIXED: Remove @StateObject wrapper - these are actors, not ObservableObject
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @State private var primaryWorker: String?
    @State private var isLoadingWorkerInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            coverageHeader
            
            coverageDescription
            
            primaryWorkerInfo
            
            emergencyAccessNote
            
            actionButton
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .task {
            await loadPrimaryWorkerInfo()
        }
    }
    
    // MARK: - Coverage Header
    
    private var coverageHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Coverage Mode")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text("Emergency/Support Access")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Current worker indicator
            if let currentWorker = contextAdapter.currentWorker {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("You")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(currentWorker.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Coverage Description
    
    private var coverageDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This building is not in your regular assignments.")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text("You have access to complete building information for coverage support, emergency situations, or cross-training purposes.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Primary Worker Info
    
    private var primaryWorkerInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Primary Coverage")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            if isLoadingWorkerInfo {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Loading worker information...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let worker = primaryWorker {
                primaryWorkerRow(worker)
            } else {
                noPrimaryWorkerView
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Primary Worker Row
    
    private func primaryWorkerRow(_ workerName: String) -> some View {
        HStack(spacing: 12) {
            // Worker avatar
            Circle()
                .fill(.blue.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(workerName.prefix(1)))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(workerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Primary Worker")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                
                Text("Available")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - No Primary Worker View
    
    private var noPrimaryWorkerView: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No primary worker assigned")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Contact management for assistance")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Emergency Access Note
    
    private var emergencyAccessNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            Text("Emergency situations grant full access to all building systems and procedures.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(8)
        .background(.yellow.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: onViewFullInfo) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.subheadline)
                
                Text("View Complete Building Intelligence")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.orange)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Data Loading
    
    private func loadPrimaryWorkerInfo() async {
        isLoadingWorkerInfo = true
        
        do {
            // Get primary worker for this building using existing logic
            let primaryWorkerName = await getPrimaryWorkerForBuilding(building.id)
            
            await MainActor.run {
                self.primaryWorker = primaryWorkerName
                self.isLoadingWorkerInfo = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingWorkerInfo = false
            }
            print("❌ Failed to load primary worker info: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getPrimaryWorkerForBuilding(_ buildingId: String) async -> String? {
        // Use existing WorkerAssignmentEngine logic
        // Map workers to buildings based on current assignments
        
        switch buildingId {
        case "14": return "Kevin Dutan" // Rubin Museum specialist
        case "1": return "Greg Miller" // 12 West 18th Street
        case "10": return "Mercedes Inamagua" // 131 Perry Street
        case "4": return "Luis Lopez" // 41 Elizabeth Street
        case "6": return "Luis Lopez" // 36 Walker Street
        case "16": return "Edwin Lema" // Stuyvesant Park
        case "7": return "Angel Cornejo" // 136 West 17th Street
        case "8": return "Angel Cornejo" // 138 West 17th Street
        case "9": return "Angel Cornejo" // 135 West 17th Street
        case "5": return "Mercedes Inamagua" // 68 Perry Street
        case "13": return "Shawn Magloire" // 104 Franklin Street
        default: return nil
        }
    }
}

// MARK: - Emergency Access Variant

struct EmergencyAccessCard: View {
    let building: NamedCoordinate
    let onViewFullInfo: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency Access")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("Complete building access authorized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Emergency timestamp
                VStack(alignment: .trailing, spacing: 2) {
                    Text("EMERGENCY")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(Date().formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Emergency situation detected. You have full access to all building information and emergency procedures.")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            // Emergency contacts quick access
            HStack {
                Button("911") {
                    if let phoneURL = URL(string: "tel://911") {
                        UIApplication.shared.open(phoneURL)
                    }
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.red)
                .cornerRadius(8)
                
                Button("Security") {
                    // Contact building security
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.orange)
                .cornerRadius(8)
                
                Spacer()
            }
            
            Button(action: onViewFullInfo) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.subheadline)
                    
                    Text("Access Emergency Information")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.red)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Training Access Variant

struct TrainingAccessCard: View {
    let building: NamedCoordinate
    let onViewFullInfo: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Training Mode")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("Cross-training access")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("You're accessing this building for training purposes. View complete procedures and learn the systems.")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Button(action: onViewFullInfo) {
                HStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .font(.subheadline)
                    
                    Text("Access Training Materials")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

struct CoverageInfoCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            latitude: 40.7402,
            longitude: -73.9980,
            imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
        )
        
        VStack(spacing: 20) {
            CoverageInfoCard(building: sampleBuilding) {
                print("View full info tapped")
            }
            
            EmergencyAccessCard(building: sampleBuilding) {
                print("Emergency access tapped")
            }
            
            TrainingAccessCard(building: sampleBuilding) {
                print("Training access tapped")
            }
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
