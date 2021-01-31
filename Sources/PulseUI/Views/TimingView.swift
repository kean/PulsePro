// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

struct TimingView: View {
    let model: [TimingRowSectionViewModel]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                ForEach(model, id: \.self.title) {
                    TimingSectionView(model: $0, width: geo.size.width)
                }
            }
        }
    }
}

private struct TimingSectionView: View {
    let model: TimingRowSectionViewModel
    let width: CGFloat

    var body: some View {
        VStack {
            HStack {
                Text(model.title)
                    .font(.headline)
                    .foregroundColor(Color(UXColor.label))
                Spacer()
            }

            VStack(spacing: 6) {
                ForEach(model.items, id: \.self.title) {
                    TimingRowView(model: $0, width: width)
                }
            }
        }
    }
}

private struct TimingRowView: View {
    let model: TimingRowViewModel
    let width: CGFloat

    static let rowHeight: CGFloat = 14
    static let titleWidth: CGFloat = 80
    static let valueWidth: CGFloat = 60

    var body: some View {
        HStack {
            let barWidth = width - TimingRowView.titleWidth - TimingRowView.valueWidth
            Text(model.title)
                .font(.footnote)
                .foregroundColor(Color(UXColor.secondaryLabel))
                .frame(width: TimingRowView.titleWidth, alignment: .leading)
            Spacer()
                .frame(width: barWidth * model.start)
            RoundedRectangle(cornerRadius: 3)
                .fill(model.color)
            Spacer()
                .frame(width: barWidth * (1 - model.end))
            Text(model.value)
                .font(.footnote)
                .foregroundColor(Color(UXColor.secondaryLabel))
                .frame(width: TimingRowView.valueWidth, alignment: .trailing)
        }
        .frame(height: TimingRowView.rowHeight)
    }
}

struct TimingRowSectionViewModel {
    let title: String
    let items: [TimingRowViewModel]
}

struct TimingRowViewModel {
    let title: String
    let value: String
    let color: Color
    // [0, 1]
    let start: CGFloat
    // [0, 1]
    let end: CGFloat
}

#if DEBUG
struct TimingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimingView(model: mockModel)
                .previewLayout(.fixed(width: 320, height: 500))
                .previewDisplayName("Light")
                .environment(\.colorScheme, .light)

            TimingView(model: mockModel)
                .previewLayout(.fixed(width: 320, height: 500))
                .previewDisplayName("Dark")
                .background(Color(UXColor.systemBackground))
                .environment(\.colorScheme, .dark)
        }
    }
}

private let mockModel = [
    TimingRowSectionViewModel(title: "Response", items: [
        TimingRowViewModel(title: "Waiting", value: "41.2ms", color: .blue, start: 0.0, end: 0.4),
        TimingRowViewModel(title: "Download", value: "0.2ms", color: .red, start: 0.4, end: 0.45)
    ]),
    TimingRowSectionViewModel(title: "Cache Lookup", items: [
        TimingRowViewModel(title: "Waiting", value: "50.2ms", color: .yellow, start: 0.45, end: 0.95),
        TimingRowViewModel(title: "Download", value: "5.2ms", color: .green, start: 0.95, end: 1)
    ])
]
#endif
