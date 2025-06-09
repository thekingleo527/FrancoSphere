//
//  AssetImageDebugger.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/2/25.
//

import SwiftUI
import Foundation

// --------------------------------------------------------------------
//  Fixed type alias to match BuildingRepository return type
// --------------------------------------------------------------------
typealias DebugBuilding = FrancoSphere.NamedCoordinate   // This matches what BuildingRepository returns

/// Utility for verifying that every building points at a valid image
/// asset and for listing the contents of the Assets catalogue.
final class AssetImageDebugger {

    static let shared = AssetImageDebugger()
    private init() {}

    // MARK: – Console diagnostics
    func debugAllBuildingImages() async {
        let buildings = await BuildingRepository.shared.allBuildings

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

    private func debugBuildingImage(_ building: DebugBuilding) {
        print("🏢 Building: \(building.name) (ID: \(building.id))")

        // 1️⃣ imageAssetName specified on the model
        let assetName     = building.imageAssetName
        let assetExists   = UIImage(named: assetName) != nil
        print("   • imageAssetName: \"\(assetName)\"  →  \(assetExists ? "✅ found" : "❌ missing")")

        // 2️⃣ A "standardised" fallback asset name
        let standardName  = building.name
                            .replacingOccurrences(of: "[\\s,()\\-]", with: "_",
                                                  options: .regularExpression)
        let standardExist = UIImage(named: standardName) != nil
        print("   • Standard name : \"\(standardName)\"  →  \(standardExist ? "✅ found" : "❌ missing")")
        print("")
    }

    // MARK: – Asset-catalogue listing
    func debugAllAssetNames() {
        let assets = listAllAssetNames()

        print("📁 ASSETS CATALOG CONTENTS:")
        print("===========================")
        print("Number of assets: \(assets.count)")
        print("===========================")

        for asset in assets.sorted() { print("   • \(asset)") }

        print("===========================")
    }

    private func listAllAssetNames() -> [String] {
        // **Only** the names you care about.  Add / remove as necessary.
        let candidates = [
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

        return candidates.filter { UIImage(named: $0) != nil }
    }
    
    // MARK: - Synchronous Helper for Legacy Code
    func debugAllBuildingImagesSync() {
        Task {
            await debugAllBuildingImages()
        }
    }
}

// MARK: – SwiftUI helper view
/// A simple UI wrapper so you can eyeball which images resolve correctly.
struct AssetDebuggerView: View {

    @State private var buildingImages: [(building: DebugBuilding, image: UIImage?)] = []
    @State private var isLoading = true
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading buildings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("Building Assets") {
                            ForEach(buildingImages, id: \.building.id) { item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.building.name).font(.headline)
                                        Text("ID: \(item.building.id)")
                                            .font(.caption).foregroundColor(.secondary)
                                        Text("Asset: \(item.building.imageAssetName)")
                                            .font(.caption2).foregroundColor(.blue)
                                    }

                                    Spacer()

                                    if let image = item.image {
                                        Image(uiImage: image)
                                            .resizable().scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.green, lineWidth: 2))
                                    } else {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 24)).foregroundColor(.red)
                                    }
                                }
                            }
                        }

                        Section("Debug Actions") {
                            Button("Print Diagnostics to Console") {
                                Task {
                                    await AssetImageDebugger.shared.debugAllBuildingImages()
                                    AssetImageDebugger.shared.debugAllAssetNames()
                                }
                            }
                            
                            Button("Reload Building Images") {
                                Task {
                                    await loadBuildingImages()
                                }
                            }
                        }
                        
                        Section("Statistics") {
                            HStack {
                                Text("Total Buildings:")
                                Spacer()
                                Text("\(buildingImages.count)")
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Images Found:")
                                Spacer()
                                Text("\(buildingImages.filter { $0.image != nil }.count)")
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Missing Images:")
                                Spacer()
                                Text("\(buildingImages.filter { $0.image == nil }.count)")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Asset Debugger")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .task {
                await loadBuildingImages()
            }
        }
    }

    private func loadBuildingImages() async {
        isLoading = true
        let buildings = await BuildingRepository.shared.allBuildings
        let images = buildings.map { ($0, UIImage(named: $0.imageAssetName)) }
        
        await MainActor.run {
            self.buildingImages = images
            self.isLoading = false
        }
    }
}

// MARK: - Legacy Compatibility Extension
extension AssetImageDebugger {
    /// For calling from non-async contexts
    func debugSync() {
        Task.detached {
            await self.debugAllBuildingImages()
            await MainActor.run {
                self.debugAllAssetNames()
            }
        }
    }
}

struct AssetDebuggerView_Previews: PreviewProvider {
    static var previews: some View { AssetDebuggerView() }
}
