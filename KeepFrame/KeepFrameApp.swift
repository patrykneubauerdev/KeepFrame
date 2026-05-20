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
        }
        .modelContainer(for: SessionRecord.self)
    }
}

private struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PhotoDeckViewModel()

    var body: some View {
        NavigationStack {
            if viewModel.hasActiveSession {
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
