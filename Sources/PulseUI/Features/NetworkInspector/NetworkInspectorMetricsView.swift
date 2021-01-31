// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

// MARK: - View

struct NetworkInspectorMetricsView: View {
    let model: NetworkInspectorMetricsViewModel

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
                    TimingView(model: model.timingModel, width: geo.size.width)
                        .padding()

                    KeyValueSectionView(title: "Total", items: [
                        ("Duration", formatDuration(model.metrics.taskInterval.duration))
                    ], tintColor: .secondaryLabel)
                    .padding()
                }
            }
        }
    }
}

// MARK: - ViewModel

final class NetworkInspectorMetricsViewModel {
    let metrics: NetworkLoggerMetrics
    let timingModel: [TimingRowSectionViewModel]

    init(metrics: NetworkLoggerMetrics) {
        self.metrics = metrics
        self.timingModel = makeTiming(metrics: metrics)
    }
}


private func makeTiming(metrics: NetworkLoggerMetrics) -> [TimingRowSectionViewModel] {
    let taskInterval = metrics.taskInterval

    var sections = [TimingRowSectionViewModel]()

    func makeRow(title: String, color: UXColor, from: Date, to: Date?) -> TimingRowViewModel {
        let start = CGFloat(from.timeIntervalSince(taskInterval.start) / taskInterval.duration)
        let duration = to.map { $0.timeIntervalSince(from) }
        let length = duration.map { CGFloat($0 / taskInterval.duration) }
        let value = duration.map(formatDuration) ?? "–"
        return TimingRowViewModel(title: title, value: value, color: Color(color), start: CGFloat(start), length: length ?? 1)
    }

    for transaction in metrics.transactions {
        guard let fetchType = URLSessionTaskMetrics.ResourceFetchType(rawValue: transaction.resourceFetchType) else {
            continue
        }

        switch fetchType {
        case .localCache:
            if let requestStartDate = transaction.requestStartDate,
               let responseEndDate = transaction.responseEndDate {
                let section = TimingRowSectionViewModel(
                    title: "Local Cache",
                    items: [
                        makeRow(title: "Cache Lookup", color: .yellow, from: requestStartDate, to: responseEndDate)
                    ])
                sections.append(section)
            }
        case .networkLoad:
            var scheduling: [TimingRowViewModel] = []
            var connection: [TimingRowViewModel] = []
            var response: [TimingRowViewModel] = []

            if let domainLookupStartDate = transaction.domainLookupStartDate {
                connection.append(makeRow(title: "DNS", color: .systemPurple, from: domainLookupStartDate, to: transaction.domainLookupEndDate))
            }
            if let connectStartDate = transaction.connectStartDate {
                connection.append(makeRow(title: "TCP", color: .systemYellow, from: connectStartDate, to: transaction.connectEndDate))
            }
            if let secureConnectionStartDate = transaction.secureConnectionStartDate {
                connection.append(makeRow(title: "Secure", color: .systemRed, from: secureConnectionStartDate, to: transaction.secureConnectionEndDate))
            }
            if !scheduling.isEmpty {
                sections.append(TimingRowSectionViewModel(title: "Connection", items: connection))
            }
            if !connection.isEmpty {
                sections.append(TimingRowSectionViewModel(title: "Connection", items: connection))
            }
            if !response.isEmpty {
                sections.append(TimingRowSectionViewModel(title: "Response", items: connection))
            }
        default:
            continue
        }
    }

    return sections
}

// MARK: - Private

private func formatDuration(_ timeInterval: TimeInterval) -> String {
    if timeInterval < 0.01 {
        return String(format: "%.2fms", timeInterval * 1000)
    }
    if timeInterval < 0.95 {
        return String(format: "%.1fms", timeInterval * 1000)
    }
    if timeInterval < 200 {
        return String(format: "%.1fs", timeInterval)
    }
    let minutes = timeInterval / 60
    return String(format: "%.1fmin", minutes)
}

// MARK: - Preview

#if DEBUG
struct NetworkInspectorMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorMetricsView(model: mockModel)
                .previewDisplayName("Light")
                .environment(\.colorScheme, .light)
            
            NetworkInspectorMetricsView(model: mockModel)
                .background(Color(UXColor.systemBackground))
                .previewDisplayName("Dark")
                .environment(\.colorScheme, .dark)
        }
    }
}

private let mockModel = NetworkInspectorMetricsViewModel(
    metrics: MockDataTask.login.metrics
)
#endif
