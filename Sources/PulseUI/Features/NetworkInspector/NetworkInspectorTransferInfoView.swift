// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

// MARK: - View

struct NetworkInspectorTransferInfoView: View {
    @Environment(\.colorScheme) var colorScheme

    let model: NetworkInspectorTransferInfoViewModel

    var body: some View {
        HStack {
            Spacer()
            makeView(title: "Bytes Sent", imageName: "icloud.and.arrow.up", total: model.totalBytesSent, headers: model.headersBytesSent, body: model.bodyBytesSent)
            Spacer()

            Divider()

            Spacer()
            makeView(title: "Bytes Received", imageName: "icloud.and.arrow.down", total: model.totalBytesRecieved, headers: model.headersBytesRecieved, body: model.bodyBytesRecieved)
            Spacer()
        }
    }

    private func makeView(title: String, imageName: String, total: String, headers: String, body: String) -> some View {
        VStack {
            Text(title)
                .font(.headline)
            HStack {
                #if os(iOS)
                Image(uiImage: UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .default)) ?? .init())
                #endif
                Text(total)
                    .font(.headline)
            }
            HStack(alignment: .center, spacing: 4) {
                VStack(alignment: .trailing) {
                    Text("Headers:")
                        .foregroundColor(Color(UXColor.label.withAlphaComponent(0.7)))
                        .font(.system(size: fontSize))
                    Text("Body:")
                        .foregroundColor(Color(UXColor.label.withAlphaComponent(0.7)))
                        .font(.system(size: fontSize))
                }
                VStack(alignment: .leading) {
                    Text(headers)
                        .font(.system(size: fontSize))
                    Text(body)
                        .font(.system(size: fontSize))
                }
            }
        }
    }
}

private var fontSize: CGFloat {
    #if os(iOS)
    return 15
    #else
    return 12
    #endif
}

private struct Row {
    let index: Int
    let items: [KeyValueSectionViewModel]
}

// MARK: - ViewModel

struct NetworkInspectorTransferInfoViewModel {
    let totalBytesSent: String
    let bodyBytesSent: String
    let headersBytesSent: String

    let totalBytesRecieved: String
    let bodyBytesRecieved: String
    let headersBytesRecieved: String

    init?(metrics: NetworkLoggerMetrics) {
        guard let metrics = metrics.transactions.last else { return nil }

        self.totalBytesSent = formatBytes(metrics.countOfRequestBodyBytesBeforeEncoding + metrics.countOfRequestHeaderBytesSent)
        self.bodyBytesSent = formatBytes(metrics.countOfRequestBodyBytesSent)
        self.headersBytesSent = formatBytes(metrics.countOfRequestHeaderBytesSent)

        self.totalBytesRecieved = formatBytes(metrics.countOfResponseBodyBytesReceived + metrics.countOfResponseHeaderBytesReceived)
        self.bodyBytesRecieved = formatBytes(metrics.countOfResponseBodyBytesReceived)
        self.headersBytesRecieved = formatBytes(metrics.countOfResponseHeaderBytesReceived)
    }
}

// MARK: - Private

private func formatBytes(_ count: Int64) -> String {
    guard count > 0 else {
        return "0"
    }
    return ByteCountFormatter.string(fromByteCount: count, countStyle: .file)
}
// MARK: - Preview

#if DEBUG
struct NetworkInspectorTransferInfoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorTransferInfoView(model: mockModel)
                .background(Color(UXColor.systemBackground))
                .previewDisplayName("Light")
                .environment(\.colorScheme, .light)

            NetworkInspectorTransferInfoView(model: mockModel)
                .background(Color(UXColor.systemBackground))
                .previewDisplayName("Dark")
                .environment(\.colorScheme, .dark)
        }
    }
}

private let mockModel = NetworkInspectorTransferInfoViewModel(
    metrics: MockDataTask.login.metrics
)!
#endif
