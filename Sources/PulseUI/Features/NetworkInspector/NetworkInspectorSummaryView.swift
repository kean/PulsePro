// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import Pulse

// MARK: - View

struct NetworkInspectorSummaryView: View {
    let model: NetworkInspectorSummaryViewModel

    var body: some View {
        ScrollView {
            VStack {
                KeyValueSectionView(model: model.summaryModel)
                if let error = model.errorModel {
                    KeyValueSectionView(model: error)
                }
                Spacer()
            }.padding()
        }
    }
}

// MARK: - ViewModel

final class NetworkInspectorSummaryViewModel {
    private let request: NetworkLoggerRequest?
    private let response: NetworkLoggerResponse?
    private let responseBody: Data?
    private let error: NetworkLoggerError?
    private let metrics: NetworkLoggerMetrics?

    init(request: NetworkLoggerRequest?,
        response: NetworkLoggerResponse?,
        responseBody: Data?,
        error: NetworkLoggerError?,
        metrics: NetworkLoggerMetrics?) {
        self.request = request
        self.response = response
        self.responseBody = responseBody
        self.error = error
        self.metrics = metrics
    }

    private var isSuccess: Bool {
        guard let response = response else {
            return false
        }
        return error == nil && (200..<400).contains(response.statusCode ?? 200)
    }

    private var tintColor: UXColor {
        guard response != nil else {
            return .systemGray
        }
        return isSuccess ? .systemGreen : .systemRed
    }

    var summaryModel: KeyValueSectionViewModel {
        KeyValueSectionViewModel(
            title: "Summary",
            color: tintColor,
            items: [
                ("URL", request?.url?.absoluteString ?? "–"),
                ("Method", request?.httpMethod ?? "–"),
                ("Status Code", response?.statusCode.map(descriptionForStatusCode) ?? "–")
            ])
    }

    var errorModel: KeyValueSectionViewModel? {
        guard let error = error else { return nil }
        return KeyValueSectionViewModel(
            title: "Error",
            color: .systemRed,
            items: [
                ("Domain", error.domain),
                ("Code", descriptionForError(domain: error.domain, code: error.code)),
                ("Message", error.localizedDescription)
            ])
    }
}

// MARK: - Private

private func descriptionForError(domain: String, code: Int) -> String {
    guard domain == NSURLErrorDomain else {
        return "\(code)"
    }
    return "\(code) (\(descriptionForURLErrorCode(code)))"
}

private func descriptionForStatusCode(_ statusCode: Int) -> String {
    switch statusCode {
    case 200: return "200 (OK)"
    default: return "\(statusCode) (\( HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized))"
    }
}

// MARK: - Preview

#if DEBUG
struct NetworkInspectorSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorSummaryView(model: mockModel)

            NetworkInspectorSummaryView(model: mockFailureModel)
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

private let mockFailureModel = NetworkInspectorSummaryViewModel(
    request: NetworkLoggerRequest(urlRequest: MockDataTask.login.request),
    response: nil,
    responseBody: nil,
    error: NetworkLoggerError(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])),
    metrics: nil
)
#endif
