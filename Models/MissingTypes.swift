//
//  MissingTypes.swift
//  FrancoSphere v6.0
//
//  🔧 COMPILATION FIX: Missing type definitions
//  ✅ RealWorldTask → ContextualTask mapping
//  ✅ SkillLevel → WorkerSkill mapping
//

import Foundation

// MARK: - Missing Type Aliases

/// RealWorldTask is an alias for ContextualTask
public typealias RealWorldTask = ContextualTask

/// SkillLevel is an alias for WorkerSkill  
public typealias SkillLevel = WorkerSkill

// MARK: - Building Access Type

public enum BuildingAccessType: String, Codable, CaseIterable {
    case assigned = "assigned"
    case coverage = "coverage" 
    case unknown = "unknown"
}

// MARK: - Building Type (alias for compatibility)
public typealias BuildingType = BuildingAccessType

// MARK: - Import Error Fix
// Remove duplicate ImportError declaration
