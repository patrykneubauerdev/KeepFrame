//
//  SwipeTutorialView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 02/07/2026.
//

import SwiftUI

struct SwipeTutorialView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 24))
                    .foregroundStyle(Color("turq"))
                    .symbolEffect(.pulse, options: .repeating)

                Text("browsing_photos")
                    .font(.headline)
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    tutorialRow(
                        icon: "arrow.left",
                        color: .red,
                        title: String(localized: "swipe_left"),
                        description: String(localized: "swipe_left_description")
                    )

                    tutorialRow(
                        icon: "arrow.right",
                        color: .green,
                        title: String(localized: "swipe_right"),
                        description: String(localized: "swipe_right_description")
                    )

                    tutorialRow(
                        icon: "arrow.up",
                        color: .yellow,
                        title: String(localized: "swipe_up"),
                        description: String(localized: "swipe_up_description")
                    )
                }
                .padding(.horizontal, 24)

                Text("can_use_buttons_below")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)

                Button { dismiss() } label: {
                    Text("understood")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .tint(Color("turq"))
                .buttonStyle(.borderedProminent)
                .glassEffect(.regular.interactive())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color("turq").opacity(0.15).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private func tutorialRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
