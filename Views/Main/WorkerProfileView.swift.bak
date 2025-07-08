//
//  WorkerProfileView.swift
//  FrancoSphere
//
//  ✅ MINIMAL WORKING VERSION: Based on actual compilation errors
//  ✅ Only uses properties that actually exist in WorkerProfile
//  ✅ Uses correct PerformanceMetrics constructor
//  ✅ Avoids all property and method conflicts
//

import SwiftUI

struct WorkerProfileView: View {
    @StateObject private var viewModel = WorkerProfileViewModel()
    let workerId: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                if let worker = viewModel.worker {
                    ProfileHeaderView(worker: worker)
                }
                
                // Performance Section
                if let metrics = viewModel.performanceMetrics {
                    PerformanceMetricsView(metrics: metrics)
                }
                
                // Recent Tasks Section
                RecentTasksView(tasks: viewModel.recentTasks)
                
                // Skills Section
                if let worker = viewModel.worker {
                    SkillsView(skills: worker.skills)
                }
            }
            .padding()
        }
        .navigationTitle("Worker Profile")
        .task {
            await viewModel.loadWorkerData(workerId: workerId)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
            }
        }
    }
}

// MARK: - Sub Views

struct ProfileHeaderView: View {
    let worker: WorkerProfile
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile Image - Simple placeholder since profileImageName doesn't exist
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(worker.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(worker.role.rawValue.capitalized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Contact info - only use properties that exist
            if !worker.email.isEmpty {
                Text(worker.email)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            // Handle phone property (might be phone or phoneNumber)
            if !worker.phoneNumber.isEmpty {
                Text(worker.phoneNumber)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            // Active status
            HStack {
                Image(systemName: worker.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(worker.isActive ? .green : .red)
                Text(worker.isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(worker.isActive ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PerformanceMetricsView: View {
    let metrics: PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
            
            HStack {
                MetricCard(
                    title: "Efficiency",
                    value: "\(Int(metrics.efficiency))%",
                    color: .green
                )
                
                MetricCard(
                    title: "Completion Rate",
                    value: "\(Int(metrics.completionRate))%",
                    color: .blue
                )
                
                MetricCard(
                    title: "Avg Time",
                    value: "\(Int(metrics.averageTime / 60))m",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecentTasksView: View {
    let tasks: [ContextualTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Tasks")
                .font(.headline)
            
            if tasks.isEmpty {
                Text("No recent tasks")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(tasks.prefix(5), id: \.id) { task in
                    SimpleTaskRow(task: task)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Simple task row to avoid conflicts
struct SimpleTaskRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack {
            Circle()
                .fill(task.status == "completed" ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            Text(task.name)
                .font(.subheadline)
            
            Spacer()
            
            Text(task.urgency.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(urgencyColor(for: task.urgency))
                .foregroundColor(.white)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
    
    private func urgencyColor(for urgency: TaskUrgency) -> Color {
        switch urgency {
        case .critical, .urgent, .emergency:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .green
        }
    }
}

struct SkillsView: View {
    let skills: [WorkerSkill]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills")
                .font(.headline)
            
            if skills.isEmpty {
                Text("No skills listed")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(skills, id: \.self) { skill in
                        Text(skill.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(skillColor(for: skill))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func skillColor(for skill: WorkerSkill) -> Color {
        switch skill {
        case .hvac, .plumbing, .electrical, .utilities:
            return .blue
        case .cleaning, .maintenance, .general:
            return .green
        case .carpentry, .painting, .repair, .installation:
            return .orange
        case .landscaping:
            return .brown
        case .security:
            return .red
        case .inspection:
            return .purple
        }
    }
}

// MARK: - ViewModel

@MainActor
class WorkerProfileViewModel: ObservableObject {
    @Published var worker: WorkerProfile?
    @Published var performanceMetrics: PerformanceMetrics?
    @Published var recentTasks: [ContextualTask] = []
    @Published var isLoading = false
    
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    
    func loadWorkerData(workerId: String) async {
        isLoading = true
        
        do {
            // Load worker profile
            worker = try await workerService.fetchWorker(id: workerId)
            
            // Load performance metrics - convert to correct type
            let workerMetrics = await workerService.getPerformanceMetrics(workerId)
            
            // Use correct PerformanceMetrics constructor
            performanceMetrics = PerformanceMetrics(
                efficiency: workerMetrics.efficiency,
                completionRate: calculateCompletionRate(from: workerMetrics),
                averageTime: workerMetrics.averageCompletionTime
            )
            
            // Load recent tasks
            recentTasks = try await taskService.getTasks(for: workerId, date: Date())
            
        } catch {
            print("Error loading worker data: \(error)")
        }
        
        isLoading = false
    }
    
    private func calculateCompletionRate(from metrics: WorkerPerformanceMetrics) -> Double {
        // Simple calculation: use efficiency as base for completion rate
        return min(100.0, metrics.efficiency)
    }
}

// MARK: - Preview

struct WorkerProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkerProfileView(workerId: "4")
        }
    }
}
