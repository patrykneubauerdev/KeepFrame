//
//  KeepFrameApp.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI
import SwiftData

@main
struct KeepFrameApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: SessionRecord.self)
    }
}

private struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PhotoDeckViewModel()

    var body: some View {
        NavigationStack {
            if !viewModel.isSessionChecked {
                LoadingView()
            } else if viewModel.hasActiveSession {
                KeepFrameView(viewModel: viewModel)
            } else {
                WelcomeView(viewModel: viewModel) {
                    Task { await viewModel.startNewSession() }
                }
            }
        }
        .onAppear { viewModel.setup(modelContext: modelContext) }
    }
}

private struct LoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color("turq").ignoresSafeArea()
            RadialGradient(
                colors: [.clear, Color("turqDark").opacity(0.8)],
                center: .center,
                startRadius: 100,
                endRadius: 350
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("iconKF")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }
            .offset(y: 28)
        }
    }
}
