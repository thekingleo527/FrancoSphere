//
//  WorkersInlineList.swift
//  FrancoSphere v6.0
//
//  🔧 SURGICAL FIXES: All compilation errors resolved
//  ✅ Fixed AnimationAnimation typo → .easeInOut animation
//  ✅ Removed non-existent ContextualTask properties
//  ✅ Simplified worker-task assignment logic
//  ✅ Compatible with WorkerContextEngine actor architecture
//

import SwiftUI

struct WorkersInlineList: View {
    let buildingId: String
    let maxDisplayCount: Int
    let showDSNYWorkers: Bool
    let onWorkerTap: ((String) -> Void)?
    
    @State private var workers: [WorkerInfo] = []
    @State private var isLoading = true
    @State private var showAllWorkers = false
    
    // Convenience initializers
    init(buildingId: String,
         maxDisplayCount: Int = 3,
         showDSNYWorkers: Bool = false,
         onWorkerTap: ((String) -> Void)? = nil) {
        self.buildingId = buildingId
        self.maxDisplayCount = maxDisplayCount
        self.showDSNYWorkers = showDSNYWorkers
        self.onWorkerTap = onWorkerTap
    }
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if workers.isEmpty {
                emptyStateView
            } else {
                workersContentView
            }
        }
        .task {
            await loadWorkers()
        }
        .onChange(of: buildingId) { _, _ in
            Task {
                await loadWorkers()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.blue)
            
            Text("Loading workers...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.slash")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Text("No workers assigned")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Workers Content View
    
    private var workersContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display workers
            if showAllWorkers || workers.count <= maxDisplayCount {
                workersFullList
            } else {
                workersCollapsedList
            }
            
            // Show more/less button if needed
            if workers.count > maxDisplayCount {
                showMoreButton
            }
        }
    }
    
    private var workersFullList: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], alignment: .leading, spacing: 12) {
            ForEach(workers, id: \.id) { worker in
                workerCard(worker)
            }
        }
    }
    
    private var workersCollapsedList: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show first few workers
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 12) {
                ForEach(workers.prefix(maxDisplayCount), id: \.id) { worker in
                    workerCard(worker)
                }
            }
            
            // Show count of additional workers
            if workers.count > maxDisplayCount {
                additionalWorkersIndicator
            }
        }
    }
    
    private var additionalWorkersIndicator: some View {
        HStack {
            Text("+\(workers.count - maxDisplayCount) more")
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    private var showMoreButton: some View {
        Button(action: {
            // ✅ FIXED: AnimationAnimation typo → proper .easeInOut animation
            withAnimation(.easeInOut(duration: 0.3)) {
                showAllWorkers.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Text(showAllWorkers ? "Show Less" : "Show All (\(workers.count))")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Image(systemName: showAllWorkers ? "chevron.up" : "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Worker Card
    
    private func workerCard(_ worker: WorkerInfo) -> some View {
        Button(action: {
            onWorkerTap?(worker.id)
        }) {
            VStack(spacing: 8) {
                // Worker avatar
                ProfileBadge(
                    workerName: worker.name,
                    imageUrl: nil, // Could be enhanced to support profile images
                    isCompact: true,
                    onTap: {
                        onWorkerTap?(worker.id)
                    }, accentColor: getWorkerAccentColor(worker)
                )
                
                // Worker info
                VStack(spacing: 2) {
                    Text(worker.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(worker.role)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                // Status indicators
                statusIndicators(for: worker)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(getWorkerAccentColor(worker).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(worker.isActive ? 1.0 : 0.95)
        .opacity(worker.isActive ? 1.0 : 0.7)
    }
    
    private func statusIndicators(for worker: WorkerInfo) -> some View {
        HStack(spacing: 4) {
            // Clock status
            if worker.isClockedIn {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            // Task count
            if worker.taskCount > 0 {
                Text("\(worker.taskCount)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2), in: Capsule())
            }
            
            // DSNY indicator
            if worker.isDSNYWorker && showDSNYWorkers {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadWorkers() async {
        await MainActor.run {
            isLoading = true
        }
        
        // ✅ FIXED: Get workers through WorkerContextEngine actor
        let detailedWorkers = await WorkerContextEngine.shared.todayWorkers()
        
        var loadedWorkers: [WorkerInfo] = []
        
        for detailedWorker in detailedWorkers {
            let worker = WorkerInfo(
                id: detailedWorker.id,
                name: detailedWorker.name,
                displayName: formatWorkerDisplayName(detailedWorker.name),
                role: detailedWorker.role.rawValue,
                shift: getWorkerShift(detailedWorker.id),
                isActive: isWorkerActive(detailedWorker.id),
                isClockedIn: await isWorkerClockedIn(detailedWorker.id),
                taskCount: await getWorkerTaskCount(detailedWorker.id),
                isDSNYWorker: await isDSNYWorker(detailedWorker.name)
            )
            loadedWorkers.append(worker)
        }
        
        // Sort workers by priority (clocked in first, then by task count)
        loadedWorkers.sort { worker1, worker2 in
            if worker1.isClockedIn != worker2.isClockedIn {
                return worker1.isClockedIn
            }
            return worker1.taskCount > worker2.taskCount
        }
        
        await MainActor.run {
            self.workers = loadedWorkers
            self.isLoading = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func getWorkerIdFromName(_ name: String) -> String {
        let workerMap: [String: String] = [
            "Greg Hutson": "1",
            "Edwin Lema": "2",
            "Kevin Dutan": "1", // Kevin's corrected ID
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn Magloire": "8"
        ]
        
        // Handle partial matches for names like "Greg" or "Kevin"
        for (fullName, id) in workerMap {
            if fullName.lowercased().contains(name.lowercased()) ||
               name.lowercased().contains(fullName.components(separatedBy: " ").first?.lowercased() ?? "") {
                return id
            }
        }
        
        return "unknown"
    }
    
    private func formatWorkerDisplayName(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0]) \(String(components[1].prefix(1)))."
        }
        return name
    }
    
    private func getWorkerShift(_ workerId: String) -> String {
        switch workerId {
        case "1": return "9:00-17:00"  // Kevin - Updated
        case "2": return "6:00-15:00"  // Edwin
        case "5": return "6:30-11:00"  // Mercedes
        default: return "9:00-17:00"
        }
    }
    
    private func isWorkerActive(_ workerId: String) -> Bool {
        let activeWorkerIds = ["1", "2", "5", "6", "7", "8"]
        return activeWorkerIds.contains(workerId)
    }
    
    private func isWorkerClockedIn(_ workerId: String) async -> Bool {
        // Check if worker is currently clocked in through WorkerContextEngine
        let isCurrentlyClockedIn = await WorkerContextEngine.shared.isWorkerClockedIn()
        let currentWorkerId = await WorkerContextEngine.shared.getWorkerId()
        return isCurrentlyClockedIn && currentWorkerId == workerId
    }
    
    private func getWorkerTaskCount(_ workerId: String) async -> Int {
        let tasks = await WorkerContextEngine.shared.getTodaysTasks()
        
        // ✅ SIMPLIFIED: Count tasks for this building (simplified assignment logic)
        return tasks.filter { task in
            task.buildingId == buildingId
        }.count / max(workers.count, 1) // Distribute tasks among workers
    }
    
    private func isDSNYWorker(_ workerName: String) async -> Bool {
        let tasks = await WorkerContextEngine.shared.getTodaysTasks()
        
        // ✅ FIXED: Use correct ContextualTask properties
        for task in tasks {
            let isDSNYTask = task.category?.rawValue.lowercased().contains("sanitation") == true ||
                           task.title.lowercased().contains("trash") ||
                           task.title.lowercased().contains("recycling") ||
                           task.title.lowercased().contains("dsny")
            
            if isDSNYTask && task.buildingId == buildingId {
                return true
            }
        }
        
        return false
    }
    
    private func getWorkerAccentColor(_ worker: WorkerInfo) -> Color {
        switch worker.id {
        case "1": return .blue    // Kevin
        case "2": return .green   // Edwin
        case "5": return .orange  // Mercedes
        case "6": return .pink    // Luis
        case "7": return .teal    // Angel
        case "8": return .red     // Shawn
        default: return .gray
        }
    }
}

// MARK: - Supporting Models

struct WorkerInfo: Identifiable {
    let id: String
    let name: String
    let displayName: String
    let role: String
    let shift: String
    let isActive: Bool
    let isClockedIn: Bool
    let taskCount: Int
    let isDSNYWorker: Bool
}

// MARK: - Preview Support

#if DEBUG
struct WorkersInlineList_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WorkersInlineList(buildingId: "1")
                .padding()
            
            WorkersInlineList(
                buildingId: "5",
                maxDisplayCount: 2,
                showDSNYWorkers: true
            )
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif
