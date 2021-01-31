// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

struct NetworkInspectorHeadersView: View {
    let model: NetworkInspectorHeaderViewModel

    var body: some View {
        ScrollView {
            VStack {
                makeSection(title: "Request", color: .systemBlue, items: model.requestHeaders)
                Spacer(minLength: 16)
                makeSection(title: "Response", color: .systemIndigo, items: model.responseHeaders)
                Spacer()
            }.padding()
        }
    }

    private func makeSection(title: String, color: UXColor, items: [(String, String)]) -> some View {
        KeyValueSectionView(model: KeyValueSectionViewModel(title: title, color: color, items: items))
    }
}

struct NetworkInspectorHeaderViewModel {
    let request: NetworkLoggerRequest?
    let response: NetworkLoggerResponse?

    var requestHeaders: [(String, String)] {
        (request?.headers ?? [:]).sorted(by: { $0.key < $1.key })
    }

    var responseHeaders: [(String, String)] {
        (response?.headers ?? [:]).sorted(by: { $0.key < $1.key })
    }
}

#if DEBUG
struct NetworkInspectorHeadersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorHeadersView(model: mockModel)
        }
    }
}

private let mockModel = NetworkInspectorHeaderViewModel(
    request: NetworkLoggerRequest(urlRequest: MockDataTask.login.request),
    response: NetworkLoggerResponse(urlResponse:  MockDataTask.login.response)
)
#endif
