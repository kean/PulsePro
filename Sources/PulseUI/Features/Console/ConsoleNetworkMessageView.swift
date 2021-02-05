// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import Pulse
import Logging

// MARK: - View

struct ConsoleNetworkMessageView: View {
    let model: ConsoleNetworkMessageViewModel

    #if os(iOS)
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(model.badgeColor)
                Text(model.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(uiImage: ConsoleNetworkMessageView.globe ?? UIImage())
                    .foregroundColor(Color(UXColor.blue))
                    .padding(.bottom, 2)
                Image(uiImage: ConsoleNetworkMessageView.shevron ?? UIImage())
                    .foregroundColor(Color(UXColor.separator))
                    .padding(.bottom, 2)
            }
            Text(model.text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .lineLimit(4)
        }
        .padding(.vertical, 4)
    }

    private static let shevron: UIImage? = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .regular, scale: .default))?.withRenderingMode(.alwaysTemplate)
    private static let globe: UIImage? = UIImage(systemName: "globe", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .regular, scale: .default))?.withRenderingMode(.alwaysTemplate)
    #endif

    #if os(macOS)
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(model.badgeColor)
                Text(model.title)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text("🌐")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(model.text)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(4)
        }.padding(.vertical, 6)
    }
    #endif
}

// MARK: - ViewModel

struct ConsoleNetworkMessageViewModel {
    let badgeColor: Color
    let title: String
    let text: String

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    init(message: NetworkLoggerMessage, event: NetworkLoggerEvent.TaskDidComplete) {
        let isSuccess: Bool
        if event.error != nil {
            isSuccess = false
        } else if let statusCode = event.response?.statusCode, !(200..<400).contains(statusCode) {
            isSuccess = false
        } else {
            isSuccess = true
        }

        let time = ConsoleMessageViewModel.timeFormatter.string(from: message.message.createdAt)
        let prefix: String
        if let statusCode = event.response?.statusCode {
            prefix = descriptionForStatusCode(statusCode)
        } else if let error = event.error {
            prefix = "ERROR: \(error.code))"
        } else {
            prefix = "SUCCESS"
        }

        self.title = "\(prefix) · \(time)"

        let method = event.request.httpMethod ?? "GET"
        self.text = method + " " + (event.request.url?.absoluteString ?? "–")

        badgeColor = isSuccess ? .green : .red
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
