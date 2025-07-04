//
//  BuildingHeaderGlassOverlay.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


//
//  BuildingHeaderGlassOverlay.swift
//  FrancoSphere
//
//  Glass overlay for building header with image background
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct BuildingHeaderGlassOverlay: View {
    let building: FrancoSphere.NamedCoordinate
    let clockedInStatus: (isClockedIn: Bool, buildingId: Int64?)
    let onClockAction: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Building image background
            buildingImageBackground
            
            // Glass overlay with building info
            VStack(spacing: 0) {
                Spacer()
                
                GlassCard(intensity: .regular) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Main building info row
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(building.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                
                                // FIXED: Replace address with location information using coordinates
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(getFormattedLocation())
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(2)
                                }
                                
                                // Coordinates for technical reference
                                Text("Lat: \(String(format: "%.4f", building.latitude)), Lon: \(String(format: "%.4f", building.longitude))")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                                    .monospaced()
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 12) {
                                // Building status badge
                                buildingStatusBadge
                                
                                // Clock status and action
                                clockStatusSection
                            }
                        }
                        
                        // Building metrics row
                        buildingMetricsRow
                    }
                    .padding(20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 280) // Fixed height for consistent layout
    }
    
    // MARK: - Sub-components
    
    private var buildingImageBackground: some View {
        Group {
            if !building.imageAssetName.isEmpty,
               let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 280)
                    .clipped()
                    .overlay(
                        // Gradient overlay for better text readability
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.4),
                                Color.clear,
                                Color.black.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                // Fallback gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 280)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                )
            }
        }
    }
    
    private var buildingStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            
            Text("Operational")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
    }
    
    private var clockStatusSection: some View {
        VStack(spacing: 8) {
            if isClockedInCurrentBuilding {
                // Clocked in indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("On Site")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(16)
            }
            
            // Clock action button
            Button(action: onClockAction) {
                HStack(spacing: 6) {
                    Image(systemName: isClockedInCurrentBuilding ? "clock.badge.checkmark" : "clock.badge")
                        .font(.caption)
                    
                    Text(isClockedInCurrentBuilding ? "Clock Out" : "Clock In")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var buildingMetricsRow: some View {
        HStack(spacing: 20) {
            buildingMetric(
                icon: "building.2",
                label: "Building ID",
                value: building.id
            )
            
            Divider()
                .frame(height: 30)
                .background(Color.white.opacity(0.3))
            
            buildingMetric(
                icon: "map",
                label: "District",
                value: getDistrict()
            )
            
            Divider()
                .frame(height: 30)
                .background(Color.white.opacity(0.3))
            
            buildingMetric(
                icon: "person.2",
                label: "Type",
                value: getBuildingType()
            )
        }
    }
    
    private func buildingMetric(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var isClockedInCurrentBuilding: Bool {
        clockedInStatus.isClockedIn &&
        clockedInStatus.buildingId == Int64(building.id)
    }
    
    // MARK: - Helper Methods
    
    // FIXED: New helper method to format location information
    private func getFormattedLocation() -> String {
        let district = getDistrict()
        let buildingType = getBuildingType()
        return "\(district) • \(buildingType)"
    }
    
    private func getDistrict() -> String {
        // Determine NYC district based on building name/address
        let name = building.name.lowercased()
        if name.contains("west") || name.contains("17th") || name.contains("18th") {
            return "Chelsea"
        } else if name.contains("east") || name.contains("20th") || name.contains("15th") {
            return "Union Sq"
        } else if name.contains("walker") || name.contains("franklin") || name.contains("elizabeth") {
            return "SoHo"
        } else if name.contains("perry") {
            return "West Village"
        } else if name.contains("1st ave") {
            return "East Village"
        } else if name.contains("stuyvesant") {
            return "Waterfront"
        }
        return "Midtown"
    }
    
    private func getBuildingType() -> String {
        if building.name.contains("Museum") {
            return "Museum"
        } else if building.name.contains("Park") {
            return "Public"
        } else {
            return "Residential"
        }
    }
}

// MARK: - Preview

struct BuildingHeaderGlassOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                BuildingHeaderGlassOverlay(
                    building: FrancoSphere.NamedCoordinate(
                        id: "15",
                        name: "Rubin Museum (142-148 W 17th)",
                        latitude: 40.740370,
                        longitude: -73.998120,
                        imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
                    ),
                    clockedInStatus: (true, 15),
                    onClockAction: {}
                )
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
