// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

// MARK: - View

struct NetworkInspectorMetricsDetailsView: View {
    @Environment(\.horizontalSizeClass) var sizeClass: UserInterfaceSizeClass?

    let model: NetworkMetricsDetailsViewModel

    var body: some View {
        #if os(iOS)
        if sizeClass == .regular {
            let rows = model.sections.chunked(into: 2).enumerated().map {
                Row(index: $0, items: $1)
            }
            ForEach(rows, id: \.index) { row in
                HStack {
                    ForEach(row.items, id: \.title) { item in
                        VStack {
                            KeyValueSectionView(model: item)
                            Spacer()
                                .layoutPriority(1)
                        }
                    }
                }
            }
        } else {
            ForEach(model.sections, id: \.title) {
                KeyValueSectionView(model: $0)
            }
        }
        #endif
    }
}

private struct Row {
    let index: Int
    let items: [KeyValueSectionViewModel]
}

// MARK: - ViewModel

struct NetworkMetricsDetailsViewModel {
    let sections: [KeyValueSectionViewModel]

    init(metrics: NetworkLoggerTransactionMetrics) {
        self.sections = [
            makeTransferSection(for: metrics),
            makeProtocolSection(for: metrics),
            makeMiscSection(for: metrics),
            makeSecuritySection(for: metrics)
        ].compactMap { $0 }
    }
}

private func makeTransferSection(for metrics: NetworkLoggerTransactionMetrics) -> KeyValueSectionViewModel {
    KeyValueSectionViewModel(title: "Data Transfer", color: .secondaryLabel, items: [
        ("Request Body", formatBytes(metrics.countOfRequestBodyBytesBeforeEncoding)),
        ("Request Body (Encoded)", formatBytes(metrics.countOfRequestBodyBytesSent)),
        ("Request Headers", formatBytes(metrics.countOfRequestHeaderBytesSent)),
        ("Response Body", formatBytes(metrics.countOfResponseBodyBytesReceived)),
        ("Response Body (Decoded)", formatBytes(metrics.countOfResponseBodyBytesAfterDecoding)),
        ("Response Headers", formatBytes(metrics.countOfResponseHeaderBytesReceived))
    ])
}

private func makeProtocolSection(for metrics: NetworkLoggerTransactionMetrics) -> KeyValueSectionViewModel {
    KeyValueSectionViewModel(title: "Protocol", color: .secondaryLabel, items: [
        ("Network Protocol", metrics.networkProtocolName),
        ("Remote Address", metrics.remoteAddress),
        ("Remote Port", metrics.remotePort.map(String.init)),
        ("Local Address", metrics.localAddress),
        ("Local Port", metrics.localPort.map(String.init))
    ])
}

private func makeSecuritySection(for metrics: NetworkLoggerTransactionMetrics) -> KeyValueSectionViewModel? {
    guard let suite = metrics.negotiatedTLSCipherSuite.flatMap(tls_ciphersuite_t.init(rawValue:)),
          let version = metrics.negotiatedTLSProtocolVersion.flatMap(tls_protocol_version_t.init(rawValue:)) else {
        return nil
    }
    return KeyValueSectionViewModel(title: "Security", color: .secondaryLabel, items: [
        ("Cipher Suite", suite.description),
        ("Protocol Version", version.description)
    ])
}

private func makeMiscSection(for metrics: NetworkLoggerTransactionMetrics) -> KeyValueSectionViewModel {
    return KeyValueSectionViewModel(title: "Characteristics", color: .secondaryLabel, items: [
        ("Cellular", metrics.isCellular.description),
        ("Expensive", metrics.isExpensive.description),
        ("Constrained", metrics.isConstrained.description),
        ("Proxy Connection", metrics.isProxyConnection.description),
        ("Reused Connection", metrics.isReusedConnection.description),
        ("Multipath", metrics.isMultipath.description),
    ])
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
struct NetworkInspectorMetricsDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorMetricsDetailsView(model: mockModel)
                .previewDisplayName("Light")
                .environment(\.colorScheme, .light)

            NetworkInspectorMetricsDetailsView(model: mockModel)
                .background(Color(UXColor.systemBackground))
                .previewDisplayName("Dark")
                .environment(\.colorScheme, .dark)
        }
    }
}

private let mockModel = NetworkMetricsDetailsViewModel(
    metrics: MockDataTask.login.metrics.transactions.first!
)
#endif
