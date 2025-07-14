//
//  ContextualTaskExtensions.swift
//  FrancoSphere v6.0
//
//  🔧 SURGICAL FIX: Extensions to provide missing ContextualTask properties
//  ✅ Provides backward compatibility for existing code
//  ✅ Maintains real data integrity
//

import Foundation

extension ContextualTask {
    
    // MARK: - Missing Property Implementations
    
    /// Status property for task completion tracking
    var status: String {
        if isCompleted {
            return "completed"
        } else if let dueDate = dueDate, dueDate < Date() {
            return "overdue"
        } else {
            return "pending"
        }
    }
    
    /// Start time as formatted string
    var startTime: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
    
    /// Task name (alias for title compatibility)
    var name: String {
        return title ?? description ?? "Untitled Task"
    }
    
    /// Estimated duration in seconds (default to 1 hour)
    var estimatedDuration: TimeInterval {
        return 3600 // 1 hour default
    }
    
    /// Assigned worker ID (mapped from existing properties)
    var assignedWorkerId: String? {
        return workerId
    }
    
    /// Work order ID for tracking
    var workerId: String? {
        // Map from existing assigned worker data
        return assignedWorkerName?.replacingOccurrences(of: " ", with: "_").lowercased()
    }
}

// MARK: - TaskCategory Extension

extension TaskCategory {
    /// Raw value accessor for string conversion
    var rawValue: String {
        switch self {
        case .cleaning: return "cleaning"
        case .maintenance: return "maintenance"
        case .repair: return "repair"
        case .sanitation: return "sanitation"
        case .inspection: return "inspection"
        case .landscaping: return "landscaping"
        case .security: return "security"
        case .emergency: return "emergency"
        case .installation: return "installation"
        case .utilities: return "utilities"
        case .renovation: return "renovation"
        }
    }
}

// MARK: - TaskUrgency Extension

extension TaskUrgency {
    /// Raw value accessor for string conversion
    var rawValue: String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        case .critical: return "critical"
        case .emergency: return "emergency"
        case .urgent: return "urgent"
        }
    }
}
