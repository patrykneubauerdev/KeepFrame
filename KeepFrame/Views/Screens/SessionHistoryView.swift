//
//  SessionHistoryView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 20/05/2026.
//

import SwiftUI
import SwiftData

struct SessionHistoryView: View {
    @Query(sort: \SessionRecord.startDate, order: .reverse)
    private var sessions: [SessionRecord]

    var body: some View {
        List(sessions) { session in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(session.startDate, style: .date)
                        .font(.headline)
                    Spacer()
                    if session.isActive {
                        Text("Aktywna")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 16) {
                    Label("\(session.deletedCount)", systemImage: "trash")
                        .foregroundStyle(.red)
                    Label("\(session.keptCount)", systemImage: "checkmark")
                        .foregroundStyle(.green)
                    Label("\(session.favoritedCount)", systemImage: "star.fill")
                        .foregroundStyle(.yellow)
                }
                .font(.subheadline)

                if let end = session.endDate {
                    Text("Zakończona: \(end, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Historia sesji")
    }
}
