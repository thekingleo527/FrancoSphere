//
//  PropertyCard.swift
//  FrancoSphere
//
//  ✅ UNIFIED BUILDING COMPONENT
//  ✅ Multi-dashboard support (Worker, Admin, Client)
//  ✅ Real-time metrics from BuildingMetricsService
//  ✅ Actor-compatible async data loading
//

import SwiftUI

struct PropertyCard: View {
    let building: NamedCoordinate
    let displayMode: DisplayMode
    let onTap: (() -> Void)?
    
    @State private var metrics: BuildingMetrics?
    @State private var isLoadingMetrics = false
    
    enum DisplayMode {
        case dashboard   // Worker view
        case admin      // Admin view
        case client     // Client view
        case minimal    // List view
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Building header
                HStack {
                    Image(buildingImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageSize, height: imageSize)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.headline)
                            .lineLimit(2)
                        
                        if displayMode != .minimal {
                            Text(building.address ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if isLoadingMetrics {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                // Mode-specific content
                if displayMode != .minimal {
                    Group {
                        switch displayMode {
                        case .dashboard:
                            workerContent
                        case .admin:
                            adminContent
                        case .client:
                            clientContent
                        case .minimal:
                            EmptyView()
                        }
                    }
                    .opacity(metrics != nil ? 1.0 : 0.3)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .task {
            await loadMetrics()
        }
    }
    
    // MARK: - Real Building Asset Mapping
    
    private var buildingImageName: String {
        switch building.id {
        case "1": return "12_West_18th_Street"
        case "4": return "41_Elizabeth_Street"
        case "5", "6": return "68_Perry_Street"
        case "7": return "136_West_17th_Street"
        case "8": return "138West17thStreet"
        case "9": return "135West17thStreet"
        case "10": return "131_Perry_Street"
        case "13": return "104_Franklin_Street"
        case "14": return "Rubin_Museum_142_148_West_17th_Street"
        case "16": return "Stuyvesant_Cove_Park"
        default: return "building_placeholder"
        }
    }
    
    private var imageSize: CGFloat {
        switch displayMode {
        case .minimal: return 40
        case .dashboard: return 60
        case .admin, .client: return 56
        }
    }
    
    // MARK: - Content Views
    
    private var workerContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let metrics = metrics {
                HStack {
                    Label("Today's Tasks", systemImage: "checklist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(metrics.pendingTasks > 0 ? "\(metrics.pendingTasks) remaining" : "All complete")
                        .font(.caption)
                        .foregroundColor(metrics.pendingTasks > 0 ? .blue : .green)
                }
                
                ProgressView(value: metrics.completionRate)
                    .tint(metrics.completionRate > 0.8 ? .green : .orange)
                
                if metrics.hasWorkerOnSite {
                    HStack {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("On Site").font(.caption).foregroundColor(.green)
                        Spacer()
                        Text("Active").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var adminContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let metrics = metrics {
                HStack {
                    Text("Efficiency: \(Int(metrics.completionRate * 100))%")
                        .font(.caption)
                    Spacer()
                    Text("\(metrics.activeWorkers) workers")
                        .font(.caption)
                }
                
                if metrics.overdueTasks > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("\(metrics.overdueTasks) overdue")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
                
                ProgressView(value: metrics.completionRate)
                    .tint(metrics.completionRate > 0.8 ? .green : .orange)
            }
        }
    }
    
    private var clientContent: some View {
        HStack {
            if let metrics = metrics {
                Image(systemName: metrics.isCompliant ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundColor(metrics.isCompliant ? .green : .orange)
                Text(metrics.isCompliant ? "Compliant" : "Needs Review")
                    .font(.caption)
                Spacer()
                Text("Score: \(metrics.overallScore)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(scoreColor(metrics.overallScore))
            }
        }
    }
    
    // MARK: - Real-Time Metrics Loading
    
    private func loadMetrics() async {
        isLoadingMetrics = true
        
        do {
            metrics = try await BuildingMetricsService.shared.calculateMetrics(for: building.id)
        } catch {
            print("❌ Failed to load metrics for building \(building.id): \(error)")
            // Set default metrics on error
            metrics = BuildingMetrics(
                completionRate: 0.0,
                pendingTasks: 0,
                overdueTasks: 0,
                activeWorkers: 0,
                isCompliant: false,
                overallScore: 0,
                hasWorkerOnSite: false
            )
        }
        
        isLoadingMetrics = false
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 70...89: return .blue
        case 50...69: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview
struct PropertyCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            latitude: 40.7402,
            longitude: -73.9980
        )
        
        VStack(spacing: 16) {
            PropertyCard(building: sampleBuilding, displayMode: .dashboard) {
                print("Dashboard card tapped")
            }
            
            PropertyCard(building: sampleBuilding, displayMode: .admin) {
                print("Admin card tapped")
            }
            
            PropertyCard(building: sampleBuilding, displayMode: .client) {
                print("Client card tapped")
            }
        }
        .padding()
    }
}
