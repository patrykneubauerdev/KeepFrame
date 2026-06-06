//
//  SessionHistoryView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 20/05/2026.
//

import SwiftUI
import SwiftData

struct SessionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SessionRecord.startDate, order: .reverse)
    private var sessions: [SessionRecord]
    @State private var appeared = false
    @State private var selectedSession: SessionRecord?

    private var activeSessions: [SessionRecord] {
        sessions.filter { $0.isActive }
    }

    private var completedSessions: [SessionRecord] {
        sessions.filter { !$0.isActive }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if !activeSessions.isEmpty {
                    sessionSection(title: "Trwająca sesja", sessions: activeSessions, startIndex: 0)
                }

                if !completedSessions.isEmpty {
                    sessionSection(title: "Wcześniejsze", sessions: completedSessions, startIndex: activeSessions.count)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .safeAreaPadding(.bottom, 50)
        }
        .mask(
            VStack(spacing: 0) {
                Color.black
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
            }
            .ignoresSafeArea()
        )
        .background(Color("turq").opacity(0.15).ignoresSafeArea())
        .navigationTitle("Historia sesji")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .task { appeared = true }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
    }

    private func tapped(_ session: SessionRecord) {
        if session.isActive {
            dismiss()
        } else {
            selectedSession = session
        }
    }

    private func sessionSection(title: String, sessions: [SessionRecord], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.bold())
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.leading, 4)

            ForEach(Array(zip(sessions.indices, sessions)), id: \.1.persistentModelID) { i, session in
                SessionCard(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture { tapped(session) }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(
                        .spring(duration: 0.5, bounce: 0.3)
                        .delay(Double(startIndex + i) * 0.06),
                        value: appeared
                    )
            }
        }
    }
}

// MARK: - Session Card

private struct SessionCard: View {
    let session: SessionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateLabel)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(timeLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if session.isActive {
                    Text("Aktywna")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("turq"), in: Capsule())
                } else {
                    Text("Zakończona")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("turq").opacity(0.3), in: Capsule())
                }
            }

            HStack(spacing: 16) {
                statItem(icon: "trash.fill", value: session.deletedCount)
                statItem(icon: "star.fill", value: session.favoritedCount)
                statItem(icon: "checkmark", value: session.keptCount)
                Spacer()
                Text("\(compactNumber(session.totalReviewed)) przejrzanych")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color("turq").opacity(session.isActive ? 0.45 : 0.3))
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(session.isActive ? 0.35 : 0.2), lineWidth: 0.5)
        )
    }

    private var dateLabel: String {
        let d = session.startDate
        let cal = Calendar.current
        let day = String(format: "%02d", cal.component(.day, from: d))
        let month = String(format: "%02d", cal.component(.month, from: d))
        let year = cal.component(.year, from: d)
        return "\(day).\(month).\(year)"
    }

    private var timeLabel: String {
        let fmt: Date.FormatStyle = .dateTime.hour().minute().second()
        let start = session.startDate.formatted(fmt)
        if let end = session.endDate {
            return "\(start) – \(end.formatted(fmt))"
        }
        return "od \(start)"
    }

    private func statItem(icon: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(compactNumber(value))
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func compactNumber(_ value: Int) -> String {
        switch value {
        case ..<1_000: return "\(value)"
        case ..<1_000_000: return String(format: "%.1fk", Double(value) / 1_000)
        default: return String(format: "%.1fM", Double(value) / 1_000_000)
        }
    }
}
