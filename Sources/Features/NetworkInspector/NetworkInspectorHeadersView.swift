// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import Pulse

struct NetworkInspectorHeadersView: View {
    let model: NetworkInspectorHeaderViewModel

    var body: some View {
        ScrollView {
            HStack {
                VStack {
                    KeyValueSectionView(model: model.requestHeaders)
                    Spacer(minLength: 16)
                    KeyValueSectionView(model: model.responseHeaders)
                    Spacer()
                }.padding()
                Spacer()
            }
        }
    }

    private func makeSection(title: String, color: UXColor, items: [(String, String)]) -> some View {
        KeyValueSectionView(model: KeyValueSectionViewModel(title: title, color: color, items: items))
    }
}

struct NetworkInspectorHeaderViewModel {
    let request: NetworkLoggerRequest?
    let response: NetworkLoggerResponse?

    var requestHeaders: KeyValueSectionViewModel {
        let items = (request?.headers ?? [:]).sorted(by: { $0.key < $1.key })
        return KeyValueSectionViewModel(title: "Request Headers", color: .systemBlue, items: items)
    }

    var responseHeaders: KeyValueSectionViewModel {
        let items = (response?.headers ?? [:]).sorted(by: { $0.key < $1.key })
        return KeyValueSectionViewModel(title: "Response Headers", color: .systemIndigo, items: items)
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
