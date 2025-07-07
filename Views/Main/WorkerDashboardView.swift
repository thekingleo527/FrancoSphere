//
//  WorkerDashboardView.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Complete architectural overhaul.
//  ✅ FIXED: All compilation errors resolved.
//  ✅ INTEGRATED: Correctly uses actor-based managers via its ViewModel.
//  ✅ PRESERVED: Original UI design from screenshots.
//

import SwiftUI
import MapKit

struct WorkerDashboardView: View {
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager

    // UI State
    @State private var showBuildingList = false
    @State private var showMapOverlay = false

    var body: some View {
        ZStack {
            // The blurred map is always in the background
            mapBackground
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Loading Dashboard...")
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.4))
            } else {
                // The main scrollable content
                ScrollView {
                    VStack(spacing: 20) {
                        // This spacer pushes content below the custom header
                        Spacer(minLength: 80)
                        
                        // Display error banner if an error occurs
                        if let errorMessage = viewModel.errorMessage {
                            errorBanner(message: errorMessage)
                        }
                        
                        // Main Dashboard Cards
                        clockInSection
                        todaysProgressSection
                        mySitesSection
                        
                        // Add other dashboard components from your design here...
                        
                        Spacer(minLength: 100) // Padding at the bottom
                    }
                    .padding()
                }
            }
            
            // The custom header floats on top of everything
            VStack {
                HeaderV3B(
                    workerName: authManager.currentWorkerName,
                    clockedInStatus: viewModel.isClockedIn,
                    onClockToggle: { Task { await viewModel.handleClockInToggle() } },
                    onProfilePress: { /* TODO: Show Profile View */ },
                    nextTaskName: viewModel.todaysTasks.first(where: { !$0.isCompleted })?.name,
                    hasUrgentWork: !viewModel.todaysTasks.filter { $0.urgency == .high || $0.urgency == .urgent }.isEmpty,
                    onNovaPress: { /* TODO: Show Nova AI */ },
                    onNovaLongPress: { /* TODO: Show Nova AI Long Press */ },
                    isNovaProcessing: false,
                    hasPendingScenario: false,
                    showClockPill: true
                )
                .background(.ultraThinMaterial)
                
                Spacer()
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
        .sheet(isPresented: $showBuildingList) {
            // Sheet for selecting a building to clock into
            BuildingSelectionSheet(
                buildings: viewModel.assignedBuildings,
                onSelect: { building in
                    Task { await viewModel.handleClockIn(building: building) }
                    showBuildingList = false
                },
                onCancel: { showBuildingList = false }
            )
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    private var mapBackground: some View {
        Map(interactionModes: []) // A non-interactive map for the background effect
            .mapStyle(.standard(elevation: .realistic))
            .blur(radius: 4)
            .overlay(Color.black.opacity(0.5))
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
                Task { await viewModel.handleClockInToggle() }
            } else {
                // Show the building selection sheet if not clocked in
                showBuildingList = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isClockedIn ? "location.fill" : "location.slash")
                    .font(.title3)
                    .foregroundColor(viewModel.isClockedIn ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isClockedIn ? "Clocked In" : "Clock In")
                        .font(.headline).foregroundColor(.white)
                    Text(viewModel.isClockedIn ? "Working at \(viewModel.currentSession?.buildingName ?? "...")" : "Select a building to start your shift")
                        .font(.caption).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.6))
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

            ProgressView(value: viewModel.taskProgress?.percentage ?? 0, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))

            HStack {
                Text("\(Int(viewModel.taskProgress?.percentage ?? 0))% Complete")
                Spacer()
                Text("\(viewModel.taskProgress?.completed ?? 0)/\(viewModel.taskProgress?.total ?? 0) Tasks")
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
                Text("\(viewModel.assignedBuildings.count) assigned")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.assignedBuildings.prefix(6)) { building in
                    MySitesCard(building: building)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Reusable Site Card
private struct MySitesCard: View {
    let building: NamedCoordinate
    
    var body: some View {
        VStack(spacing: 0) {
            // Use a placeholder if the asset is missing
            if let assetName = building.imageAssetName, !assetName.isEmpty, let uiImage = UIImage(named: assetName) {
                Image(uiImage: uiImage)
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(height: 80)
            } else {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 80)
                    .overlay(Image(systemName: "building.2").foregroundColor(.white))
            }
            
            VStack {
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 35) // Ensure consistent height
            }
            .padding(8)
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .clipped()
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
            .navigationBarItems(leading: Button("Cancel", action: onCancel))
        }
        .preferredColorScheme(.dark)
    }
}


// MARK: - Preview
struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = NewAuthManager.shared
        // Simulate a logged-in user for the preview
        Task {
            try? await authManager.login(email: "dutankevin1@gmail.com", password: "password")
        }
        
        return WorkerDashboardView()
            .environmentObject(authManager)
    }
}
