// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

// MARK: - View

struct NetworkInspectorMetricsView: View {
    let model: NetworkInspectorMetricsViewModel

    var body: some View {
        ScrollView {
            GeometryReader { geo in
                VStack {
                    TimingView(model: model.timingModel, width: geo.size.width)
                    Spacer(minLength: 32)

                    if let details = model.details {
                        ForEach(details.sections, id: \.title) {
                            KeyValueSectionView(title: $0.title, items: $0.items, tintColor: $0.color)
                        }
                    }
                }
            }.padding()
        }
    }
}

// MARK: - ViewModel

final class NetworkInspectorMetricsViewModel {
    let metrics: NetworkLoggerMetrics
    fileprivate let timingModel: [TimingRowSectionViewModel]
    fileprivate let details: NetworkMetricsDetailsViewModel?

    init(metrics: NetworkLoggerMetrics) {
        self.metrics = metrics
        self.timingModel = makeTiming(metrics: metrics)

        self.details = metrics.transactions.first(where: {
            $0.resourceFetchType == URLSessionTaskMetrics.ResourceFetchType.networkLoad.rawValue
        }).map(NetworkMetricsDetailsViewModel.init)
    }
}

private struct NetworkMetricsDetailsViewModel {
    let sections: [NetworkMetricsDetailsSectionViewModel]

    init(metrics: NetworkLoggerTransactionMetrics) {
        self.sections = [
            makeTransferSection(for: metrics),
            makeProtocolSection(for: metrics),
            makeSecuritySection(for: metrics),
            makeMiscSection(for: metrics)
        ].compactMap { $0 }
    }
}

private struct NetworkMetricsDetailsSectionViewModel {
    let title: String
    let color: UXColor
    let items: [(String, String?)]
}

private func makeTransferSection(for metrics: NetworkLoggerTransactionMetrics) -> NetworkMetricsDetailsSectionViewModel {
    NetworkMetricsDetailsSectionViewModel(title: "Data Transfer", color: .secondaryLabel, items: [
        ("Request Body", formatBytes(metrics.countOfRequestBodyBytesBeforeEncoding)),
        ("Request Body (Encoded)", formatBytes(metrics.countOfRequestBodyBytesSent)),
        ("Request Headers", formatBytes(metrics.countOfRequestHeaderBytesSent)),
        ("Response Body", formatBytes(metrics.countOfResponseBodyBytesReceived)),
        ("Response Body (Decoded)", formatBytes(metrics.countOfResponseBodyBytesAfterDecoding)),
        ("Response Headers", formatBytes(metrics.countOfResponseHeaderBytesReceived))
    ])
}

private func makeProtocolSection(for metrics: NetworkLoggerTransactionMetrics) -> NetworkMetricsDetailsSectionViewModel {
    NetworkMetricsDetailsSectionViewModel(title: "Protocol", color: .secondaryLabel, items: [
        ("Network Protocol", metrics.networkProtocolName),
        ("Remote Address", metrics.remoteAddress),
        ("Remote Port", metrics.remotePort.map(String.init)),
        ("Local Address", metrics.localAddress),
        ("Local Port", metrics.localPort.map(String.init))
    ])
}

private func makeSecuritySection(for metrics: NetworkLoggerTransactionMetrics) -> NetworkMetricsDetailsSectionViewModel? {
    guard let suite = metrics.negotiatedTLSCipherSuite.flatMap(tls_ciphersuite_t.init(rawValue:)),
          let version = metrics.negotiatedTLSProtocolVersion.flatMap(tls_protocol_version_t.init(rawValue:)) else {
        return nil
    }
    return NetworkMetricsDetailsSectionViewModel(title: "Security", color: .secondaryLabel, items: [
        ("Cipher Suite", suite.description),
        ("Protocol Version", version.description)
    ])
}

private func makeMiscSection(for metrics: NetworkLoggerTransactionMetrics) -> NetworkMetricsDetailsSectionViewModel {
    return NetworkMetricsDetailsSectionViewModel(title: "Characteristics", color: .secondaryLabel, items: [
        ("Cellular", metrics.isCellular.description),
        ("Expensive", metrics.isExpensive.description),
        ("Constrained", metrics.isConstrained.description),
        ("Proxy Connection", metrics.isProxyConnection.description),
        ("Reused Connection", metrics.isReusedConnection.description),
        ("Multipath", metrics.isMultipath.description),
    ])
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
                        makeRow(title: "Lookup", color: .yellow, from: requestStartDate, to: responseEndDate)
                    ])
                sections.append(section)
            }
        case .networkLoad:
            var scheduling: [TimingRowViewModel] = []
            var connection: [TimingRowViewModel] = []
            var response: [TimingRowViewModel] = []

            let earliestEventDate = [
                transaction.requestStartDate,
                transaction.connectStartDate,
                transaction.domainLookupStartDate,
                transaction.responseStartDate,
                transaction.connectStartDate
            ]
            .compactMap { $0 }
            .sorted()
            .first

            if let fetchStartDate = transaction.fetchStartDate, let endDate = earliestEventDate {
                scheduling.append(makeRow(title: "Queued", color: .systemGray4, from: fetchStartDate, to: endDate))
            }

            if let domainLookupStartDate = transaction.domainLookupStartDate {
                connection.append(makeRow(title: "DNS", color: .systemPurple, from: domainLookupStartDate, to: transaction.domainLookupEndDate))
            }
            if let connectStartDate = transaction.connectStartDate {
                connection.append(makeRow(title: "TCP", color: .systemYellow, from: connectStartDate, to: transaction.connectEndDate))
            }
            if let secureConnectionStartDate = transaction.secureConnectionStartDate {
                connection.append(makeRow(title: "Secure", color: .systemRed, from: secureConnectionStartDate, to: transaction.secureConnectionEndDate))
            }

            if let requestStartDate = transaction.requestStartDate {
                response.append(makeRow(title: "Request", color: .systemGreen, from: requestStartDate, to: transaction.requestEndDate))
            }
            if let requestStartDate = transaction.requestStartDate, let responseStartDate = transaction.responseStartDate {
                response.append(makeRow(title: "Waiting", color: .systemGray3, from: requestStartDate, to: responseStartDate))
            }
            if let responseStartDate = transaction.responseStartDate {
                response.append(makeRow(title: "Download", color: .systemBlue, from: responseStartDate, to: transaction.responseEndDate))
            }

            if !scheduling.isEmpty {
                sections.append(TimingRowSectionViewModel(title: "Scheduling", items: scheduling))
            }
            if !connection.isEmpty {
                sections.append(TimingRowSectionViewModel(title: "Connection", items: connection))
            }
            if !response.isEmpty {
                sections.append(TimingRowSectionViewModel(title: "Response", items: response))
            }
        default:
            continue
        }
    }

    sections.append(TimingRowSectionViewModel(title: "Total", items: [
        makeRow(title: "Total", color: .systemGray2, from: taskInterval.start, to: taskInterval.end)
    ]))

    return sections
}

// MARK: - Private

private func formatDuration(_ timeInterval: TimeInterval) -> String {
    if timeInterval < 0.95 {
        return String(format: "%.1fms", timeInterval * 1000)
    }
    if timeInterval < 200 {
        return String(format: "%.1fs", timeInterval)
    }
    let minutes = timeInterval / 60
    if minutes < 60 {
        return String(format: "%.1fmin", minutes)
    }
    let hours = timeInterval / (60 * 60)
    return String(format: "%.1fh", hours)
}

private func formatBytes(_ count: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: count, countStyle: .file)
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
