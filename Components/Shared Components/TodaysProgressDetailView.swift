//
//  TodaysProgressDetailView.swift
//  FrancoSphere
//
//  ✅ F6: Navigation destination for "Today's Progress" taps
//  Shows detailed progress analytics with completed vs pending tasks grid
//  Includes building-wise breakdown and time-based analysis
//

import SwiftUI

struct TodaysProgressDetailView: View {
    @EnvironmentObject private var contextEngine: WorkerContextEngine
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMetric: ProgressMetric = .overview
    @State private var selectedBuilding: String = "All Buildings"
    @State private var isLoading = true
    
    enum ProgressMetric: String, CaseIterable {
        case overview = "Overview"
        case byBuilding = "By Building"
        case byTime = "By Time"
        case byPriority = "By Priority"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .byBuilding: return "building.2.fill"
            case .byTime: return "clock.fill"
            case .byPriority: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    private var allTasks: [ContextualTask] {
        contextEngine.getTodaysTasks()
    }
    
    private var completedTasks: [ContextualTask] {
        allTasks.filter { $0.status == "completed" }
    }
    
    private var pendingTasks: [ContextualTask] {
        allTasks.filter { $0.status != "completed" }
    }
    
    private var overdueTasks: [ContextualTask] {
        pendingTasks.filter { task in
            guard let startTime = task.startTime else { return false }
            return isTaskOverdue(startTime)
        }
    }
    
    private var completionPercentage: Double {
        guard !allTasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(allTasks.count) * 100
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                metricSelectorSection
                contentSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.black)
        .navigationTitle("Today's Progress")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .task {
            await loadProgressData()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Main progress circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: completionPercentage / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: completionPercentage)
                
                VStack(spacing: 4) {
                    Text("\(Int(completionPercentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Quick stats grid
            HStack(spacing: 16) {
                quickStatCard("Completed", count: completedTasks.count, color: .green)
                quickStatCard("Pending", count: pendingTasks.count, color: .orange)
                quickStatCard("Overdue", count: overdueTasks.count, color: .red)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func quickStatCard(_ title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Metric Selector
    
    private var metricSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ProgressMetric.allCases, id: \.self) { metric in
                    metricChip(metric)
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    private func metricChip(_ metric: ProgressMetric) -> some View {
        Button(action: {
            selectedMetric = metric
            HapticManager.impact(.light)
        }) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.caption)
                
                Text(metric.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                selectedMetric == metric ?
                    Color.blue : Color.white.opacity(0.1)
            )
            .foregroundColor(
                selectedMetric == metric ?
                    .white : .white.opacity(0.8)
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        Group {
            switch selectedMetric {
            case .overview:
                overviewContent
            case .byBuilding:
                buildingBreakdownContent
            case .byTime:
                timeBreakdownContent
            case .byPriority:
                priorityBreakdownContent
            }
        }
    }
    
    // MARK: - Overview Content
    
    private var overviewContent: some View {
        VStack(spacing: 16) {
            if !completedTasks.isEmpty {
                progressSection("Completed Tasks (\(completedTasks.count))", tasks: completedTasks, color: .green)
            }
            
            if !pendingTasks.isEmpty {
                progressSection("Pending Tasks (\(pendingTasks.count))", tasks: pendingTasks, color: .orange)
            }
            
            if !overdueTasks.isEmpty {
                progressSection("Overdue Tasks (\(overdueTasks.count))", tasks: overdueTasks, color: .red)
            }
        }
    }
    
    private func progressSection(_ title: String, tasks: [ContextualTask], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(tasks.prefix(5), id: \.id) { task in
                    ProgressTaskRow(task: task, accentColor: color)
                }
                
                if tasks.count > 5 {
                    Text("+ \(tasks.count - 5) more tasks")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Building Breakdown Content
    
    private var buildingBreakdownContent: some View {
        let tasksByBuilding = Dictionary(grouping: allTasks) { $0.buildingName }
        
        return VStack(spacing: 16) {
            ForEach(Array(tasksByBuilding.keys.sorted()), id: \.self) { buildingName in
                let tasks = tasksByBuilding[buildingName] ?? []
                let completed = tasks.filter { $0.status == "completed" }.count
                let progress = Double(completed) / Double(tasks.count) * 100
                
                buildingProgressCard(
                    buildingName: buildingName,
                    completed: completed,
                    total: tasks.count,
                    progress: progress
                )
            }
        }
    }
    
    private func buildingProgressCard(buildingName: String, completed: Int, total: Int, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.blue)
                
                Text(buildingName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Progress bar
            HStack {
                ProgressView(value: progress / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                
                Text("\(Int(progress))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Time Breakdown Content
    
    private var timeBreakdownContent: some View {
        let timeSlots = getTimeSlotBreakdown()
        
        return VStack(spacing: 16) {
            ForEach(Array(timeSlots.keys.sorted()), id: \.self) { timeSlot in
                let tasks = timeSlots[timeSlot] ?? []
                let completed = tasks.filter { $0.status == "completed" }.count
                
                timeSlotCard(
                    timeSlot: timeSlot,
                    completed: completed,
                    total: tasks.count
                )
            }
        }
    }
    
    private func timeSlotCard(timeSlot: String, completed: Int, total: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeSlot)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(completed) of \(total) completed")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(total > 0 ? Int(Double(completed) / Double(total) * 100) : 0)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                ProgressView(value: total > 0 ? Double(completed) / Double(total) : 0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(width: 60)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Priority Breakdown Content
    
    private var priorityBreakdownContent: some View {
        let priorities = ["high", "medium", "low"]
        
        return VStack(spacing: 16) {
            ForEach(priorities, id: \.self) { priority in
                let tasks = allTasks.filter { $0.priority == priority }
                let completed = tasks.filter { $0.status == "completed" }.count
                let color = priorityColor(for: priority)
                
                if !tasks.isEmpty {
                    priorityCard(
                        priority: priority.capitalized,
                        completed: completed,
                        total: tasks.count,
                        color: color
                    )
                }
            }
        }
    }
    
    private func priorityCard(priority: String, completed: Int, total: Int, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(color)
                    
                    Text("\(priority) Priority")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Text("\(completed) of \(total) completed")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(total > 0 ? Int(Double(completed) / Double(total) * 100) : 0)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                ProgressView(value: total > 0 ? Double(completed) / Double(total) : 0)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(width: 60)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Methods
    
    private func getTimeSlotBreakdown() -> [String: [ContextualTask]] {
        var timeSlots: [String: [ContextualTask]] = [:]
        
        for task in allTasks {
            guard let startTime = task.startTime else { continue }
            let components = startTime.split(separator: ":")
            guard let hour = Int(components.first ?? "0") else { continue }
            
            let timeSlot: String
            switch hour {
            case 6..<12:
                timeSlot = "Morning (6 AM - 12 PM)"
            case 12..<17:
                timeSlot = "Afternoon (12 PM - 5 PM)"
            case 17..<22:
                timeSlot = "Evening (5 PM - 10 PM)"
            default:
                timeSlot = "Other Times"
            }
            
            timeSlots[timeSlot, default: []].append(task)
        }
        
        return timeSlots
    }
    
    private func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
    
    private func isTaskOverdue(_ startTime: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let taskTime = formatter.date(from: startTime) else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        
        guard let todayTaskTime = calendar.date(byAdding: .second,
                                               value: Int(taskTime.timeIntervalSince1970),
                                               to: todayStart) else { return false }
        
        return now.timeIntervalSince(todayTaskTime) > 1800 // 30 minutes
    }
    
    private func loadProgressData() async {
        await MainActor.run {
            isLoading = false
        }
    }
}

// MARK: - Progress Task Row Component

struct ProgressTaskRow: View {
    let task: ContextualTask
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(accentColor)
                .frame(width: 8, height: 8)
            
            // Task details
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(task.buildingName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let startTime = task.startTime {
                        Text("• \(startTime)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Priority indicator
            if task.priority == "high" {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
    }
}