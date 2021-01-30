// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorResponseView: View {
    let response: Data

    init(response: Data) {
        self.response = response
    }

    var body: some View {
        Wrapped<PlatformTextView> {
            $0.isSelectable = true
            $0.isEditable = false
            #if os(iOS)
            $0.dataDetectorTypes = [.link]
            #elseif os(macOS)
            $0.isAutomaticLinkDetectionEnabled = true
            #endif
            $0.linkTextAttributes = [
                .foregroundColor: JSONColors.valueString,
                .underlineStyle: 1
            ]

            if let text = JSONPrinter.print(data: response) {
                #if os(iOS)
                $0.attributedText = text
                #elseif os(macOS)
                $0.textStorage?.setAttributedString(text)
                #endif
            }
        }
    }
}

#if DEBUG
struct NetworkInspectorResponseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorResponseView(response: MockDataTask.first.responseBody)
                .environment(\.colorScheme, .light)

            NetworkInspectorResponseView(response: MockDataTask.first.responseBody)
            .previewDisplayName("Dark")
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif
