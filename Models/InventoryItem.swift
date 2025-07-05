//
//  InventoryItem.swift
//  FrancoSphere
//
//  Sample inventory data with fixed constructor
//

import Foundation

extension InventoryItem {
    static let sampleData: [InventoryItem] = [
        InventoryItem(
            id: "1",
            name: "All-Purpose Cleaner",
            category: .cleaning,
            quantity: 15,
            status: .inStock,
            minimumStock: 5
        ),
        InventoryItem(
            id: "2",
            name: "Paper Towels",
            category: .cleaning,
            quantity: 3,
            status: .lowStock,
            minimumStock: 10
        ),
        InventoryItem(
            id: "3",
            name: "Light Bulbs",
            category: .maintenance,
            quantity: 0,
            status: .outOfStock,
            minimumStock: 5
        ),
        InventoryItem(
            id: "4",
            name: "Printer Paper",
            category: .office,
            quantity: 10,
            status: .inTransit,
            minimumStock: 8
        ),
        InventoryItem(
            id: "5",
            name: "Safety Vests",
            category: .safety,
            quantity: 8,
            status: .delivered,
            minimumStock: 3
        ),
        InventoryItem(
            id: "6",
            name: "Screwdriver Set",
            category: .maintenance,
            quantity: 0,
            status: .cancelled,
            minimumStock: 2
        )
    ]
}
