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
    @State private var favoritesSelected = false
    let onStart: () -> Void

    private let service = PhotoLibraryService.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("iconKFturq")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("KeepFrame")
                .font(.largeTitle.bold())

            Text("Wybierz rok i zacznij porządkować zdjęcia")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if isLoadingYears {
                ProgressView()
            } else {
                yearPicker
            }

            sortPicker

            Spacer()

            Button {
                if favoritesSelected {
                    Task { await viewModel.startFavoritesSession() }
                } else {
                    onStart()
                }
            } label: {
                Label("Rozpocznij", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .task {
            let status = await service.requestAuthorization()
            guard status == .authorized || status == .limited else { return }
            years = service.availableYears()
            isLoadingYears = false
        }
    }

    private var yearPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Ulubione
                Button {
                    favoritesSelected = true
                    viewModel.selectedYear = nil
                } label: {
                    Label("Ulubione", systemImage: "star.fill")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(favoritesSelected ? Color.yellow : Color.gray.opacity(0.15))
                        .foregroundStyle(favoritesSelected ? .white : .primary)
                        .clipShape(Capsule())
                }

                // Wszystkie
                yearChip(label: "Wszystkie", year: nil)

                ForEach(years, id: \.self) { year in
                    yearChip(label: "\(year)", year: year)
                }
            }
            .padding(.horizontal)
        }
    }

    private func yearChip(label: String, year: Int?) -> some View {
        Button {
            favoritesSelected = false
            viewModel.selectedYear = year
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(!favoritesSelected && viewModel.selectedYear == year ? Color.accentColor : Color.gray.opacity(0.15))
                .foregroundStyle(!favoritesSelected && viewModel.selectedYear == year ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private var sortPicker: some View {
        Picker("Kolejność", selection: $viewModel.sortOrder) {
            ForEach(PhotoSortOrder.allCases, id: \.self) { order in
                Text(order.rawValue).tag(order)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 32)
    }
}
