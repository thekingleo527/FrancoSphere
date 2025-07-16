//
//  WorkerDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ CORRECTED: Uses actual ViewModel properties and methods that exist
//  ✅ SIMPLIFIED: Clock toggle logic to use existing clockOut() method
//  ✅ ENHANCED: Proper error handling and state management
//

import SwiftUI
import MapKit

struct WorkerDashboardView: View {
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager

    // UI State
    @State private var showBuildingList = false
    @State private var showMapOverlay = false
    @State private var showProfileView = false
    @State private var workerName = "Worker" // Local state for worker name
    
    var body: some View {
        NavigationView {
            ZStack {
                mapBackground
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else {
                    mainContentScrollView
                }
                
                // Custom header floats on top
                VStack {
                    HeaderV3B(
                        workerName: workerName,
                        clockedInStatus: viewModel.isClockedIn,
                        onClockToggle: {
                            Task {
                                if viewModel.isClockedIn {
                                    await viewModel.clockOut()
                                } else {
                                    showBuildingList = true
                                }
                            }
                        },
                        onProfilePress: { showProfileView = true },
                        nextTaskName: viewModel.todaysTasks.first(where: { !$0.isCompleted })?.title,
                        hasUrgentWork: viewModel.todaysTasks.contains { task in
                            task.urgency == .high || task.urgency == .urgent || task.urgency == .critical
                        },
                        onNovaPress: { /* TODO: Show Nova AI */ },
                        onNovaLongPress: { /* TODO: Show Nova AI Long Press */ },
                        isNovaProcessing: false,
                        showClockPill: true
                    )
                    .background(.ultraThinMaterial)
                    Spacer()
                }
            }
            .task {
                await viewModel.loadInitialData()
                // Load worker name separately
                workerName = await viewModel.getCurrentWorkerName()
            }
            .sheet(isPresented: $showBuildingList) {
                BuildingSelectionSheet(
                    buildings: viewModel.assignedBuildings,
                    onSelect: { building in
                        Task { await viewModel.clockIn(at: building) }
                        showBuildingList = false
                    },
                    onCancel: { showBuildingList = false }
                )
            }
            .sheet(isPresented: $showProfileView) {
                ProfileView()
            }
            .fullScreenCover(isPresented: $showMapOverlay) {
                EnhancedMapOverlay(
                    isPresented: $showMapOverlay,
                    buildings: viewModel.assignedBuildings,
                    currentBuildingId: viewModel.currentBuilding?.id
                )
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Computed Properties
    
    private var clockInButtonText: String {
        return viewModel.isClockedIn ? "Clock Out" : "Start Shift"
    }
    
    private var clockInStatusText: String {
        if viewModel.isClockedIn {
            return "Working at \(viewModel.currentBuilding?.name ?? "Unknown Location")"
        } else {
            return "Select a building to start your shift"
        }
    }

    // MARK: - Subviews

    private var mapBackground: some View {
        Map(interactionModes: [])
            .mapStyle(.standard(elevation: .realistic))
            .blur(radius: 4)
            .overlay(Color.black.opacity(0.5))
    }
    
    private var loadingView: some View {
        ProgressView("Loading Dashboard...")
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black.opacity(0.4))
    }
    
    private var mainContentScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 100) // Pushes content below the floating header
                
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }
                
                clockInSection
                todaysProgressSection
                mySitesSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.caption)
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.red.opacity(0.8))
        .cornerRadius(12)
    }

    private var clockInSection: some View {
        Button(action: {
            if viewModel.isClockedIn {
                Task { await viewModel.clockOut() }
            } else {
                showBuildingList = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isClockedIn ? "location.fill" : "location.slash")
                    .font(.title3)
                    .foregroundColor(viewModel.isClockedIn ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(clockInButtonText)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(clockInStatusText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var todaysProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            // ✅ FIXED: Use progressPercentage property that actually exists
            ProgressView(value: viewModel.taskProgress?.progressPercentage ?? 0, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("\(Int(viewModel.taskProgress?.progressPercentage ?? 0))% Complete")
                Spacer()
                Text("\(viewModel.taskProgress?.completedTasks ?? 0)/\(viewModel.taskProgress?.totalTasks ?? 0) Tasks")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var mySitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Sites")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("View All") {
                    showMapOverlay = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.assignedBuildings.prefix(6)) { building in
                    MySitesCard(building: building)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Building Selection Sheet
struct BuildingSelectionSheet: View {
    let buildings: [NamedCoordinate]
    let onSelect: (NamedCoordinate) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            List(buildings) { building in
                Button(action: { onSelect(building) }) {
                    HStack {
                        Text(building.name)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .navigationTitle("Select a Building")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
            .environmentObject(NewAuthManager.shared)
    }
}
