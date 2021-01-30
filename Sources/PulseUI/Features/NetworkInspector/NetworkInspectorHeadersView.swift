// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorHeadersView: View {
    let request: URLRequest
    let response: URLResponse

    private var responseHeaders: [String: String]? {
        guard let httpResponse = (response as? HTTPURLResponse) else { return nil}
        return httpResponse.allHeaderFields as? [String: String]
    }

    var body: some View {
        ScrollView {
            VStack {
                makeSection(title: "Request", headers: request.allHTTPHeaderFields)
                makeSection(title: "Response", headers: responseHeaders)
                Spacer()
            }.padding(10)
        }
    }

    private func makeSection(title: String, headers: [String: String]?) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title)

            Wrapped<PlatformAutoTextView> {
                $0.isSelectable = true
                $0.isEditable = false
                #if os(iOS)
                $0.isScrollEnabled = false
                $0.dataDetectorTypes = [.link]
                #elseif os(macOS)
                $0.isAutomaticLinkDetectionEnabled = true
                $0.backgroundColor = .clear
                #endif
                $0.linkTextAttributes = [
                    .foregroundColor: JSONColors.valueString,
                    .underlineStyle: 1
                ]

                let text = makeAttributedText(headers: headers)
                #if os(iOS)
                $0.attributedText = text
                #elseif os(macOS)
                $0.textStorage?.setAttributedString(text)
                #endif
            }
            .padding(EdgeInsets(top: 0, leading: 5, bottom: 2, trailing: 0))
            .border(width: 2, edges: [.leading], color: Color(PlatformColor.systemBlue))
            .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
        }
    }

    private func makeAttributedText(headers: [String: Any]?) -> NSAttributedString {
        guard let headers = headers, !headers.isEmpty else {
            return NSAttributedString(string: "No Headers", attributes: [
                .foregroundColor: PlatformColor.systemBlue, .font: PlatformFont.systemFont(ofSize: 14, weight: .medium)
            ])
        }
        let output = NSMutableAttributedString()
        let keys = headers.keys.sorted()
        for key in keys {
            let string = NSMutableAttributedString()
            string.append("" + key + ": ", [
                .foregroundColor: PlatformColor.systemBlue,
                .font: PlatformFont.systemFont(ofSize: 14, weight: .medium)
            ])
            string.append("\(headers[key]!)", [
                .foregroundColor: PlatformColor.label,
                .font: PlatformFont.systemFont(ofSize: 14, weight: .regular)
            ])
            if key != keys.last {
                string.append("\n")
            }
            output.append(string)
        }

        return output
    }
}

#if DEBUG
struct NetworkInspectorHeadersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorSummaryView(request: MockDataTask.first.request, response: MockDataTask.first.response)
        }
    }
}
#endif
