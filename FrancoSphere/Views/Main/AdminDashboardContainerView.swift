
//  Created by Shawn Magloire on 7/31/25.
//


//
//  AdminDashboardContainerView.swift
//  FrancoSphere
//

import SwiftUI

struct AdminDashboardContainerView_WithEnvironment: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    
    var body: some View {
        AdminDashboardView()
            .environmentObject(viewModel)
    }
}
