//
//  WelcomeView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 20/05/2026.
//

import SwiftUI
import Photos

struct WelcomeView: View {
    @Bindable var viewModel: PhotoDeckViewModel
    @State private var years: [Int] = []
    @State private var isLoadingYears = true
    @State private var sourceMode: SourceMode = .all
    @State private var selectedYear: Int = 2025
    @State private var showInfo = false
    @State private var appeared = false
    let onStart: () -> Void

    private let service = PhotoLibraryService.shared

    enum SourceMode: String, CaseIterable {
        case all = "Wszystkie"
        case favorites = "Ulubione"
        case year = "Rok"
    }

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

            VStack(spacing: 0) {
                // Fixed logo at top
                Image("iconKF")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 50)
                    .padding(.bottom, 50)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: appeared)

                if isLoadingYears {
                    Spacer()
                    SpinnerView()
                        .offset(y: -34)
                    Spacer()
                } else {
                    Spacer().frame(height: 4)

                    // Content
                    VStack(spacing: 50) {
                        // Section: Źródło
                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeader(String(localized: "photo_scope"), icon: "photo.on.rectangle.angled")

                            HStack(spacing: 10) {
                                tileButton(String(localized: "all_photos"), icon: "photo.stack", selected: sourceMode == .all) {
                                    sourceMode = .all
                                }
                                tileButton(String(localized: "favorites"), icon: "star.fill", selected: sourceMode == .favorites) {
                                    sourceMode = .favorites
                                }
                                yearMenuButton
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.1), value: appeared)

                        // Section: Kolejność
                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeader(String(localized: "display_order"), icon: "arrow.up.arrow.down")

                            HStack(spacing: 10) {
                                tileButton(String(localized: "newest"), icon: "arrow.down", selected: viewModel.sortOrder == .newest) {
                                    viewModel.sortOrder = .newest
                                }
                                tileButton(String(localized: "oldest"), icon: "arrow.up", selected: viewModel.sortOrder == .oldest) {
                                    viewModel.sortOrder = .oldest
                                }
                                tileButton(String(localized: "random"), icon: "shuffle", selected: viewModel.sortOrder == .random) {
                                    viewModel.sortOrder = .random
                                }
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.2), value: appeared)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }

                // Fixed button at bottom
                Button {
                    applySource()
                    if sourceMode == .favorites {
                        Task { await viewModel.startFavoritesSession() }
                    } else {
                        onStart()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("start_session")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 240)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("turqLight"))
                .glassEffect(.regular.interactive())
                .padding(.bottom, 30)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.3), value: appeared)
            }

            // Info button
            VStack {
                HStack {
                    Spacer()
                    Button { showInfo = true } label: {
                        Image(systemName: "info.circle")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 56)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.25), value: sourceMode)
        .sheet(isPresented: $showInfo) {
            infoSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task {
            let status = await service.requestAuthorization()
            guard status == .authorized || status == .limited else { return }
            years = service.availableYears()
            if let first = years.first { selectedYear = first }
            isLoadingYears = false
            try? await Task.sleep(for: .milliseconds(50))
            appeared = true
        }
    }

    // MARK: - Info Sheet

    private var infoSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("photo_scope", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                    Text("photo_scope_description")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("display_order", systemImage: "arrow.up.arrow.down")
                        .font(.headline)
                    Text("display_order_description")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle(Text("info"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showInfo = false } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func sectionHeader(_ title: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func tileButton(_ label: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(selected ? .white : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(selected ? Color("turqLight").opacity(0.4) : Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? Color("turqLight") : .white.opacity(0.1), lineWidth: selected ? 2 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .glassEffect(selected ? .regular.interactive() : .regular, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var yearMenuButton: some View {
        let isSelected = sourceMode == .year
        return Menu {
            Picker(String(localized: "year"), selection: Binding(
                get: { selectedYear },
                set: { selectedYear = $0; sourceMode = .year }
            )) {
                ForEach(years, id: \.self) { year in
                    Text(verbatim: "\(year)").tag(year)
                }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.body)
                Text(verbatim: isSelected ? "\(selectedYear)" : String(localized: "year"))
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(isSelected ? Color("turqLight").opacity(0.4) : Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color("turqLight") : .white.opacity(0.1), lineWidth: isSelected ? 2 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .glassEffect(isSelected ? .regular.interactive() : .regular, in: .rect(cornerRadius: 14))
        }
    }

    private func applySource() {
        switch sourceMode {
        case .all: viewModel.selectedYear = nil
        case .favorites: viewModel.selectedYear = nil
        case .year: viewModel.selectedYear = selectedYear
        }
    }
}


private struct SpinnerView: View {
    @State private var rotation: Double = 0

    var body: some View {
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
    }
}
