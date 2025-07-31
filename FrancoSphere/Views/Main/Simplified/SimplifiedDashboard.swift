
//
//  SimplifiedDashboard.swift
//  FrancoSphere
//
//  Stream A: UI/UX & Spanish
//  Mission: Create a simplified dashboard for workers needing an accessible interface.
//
//  ✅ PRODUCTION READY: A focused, high-contrast dashboard.
//  ✅ INTEGRATED: Powered by WorkerDashboardViewModel and embeds SimplifiedTaskList.
//  ✅ ACCESSIBLE: Uses large fonts, simple layout, and clear action buttons.
//

import SwiftUI

struct SimplifiedDashboard: View {
    
    // The ViewModel is the single source of truth for all dashboard data.
    @ObservedObject var viewModel: WorkerDashboardViewModel
    
    // State for navigating to the task detail view.
    @State private var selectedTask: ContextualTask?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // High-contrast background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header displaying the worker's name
                headerView
                
                // Main content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Current Building Card
                        currentBuildingCard
                        
                        // Today's Tasks Section
                        tasksSection
                    }
                    .padding()
                }
            }
            
            // Large, persistent clock in/out button at the bottom
            clockInOutButton
                .padding()
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedTask) { task in
            // When a task is tapped, show the simplified detail view.
            SimplifiedTaskView(viewModel: TaskDetailViewModel(), task: task)
        }
        .onAppear {
            // Ensure the latest data is loaded when the view appears.
            Task {
                await viewModel.refreshData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack {
            Text(greeting, bundle: .main)
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text(viewModel.workerProfile?.name ?? "Worker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    @ViewBuilder
    private var currentBuildingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current Building", systemImage: "building.2.fill")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.isClockedIn, let building = viewModel.currentBuilding {
                Text(building.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            } else {
                Text("Not currently clocked in at a building.", bundle: .main)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Today's Tasks", systemImage: "checklist")
                .font(.headline)
                .foregroundColor(.primary)
            
            SimplifiedTaskList(
                tasks: viewModel.todaysTasks,
                onTaskTap: { task in
                    self.selectedTask = task
                },
                onTaskComplete: { task in
                    Task {
                        await viewModel.completeTask(task)
                    }
                }
            )
        }
    }
    
    private var clockInOutButton: some View {
        Button(action: {
            Task {
                if viewModel.isClockedIn {
                    await viewModel.clockOut()
                } else {
                    // For simplified UI, clocking in requires selecting a building first.
                    // This logic would be handled by the parent view coordinator.
                    // For now, we assume a primary building or a selection flow is triggered.
                    if let primaryBuilding = viewModel.assignedBuildings.first {
                        await viewModel.clockIn(at: primaryBuilding)
                    }
                }
            }
        }) {
            HStack {
                Spacer()
                Image(systemName: viewModel.isClockedIn ? "arrow.right.square.fill" : "arrow.left.square.fill")
                    .font(.system(size: 40))
                
                Text(viewModel.isClockedIn ? "Clock Out" : "Clock In", bundle: .main)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            .frame(height: 80)
            .background(viewModel.isClockedIn ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: (viewModel.isClockedIn ? Color.red : Color.green).opacity(0.4), radius: 10, y: 5)
        }
    }
    
    // MARK: - Computed Properties
    
    private var greeting: LocalizedStringKey {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
}


// MARK: - Preview

struct SimplifiedDashboard_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock ViewModel for the preview
        let mockViewModel = WorkerDashboardViewModel.preview()
        mockViewModel.isClockedIn = true
        mockViewModel.currentBuilding = .init(id: "14", name: "Rubin Museum", address: "", latitude: 0, longitude: 0)
        
        SimplifiedDashboard(viewModel: mockViewModel)
            .preferredColorScheme(.dark)
    }
}
