// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import Pulse
import Combine

enum RichTextViewContentType {
    case message
    case response
    case headers
    case story
    case curl
}

struct RichTextViewPro: View {
    @ObservedObject private var viewModel: RichTextViewModelPro
    var isAutomaticLinkDetectionEnabled = true
    var hasVerticalScroller = false
    let isSearchBarHidden: Bool
    let content: RichTextViewContentType
    let onFind = PassthroughSubject<Void, Never>()
    let onLinkClicked: (URL) -> Bool
    let rulerWidth: CGFloat?
    let onTerminalTapped: (() -> Void)?
    
    init(viewModel: RichTextViewModelPro,
         isAutomaticLinkDetectionEnabled: Bool = true,
         hasVerticalScroller: Bool = true,
         isSearchBarHidden: Bool = false,
         content: RichTextViewContentType,
         onLinkClicked: @escaping (URL) -> Bool = { _ in false },
         rulerWidth: CGFloat? = nil,
         onTerminalTapped: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.isAutomaticLinkDetectionEnabled = isAutomaticLinkDetectionEnabled
        self.hasVerticalScroller = hasVerticalScroller
        self.isSearchBarHidden = isSearchBarHidden
        self.content = content
        self.onLinkClicked = onLinkClicked
        self.rulerWidth = rulerWidth
        self.onTerminalTapped = onTerminalTapped
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
            WrappedTextView(
                viewModel: viewModel,
                isAutomaticLinkDetectionEnabled: isAutomaticLinkDetectionEnabled,
                hasVerticalScroller: hasVerticalScroller,
                content: content,
                onFind: onFind,
                onLinkClicked: onLinkClicked,
                rulerWidth: rulerWidth,
                onCommand: onCommand(_:)
            ).frame(maxWidth: .infinity, maxHeight: .infinity)
                if !viewModel.isResetFocusButtonHidden {
                    Button(action: { viewModel.textDelegate?.resetFocus() }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 24))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            if !isSearchBarHidden {
                Divider()
                SearchToobar(viewModel: viewModel, onFind: onFind, content: content, onTerminalTapped: onTerminalTapped, onCommand: onCommand(_:))
            }
        }
    }
    
    private func onCommand(_ command: LocalCommand) {
        switch command {
        case .increaseFont:
            guard content.fontSizeBinding.wrappedValue < Constants.ResponseViewer.maxFontSize else { return }
            content.fontSizeBinding.wrappedValue += 1
        case .decreaseFont:
            guard content.fontSizeBinding.wrappedValue > Constants.ResponseViewer.minFontSize else { return }
            content.fontSizeBinding.wrappedValue -= 1
        case .resetFont:
            switch content {
            case .message, .story:
                content.fontSizeBinding.wrappedValue = Constants.ResponseViewer.defaultFontSize
            case .response, .headers, .curl:
                content.fontSizeBinding.wrappedValue = Constants.ResponseViewer.defaultCodeFontSize
            }
        }
    }
}

private struct WrappedTextView: NSViewRepresentable {
    let viewModel: RichTextViewModelPro
    let isAutomaticLinkDetectionEnabled: Bool
    var hasVerticalScroller: Bool
    let content: RichTextViewContentType
    let onFind: PassthroughSubject<Void, Never>
    let onLinkClicked: (URL) -> Bool
    let rulerWidth: CGFloat?
    let onCommand: (LocalCommand) -> Void
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        let onLinkClicked: (URL) -> Bool
        var cancellables: [AnyCancellable] = []
        
        init(onLinkClicked: @escaping (URL) -> Bool) {
            self.onLinkClicked = onLinkClicked
        }

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            guard let url = link as? URL else {
                return false
            }
            return onLinkClicked(url)
        }
        
        func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            (view as! JSONTextView).makeMenu(menu, for: event, at: charIndex)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onLinkClicked: onLinkClicked)
    }
    
    var lineNumberHeight: CGFloat {
        CGFloat(content.fontSizeBinding.wrappedValue)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = JSONTextView.scrollableTextView()
        scrollView.hasVerticalScroller = hasVerticalScroller
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        let textView = scrollView.documentView as! JSONTextView
        textView.textDelegate = viewModel.textDelegate
        textView.textContainer?.replaceLayoutManager(JSONLayoutManager())
        configureTextView(textView, isAutomaticLinkDetectionEnabled, content: content)
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.delegate = context.coordinator
                
        UserDefaults.standard.publisher(for: content.lineNumbersKeyPath).sink { [weak textView] isEnabled in
            if isEnabled {
                textView?.lnv_setUpLineNumberView(fontSize: lineNumberHeight, rulerWidth: rulerWidth)
            } else {
                textView?.enclosingScrollView?.rulersVisible = false
            }
        }.store(in: &context.coordinator.cancellables)
        
        registerCodeSizeChanges(textView: textView, coordinator: context.coordinator)
        
        commands.onFindFirst.sink { [weak textView] in
            guard let textView = textView, let window = textView.window,
                  window.isKeyWindow, window.firstResponder === textView else { return }
            onFind.send()
            commands.isCommandHandled = true
        }.store(in: &context.coordinator.cancellables)
        
        NotificationCenter.default.publisher(for: NSScrollView.didLiveScrollNotification, object: scrollView).sink { [weak viewModel] _ in
            viewModel?.didLiveScroll?()
        }.store(in: &context.coordinator.cancellables)
               
        viewModel.textView = textView
        textView.attributedText = viewModel.sourceText
        return scrollView
    }
    
    private func registerCodeSizeChanges(textView: NSTextView, coordinator: Coordinator) {
        // TODO: refactor
        let commands = CommandsRegistry.shared
        commands.onIncreaseFont.sink { [weak textView] in
            guard textView?.window?.firstResponder === textView else { return }
            onCommand(.increaseFont)
        }.store(in: &coordinator.cancellables)
        
        commands.onDecreaseFont.sink { [weak textView] in
            guard textView?.window?.firstResponder === textView else { return }
            onCommand(.decreaseFont)
        }.store(in: &coordinator.cancellables)
        
        commands.onResetFont.sink { [weak textView] in
            guard textView?.window?.firstResponder === textView else { return }
            onCommand(.resetFont)
        }.store(in: &coordinator.cancellables)
        
        commands.onToggleLineNumbers.sink { [weak textView] in
            guard textView?.window?.firstResponder === textView else { return }
            TempWorkaround(content: content).lineNumbersBinding.wrappedValue.toggle()
        }.store(in: &coordinator.cancellables)
        
        UserDefaults.standard.publisher(for: content.fontSizeKeyPath, options: [.new]).sink { [weak textView] fontSize in
            guard let textView = textView else { return }
            
            func refreshLineNumbers() {
                guard UserDefaults.standard[keyPath: content.lineNumbersKeyPath] else { return }
                let font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
                textView.font = font
                textView.lnv_setUpLineNumberView(fontSize: CGFloat(fontSize), rulerWidth: rulerWidth)
                if let view = textView.enclosingScrollView?.verticalRulerView {
                    view.setNeedsDisplay(view.bounds)
                }
            }
            
            switch self.content {
            case .message, .headers, .response, .curl:
                let ps = NSParagraphStyle.make(lineHeight: Constants.ResponseViewer.lineHeight(for: fontSize))

                let font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
                
                textView.textStorage?.addAttributes([.font: font, .paragraphStyle: ps ])
                refreshLineNumbers()
            case .story:
                // The font size is refreshed automatically
                refreshLineNumbers()
            }
        }.store(in: &coordinator.cancellables)
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Break
    }
}

private func configureTextView(_ textView: UXTextView, _ isAutomaticLinkDetectionEnabled: Bool, content: RichTextViewContentType) {
    textView.isSelectable = true
    textView.isEditable = false
    textView.isAutomaticLinkDetectionEnabled = isAutomaticLinkDetectionEnabled
    switch content {
    case .story:
        textView.linkTextAttributes = [
            .underlineStyle: 0,
            .cursor: NSCursor.pointingHand
        ]
    case .message, .headers, .response, .curl:
        textView.linkTextAttributes = [
            .foregroundColor: JSONColors.valueString,
            .underlineStyle: 1,
            .cursor: NSCursor.pointingHand
        ]
    }
    
    textView.backgroundColor = .clear
}

private enum LocalCommand {
    case increaseFont
    case decreaseFont
    case resetFont
}

private struct TempWorkaround {
    let content: RichTextViewContentType
    
    @AppStorage("textViewLineNumbersEnabledForMessage") var textViewLineNumbersEnabledForMessage = true
    @AppStorage("textViewLineNumbersEnabledForResponse") var textViewLineNumbersEnabledForResponse = true
    @AppStorage("textViewLineNumbersEnabledForHeaders") var textViewLineNumbersEnabledForHeaders = true
    @AppStorage("textViewLineNumbersEnabledForStory") var textViewLineNumbersEnabledForStory = true
    @AppStorage("textViewLineNumbersEnabledForCURL") var textViewLineNumbersEnabledForCURL = true
    
    var lineNumbersBinding: Binding<Bool> {
        switch content {
        case .message: return $textViewLineNumbersEnabledForMessage
        case .response: return $textViewLineNumbersEnabledForResponse
        case .headers: return $textViewLineNumbersEnabledForHeaders
        case .story: return $textViewLineNumbersEnabledForStory
        case .curl: return $textViewLineNumbersEnabledForCURL
        }
    }
}

private struct SearchToobar: View {
    @ObservedObject var viewModel: RichTextViewModelPro
    @State private var isEditing: Bool = false
    @State private var isEditingFilter: Bool = false

    let onFind: PassthroughSubject<Void, Never>
    let content: RichTextViewContentType
    let onTerminalTapped: (() -> Void)?
    let onCommand: (LocalCommand) -> Void
    
    @AppStorage("textViewLineNumbersEnabledForMessage") var textViewLineNumbersEnabledForMessage = true
    @AppStorage("textViewLineNumbersEnabledForResponse") var textViewLineNumbersEnabledForResponse = true
    @AppStorage("textViewLineNumbersEnabledForHeaders") var textViewLineNumbersEnabledForHeaders = true
    @AppStorage("textViewLineNumbersEnabledForStory") var textViewLineNumbersEnabledForStory = true
    @AppStorage("textViewLineNumbersEnabledForCURL") var textViewLineNumbersEnabledForCURL = true
    
    var lineNumbersBinding: Binding<Bool> {
        switch content {
        case .message: return $textViewLineNumbersEnabledForMessage
        case .response: return $textViewLineNumbersEnabledForResponse
        case .headers: return $textViewLineNumbersEnabledForHeaders
        case .story: return $textViewLineNumbersEnabledForStory
        case .curl: return $textViewLineNumbersEnabledForCURL
        }
    }

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                SearchBar(title: "Search", text: $viewModel.searchTerm, onFind: onFind, onEditingChanged: { isEditing in
                    withAnimation {
                        self.isEditing = isEditing
                    }
                    if isEditing {
                        viewModel.isSearching = isEditing
                    }
                }, onReturn: viewModel.nextMatch)
                    .frame(width: isEditing ? 120 : 90)
                
                StringSearchOptionsMenu(options: $viewModel.options, isKindNeeded: false)
                    .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: false))
                    .fixedSize()
                    .padding(.trailing, 2)
            }
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.separator, lineWidth: 1))
            
            HStack(spacing: 5) {
                SearchBar(title: "Filter", text: $viewModel.filterTerm, imageName: "line.horizontal.3.decrease.circle", onEditingChanged: { isEditing in
                    withAnimation {
                        self.isEditingFilter = isEditing
                    }
                    if isEditing {
                        viewModel.isSearching = isEditing
                    }
                }, onReturn: viewModel.nextMatch)
                    .frame(width: isEditingFilter ? 120 : 80)
                
                StringSearchOptionsMenu(options: $viewModel.filterOptions, isKindNeeded: false)
                    .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: false))
                    .fixedSize()
                    .padding(.trailing, 2)
            }
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.separator, lineWidth: 1))
            
            if !viewModel.matches.isEmpty {
                Text(viewModel.matches.isEmpty ? "0/0" : "\(viewModel.selectedMatchIndex+1)/\(viewModel.matches.count)")
                    .lineLimit(1)
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(.secondary)
                
                
                HStack(spacing: 2) {
                    Button(action: viewModel.previousMatch) {
                        Image(systemName: "chevron.left")
                    }
                    Button(action: viewModel.nextMatch) {
                        Image(systemName: "chevron.right")
                    }
                }
                .fixedSize()
            }
            
            Spacer()
            
            if viewModel.isJSON {
                Button(action: viewModel.toggleExpanded) {
                    Image(systemName: viewModel.isJSONExpanded ? "arrow.down.forward.and.arrow.up.backward" : "arrow.up.backward.and.arrow.down.forward")
                }.buttonStyle(PlainButtonStyle())
                    .foregroundColor(.secondary)
            }
            
            if let action = onTerminalTapped {
                Button(action: action) {
                    Image(systemName: "terminal")
                }.buttonStyle(PlainButtonStyle())
                    .foregroundColor(.secondary)
            }
            
            Menu(content: {
                Section {
                    Toggle("Line Numbers", isOn: lineNumbersBinding).keyboardShortcut("l")
                }
                Section {
                    Button("Increase Font", action: { onCommand(.increaseFont) }).keyboardShortcut("+")
                    Button("Decrease Font", action: { onCommand(.decreaseFont) }).keyboardShortcut("-")
                    Button("Reset Font", action: { onCommand(.resetFont) }).keyboardShortcut("0")
                }
            }, label: {
                Image(systemName: "gearshape.fill")
            })
                .menuStyle(BorderlessButtonMenuStyle())
                .foregroundColor(.secondary)
                .fixedSize()
        }
        .padding(6)
    }
}

final class RichTextViewModelPro: ObservableObject {
    @Published var isSearching = false
    @Published var selectedMatchIndex: Int = 0
    @Published var matches: [NSRange] = []
    @Published var searchTerm: String = ""
    @Published var options: StringSearchOptions = .default
    @Published var filterTerm: String = ""
    @Published var filterOptions: StringSearchOptions = .default
    @Published var isResetFocusButtonHidden = true

    private var isShowingFilteredResults = false {
        didSet { (textView as? JSONTextView)?.isShowingFilteredResults = isShowingFilteredResults }
    }
    
    private(set) var sourceText: NSMutableAttributedString
    
    weak var textView: UXTextView?
    var mutableText: NSMutableAttributedString {
        textView?.textStorage ?? NSMutableAttributedString()
    }

    private var bag = [AnyCancellable]()

    var textDelegate: JSONTextViewDelegate?
    var didLiveScroll: (() -> Void)?
    
    init(string: NSAttributedString) {
        self.sourceText = NSMutableAttributedString(attributedString: string)

        Publishers.CombineLatest4($searchTerm, $options, $filterTerm, $filterOptions).sink { [weak self] in
            guard let self = self else { return }
            self.textView?.textStorage?.beginEditing()
            self.refresh(searchTerm: $0, options: $1, filterTerm: $2, filterOptions: $3)
            self.textView?.textStorage?.endEditing()
        }.store(in: &bag)
    }
    
    var isJSON: Bool {
        textDelegate != nil
    }
    
    var isJSONExpanded: Bool = true
    
    func toggleExpanded() {
        isJSONExpanded.toggle()
        textDelegate?.toggleExpandedAll(isJSONExpanded)
    }
    
    func display(text: NSAttributedString) {
        textView?.textStorage!.beginEditing()
        clearMatches()
        self.sourceText = NSMutableAttributedString(attributedString: text)
        textView?.textStorage!.setAttributedString(text)
        didChangeOriginalText()
        textView?.textStorage!.endEditing()
    }
    
    func append(text: NSAttributedString) {
        textView?.textStorage!.beginEditing()
        clearMatches()
        self.sourceText.append(text)
        textView?.textStorage!.append(text)
        didChangeOriginalText()
        textView?.textStorage!.endEditing()
    }
        
    func replace(text: NSAttributedString, at range: NSRange) {        
        textView?.textStorage!.beginEditing()
        clearMatches()
        self.sourceText.replaceCharacters(in: range, with: text)
        textView?.textStorage!.replaceCharacters(in: range, with: text)
        didChangeOriginalText()
        textView?.textStorage!.endEditing()
    }
    
    private func didChangeOriginalText() {
        cachedSplitLines = nil
        refresh()
        refreshLineNumbers()
    }
    
    private var cachedSplitLines: [(NSAttributedString, NSString)]?
    
    private func getSplitLines() -> [(NSAttributedString, NSString)] {
        if let cache = cachedSplitLines {
            return cache
        }
        
        let matches = newLineRegex.matches(in: sourceText.string, options: [], range: NSRange(location: 0, length: sourceText.length))
        var startIndex = 0
        var lines: [NSRange] = []
        for match in matches where match.numberOfRanges > 0 {
            let range = match.range(at: 0)
            lines.append(NSRange(location: startIndex, length: range.location - startIndex))
            startIndex = range.location + range.length
        }
        lines.append(NSRange(location: startIndex, length: sourceText.length - startIndex))
        
        var output: [(NSAttributedString, NSString)] = []
        for range in lines {
            let line = sourceText.attributedSubstring(from: range)
            let string = line.string as NSString
            output.append((line, string))
        }
        
        cachedSplitLines = output
        return output
    }
    
    private func refreshLineNumbers() {
        textView?.enclosingScrollView?.verticalRulerView?.setNeedsDisplay(textView?.enclosingScrollView?.verticalRulerView?.bounds ?? .zero)
    }
    
    private let newLineRegex = try! NSRegularExpression(pattern: "\n", options: [])

    private func refresh() {
        refresh(searchTerm: searchTerm, options: options, filterTerm: filterTerm, filterOptions: filterOptions)
    }
    
    private func refresh(searchTerm: String, options: StringSearchOptions, filterTerm: String, filterOptions: StringSearchOptions) {
        selectedMatchIndex = 0
        clearMatches()

        if !filterTerm.isEmpty {
            var hasMatch = false
            let output = NSMutableAttributedString()
            for (line, string) in getSplitLines() {
                if string.firstRange(of: filterTerm, options: .init(filterOptions)).location != NSNotFound {
                    if hasMatch {
                        output.append("\n")
                    }
                    hasMatch = true
                    output.append(line)
                }
            }
            textView?.attributedText = output
            isShowingFilteredResults = true
            refreshLineNumbers()
        } else {
            if isShowingFilteredResults {
                textView?.attributedText = NSMutableAttributedString(attributedString: sourceText)
                isShowingFilteredResults = false
            }
        }

        if !searchTerm.isEmpty {
            let input = isShowingFilteredResults ? mutableText.string : sourceText.string // Can use default string
            let ranges = (input as NSString).ranges(of: searchTerm, options: .init(options))
            for range in ranges {
                highlight(range: range, in: mutableText)
            }

            selectedMatchIndex = 0
            matches = ranges
            
            self.didUpdateCurrentSelectedMatch()
        }
    }

    func scrollToBottom() {
        textView?.scrollToEndOfDocument(nil)
    }
    
    func cancelSearch() {
        searchTerm = ""
        isSearching = false
        hideKeyboard()
    }

    func nextMatch() {
        guard !matches.isEmpty else { return }
        updateMatchIndex(selectedMatchIndex + 1 < matches.count ? selectedMatchIndex + 1 : 0)
    }

    func previousMatch() {
        guard !matches.isEmpty else { return }
        updateMatchIndex(selectedMatchIndex - 1 < 0 ? matches.count - 1 : selectedMatchIndex - 1)
    }

    private func updateMatchIndex(_ newIndex: Int) {
        let previousIndex = selectedMatchIndex
        selectedMatchIndex = newIndex
        didUpdateCurrentSelectedMatch(previousMatch: previousIndex)
    }

    private func didUpdateCurrentSelectedMatch(previousMatch: Int? = nil) {
        guard !matches.isEmpty, selectedMatchIndex < matches.count else { return }

        // Scroll to visible range
        let range = matches[selectedMatchIndex]
        DispatchQueue.main.async {
            self.textView?.scrollRangeToVisible(range) // TODO: remove this workaround
        }

        // Update highlights
        if let previousMatch = previousMatch {
            highlight(range: matches[previousMatch], in: mutableText)
        }
        highlight(range: matches[selectedMatchIndex], in: mutableText, isFocused: true)
    }

    private func clearMatches() {
        for range in matches {
            mutableText.removeAttribute(.underlineStyle, range: range)
            if let originalForegroundColor = sourceText.attribute(.foregroundColor, at: range.lowerBound, effectiveRange: nil) {
                mutableText.addAttribute(.foregroundColor, value: originalForegroundColor, range: range)
            }
        }
        matches.removeAll()
    }
}

private let highlightedAttributes: [NSAttributedString.Key: Any] = [
    .underlineStyle: 11,
    .foregroundColor: UXColor.textColor
]

private let focusedAttributes: [NSAttributedString.Key: Any] = [
    .underlineStyle: 12,
    .foregroundColor: UXColor.black
]

private func highlight(range: NSRange, in text: NSMutableAttributedString, isFocused: Bool = false) {
    text.addAttributes(isFocused ? focusedAttributes : highlightedAttributes, range: range)
}

#if DEBUG
@available(iOS 13.0, tvOS 14.0, *)
struct RichTextViewPro_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RichTextViewPro(json: try! JSONSerialization.jsonObject(with: MockJSON.allPossibleValues, options: []))
                .background(Color(UXColor.secondarySystemFill))
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .light)

            RichTextViewPro(json: try! JSONSerialization.jsonObject(with: MockJSON.allPossibleValues, options: []))
            .previewDisplayName("Dark")
                .background(Color(UXColor.secondarySystemFill))
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
        }
    }
}

private extension RichTextViewPro {
    init(json: Any) {
        let fontSize = AppSettings.shared.viewerFontSize
        let renderer = AttributedStringJSONRenderer(fontSize: CGFloat(fontSize), lineHeight: Constants.ResponseViewer.lineHeight(for: fontSize))
        let printer = JSONPrinter(renderer: renderer)
        #warning("TODO: pass error")
        printer.render(json: json, error: nil)
        self.init(viewModel: .init(string: renderer.make()), content: .response)
    }
}

#endif

private extension NSString {
    /// Finds all occurrences of the given string
    func ranges(of substring: String, options: String.CompareOptions = []) -> [NSRange] {
        var index = 0
        var ranges = [NSRange]()
        while index < length {
            let range = range(of: substring, options: options, range: NSRange(location: index, length: length - index), locale: nil)
            if range.location == NSNotFound {
                break
            }
            ranges.append(range)
            if index == range.upperBound {
                index += 1 // Regex found empty match, move along
            } else {
                index = range.upperBound
            }
        }
        return ranges
    }
    
    /// Returns first range of substring.
    func firstRange(of substring: String, options: String.CompareOptions = []) -> NSRange {
        range(of: substring, options: options, range: NSRange(location: 0, length: length), locale: nil)
    }
}

