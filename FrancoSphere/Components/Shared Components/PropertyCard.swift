//
//  PropertyCard.swift
//  FrancoSphere v6.0 - THEME FIXES
//
//  ✅ FIXED: Building image mapping with fallbacks
//  ✅ FIXED: Dark mode compatibility
//  ✅ FIXED: Copy changes from "My Sites" to "Portfolio"
//

import SwiftUI

struct PropertyCard: View {
    let building: NamedCoordinate
    let metrics: BuildingMetrics?
    let mode: PropertyCardMode
    let onTap: () -> Void
    
    enum PropertyCardMode {
        case worker
        case admin
        case client
    }
    
    private let imageSize: CGFloat = 60
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                buildingImage
                buildingContent
                Spacer()
                chevron
            }
            .padding()
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buildingImage: some View {
        Group {
            if let image = UIImage(named: buildingImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .cornerRadius(8)
            } else {
                // Fallback placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: imageSize * 0.4))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        }
    }
    
    private var buildingContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(building.name)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
            
            switch mode {
            case .worker:
                workerContent
            case .admin:
                adminContent
            case .client:
                clientContent
            }
        }
    }
    
    private var workerContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let metrics = metrics {
                HStack {
                    Label("Portfolio", systemImage: "building.2.fill")  // CHANGED FROM "Today's Tasks"
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(metrics.pendingTasks > 0 ? "\(metrics.pendingTasks) remaining" : "All complete")
                        .font(.caption)
                        .foregroundColor(metrics.pendingTasks > 0 ? .blue : .green)
                }
                
                // Progress bar
                ProgressView(value: metrics.completionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .frame(height: 4)
            } else {
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var adminContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let metrics = metrics {
                HStack {
                    Label("Efficiency", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(metrics.efficiency))%")
                        .font(.caption)
                        .foregroundColor(efficiencyColor)
                }
                
                HStack {
                    Label("Workers", systemImage: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(metrics.activeWorkers)")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                if metrics.overdueCount > 0 {
                    HStack {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Text("\(metrics.overdueCount)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            } else {
                Text("Loading metrics...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var clientContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let metrics = metrics {
                HStack {
                    Label("Compliance", systemImage: "checkmark.shield.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(metrics.complianceScore))%")
                        .font(.caption)
                        .foregroundColor(complianceColor)
                }
                
                HStack {
                    Label("Score", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", metrics.overallScore))")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                if metrics.requiresReview {
                    HStack {
                        Label("Review", systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        Text("Required")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            } else {
                Text("Loading compliance...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    // MARK: - Helper Properties
    
    private var buildingImageName: String {
        switch building.id {
        case "1": return "12_West_18th_Street"
        case "2": return "29_East_20th_Street"
        case "3": return "135West17thStreet"
        case "4": return "104_Franklin_Street"
        case "5": return "138West17thStreet"
        case "6": return "68_Perry_Street"
        case "7": return "112_West_18th_Street"
        case "8": return "41_Elizabeth_Street"
        case "9": return "117_West_17th_Street"
        case "10": return "131_Perry_Street"
        case "11": return "123_1st_Avenue"
        case "13": return "136_West_17th_Street"
        case "14": return "Rubin_Museum_142_148_West_17th_Street"
        case "15": return "133_East_15th_Street"
        case "16": return "Stuyvesant_Cove_Park"
        case "17": return "178_Spring_Street"
        case "18": return "36_Walker_Street"
        case "19": return "115_7th_Avenue"
        case "20": return "FrancoSphere_HQ"
        default: 
            print("⚠️ No image found for building ID: \(building.id)")
            return "building_placeholder"
        }
    }
    
    private var progressColor: Color {
        guard let metrics = metrics else { return .gray }
        switch Int(metrics.completionRate * 100) {
        case 80...100: return .green
        case 50...79: return .yellow
        default: return .red
        }
    }
    
    private var efficiencyColor: Color {
        guard let metrics = metrics else { return .gray }
        switch Int(metrics.efficiency) {
        case 90...100: return .green
        case 70...89: return .yellow
        default: return .red
        }
    }
    
    private var complianceColor: Color {
        guard let metrics = metrics else { return .gray }
        switch Int(metrics.complianceScore) {
        case 95...100: return .green
        case 80...94: return .yellow
        default: return .red
        }
    }
}

// MARK: - Preview Provider

struct PropertyCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            PropertyCard(
                building: NamedCoordinate(
                    id: "14",
                    name: "Rubin Museum",
                    latitude: 40.7401,
                    longitude: -73.9978
                ),
                metrics: BuildingMetrics(
                    pendingTasks: 3,
                    completionRate: 0.75,
                    efficiency: 85,
                    activeWorkers: 2,
                    overdueCount: 1,
                    complianceScore: 92,
                    overallScore: 4.2,
                    requiresReview: false
                ),
                mode: .worker,
                onTap: {}
            )
            
            PropertyCard(
                building: NamedCoordinate(
                    id: "1",
                    name: "12 West 18th Street",
                    latitude: 40.7389,
                    longitude: -73.9936
                ),
                metrics: nil,
                mode: .worker,
                onTap: {}
            )
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
