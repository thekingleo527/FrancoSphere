import Foundation
import SwiftUI
import Combine

@MainActor
public class WorkerContextEngineAdapter: ObservableObject {
    public static let shared = WorkerContextEngineAdapter()
    
    @Published public var currentWorker: WorkerProfile?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: TaskProgress?
    @Published public var isLoading = false
    @Published public var hasPendingScenario = false
    
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPeriodicUpdates()
    }
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async {
        isLoading = true
        do {
            try await contextEngine.loadContext(for: workerId)
            await refreshPublishedState()
        } catch {
            print("❌ Failed to load context: \(error)")
        }
        isLoading = false
    }
    
    public func todayWorkers() -> [WorkerProfile] {
        if let worker = currentWorker { return [worker] }
        return []
    }
    
    public func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return todaysTasks.filter { $0.buildingId == buildingId }
    }
    
    public func getUrgentTaskCount() -> Int {
        return todaysTasks.filter { $0.urgency == .high || $0.urgency == .critical }.count
    }
    
    private func refreshPublishedState() async {
        self.currentWorker       = await contextEngine.getCurrentWorker()
        self.assignedBuildings   = await contextEngine.getAssignedBuildings()
        self.todaysTasks         = await contextEngine.getTodaysTasks()
        self.taskProgress        = await contextEngine.getTaskProgress()
        self.isLoading           = await contextEngine.getIsLoading()
        self.hasPendingScenario  = getUrgentTaskCount() > 0
    }
    
    private func setupPeriodicUpdates() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refreshPublishedState() }
            }
            .store(in: &cancellables)
    }
}
