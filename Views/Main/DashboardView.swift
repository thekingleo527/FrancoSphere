//
//  DashboardView.swift
//  FrancoSphere
//
//  ✅ V6.0: Stabilized with a placeholder view to allow compilation.
//  This file needs to be fully refactored later using the new architecture.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Dashboard")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("This view has been temporarily disabled and needs to be refactored.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}
