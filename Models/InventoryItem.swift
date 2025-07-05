//
//  InventoryItem.swift
//  FrancoSphere
//
//  Sample inventory data matching new constructor
//

import Foundation

extension InventoryItem {
    static let sampleData: [InventoryItem] = [
        InventoryItem(
            id: "1",
            name: "All-Purpose Cleaner",
            category: .cleaning,
            quantity: 15,
            status: .inStock
        ),
        InventoryItem(
            id: "2",
            name: "Paper Towels",
            category: .cleaning,
            quantity: 3,
            status: .lowStock
        ),
        InventoryItem(
            id: "3",
            name: "Light Bulbs",
            category: .maintenance,
            quantity: 0,
            status: .outOfStock
        ),
        InventoryItem(
            id: "4",
            name: "Printer Paper",
            category: .office,
            quantity: 10,
            status: .inTransit
        ),
        InventoryItem(
            id: "5",
            name: "Safety Vests",
            category: .safety,
            quantity: 8,
            status: .delivered
        ),
        InventoryItem(
            id: "6",
            name: "Screwdriver Set",
            category: .maintenance,
            quantity: 0,
            status: .cancelled
        )
    ]
    
    var statusColor: String {
        switch status {
        case .inStock: return "green"
        case .lowStock: return "orange"
        case .outOfStock: return "red"
        case .ordered: return "blue"
        case .inTransit: return "purple"
        case .delivered: return "green"
        case .cancelled: return "gray"
        }
    }
}
