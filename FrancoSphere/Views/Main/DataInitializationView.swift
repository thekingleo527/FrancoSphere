//
//  DataInitializationView.swift
//  FrancoSphere
//
//  ✅ V6.0: Cleaned up to remove duplicate InitializationViewModel.
//

import SwiftUI

struct DataInitializationView: View {
    @State var isInitialized: Bool
    
    var body: some View {
        VStack {
            Text("Data Initialization...")
            ProgressView()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInitialized = true
            }
        }
    }
}
