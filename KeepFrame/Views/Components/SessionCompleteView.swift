//
//  SessionCompleteView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 02/07/2026.
//

import SwiftUI

struct SessionCompleteView: View {
    let totalReviewed: Int
    let trashCount: Int
    let onTrash: () -> Void
    let onEnd: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if totalReviewed == 0 {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 52))
                    .foregroundStyle(.white)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: appeared)

                Text("no_photos_found")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                Text("no_photos_found_description")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
            } else {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.white)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: appeared)

                Text("all_photos_reviewed")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                if trashCount > 0 {
                    Button(action: onTrash) {
                        Label("\(String(localized: "review_trash")) (\(trashCount))", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .tint(Color("turq"))
                    .buttonStyle(.bordered)
                    .glassEffect(.regular.interactive())
                    .padding(.horizontal, 35)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                }
            }

            Button(action: onEnd) {
                Text("end_session_button")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .tint(Color("turq"))
            .buttonStyle(.borderedProminent)
            .glassEffect(.regular.interactive())
            .padding(.horizontal, 35)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)

            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                appeared = true
            }
        }
    }
}
