//
//  AssetImageDebugger.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/2/25.
//

import SwiftUI
import Foundation

// This file helps diagnose image loading issues without using BuildingImageHelper.

class AssetImageDebugger {
    static let shared = AssetImageDebugger()
    
    func debugAllBuildingImages() {
        let buildings = BuildingRepository.shared.buildings
        
        print("🏢 DIAGNOSING BUILDING IMAGES:")
        print("==============================")
        print("Number of buildings: \(buildings.count)")
        print("==============================")
        
        for building in buildings {
            debugBuildingImage(building)
        }
        
        print("==============================")
        print("Diagnosis complete")
        print("==============================")
    }
    
    func debugBuildingImage(_ building: NamedCoordinate) {
        print("🏢 Building: \(building.name) (ID: \(building.id))")
        
        // Check imageAssetName property
        let assetName = building.imageAssetName
        let exists = UIImage(named: assetName) != nil
        print("   - imageAssetName: \"\(assetName)\" (Exists: \(exists ? "✅" : "❌"))")
        
        // Try standard format: replace spaces, dashes, parentheses, and commas with underscores or remove them
        let standardName = building.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ",", with: "")
        let standardExists = UIImage(named: standardName) != nil
        print("   - Standard format: \"\(standardName)\" (Exists: \(standardExists ? "✅" : "❌"))")
        
        print("")
    }
    
    func debugAllAssetNames() {
        let assets = listAllAssetNames()
        
        print("📁 ASSETS CATALOG CONTENTS:")
        print("===========================")
        print("Number of assets: \(assets.count)")
        print("===========================")
        
        for assetName in assets.sorted() {
            print("   - \(assetName)")
        }
        
        print("===========================")
    }
    
    private func listAllAssetNames() -> [String] {
        // Known asset names to test against.
        let knownAssets = [
            "12_West_18th_Street",
            "29_31_East_20th_Street",
            "36_Walker_Street",
            "41_Elizabeth_Street",
            "68_Perry_Street",
            "104_Franklin_Street",
            "112_West_18th_Street",
            "117_West_17th_Street",
            "123_1st_Avenue",
            "131_Perry_Street",
            "133_East_15th_Street",
            "135-139_W_17th_Street",
            "136_West_17th_Street",
            "138_West_17th_Street",
            "Rubin_Museum_17th_Street",
            "Stuyvesant_Cove_Park"
        ]
        
        return knownAssets.filter { UIImage(named: $0) != nil }
    }
}

// MARK: - View for Debugging Assets

struct AssetDebuggerView: View {
    @State private var buildingImages: [(building: NamedCoordinate, image: UIImage?)] = []
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Building Assets")) {
                    ForEach(buildingImages, id: \.building.id) { item in
                        HStack {
                            // Building name and ID
                            VStack(alignment: .leading) {
                                Text(item.building.name)
                                    .font(.headline)
                                Text("ID: \(item.building.id)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Display the image if available, otherwise show an error icon
                            if let image = item.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.green, lineWidth: 2))
                            } else {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                                    .font(.system(size: 24))
                            }
                        }
                    }
                }
                
                Section(header: Text("Debug Actions")) {
                    Button("Print Debug Info to Console") {
                        AssetImageDebugger.shared.debugAllBuildingImages()
                        AssetImageDebugger.shared.debugAllAssetNames()
                    }
                }
            }
            .navigationTitle("Asset Debugger")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                loadBuildingImages()
            }
        }
    }
    
    private func loadBuildingImages() {
        let buildings = BuildingRepository.shared.buildings
        buildingImages = buildings.map { building in
            (building, UIImage(named: building.imageAssetName))
        }
    }
}

struct AssetDebuggerView_Previews: PreviewProvider {
    static var previews: some View {
        AssetDebuggerView()
    }
}
