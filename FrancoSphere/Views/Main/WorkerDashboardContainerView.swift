//
//  WorkerDashboardContainerView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  WorkerDashboardContainerView.swift
//  FrancoSphere
//
//  This view acts as a factory and router for the worker experience.
//  It creates the ViewModel and decides whether to show the standard or simplified dashboard.
//

import SwiftUI

struct WorkerDashboardContainerView: View {
    // Create the ViewModel here. It becomes the single source of truth for all worker views.
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager

    var body: some View {
        Group {
            if viewModel.isLoading {
                // Show a loading view while the initial data (including capabilities) is fetched.
                ProgressView("Loading Your Dashboard...")
            } else if viewModel.workerCapabilities?.simplifiedInterface == true {
                // If the worker has simplified capabilities, show the simplified dashboard.
                SimplifiedDashboard(viewModel: viewModel)
            } else {
                // Otherwise, show the full-featured standard dashboard.
                WorkerDashboardView(viewModel: viewModel)
            }
        }
        .task {
            // Load all necessary data for the worker when this container appears.
            // This single data load will power either dashboard version.
            await viewModel.loadInitialData()
        }
    }
}