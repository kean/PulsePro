// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorSummaryView: View {
    let request: URLRequest
    let response: URLResponse

    private var responseHeaders: [String: String]? {
        guard let httpResponse = (response as? HTTPURLResponse) else { return nil}
        return httpResponse.allHeaderFields as? [String: String]
    }

    var body: some View {
        Text("placeholder")
    }
}

#if DEBUG
struct NetworkInspectorSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorSummaryView(request: MockDataTask.first.request, response: MockDataTask.first.response)
        }
    }
}


#endif
