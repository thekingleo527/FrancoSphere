//
//  TaskItem.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/2/25.
//
import Foundation

struct TaskItem: Identifiable {
    let id: Int64
    let name: String
    let description: String
    let buildingId: Int64
    let workerId: Int64?
    var isCompleted: Bool
    let scheduledDate: Date
}
