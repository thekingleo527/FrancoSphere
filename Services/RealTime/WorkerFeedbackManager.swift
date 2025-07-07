//
//  WorkerFeedbackManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  WorkerFeedbackManager.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 2.3 - Worker Feedback Loop
//  ✅ Provides immediate UI confirmation to workers for their actions.
//  ✅ Manages the state of pending, synced, and failed actions.
//

import Foundation
import SwiftUI
import Combine

/// An observable object that provides real-time feedback to the worker about the status of their actions.
@MainActor
class WorkerFeedbackManager: ObservableObject {
    static let shared = WorkerFeedbackManager()

    /// Represents the confirmation status of a single worker action.
    struct ActionConfirmation: Identifiable, Equatable {
        let id: String
        let actionType: WorkerActionType
        let timestamp: Date
        var status: ConfirmationStatus
        let buildingName: String
    }
    
    /// The possible states for an action confirmation.
    enum ConfirmationStatus: String {
        case pending, synced, failed
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .synced: return .green
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "hourglass"
            case .synced: return "checkmark.circle.fill"
            case .failed: return "exclamationmark.triangle.fill"
            }
        }
        
        var displayText: String {
            self.rawValue.capitalized
        }
    }

    @Published var recentActions: [ActionConfirmation] = []
    @Published var pendingCount: Int = 0
    
    private let dataSyncService = DataSynchronizationService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Listen for successful sync events from the DataSynchronizationService
        dataSyncService.workerEventSynced
            .receive(on: DispatchQueue.main)
            .sink { [weak self] syncedEvent in
                self?.confirmSync(for: syncedEvent)
            }
            .store(in: &cancellables)
    }

    /// Called immediately when a worker performs an action. This provides instant UI feedback.
    func recordAction(type: WorkerActionType, buildingName: String, actionId: String) {
        print("👍 Recording action for immediate feedback: \(type.displayName)")
        
        let confirmation = ActionConfirmation(
            id: actionId,
            actionType: type,
            timestamp: Date(),
            status: .pending,
            buildingName: buildingName
        )
        
        // Insert at the top and limit the list to the 5 most recent actions.
        recentActions.insert(confirmation, at: 0)
        if recentActions.count > 5 {
            recentActions.removeLast()
        }
        
        updatePendingCount()
    }

    /// Called by the data sync listener when an action is confirmed as synced.
    private func confirmSync(for syncedEvent: WorkerEventSynced) {
        // We need to find the original action ID. This would typically be part of the syncedEvent payload.
        // For now, we'll assume the latest pending action of that type is the one that synced.
        
        if let index = recentActions.firstIndex(where: { $0.status == .pending && $0.actionType.rawValue == syncedEvent.eventType }) {
            print("✅ Confirming sync for action: \(recentActions[index].actionType.displayName)")
            recentActions[index].status = .synced
            updatePendingCount()
        }
    }
    
    /// Updates the count of actions that are still waiting to be synced.
    private func updatePendingCount() {
        pendingCount = recentActions.filter { $0.status == .pending }.count
    }
}
