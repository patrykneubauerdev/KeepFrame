//
//  KeepFrame.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI

struct KeepFrameView: View {
    @State private var viewModel = PhotoDeckViewModel()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                if let photo = viewModel.currentPhoto {
                    SwipeableCardView(photo: photo) { action in
                        viewModel.perform(action)
                    }
                    .id(photo.id)
                } else {
                    emptyState
                }
            }
            .frame(height: 420)

            HStack(spacing: 40) {
                ActionButton(icon: "xmark", color: .red) {
                    viewModel.perform(.delete)
                }
                ActionButton(icon: "questionmark", color: .yellow) {
                    viewModel.perform(.skip)
                }
                ActionButton(icon: "checkmark", color: .green) {
                    viewModel.perform(.keep)
                }
            }

            Text("\(viewModel.remainingCount) zdjęć pozostało")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Brak zdjęć do przejrzenia")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    KeepFrameView()
}
