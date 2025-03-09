import Foundation
import SwiftUI

// MARK: - Extensions to FrancoSphere Inventory Models

// NOTE: These extensions are no longer needed since the properties
// have been moved into the main FrancoSphereModels.swift file.
// Keeping factory methods only.

extension FrancoSphere.InventoryItem {
    // Sample factory methods only - other properties are now in the main struct
    static func sample(buildingID: String) -> FrancoSphere.InventoryItem {
        return FrancoSphere.InventoryItem(
            id: UUID().uuidString,
            name: "Sample Item",
            buildingID: buildingID,
            category: .other,
            quantity: 10,
            unit: "pieces",
            minimumQuantity: 5,
            needsReorder: false,
            lastRestockDate: Date(),
            location: "Storage Room",
            notes: "Sample item for testing"
        )
    }
    
    static func commonInventoryItems(for buildingID: String) -> [FrancoSphere.InventoryItem] {
        return [
            FrancoSphere.InventoryItem(
                id: UUID().uuidString,
                name: "All-Purpose Cleaner",
                buildingID: buildingID,
                category: .cleaning,
                quantity: 12,
                unit: "bottles",
                minimumQuantity: 5,
                needsReorder: false,
                lastRestockDate: Date(),
                location: "Janitor Closet",
                notes: "For general cleaning tasks"
            ),
            FrancoSphere.InventoryItem(
                id: UUID().uuidString,
                name: "Light Bulbs (LED)",
                buildingID: buildingID,
                category: .electrical,
                quantity: 30,
                unit: "pieces",
                minimumQuantity: 15,
                needsReorder: false,
                lastRestockDate: Date(),
                location: "Maintenance Room",
                notes: "12W LED bulbs for common areas"
            ),
            // Add other items as needed...
        ]
    }
}

// Add color property to RestockStatus if it's not in the main model
extension FrancoSphere.RestockStatus {
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .blue
        case .fulfilled: return .green
        case .rejected: return .red
        }
    }
}
