//
//  WorkerConstants.swift
//  FrancoSphere v6.0
//

import Foundation

public struct WorkerConstants {
    
    public static let workerNames: [String: String] = [
        "1": "Greg Franco",
        "2": "Edwin Lema", 
        "3": "Maria Rodriguez",
        "4": "Kevin Dutan",
        "5": "Mercedes Inamagua",
        "6": "Luis Lopez",
        "7": "Angel Santos",
        "8": "Shawn Magloire"
    ]
    
    public static func getWorkerName(id: String) -> String {
        return workerNames[id] ?? "Unknown Worker"
    }
    
    public static func getWorkerId(name: String) -> String? {
        return workerNames.first { $1 == name }?.key
    }
}
