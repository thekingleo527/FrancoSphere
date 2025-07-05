//
//  AssetImageDebugger.swift
//  FrancoSphere
//
//  🔧 COMPILATION FIXED - Corrected buildings data source
//  ✅ Fixed: TaskService.shared.allBuildings → NamedCoordinate.allBuildings
//  ✅ Removed unnecessary async calls since allBuildings is static
//  ✅ All functionality preserved and enhanced
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)


// --------------------------------------------------------------------
//  Fixed type alias to match BuildingRepository return type
// --------------------------------------------------------------------
typealias DebugBuilding = NamedCoordinate   // This matches what BuildingRepository returns

/// Utility for verifying that every building points at a valid image
/// asset and for listing the contents of the Assets catalogue.
final class AssetImageDebugger {

    static let shared = AssetImageDebugger()
    private init() {}

    // MARK: – Console diagnostics
    func debugAllBuildingImages() {
        // ✅ FIX: Use NamedCoordinate.allBuildings (static property)
        let buildings = NamedCoordinate.allBuildings

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
        
        // 3️⃣ Check if this is a special case (Kevin's Rubin Museum)
        if building.id == "14" && building.name.contains("Rubin") {
            print("   • ✅ KEVIN ASSIGNMENT: Rubin Museum correctly assigned")
        }
        
        // 4️⃣ Check for deprecated Franklin Street assignment
        if building.name.contains("104 Franklin") {
            print("   • ⚠️  DEPRECATED: 104 Franklin Street should not be used (Kevin now works at Rubin Museum)")
        }
        
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
        // **Updated asset candidates including Kevin's corrected assignment**
        let candidates = [
            "12_West_18th_Street",
            "29_31_East_20th_Street",
            "36_Walker_Street",
            "41_Elizabeth_Street",
            "68_Perry_Street",
            "104_Franklin_Street",              // ⚠️ DEPRECATED (Kevin no longer works here)
            "112_West_18th_Street",
            "117_West_17th_Street",
            "123_1st_Avenue",
            "131_Perry_Street",
            "133_East_15th_Street",
            "135-139_W_17th_Street",
            "136_West_17th_Street",
            "138_West_17th_Street",
            "rubin_museum",                     // ✅ CORRECTED: Kevin's actual workplace
            "Rubin_Museum_17th_Street",         // Alternative naming
            "Rubin_Museum_142_148_West_17th_Street", // Full address variant
            "Stuyvesant_Cove_Park",
            
            // Additional building assets that might exist
            "178_Spring_Street",
            "west17_135",
            "west17_136",
            "west17_138",
            "perry_131",
            "perry_68",
            "east20_29",
            "spring_178"
        ]

        return candidates.filter { UIImage(named: $0) != nil }
    }
    
    // MARK: - Enhanced Debugging for Kevin Assignment
    func debugKevinAssignment() {
        print("🔍 KEVIN ASSIGNMENT VALIDATION:")
        print("===============================")
        
        let buildings = NamedCoordinate.allBuildings
        
        // Check for Rubin Museum
        let rubinMuseum = buildings.first { $0.id == "14" && $0.name.contains("Rubin") }
        if let rubin = rubinMuseum {
            print("✅ Kevin's Rubin Museum found:")
            print("   • ID: \(rubin.id)")
            print("   • Name: \(rubin.name)")
            print("   • Asset: \(rubin.imageAssetName)")
            print("   • Image exists: \(UIImage(named: rubin.imageAssetName) != nil ? "✅" : "❌")")
        } else {
            print("❌ Kevin's Rubin Museum NOT FOUND!")
        }
        
        // Check for deprecated Franklin Street
        let franklinStreet = buildings.first { $0.name.contains("104 Franklin") }
        if let franklin = franklinStreet {
            print("⚠️  DEPRECATED Franklin Street still exists:")
            print("   • ID: \(franklin.id)")
            print("   • Name: \(franklin.name)")
            print("   • This should be removed from Kevin's assignments")
        } else {
            print("✅ No deprecated Franklin Street assignments found")
        }
        
        print("===============================")
    }
    
    // MARK: - Building Statistics
    func getBuildingImageStatistics() -> (total: Int, found: Int, missing: Int, foundPercentage: Double) {
        let buildings = NamedCoordinate.allBuildings
        let total = buildings.count
        let found = buildings.filter { UIImage(named: $0.imageAssetName) != nil }.count
        let missing = total - found
        let percentage = total > 0 ? (Double(found) / Double(total)) * 100 : 0
        
        return (total: total, found: found, missing: missing, foundPercentage: percentage)
    }
    
    // MARK: - Synchronous Helper for Legacy Code
    func debugAllBuildingImagesSync() {
        // ✅ FIX: No longer async since we're using static data
        debugAllBuildingImages()
    }
}

// MARK: – SwiftUI helper view
/// A simple UI wrapper so you can eyeball which images resolve correctly.
struct AssetDebuggerView: View {

    @State private var buildingImages: [(building: DebugBuilding, image: UIImage?)] = []
    @State private var isLoading = true
    @State private var statistics: (total: Int, found: Int, missing: Int, foundPercentage: Double) = (0, 0, 0, 0)
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
                                        
                                        // ✅ Special indicators for Kevin's assignments
                                        if item.building.id == "14" && item.building.name.contains("Rubin") {
                                            Text("✅ KEVIN'S WORKPLACE")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                                .fontWeight(.bold)
                                        }
                                        
                                        if item.building.name.contains("104 Franklin") {
                                            Text("⚠️ DEPRECATED FOR KEVIN")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                                .fontWeight(.bold)
                                        }
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
                                AssetImageDebugger.shared.debugAllBuildingImages()
                                AssetImageDebugger.shared.debugAllAssetNames()
                            }
                            
                            Button("Validate Kevin Assignment") {
                                AssetImageDebugger.shared.debugKevinAssignment()
                            }
                            
                            Button("Reload Building Images") {
                                loadBuildingImages()
                            }
                        }
                        
                        Section("Statistics") {
                            HStack {
                                Text("Total Buildings:")
                                Spacer()
                                Text("\(statistics.total)")
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Images Found:")
                                Spacer()
                                Text("\(statistics.found)")
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Missing Images:")
                                Spacer()
                                Text("\(statistics.missing)")
                                    .foregroundColor(.red)
                            }
                            
                            HStack {
                                Text("Success Rate:")
                                Spacer()
                                Text("\(String(format: "%.1f", statistics.foundPercentage))%")
                                    .foregroundColor(statistics.foundPercentage > 75 ? .green : .orange)
                            }
                            
                            HStack {
                                Text("Kevin Assignment:")
                                Spacer()
                                let hasRubin = buildingImages.contains {
                                    $0.building.id == "14" && $0.building.name.contains("Rubin")
                                }
                                Text(hasRubin ? "✅ Rubin Museum" : "❌ Not Found")
                                    .foregroundColor(hasRubin ? .green : .red)
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
            .onAppear {
                loadBuildingImages()
            }
        }
    }

    private func loadBuildingImages() {
        isLoading = true
        
        // ✅ FIX: Use static buildings data (no async needed)
        let buildings = NamedCoordinate.allBuildings
        let images = buildings.map { ($0, UIImage(named: $0.imageAssetName)) }
        
        self.buildingImages = images
        self.statistics = AssetImageDebugger.shared.getBuildingImageStatistics()
        self.isLoading = false
    }
}

// MARK: - Legacy Compatibility Extension
extension AssetImageDebugger {
    /// For calling from non-async contexts
    func debugSync() {
        // ✅ FIX: No longer needs Task since methods are synchronous
        self.debugAllBuildingImages()
        self.debugAllAssetNames()
        self.debugKevinAssignment()
    }
}

struct AssetDebuggerView_Previews: PreviewProvider {
    static var previews: some View { AssetDebuggerView() }
}

// MARK: - Quick Access Functions for Console Debugging

extension AssetImageDebugger {
    /// Quick console validation of all systems
    func validateEverything() {
        print("\n🚀 FRANCOSPHERE ASSET VALIDATION")
        print("=================================")
        
        debugAllBuildingImages()
        print("\n")
        debugKevinAssignment()
        print("\n")
        debugAllAssetNames()
        
        let stats = getBuildingImageStatistics()
        print("\n📊 FINAL STATISTICS:")
        print("====================")
        print("Total Buildings: \(stats.total)")
        print("Images Found: \(stats.found)")
        print("Missing Images: \(stats.missing)")
        print("Success Rate: \(String(format: "%.1f", stats.foundPercentage))%")
        print("=================================\n")
    }
}
