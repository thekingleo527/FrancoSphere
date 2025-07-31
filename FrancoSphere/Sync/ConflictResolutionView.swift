/
//  ConflictResolutionView.swift
//  FrancoSphere
//
//  Stream A: UI/UX & Spanish
//  Mission: Create the UI for resolving data sync conflicts.
//
//  ✅ PRODUCTION READY: A clear interface for comparing and choosing data versions.
//  ✅ INTEGRATED: Designed to work with the Conflict object from ConflictResolutionService.
//

import SwiftUI

struct ConflictResolutionView: View {
    
    let conflict: Conflict
    var onResolve: (ConflictChoice) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Sync Conflict Detected")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("A change made on another device conflicts with your local changes. Please choose which version to keep.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Comparison View
                HStack(spacing: 16) {
                    VersionCard(
                        title: "Your Version (Local)",
                        update: conflict.localVersion,
                        onSelect: {
                            onResolve(.keepLocal)
                            dismiss()
                        }
                    )
                    
                    VersionCard(
                        title: "Incoming Version (Remote)",
                        update: conflict.remoteVersion,
                        onSelect: {
                            onResolve(.acceptRemote)
                            dismiss()
                        }
                    )
                }
                .padding()
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Resolve Conflict")
                }
            }
        }
    }
}

// MARK: - Version Card Sub-view
fileprivate struct VersionCard: View {
    let title: String
    let update: CoreTypes.DashboardUpdate
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor.opacity(0.2))
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Action", value: update.type.rawValue)
                InfoRow(label: "Worker", value: update.data["workerName"] ?? "N/A")
                InfoRow(label: "Time", value: update.timestamp.formatted(date: .omitted, time: .standard))
                
                // Display changed data
                if !update.data.isEmpty {
                    Divider()
                    Text("Changes:").font(.caption).foregroundColor(.secondary)
                    ForEach(update.data.sorted(by: <), id: \.key) { key, value in
                        InfoRow(label: key.capitalized, value: value)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            Button(action: onSelect) {
                Text("Keep This Version")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    struct InfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
    }
}


// MARK: - Preview
struct ConflictResolutionView_Previews: PreviewProvider {
    static var previews: some View {
        let localUpdate = CoreTypes.DashboardUpdate(source: .worker, type: .taskCompleted, buildingId: "14", workerId: "4", data: ["notes": "Finished cleaning."])
        let remoteUpdate = CoreTypes.DashboardUpdate(source: .admin, type: .taskUpdated, buildingId: "14", workerId: "4", data: ["priority": "high"])
        
        let conflict = Conflict(entityId: "task123", entityType: "task", localVersion: localUpdate, remoteVersion: remoteUpdate)
        
        ConflictResolutionView(conflict: conflict) { choice in
            print("User chose to \(choice)")
        }
    }
}
