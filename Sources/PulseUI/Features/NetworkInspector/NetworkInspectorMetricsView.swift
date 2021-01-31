// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

// MARK: - View

struct NetworkInspectorMetricsView: View {
    let model: NetworkInspectorMetricsViewModel

    var body: some View {
        ScrollView {
            TimingView(model: model.timingModel)
                .padding()

            Spacer(minLength: 32)

            KeyValueSectionView(title: "Total", items: [
                ("Duration", formatDuration(model.metrics.taskInterval.duration))
            ], tintColor: .secondaryLabel)
            .padding()
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

    func makeRow(title: String, color: Color, from: Date, to: Date) -> TimingRowViewModel {
        let duration = to.timeIntervalSince(from)
        let start = from.timeIntervalSince(taskInterval.start) / taskInterval.duration
        let length = duration / taskInterval.duration
        return TimingRowViewModel(title: title, value: formatDuration(duration), color: color, start: CGFloat(start), length: CGFloat(length))
    }

    for transaction in metrics.transactions {
        guard let fetchType = URLSessionTaskMetrics.ResourceFetchType(rawValue: transaction.resourceFetchType) else {
            continue
        }

        switch fetchType {
        case .localCache:
            if let requestStartDate = transaction.requestStartDate, let responseEndDate = transaction.responseEndDate {
                let section = TimingRowSectionViewModel(
                    title: "Local Cache",
                    items: [
                        makeRow(title: "Cache Lookup", color: .yellow, from: requestStartDate, to: responseEndDate)
                    ])
                sections.append(section)
            }
        case .networkLoad:
            continue
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
                .previewDisplayName("Dark")
                .environment(\.colorScheme, .dark)
        }
    }
}

private let mockModel = NetworkInspectorMetricsViewModel(
    metrics: MockDataTask.login.metrics
)
#endif
