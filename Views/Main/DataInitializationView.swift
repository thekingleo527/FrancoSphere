//
//  DataInitializationView.swift
//  FrancoSphere
//
//  ✅ V6.0: Cleaned up to remove duplicate InitializationViewModel.
//  This view may be deprecated or refactored later.
//

import SwiftUI

struct DataInitializationView: View {
    @Binding var isInitialized: Bool
    
    // This view now relies on a parent to pass in the ViewModel if needed,
    // or it can be refactored to use the shared instance.
    // For now, we provide a simple placeholder.

    var body: some View {
        VStack {
            Text("Data Initialization...")
            ProgressView()
        }
        .onAppear {
            // Simulate work and then set to initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isInitialized = true
            }
        }
    }
}
