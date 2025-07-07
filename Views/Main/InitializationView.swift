//
//  InitializationView.swift
//  FrancoSphere
//
//  ✅ V6.0: Cleaned up to consume the authoritative ViewModel.
//

import SwiftUI

struct InitializationView: View {
    @ObservedObject var viewModel: InitializationViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 30) {
                Text("FrancoSphere")
                    .font(.largeTitle).bold().foregroundColor(.white)
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                Text(viewModel.currentStep)
                    .foregroundColor(.secondary)
                if let error = viewModel.initializationError {
                    Text(error)
                        .font(.caption).foregroundColor(.red)
                }
            }
            .padding()
        }
    }
}
