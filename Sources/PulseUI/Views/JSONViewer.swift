// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct JSONViewer: View {
    let json: Any

    var body: some View {
        Wrapped<UXTextView> {
            $0.isSelectable = true
            $0.isEditable = false
            $0.isAutomaticLinkDetectionEnabled = true
            $0.linkTextAttributes = [
                .foregroundColor: JSONColors.valueString,
                .underlineStyle: 1
            ]
            $0.attributedText = JSONPrinter(json: json).print()
        }
    }
}

#if DEBUG
struct JSONViewer_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            JSONViewer(json: json)
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .light)

            JSONViewer(json: json)
            .previewDisplayName("Dark")
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
        }
    }
}

private var json: Any {
    let body = MockDataTask.first.responseBody
    return try! JSONSerialization.jsonObject(with: body, options: [])
}

#endif
