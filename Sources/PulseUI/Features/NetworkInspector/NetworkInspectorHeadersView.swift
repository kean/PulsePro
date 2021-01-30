// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

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
        let items = (headers ?? [:]).sorted(by: { $0.key > $1.key })
        return KeyValueSectionView(title: title, items: items, tintColor: .systemBlue)
    }
}

#if DEBUG
struct NetworkInspectorHeadersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorHeadersView(request: MockDataTask.first.request, response: MockDataTask.first.response)
        }
    }
}
#endif
