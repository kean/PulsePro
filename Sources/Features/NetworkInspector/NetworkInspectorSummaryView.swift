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
                if let transfer = model.transferModel {
                    NetworkInspectorTransferInfoView(model: transfer)
                    Spacer(minLength: 32)
                }
                KeyValueSectionView(model: model.summaryModel)
                if let error = model.errorModel {
                    KeyValueSectionView(model: error)
                }
                if let timing = model.timingDetailsModel {
                    KeyValueSectionView(model: timing)
                }
                if let parameters = model.parametersModel {
                    KeyValueSectionView(model: parameters)
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

    convenience init(summary: NetworkLoggerSummary) {
        self.init(request: summary.request, response: summary.response, responseBody: summary.responseBody, error: summary.error, metrics: summary.metrics)
    }

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

    var transferModel: NetworkInspectorTransferInfoViewModel? {
        metrics.flatMap(NetworkInspectorTransferInfoViewModel.init)
    }

    var timingDetailsModel: KeyValueSectionViewModel? {
        guard let metrics = metrics else { return nil }
        return KeyValueSectionViewModel(title: "Timing", color: .systemBlue, items: [
            ("Start Date", dateFormatter.string(from: metrics.taskInterval.start)),
            ("Duration", DurationFormatter.string(from: metrics.taskInterval.duration)),
            ("Redirect Count", metrics.redirectCount.description),
        ])
    }

    var parametersModel: KeyValueSectionViewModel? {
        guard let request = request else { return nil }
        return KeyValueSectionViewModel(title: "Request Parameters", color: .systemGray, items: [
            ("Cache Policy", URLRequest.CachePolicy(rawValue: request.cachePolicy).map { $0.description }),
            ("Timeout Interval", DurationFormatter.string(from: request.timeoutInterval)),
            ("Allows Cellular Access", request.allowsCellularAccess.description),
            ("Allows Expensive Network Access", request.allowsExpensiveNetworkAccess.description),
            ("Allows Constrained Network Access", request.allowsConstrainedNetworkAccess.description),
            ("HTTP Should Handle Cookies", request.httpShouldHandleCookies.description),
            ("HTTP Should Use Pipelining", request.httpShouldUsePipelining.description)
        ])
    }
}

// MARK: - Private

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.doesRelativeDateFormatting = true
    formatter.timeStyle = .medium
    return formatter
}()

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
    metrics: MockDataTask.login.metrics
)

private let mockFailureModel = NetworkInspectorSummaryViewModel(
    request: NetworkLoggerRequest(urlRequest: MockDataTask.login.request),
    response: nil,
    responseBody: nil,
    error: NetworkLoggerError(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])),
    metrics: nil
)
#endif
