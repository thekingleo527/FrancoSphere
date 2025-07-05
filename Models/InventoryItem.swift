//
//  InventoryItem.swift
//  FrancoSphere
//
//  ✅ FIXED: All constructors use correct signatures
//

import Foundation

let sampleInventoryItems: [InventoryItem] = [
    InventoryItem(
        id: "1", 
        name: "All-Purpose Cleaner", 
        category: .cleaning, 
        quantity: 24, 
        unit: "bottles",
        minimumQuantity: 5,
        buildingId: "1",
        location: "Storage Room A",
        restockStatus: .inStock
    ),
    InventoryItem(
        id: "2",
        name: "Paper Towels", 
        category: .cleaning, 
        quantity: 3, 
        unit: "cases",
        minimumQuantity: 5,
        buildingId: "1", 
        location: "Storage Room A",
        restockStatus: .lowStock
    ),
    InventoryItem(
        id: "3",
        name: "Office Supplies", 
        category: .office, 
        quantity: 15, 
        unit: "sets",
        minimumQuantity: 3,
        buildingId: "2",
        location: "Office Storage",
        restockStatus: .inTransit
    ),
    InventoryItem(
        id: "4",
        name: "Light Bulbs", 
        category: .electrical, 
        quantity: 48, 
        unit: "pieces",
        minimumQuantity: 10,
        buildingId: "2",
        location: "Electrical Room",
        restockStatus: .delivered
    ),
    InventoryItem(
        id: "5",
        name: "Tools & Equipment", 
        category: .tools, 
        quantity: 0, 
        unit: "sets",
        minimumQuantity: 1,
        buildingId: "3",
        location: "Tool Storage",
        restockStatus: .cancelled
    )
]
