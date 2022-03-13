//
//  JSONViewer.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/9/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import SwiftUI
import AppKit

struct StandaloneJSONViewer: View {
    @StateObject var model: StandaloneJSONViewerModel
    @State private var isSpinnerHidden = true

    var body: some View {
        content
            .onReceive(model.$isLoading.debounce(for: 0.33, scheduler: RunLoop.main, options: nil).removeDuplicates()) {
            self.isSpinnerHidden = !$0
        }
            .navigationTitle(model.url.path)
    }
    
    @ViewBuilder var content: some View {
        if let data = model.displayedData {
            switch data {
            case .json(let model):
                makeJSONViewer(model: model)
            case .text(let text):
                makePlainTextView(text: text)
            }
        } else {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .opacity(isSpinnerHidden ? 0 : 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func makeJSONViewer(model: JSONViewModel) -> some View {
        JSONView(model: model)
    }

    @ViewBuilder
    private func makePlainTextView(text: NSAttributedString) -> some View {
        RichTextViewPro(model: .init(string: text), content: .response)
    }
}

final class StandaloneJSONViewerModel: ObservableObject {
    let url: URL
    @Published private(set) var displayedData: DisplayedData?
    @Published private(set) var isLoading = false
    
    enum DisplayedData {
        case json(JSONViewModel)
        case text(NSAttributedString)
    }
        
    init(data: Data, url: URL) {
        self.url = url
        
        if data.count < 1000 {
            // Fast path
            displayedData = process(data: data)
        } else {
            isLoading = true
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                let result = self.process(data: data)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.displayedData = result
                }
            }
        }
    }
    
    private func process(data: Data) -> DisplayedData {
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            return .json(JSONViewModel(json: json, isExpanded: data.count < (1 * 1024 * 1024)))
        } else {
            let string = String(data: data, encoding: .utf8) ?? ""
            let text = NSAttributedString(string: string, attributes: [
                .font: NSFont.systemFont(ofSize: CGFloat(AppSettings.shared.viewerFontSize)), .foregroundColor: UXColor.label,
                .paragraphStyle: NSParagraphStyle.make(lineHeight: Constants.ResponseViewer.lineHeight(for: AppSettings.shared.viewerFontSize))
            ])
            return .text(text)
        }
    }
}
