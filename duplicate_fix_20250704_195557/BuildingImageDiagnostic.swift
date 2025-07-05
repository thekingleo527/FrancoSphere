//
//  BuildingImageDiagnostic.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/2/25.
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Extensions for NamedCoordinate Diagnostics

extension NamedCoordinate {
    // Dummy implementation – update based on your data model if needed
    func getAssignedWorkersFormatted() -> String {
        return "No assigned workers"
    }
    
    // Create a standardized asset name by removing parentheses and replacing special characters with underscores.
    func standardizeAssetName() -> String {
        var processedName = self.name.replacingOccurrences(of: "\\(.*\\)", with: "", options: .regularExpression)
        processedName = processedName.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "'", with: "")
        return processedName
    }
    
    // Create a sanitized asset name by simply replacing spaces, dashes, and punctuation with underscores.
    func sanitizeAssetName() -> String {
        let sanitized = self.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
        return sanitized
    }
}

// MARK: - Main Diagnostic Views

struct BuildingImageDiagnostic: View {
    @State private var buildings: [NamedCoordinate] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            if isLoading {
                VStack {
                    ProgressView()
                        .padding()
                    Text("Loading buildings...")
                }
            } else {
                List {
                    ForEach(buildings) { building in
                        NavigationLink(destination: BuildingImageDetailDiagnostic(building: building)) {
                            HStack {
                                // Use direct UIImage lookup for the asset
                                if let uiImage = UIImage(named: building.imageAssetName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.green, lineWidth: 2))
                                } else {
                                    // Fallback with building initials
                                    ZStack {
                                        Circle()
                                            .fill(Color.red.opacity(0.7))
                                            .frame(width: 50, height: 50)
                                        
                                        Text(String(building.name.prefix(2)))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .overlay(Circle().stroke(Color.red, lineWidth: 2))
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(building.name)
                                        .font(.headline)
                                    
                                    Text("ID: \(building.id)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.leading, 8)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                .navigationTitle("Image Diagnostic")
            }
        }
        .task {
            await loadBuildings()
        }
    }
    
    private func loadBuildings() async {
        buildings = await BuildingService.shared.allBuildings
        isLoading = false
    }
}

struct BuildingImageDetailDiagnostic: View {
    let building: NamedCoordinate
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with building info
                buildingInfoHeader
                
                // Image result section
                imageResultSection
                
                // Diagnostic details section
                diagnosticDetailsSection
                
                // Assigned workers section
                assignedWorkersSection
            }
            .padding()
        }
        .navigationTitle("Building Diagnostic")
    }
    
    private var buildingInfoHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(building.name)
                .font(.title)
                .bold()
            
            Text("ID: \(building.id)")
                .font(.subheadline)
            
            Text("Original Asset Name: \(building.imageAssetName)")
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var imageResultSection: some View {
        VStack(spacing: 16) {
            Text("Image Result")
                .font(.headline)
            
            if let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.green, lineWidth: 2)
                    )
                
                Text("✅ Image loaded successfully")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "building.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .foregroundColor(.gray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red, lineWidth: 2)
                    )
                
                Text("❌ Failed to load image")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var diagnosticDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Diagnostic Details")
                .font(.headline)
            
            // Compute diagnostic results using different naming approaches
            let diagnosticResults: [String: Bool] = [
                "Direct lookup": UIImage(named: building.imageAssetName) != nil,
                "Standardized Name": UIImage(named: building.standardizeAssetName()) != nil,
                "Sanitized Name": UIImage(named: building.sanitizeAssetName()) != nil
            ]
            
            ForEach(diagnosticResults.sorted(by: { $0.key < $1.key }), id: \.key) { pair in
                HStack {
                    Image(systemName: pair.value ? "checkmark.circle.fill" : "x.circle.fill")
                        .foregroundColor(pair.value ? .green : .red)
                    
                    Text(pair.key)
                        .font(.body)
                    
                    Spacer()
                    
                    Text(pair.value ? "Success" : "Failed")
                        .font(.caption)
                        .foregroundColor(pair.value ? .green : .red)
                }
                .padding(.vertical, 8)
            }
            
            // Show generated asset name variations
            assetNameVariations
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var assetNameVariations: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Asset Name Variations:")
                .font(.subheadline)
                .bold()
            
            Text("• Original: \(building.imageAssetName)")
            Text("• Standardized: \(building.standardizeAssetName())")
            Text("• Sanitized: \(building.sanitizeAssetName())")
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var assignedWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assigned Workers")
                .font(.headline)
            
            Text(building.getAssignedWorkersFormatted())
                .font(.body)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
}

struct BuildingImageDiagnostic_Previews: PreviewProvider {
    static var previews: some View {
        BuildingImageDiagnostic()
    }
}
