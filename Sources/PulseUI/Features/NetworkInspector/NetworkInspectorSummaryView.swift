// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import Pulse

struct NetworkInspectorSummaryView: View {
    let model: NetworkInspectorSummaryViewModel

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
            items: model.itemsForSummary,
            tintColor: tintColor
        )
    }

    private var tintColor: UXColor {
        guard model.response != nil else {
            return .systemGray
        }
        return model.isSuccess ? .systemGreen : .systemRed
    }
}

struct NetworkInspectorSummaryViewModel {
    let request: NetworkLoggerRequest?
    let response: NetworkLoggerResponse?
    let responseBody: Data?
    let error: NetworkLoggerError?
    let metrics: NetworkLoggerMetrics?

    var isSuccess: Bool {
        guard let response = response else {
            return false
        }
        return error == nil && (200..<400).contains(response.statusCode ?? 200)
    }

    var itemsForSummary: [(String, String)] {
        [("URL", request?.url?.absoluteString ?? "–"),
         ("Method", request?.httpMethod ?? "–"),
         ("Status Code", response?.statusCode.map(descriptionForStatusCode) ?? "–")]
    }
}

private func descriptionForStatusCode(_ statusCode: Int) -> String {
    switch statusCode {
    case 200: return "200 (OK)"
    default: return "\(statusCode) (\( HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized))"
    }
}

#if DEBUG
struct NetworkInspectorSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorSummaryView(model: mockModel)
        }
    }
}

private let mockModel = NetworkInspectorSummaryViewModel(
    request: NetworkLoggerRequest(urlRequest: MockDataTask.login.request),
    response: NetworkLoggerResponse(urlResponse: MockDataTask.login.response),
    responseBody: MockDataTask.login.responseBody,
    error: nil,
    metrics: nil
)
#endif
