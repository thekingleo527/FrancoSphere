//
//  WorkerProfileView.swift
//  FrancoSphere
//

import SwiftUI
import Foundation

struct WorkerProfileView: View {
    let workerId: String
    
    @State private var worker: WorkerProfile?
    @State private var isLoading = true
    @State private var performanceMetrics: PerformanceMetrics?
    @State private var recentTasks: [ContextualTask] = []
    @State private var currentBuilding: NamedCoordinate?
    @State private var showingTaskDetail = false
    @State private var selectedTask: ContextualTask?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    loadingView
                } else if let worker = worker {
                    profileHeader(worker: worker)
                    performanceSection
                    currentAssignmentSection
                    recentTasksSection
                    skillsSection(worker: worker)
                } else {
                    errorView
                }
            }
            .padding()
        }
        .navigationTitle("Worker Profile")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadWorkerData()
        }
        .refreshable {
            await loadWorkerData()
        }
        .sheet(isPresented: $showingTaskDetail) {
            if let selectedTask = selectedTask {
                TaskDetailSheet(task: selectedTask)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading worker profile...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Worker Not Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Unable to load profile for worker ID: \(workerId)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await loadWorkerData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Profile Header
    @ViewBuilder
    private func profileHeader(worker: WorkerProfile) -> some View {
        VStack(spacing: 16) {
            // Worker Avatar and Basic Info
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Text(String(worker.name.prefix(1)))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(worker.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Worker ID: \(worker.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: worker.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                            .foregroundColor(worker.isActive ? .green : .orange)
                        
                        Text(worker.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text(worker.role.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            // Contact Info
            if !worker.contactInfo.isEmpty {
                HStack {
                    Image(systemName: "envelope.circle.fill")
                        .foregroundColor(.blue)
                    Text(worker.contactInfo)
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let metrics = performanceMetrics {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    performanceCard(
                        title: "Efficiency",
                        value: "\(Int(metrics.efficiency * 100))%",
                        icon: "speedometer",
                        color: .blue
                    )
                    
                    performanceCard(
                        title: "Tasks Completed",
                        value: "\(metrics.tasksCompleted)",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    performanceCard(
                        title: "Avg. Time",
                        value: formatDuration(metrics.averageTime),
                        icon: "clock",
                        color: .orange
                    )
                    
                    performanceCard(
                        title: "Quality Score",
                        value: String(format: "%.1f", metrics.qualityScore),
                        icon: "star.fill",
                        color: .yellow
                    )
                }
            } else {
                Text("Performance data not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    @ViewBuilder
    private func performanceCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Current Assignment Section
    private var currentAssignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Assignment")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let building = currentBuilding {
                HStack(spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let address = building.address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Building ID: \(building.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Button("View Building") {
                            // Navigate to building detail
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else {
                HStack {
                    Image(systemName: "building.slash")
                        .foregroundColor(.orange)
                    Text("No current assignment")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Recent Tasks Section
    private var recentTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(recentTasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if recentTasks.isEmpty {
                Text("No recent tasks found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(recentTasks.prefix(5)) { task in
                        taskRow(task: task)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    @ViewBuilder
    private func taskRow(task: ContextualTask) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(colorForTaskCategory(task.category))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(task.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(task.status.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorForTaskStatus(task.status))
                
                if let completedAt = task.completedAt {
                    Text(formatDate(completedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .onTapGesture {
            selectedTask = task
            showingTaskDetail = true
        }
    }
    
    // MARK: - Skills Section
    @ViewBuilder
    private func skillsSection(worker: WorkerProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills & Certifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            if worker.skills.isEmpty {
                Text("No skills recorded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100))
                ], spacing: 8) {
                    ForEach(worker.skills, id: \.self) { skill in
                        skillBadge(skill: skill)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    @ViewBuilder
    private func skillBadge(skill: WorkerSkill) -> some View {
        Text(skill.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(16)
    }
    
    // MARK: - Data Loading
    private func loadWorkerData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load worker profile using shared service instances
            worker = await WorkerService.shared.fetchWorker(id: workerId)
            
            // Load performance metrics
            performanceMetrics = await WorkerService.shared.fetchPerformanceMetrics(for: workerId)
            
            // Load recent tasks
            recentTasks = await TaskService.shared.fetchRecentTasks(for: workerId, limit: 10)
            
            // Load current building assignment
            if let buildingId = worker?.currentBuildingId {
                currentBuilding = await BuildingService.shared.fetchBuilding(id: buildingId)
            }
            
        } catch {
            print("Error loading worker data: \(error)")
            worker = nil
        }
    }
    
    // MARK: - Helper Functions
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func colorForTaskCategory(_ category: TaskCategory) -> Color {
        switch category {
        case .cleaning:
            return .blue
        case .maintenance:
            return .orange
        case .inspection:
            return .purple
        case .repair:
            return .red
        case .safety:
            return .green
        }
    }
    
    private func colorForTaskStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed":
            return .green
        case "in progress", "active":
            return .blue
        case "pending":
            return .orange
        case "overdue":
            return .red
        default:
            return .secondary
        }
    }
}

// MARK: - Task Detail Sheet
struct TaskDetailSheet: View {
    let task: ContextualTask
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(task.description)
                    .font(.body)
                
                HStack {
                    Label(task.category.rawValue.capitalized, systemImage: "tag")
                    Spacer()
                    Label(task.urgency.rawValue.capitalized, systemImage: "exclamationmark.triangle")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if let completedAt = task.completedAt {
                    Text("Completed: \(completedAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        WorkerProfileView(workerId: "kevin")
    }
    .preferredColorScheme(.dark)
}
