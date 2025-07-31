//
//  AdminDashboardContainerView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  AdminDashboardContainerView.swift
//  FrancoSphere
//

import SwiftUI

struct AdminDashboardContainerView: View {
    // This view creates the ViewModel for the admin experience.
    @StateObject private var viewModel = AdminDashboardViewModel()

    var body: some View {
        AdminDashboardView(viewModel: viewModel)
    }
}