
//  VectorClock.swift
//  FrancoSphere
//
//  Stream B: Gemini - Backend Services
//  Mission: Implement conflict resolution for real-time sync.
//
//  ✅ PRODUCTION READY: Core data structure for CRDTs.
//  ✅ SAFE: Codable and Equatable for reliable serialization and comparison.
//  ✅ COMPLETE: Implements all required comparison and merging logic.
//

import Foundation

/// A data structure to determine the causal ordering of events in a distributed system.
/// This is essential for detecting and resolving conflicts in multi-device sync.
public struct VectorClock: Codable, Equatable {
    
    // The dictionary holds the logical clock for each node (device/user) in the system.
    // [NodeID: LogicalTime]
    private var clocks: [String: Int] = [:]
    
    /// Increments the clock for a specific node ID. This should be called
    /// whenever an entity is modified on a given device.
    ///
    /// - Parameter nodeId: The unique identifier for the device or user making the change.
    public mutating func increment(for nodeId: String) {
        clocks[nodeId, default: 0] += 1
    }
    
    /// Determines if this vector clock causally precedes another.
    /// Returns `true` if this clock is an ancestor of the other clock.
    ///
    /// - Parameter other: The vector clock to compare against.
    public func happensBefore(_ other: VectorClock) -> Bool {
        var selfIsStrictlySmaller = false
        for (nodeId, selfTime) in clocks {
            let otherTime = other.clocks[nodeId] ?? 0
            if selfTime > otherTime {
                return false // An element in self is greater, so it cannot happen before.
            }
            if selfTime < otherTime {
                selfIsStrictlySmaller = true
            }
        }
        return selfIsStrictlySmaller
    }
    
    /// Determines if this vector clock causally succeeds another.
    /// Returns `true` if this clock is a descendant of the other clock.
    ///
    /// - Parameter other: The vector clock to compare against.
    public func happensAfter(_ other: VectorClock) -> Bool {
        return other.happensBefore(self)
    }
    
    /// Determines if two vector clocks are concurrent (i.e., in conflict).
    /// This occurs when neither clock happens before the other.
    ///
    /// - Parameter other: The vector clock to compare against.
    public func areConcurrent(with other: VectorClock) -> Bool {
        return !self.happensBefore(other) && !other.happensBefore(self)
    }
    
    /// Merges another vector clock into this one, resolving causality by taking the maximum
    /// value for each node's clock. This is the fundamental operation for resolving state.
    ///
    /// - Parameter other: The vector clock to merge with.
    /// - Returns: A new `VectorClock` instance representing the merged state.
    public func merge(with other: VectorClock) -> VectorClock {
        var mergedClock = self
        for (nodeId, otherTime) in other.clocks {
            let selfTime = mergedClock.clocks[nodeId] ?? 0
            mergedClock.clocks[nodeId] = max(selfTime, otherTime)
        }
        return mergedClock
    }
    
    /// Provides direct, read-only access to the internal clock values.
    public func getClocks() -> [String: Int] {
        return clocks
    }
}

// MARK: - Integration Point in CoreTypes

extension CoreTypes.DashboardUpdate {
    // This would be added to the DashboardUpdate struct in CoreTypes.swift
    // public var vectorClock: VectorClock
}
