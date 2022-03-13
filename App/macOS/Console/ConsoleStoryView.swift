// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine
import WebKit

//
//  LineNumberRulerView.swift
//  LineNumber
//
//  Copyright (c) 2015 Yichi Zhang. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

import AppKit
import Foundation
import ObjectiveC

struct ConsoleStoryView: View {
    @StateObject private var model: ConsoleStoryViewModel
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    init(model: ConsoleMainViewModel) {
        _model = StateObject(wrappedValue: ConsoleStoryViewModel(model: model))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ConsoleStoryOptionsView(model: model)
            Divider()
            RichTextViewPro(
                model: model.text,
                content: .story,
                onLinkClicked: model.onLinkClicked,
                rulerWidth: 27
            )
                .id(ObjectIdentifier(model.text)) // TODO: fix this
                .background(colorScheme == .dark ? Color(NSColor(red: 30/255.0, green: 30/255.0, blue: 30/255.0, alpha: 1)) : .clear)
        }
        .onAppear(perform: model.onAppear)
    }
}

private struct ConsoleStoryOptionsView: View {
    @ObservedObject var model: ConsoleStoryViewModel
    
    var body: some View {
        HStack {
            Toggle("Compact Mode", isOn: AppSettings.shared.$isStoryCompactModeEnabled)
            Toggle("Limit to Thousand", isOn: AppSettings.shared.$isStoryReducedCount)
            Toggle("Show Responses", isOn: AppSettings.shared.$isStoryNetworkExpanded)
            Spacer()
        }
        .padding([.leading, .trailing], 6)
        .frame(height: 29, alignment: .center)
    }
}

final class ConsoleStoryViewModel: NSObject, ObservableObject {
    let main: ConsoleMainViewModel
    let text = RichTextViewModelPro(string: .init())
    @Published var isRefreshButtonVisible = false
    
    private var ids: [UUID: NSManagedObjectID] = [:]
    private var cache: [NSManagedObjectID: MessageViewModel] = [:]
    
    private var cancellables: [AnyCancellable] = []
    private let queue = DispatchQueue(label: "com.github.kean.pulse.story")
    private var options: Options
    private var helpers: TextRenderingHelpers
            
    init(model: ConsoleMainViewModel) {
        self.main = model
        self.options = ConsoleStoryViewModel.makeOptions()
        self.helpers = TextRenderingHelpers(options: options)
        
        super.init()
  
        UserDefaults.standard.publisher(for: \.isStoryNetworkExpanded, options: [.new]).sink { [weak self] _ in
            self?.didRefreshOptions()
        }.store(in: &cancellables)
        
        UserDefaults.standard.publisher(for: \.isStoryCompactModeEnabled, options: [.new]).sink { [weak self] _ in
            self?.didRefreshOptions()
        }.store(in: &cancellables)
        
        UserDefaults.standard.publisher(for: \.isStoryReducedCount, options: [.new]).sink { [weak self] _ in
            self?.didRefreshOptions()
        }.store(in: &cancellables)
        
        UserDefaults.standard.publisher(for: \.storyFontSize, options: [.new]).sink { [weak self] _ in
            self?.didRefreshOptions()
        }.store(in: &cancellables)
        
        main.toolbar.$isNowEnabled.dropFirst().sink { [weak text] in
            if $0 {
                text?.scrollToBottom()
            }
        }.store(in: &cancellables)
        
        text.didLiveScroll = { [weak main] in
            main?.toolbar.isNowEnabled = false
        }
        
        main.list.updates.sink { [weak self] in
            self?.process(update: $0)
        }.store(in: &cancellables)
        
        didRefreshMessages()
    }
    
    func onAppear() {
        if main.toolbar.isNowEnabled {
            DispatchQueue.main.async {
                self.text.scrollToBottom()
            }
        }
    }
    
    private func process(update: FetchedObjectsUpdate) {
        switch update {
        case .append(let range):
            let t = makeText(indices: range)
            if t.length > 0 {
                let s = NSMutableAttributedString(string: "\n")
                s.append(t)
                text.append(text: s)
                if main.toolbar.isNowEnabled {
                    text.scrollToBottom()
                }
            }
        case .reload:
            didRefreshMessages()
        }
    }
    
    private func didRefreshOptions() {
        options = ConsoleStoryViewModel.makeOptions()
        helpers = TextRenderingHelpers(options: options)
        cache.values.forEach { $0.isDirty = true }
        didRefreshMessages()
        objectWillChange.send()
    }
    
    private func didRefreshMessages() {
        text.display(text: makeText())
        if main.toolbar.isNowEnabled {
            text.scrollToBottom()
        }
    }
    
    func onLinkClicked(_ url: URL) -> Bool {
        guard url.scheme == "story" else {
            return false
        }
        let string = url.absoluteString
        
        if string.hasPrefix("story://toggle-message-limit") {
            AppSettings.shared.isStoryReducedCount = false
            return true
        }
        if string.hasPrefix("story://toggle-info") {
            let uuidString = url.lastPathComponent
            guard let uuid = UUID(uuidString: uuidString), let objectID = ids[uuid], let model = cache[objectID] else {
                assertionFailure()
                return false
            }
            self.main.selectEntityAt(model.index)
            return true
        }
 
        return true
    }
}

// MARK: - Regular Messages

#warning("TODO: add pins")

// TODO:
// - Cache RenderingCache per Options

extension ConsoleStoryViewModel {
    final class Options {
        let isNetworkExpanded: Bool
        let isCompactMode: Bool
        let isStoryReducedCount: Bool
        let fontSize: CGFloat
        
        init(isNetworkExpanded: Bool, isCompactMode: Bool, isStoryReducedCount: Bool, fontSize: CGFloat) {
            self.isNetworkExpanded = isNetworkExpanded
            self.isCompactMode = isCompactMode
            self.isStoryReducedCount = isStoryReducedCount
            self.fontSize = fontSize
        }
    }
    
    final class TextRenderingHelpers {
        let ps: NSParagraphStyle
        
        // Cache
        let digitalAttributes: [NSAttributedString.Key: Any]
        let titleAttributes: [NSAttributedString.Key: Any]
        private(set) var textAttributes: [LoggerStore.Level: [NSAttributedString.Key: Any]] = [:]
        
        let infoIconAttributes: [NSAttributedString.Key: Any]
        let showAllAttributes: [NSAttributedString.Key: Any]
        
        init(options: Options) {
            let ps = NSParagraphStyle.make(lineHeight: Constants.ResponseViewer.lineHeight(for: Int(options.fontSize)))
            self.ps = ps
            
            self.digitalAttributes = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: options.fontSize, weight: .regular),
                .foregroundColor: UXColor.secondaryLabel,
                .paragraphStyle: ps
            ]
            
            self.titleAttributes = [
                .font: NSFont.systemFont(ofSize: options.fontSize),
                .foregroundColor: UXColor.secondaryLabel,
                .paragraphStyle: ps
            ]
            
            var infoIconAttributes = titleAttributes
            infoIconAttributes[.foregroundColor] = NSColor.controlAccentColor
            self.infoIconAttributes = infoIconAttributes
            
            self.showAllAttributes = [
                .font: NSFont.systemFont(ofSize: options.fontSize),
                .foregroundColor: NSColor.systemBlue,
                .paragraphStyle: ps
            ]
            
            func makeLabelAttributes(level: LoggerStore.Level) -> [NSAttributedString.Key: Any] {
                let textColor = level == .trace ? .secondaryLabel : NSColor(ConsoleMessageStyle.textColor(level: level))
                return [
                    .font: NSFont.systemFont(ofSize: options.fontSize),
                    .foregroundColor: textColor,
                    .paragraphStyle: ps
                ]
            }
             
            for level in LoggerStore.Level.allCases {
                textAttributes[level] = makeLabelAttributes(level: level)
            }
        }
    }
    
    private static func makeOptions() -> Options {
        Options(
            isNetworkExpanded: AppSettings.shared.isStoryNetworkExpanded,
            isCompactMode: AppSettings.shared.isStoryCompactModeEnabled,
            isStoryReducedCount: AppSettings.shared.isStoryReducedCount,
            fontSize: CGFloat(AppSettings.shared.storyFontSize)
        )
    }
    
    private func makeText(indices: Range<Int>? = nil) -> NSAttributedString {
        let date = Date()
        pulseLog("Start rendering text view \(date)")
        defer { pulseLog("Finished rendering \(date), \(stringPrecise(from: Date().timeIntervalSince(date)))") }
        return makeText(indices: indices ?? main.list.indices, options: options, helpers: helpers)
    }
    
    private func makeText(indices: Range<Int>, options: Options, helpers: TextRenderingHelpers) -> NSAttributedString {
        let text = NSMutableAttributedString()
        let messages = main.list
        let lastIndex = main.list.count - 1
        for index in indices {
            if options.isStoryReducedCount && index > 999 {
                break
            }
            text.append(makeText(for: messages[index], index: index, options: options, helpers: helpers))
            if options.isStoryReducedCount && index == 999 {
                let remaining = messages.count - (index + 1)
                if remaining > 0 {
                    text.append("\n\n\(remaining)+ messages were not displayed. ", helpers.textAttributes[.trace]!)
                    var showAllAttributes = helpers.showAllAttributes
                    showAllAttributes[.link] = URL(string: "story://toggle-message-limit")
                    text.append("Show all.", showAllAttributes)
                }
                break
            }
            if index != lastIndex {
                if options.isCompactMode {
                    text.append("\n", helpers.digitalAttributes)
                } else {
                    text.append("\n\n", helpers.digitalAttributes)
                }
            }
        }
        return text
    }
    
    private func makeToggleInfoURL(for id: UUID) -> URL {
        URL(string: "story://toggle-info/\(id.uuidString)")!
    }
    
    private func getInterval(for message: LoggerMessageEntity) -> TimeInterval {
        guard let first = main.earliestMessage ?? main.list.first else { return 0 }
        return message.createdAt.timeIntervalSince1970 - first.createdAt.timeIntervalSince1970
    }
    
    private func makeText(for message: LoggerMessageEntity, index: Int, options: Options, helpers: TextRenderingHelpers) -> NSAttributedString {
        if let request = message.request {
            return makeText(for: message, request: request, index: index, options: options, helpers: helpers)
        }
        
        let model = getMessageModel(for: message, at: index)
        if !model.isDirty {
            return model.text
        }
        model.isDirty = false
        
        let text = NSMutableAttributedString()

        // Title
        let time = ConsoleMessageViewModel.timeFormatter.string(from: message.createdAt)
        
        // Title first part (digital)
        var titleFirstPart = "\(time) · "
        if !options.isCompactMode {
            let interval = getInterval(for: message)
            if interval < 3600 * 24 {
                titleFirstPart.append(contentsOf: "\(stringPrecise(from: interval)) · ")
            }
        }
        text.append(titleFirstPart, helpers.digitalAttributes)
        
        // Title second part (regular)
        var titleSecondPart = options.isCompactMode ? "" : "\(message.level) · "
        titleSecondPart.append("\(message.label)")
        titleSecondPart.append(options.isCompactMode ? " " : "\n")
        text.append(titleSecondPart, helpers.titleAttributes)
        
        // Text
        let level = LoggerStore.Level(rawValue: message.level) ?? .debug
        let textAttributes = helpers.textAttributes[level]!
        if options.isCompactMode {
            if let newlineIndex = message.text.firstIndex(of: "\n") {
                text.append(message.text[..<newlineIndex] + " ", textAttributes)
                var moreAttr = helpers.showAllAttributes
                moreAttr[.link] = makeToggleInfoURL(for: model.id)
                text.append("Show More", moreAttr)
            } else {
                text.append(message.text, textAttributes)
            }
        } else {
            text.append(message.text, textAttributes)
        }

        model.text = text
        return text
    }
    
    private func makeText(for message: LoggerMessageEntity, request: LoggerNetworkRequestEntity, index: Int, options: Options, helpers: TextRenderingHelpers) -> NSAttributedString {
        let model = getMessageModel(for: message, at: index)
        if !model.isDirty {
            return model.text
        }
        model.isDirty = false
        
        let text = NSMutableAttributedString()
        
        // Title
        let isSuccess = request.isSuccess
        
        let time = ConsoleMessageViewModel.timeFormatter.string(from: message.createdAt)
        
        let prefix: String
        if request.statusCode != 0 {
            prefix = StatusCodeFormatter.string(for: Int(request.statusCode))
        } else if request.errorCode != 0 {
            prefix = "\(request.errorCode) (\(descriptionForURLErrorCode(Int(request.errorCode))))"
        } else {
            prefix = "Success"
        }
        
        var title = "\(prefix)"
        if request.duration > 0 {
            title += " · \(DurationFormatter.string(from: request.duration))"
        }
        
        text.append("\(time) · ", helpers.digitalAttributes)
        if !options.isCompactMode  {
            let interval = getInterval(for: message)
            if interval < 3600 * 24 {
                text.append("\(stringPrecise(from: interval)) · ", helpers.digitalAttributes)
            }
        }
        text.append(title + " ", helpers.titleAttributes)
        text.append(isSuccess ? "🟢" : "🔴", helpers.titleAttributes)

        text.append(options.isCompactMode ? " " : "\n", helpers.titleAttributes)

        // Text
        let level = LoggerStore.Level(rawValue: message.level) ?? .debug
        let textAttributes = helpers.textAttributes[level]!
        let method = request.httpMethod ?? "GET"
        let messageText = method + " " + (request.url ?? "–")

        text.append(messageText + " ", textAttributes)
        
        var attributes = helpers.infoIconAttributes
        attributes[.link] = makeToggleInfoURL(for: model.id)
        text.append("✶", attributes)
        
        if options.isNetworkExpanded, let data = request.responseBodyKey.flatMap(self.main.context.store.getData(forKey:)) {
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                let renderer = AttributedStringJSONRenderer(fontSize: options.fontSize, lineHeight: Constants.ResponseViewer.lineHeight(for: Int(options.fontSize)))
                let printer = JSONPrinter(renderer: renderer)
                printer.render(json: json)
                text.append("\n")
                text.append(renderer.make())
            } else if let string = String(data: data, encoding: .utf8) {
                text.append("\n")
                text.append(string, helpers.textAttributes[.debug]!)
            }
        }
        
        model.text = text
        return text
    }
    
    private func getMessageModel(for message: LoggerMessageEntity, at index: Int) -> MessageViewModel {
        if let model = cache[message.objectID] { return model }
        let model = MessageViewModel(index: index)
        cache[message.objectID] = model
        ids[model.id] = message.objectID
        return model
    }
}

// MARK: - ConsoleStoryViewModel

private final class MessageViewModel {
    let id = UUID()
    let index: Int
    var text = NSAttributedString()
    var isDirty = true
    
    init(index: Int) {
        self.index = index
    }
}

// MARK: - Helpers

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    return formatter
}()

#if DEBUG
@available(iOS 13.0, *)
struct ConsoleStoryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConsoleStoryView(model: .init(store: .mock, toolbar: .init(), details: .init(context: .init(store: .mock)), mode: .init()))
                .previewLayout(.fixed(width: 700, height: 1200))
            //            ConsoleStoryView(model: .init(store: .mock))
            //                .background(Color.white)
            //                .environment(\.colorScheme, .light)
        }
    }
}
#endif
