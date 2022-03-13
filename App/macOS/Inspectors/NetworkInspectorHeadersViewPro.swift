// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import PulseCore

// MARK: - View
@available(iOS 13.0, tvOS 14.0, watchOS 6, *)
struct NetworkInspectorHeadersViewPro: View {
    @ObservedObject var model: NetworkInspectorHeaderViewModel

    var items: [KeyValueSectionViewModel] {
        [
            model.requestHeaders,
            model.responseHeaders
        ].compactMap { $0 }
    }
    
    var body: some View {
        RichTextViewPro(model: .init(string: text), isAutomaticLinkDetectionEnabled: false, content: .headers)
    }

    private var text: NSAttributedString {
        let output = NSMutableAttributedString()
        let fontSize = CGFloat(AppSettings.shared.headersFontSize)
        for item in items {
            output.append(KeyValuePro.makeString(for: item, fontSize: fontSize))
            if item.title != items.last?.title {
                output.append(KeyValuePro.makeNewline(fontSize: fontSize))
            }
        }
        return output
    }
}
