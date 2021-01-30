// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorSummaryView: View {
    let request: URLRequest
    let response: URLResponse?
    let error: Error?

    private var httpResponse: HTTPURLResponse? {
        response as? HTTPURLResponse
    }

    private var isSuccess: Bool {
        error == nil && (200..<400).contains(httpResponse?.statusCode ?? 200)
    }

    private var responseHeaders: [String: String]? {
        httpResponse?.allHeaderFields as? [String: String]
    }

    var body: some View {
        ScrollView {
            VStack {
                responseSummaryView
                Spacer()
            }.padding(10)
        }
    }

    private var responseSummaryView: some View {
        KeyValueSectionView(
            title: "Summary",
            items: itemsForSummary,
            tintColor: isSuccess ? .systemGreen : .systemRed
        )
    }

    // MARK: Data Access

    private var itemsForSummary: [(String, String)] {
        [("URL", request.url?.absoluteString ?? "–"),
         ("Method", request.httpMethod ?? "–"),
         ("Status Code", httpResponse.map { "\($0.statusCode)" } ?? "–")]
    }
}

#if DEBUG
struct NetworkInspectorSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorSummaryView(
                request: MockDataTask.first.request,
                response: MockDataTask.first.response,
                error: nil
            )
        }
    }
}


#endif
