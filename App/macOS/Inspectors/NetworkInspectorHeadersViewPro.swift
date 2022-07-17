// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import PulseCore

struct NetworkInspectorHeadersViewPro: View {
    @ObservedObject var viewModel: NetworkInspectorHeaderViewModel
    @ObservedObject var textViewModel: RichTextViewModelPro

    init(viewModel: NetworkInspectorHeaderViewModel) {
        self.viewModel = viewModel
        self.textViewModel = RichTextViewModelPro(string: .init())
        self.refresh()
    }

    private func refresh() {
        self.textViewModel.display(text: text)
    }

    var items: [KeyValueSectionViewModel] {
        [
            viewModel.requestHeaders,
            viewModel.responseHeaders
        ].compactMap { $0 }
    }
    
    var body: some View {
        RichTextViewPro(model: textViewModel, isAutomaticLinkDetectionEnabled: false, content: .headers)
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
