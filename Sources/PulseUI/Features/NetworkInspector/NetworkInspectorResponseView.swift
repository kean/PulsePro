// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorResponseView: View {
    let data: Data

    var body: some View {
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            JSONViewer(json: json)
        } else {
            Text(String(bytes: data, encoding: .utf8) ?? "–")
        }
    }
}

#if DEBUG
struct NetworkInspectorResponseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorResponseView(data: MockDataTask.first.responseBody)
                .environment(\.colorScheme, .light)

            NetworkInspectorResponseView(data: MockDataTask.first.responseBody)
            .previewDisplayName("Dark")
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif
