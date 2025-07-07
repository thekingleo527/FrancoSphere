//
//  InitializationView.swift
//  FrancoSphere
//
//  ✅ V6.0: This is the single, authoritative definition for the InitializationView.
//  ✅ It now consumes the InitializationViewModel from its own separate file, fixing all redeclaration errors.
//

import SwiftUI

struct InitializationView: View {
    @ObservedObject var viewModel: InitializationViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.25), Color(red: 0.15, green: 0.2, blue: 0.35)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("FrancoSphere")
                        .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)

                    Text("Property Operations Management")
                        .font(.subheadline).foregroundColor(.white.opacity(0.7))
                }

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 4)
                        
                        Text(viewModel.currentStep)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .animation(.none, value: viewModel.currentStep)
                    }
                    ProgressView().scaleEffect(1.2).tint(.blue)
                }.frame(maxWidth: 300)

                if let error = viewModel.initializationError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.title2).foregroundColor(.orange)
                        Text("Initialization Failed").font(.headline).foregroundColor(.orange)
                        Text(error).font(.caption).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.startInitialization() }
                        }.buttonStyle(.bordered).tint(.orange)
                    }.padding(20).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
