//
//  ClientDashboardContainerView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  ClientDashboardContainerView.swift
//  FrancoSphere
//

import SwiftUI

struct ClientDashboardContainerView: View {
    // This view creates the ViewModel for the client experience.
    @StateObject private var viewModel = ClientDashboardViewModel()

    var body: some View {
        ClientDashboardView(viewModel: viewModel)
    }
}