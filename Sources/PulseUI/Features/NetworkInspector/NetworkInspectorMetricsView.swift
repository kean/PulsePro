// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

// MARK: - View

struct NetworkInspectorMetricsView: View {
    let model: NetworkInspectorMetricsViewModel

    var body: some View {
        Text("Timing View")

        GeometryReader { geo in
//            TimingRowView(width: geo.size.width)
            Text("123")
        }.padding()
    }
}

// MARK: - ViewModel

final class NetworkInspectorMetricsViewModel {
    private let metrics: NetworkLoggerMetrics

    init(metrics: NetworkLoggerMetrics) {
        self.metrics = metrics
    }
}

// MARK: - Preview

#if DEBUG
struct NetworkInspectorMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorMetricsView(model: mockModel)
                .previewLayout(.fixed(width: 320, height: 500))
                .previewDisplayName("Light")
                .environment(\.colorScheme, .light)
            
            NetworkInspectorMetricsView(model: mockModel)
                .previewLayout(.fixed(width: 320, height: 500))
                .previewDisplayName("Dark")
                .environment(\.colorScheme, .dark)
        }
    }
}

private let mockModel = NetworkInspectorMetricsViewModel(
    metrics: MockDataTask.login.metrics
)
#endif
