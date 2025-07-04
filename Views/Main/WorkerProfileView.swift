// UPDATED: Using centralized TypeRegistry for all types
//
//  WorkerProfileView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/29/25.
//


//
//  WorkerProfileView.swift
//  FrancoSphere
//
//  ✅ Worker profile view for displaying individual worker information
//  ✅ Compatible with existing WorkerContextEngine and data models
//  ✅ Supports worker stats, assignments, and performance metrics
//

import SwiftUI

struct WorkerProfileView: View {
    let workerId: String
    let workerName: String
    
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @StateObject private var authManager = NewAuthManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var workerStats: WorkerStats?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        loadingView
                    } else {
                        // Profile header
                        profileHeaderSection
                        
                        // Stats overview
                        statsOverviewSection
                        
                        // Current assignments
                        currentAssignmentsSection
                        
                        // Performance metrics
                        performanceMetricsSection
                        
                        // Recent activity
                        recentActivitySection
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(workerName)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                            Text("Back")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadWorkerData()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Loading \(workerName)'s Profile...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Profile Header Section
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Worker avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(getWorkerInitials())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Worker info
            VStack(spacing: 8) {
                Text(workerName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Worker ID: \(workerId)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 16) {
                    statusBadge(
                        text: getWorkerRole(),
                        color: .blue
                    )
                    
                    statusBadge(
                        text: getWorkerShift(),
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Stats Overview Section
    
    private var statsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Overview")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                statCard(
                    title: "Tasks Today",
                    value: "\(getTodaysTaskCount())",
                    subtitle: "\(getCompletedTaskCount()) completed",
                    icon: "list.bullet.clipboard",
                    color: .blue
                )
                
                statCard(
                    title: "Buildings",
                    value: "\(getAssignedBuildingsCount())",
                    subtitle: "assigned sites",
                    icon: "building.2",
                    color: .purple
                )
            }
            
            HStack(spacing: 12) {
                statCard(
                    title: "Completion Rate",
                    value: "\(getCompletionRate())%",
                    subtitle: "today",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                statCard(
                    title: "Hours Worked",
                    value: "\(getHoursWorked())",
                    subtitle: "this week",
                    icon: "clock",
                    color: .orange
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Current Assignments Section
    
    private var currentAssignmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Assignments")
                .font(.headline)
                .foregroundColor(.white)
            
            if getAssignedBuildings().isEmpty {
                Text("No current assignments")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(getAssignedBuildings(), id: \.id) { building in
                        buildingAssignmentCard(building)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Performance Metrics Section
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                performanceMetric(
                    title: "Tasks Completed This Week",
                    value: getWeeklyTasksCompleted(),
                    trend: .up,
                    percentage: 12
                )
                
                performanceMetric(
                    title: "Average Task Duration",
                    value: getAverageTaskDuration(),
                    trend: .down,
                    percentage: 8
                )
                
                performanceMetric(
                    title: "Quality Score",
                    value: getQualityScore(),
                    trend: .up,
                    percentage: 5
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(getRecentActivities(), id: \.id) { activity in
                    activityCard(activity)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Views
    
    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.3), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
    }
    
    private func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func buildingAssignmentCard(_ building: FrancoSphere.NamedCoordinate) -> some View {
        HStack(spacing: 12) {
            // Building icon or image
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "building.2")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(getBuildingTaskCount(building.id)) tasks scheduled")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func performanceMetric(title: String, value: String, trend: TrendDirection, percentage: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: trend == .up ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(trend == .up ? .green : .red)
                
                Text("\(percentage)%")
                    .font(.caption)
                    .foregroundColor(trend == .up ? .green : .red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func activityCard(_ activity: WorkerActivity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.system(size: 16))
                .foregroundColor(activity.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(activity.timestamp)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Data Loading and Helper Methods
    
    private func loadWorkerData() async {
        // Simulate data loading
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func getWorkerInitials() -> String {
        let components = workerName.components(separatedBy: " ")
        let firstInitial = components.first?.first ?? Character("?")
        let lastInitial = components.count > 1 ? components.last?.first ?? Character("") : Character("")
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
    
    private func getWorkerRole() -> String {
        switch workerId {
        case "1": return "Lead Technician"
        case "2": return "Maintenance Specialist"
        case "4": return "Building Supervisor"
        case "5": return "Cleaning Specialist"
        case "6": return "General Maintenance"
        case "7": return "Building Technician"
        case "8": return "Facilities Manager"
        default: return "Worker"
        }
    }
    
    private func getWorkerShift() -> String {
        switch workerId {
        case "2": return "6:00-15:00"
        case "5": return "6:30-11:00"
        case "4": return "9:00-17:00"
        default: return "9:00-17:00"
        }
    }
    
    private func getTodaysTaskCount() -> Int {
        return contextEngine.getTodaysTasks().filter { 
            $0.assignedWorkerName?.lowercased().contains(workerName.lowercased()) == true 
        }.count
    }
    
    private func getCompletedTaskCount() -> Int {
        return contextEngine.getTodaysTasks().filter { 
            $0.assignedWorkerName?.lowercased().contains(workerName.lowercased()) == true && 
            $0.status == "completed"
        }.count
    }
    
    private func getAssignedBuildingsCount() -> Int {
        return getAssignedBuildings().count
    }
    
    private func getAssignedBuildings() -> [FrancoSphere.NamedCoordinate] {
        // Get buildings assigned to this worker
        let workerTasks = contextEngine.getTodaysTasks().filter { 
            $0.assignedWorkerName?.lowercased().contains(workerName.lowercased()) == true 
        }
        
        let buildingIds = Set(workerTasks.map { $0.buildingId })
        return FrancoSphere.NamedCoordinate.allBuildings.filter { buildingIds.contains($0.id) }
    }
    
    private func getBuildingTaskCount(_ buildingId: String) -> Int {
        return contextEngine.getTodaysTasks().filter { 
            $0.buildingId == buildingId && 
            $0.assignedWorkerName?.lowercased().contains(workerName.lowercased()) == true 
        }.count
    }
    
    private func getCompletionRate() -> Int {
        let total = getTodaysTaskCount()
        let completed = getCompletedTaskCount()
        return total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0
    }
    
    private func getHoursWorked() -> String {
        return "32.5"
    }
    
    private func getWeeklyTasksCompleted() -> String {
        return "47"
    }
    
    private func getAverageTaskDuration() -> String {
        return "24 min"
    }
    
    private func getQualityScore() -> String {
        return "4.8/5.0"
    }
    
    private func getRecentActivities() -> [WorkerActivity] {
        return [
            WorkerActivity(
                id: "1",
                title: "Completed HVAC Maintenance",
                subtitle: "117 West 17th Street",
                timestamp: "2 hours ago",
                icon: "wrench.and.screwdriver",
                color: .green
            ),
            WorkerActivity(
                id: "2",
                title: "Clocked in at Building",
                subtitle: "131 Perry Street",
                timestamp: "4 hours ago",
                icon: "clock.arrow.circlepath",
                color: .blue
            ),
            WorkerActivity(
                id: "3",
                title: "Photo Uploaded",
                subtitle: "Boiler room inspection",
                timestamp: "6 hours ago",
                icon: "camera",
                color: .purple
            )
        ]
    }
}

// MARK: - Supporting Models

enum TrendDirection {
    case up, down
}

struct WorkerStats {
    let tasksCompleted: Int
    let buildingsAssigned: Int
    let hoursWorked: Double
    let completionRate: Double
}

struct WorkerActivity: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let timestamp: String
    let icon: String
    let color: Color
}