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
        isLoading=true
        do
            try await contextEngine.loadContext(for: workerId)
            await refreshPublishedState()
        catch {
            print("❌ Failed to load context:", error)
        }
        isLoading=false
    }
    
    public func todayWorkers() -> [WorkerProfile] {
        if let w = currentWorker { return [w] }
        return []
    }
    
    public func getTasksForBuilding(_ b: String) -> [ContextualTask] {
        todaysTasks.filter{ $0.buildingId == b }
    }
    
    public func getUrgentTaskCount() -> Int {
        todaysTasks.filter{ [.high,.critical].contains($0.urgency) }.count
    }
    
    private func refreshPublishedState() async {
        currentWorker      = await contextEngine.getCurrentWorker()
        assignedBuildings  = await contextEngine.getAssignedBuildings()
        todaysTasks        = await contextEngine.getTodaysTasks()
        taskProgress       = await contextEngine.getTaskProgress()
        isLoading          = await contextEngine.getIsLoading()
        hasPendingScenario = getUrgentTaskCount()>0
    }
    
    private func setupPeriodicUpdates() {
        Timer.publish(every:30,on:.main,in:.common)
            .autoconnect()
            .sink{ [weak self]_ in Task{ await self?.refreshPublishedState() } }
            .store(in:&cancellables)
    }
}
