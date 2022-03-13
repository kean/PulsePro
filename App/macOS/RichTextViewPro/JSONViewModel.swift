//
//  JSONViewModel.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/6/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

final class JSONViewModel: ObservableObject, JSONTextViewDelegate {
    private var json: JSONNode
    private let originalJSON: JSONNode
    
    private(set) var textModel = RichTextViewModelPro(string: .init())
    
    // JQ
    @Published var isJQHidden = true
    @Published var jqExpression = ""
    @Published var jqProcessing = false
    private var task: Process?
    let jqOutput = RichTextViewModelPro(string: .init())
    
    private var tempDir: TemporaryDirectory?
    private var tempFileURL: URL?
    private let printer: NewJSONPrinter
    
    private var cancellables: [AnyCancellable] = []
    
    deinit {
        task?.terminate()
        tempDir?.remove()
    }
    
    init(json: Any, isExpanded: Bool = true) {
        self.printer = NewJSONPrinter()
        self.json = JSON.Element.make(json: json).toNode()
        self.originalJSON = self.json
        
        if !isExpanded {
            self.textModel.isJSONExpanded = isExpanded
            self.toggleExpandedAll(for: self.json, isExpanded: isExpanded)
        }

        self.textModel.textDelegate = self
        render()

        $isJQHidden.sink { [weak self] in
            if $0 { self?.jqExpression = "" }
        }.store(in: &cancellables)
        
        jqOutput.display(text: makeJQEmptyString())
        
        $jqExpression.sink { [weak self] in
            self?.process(expression: $0)
        }.store(in: &cancellables)
    }
    
    private func render() {
        tempDir?.remove()
        tempDir = nil
        tempFileURL = nil
    
        let string = format(json: json)
        self.textModel.display(text: string)
    }
    
    private func getInputFileURL() -> URL {
        guard let fileURL = tempFileURL else {
            let tempDir = TemporaryDirectory()
            let tempFileURL = tempDir.write(text: textModel.sourceText.string, extension: "json")
            (self.tempDir, self.tempFileURL) = (tempDir, tempFileURL)
            return tempFileURL
        }
        return fileURL
    }

    private func format(json: Any) -> NSAttributedString {
        format(json: JSON.Element.make(json: json).toNode())
    }
    
    private func format(json: JSONNode, isFree: Bool = true) -> NSAttributedString {
        let string = printer.render(node: json, isFree: isFree)
        
        let fontSize = AppSettings.shared.viewerFontSize
        let lineHeight = Constants.ResponseViewer.lineHeight(for: fontSize)
        
        let mutable = NSMutableAttributedString(attributedString: string)

        let ps = NSMutableParagraphStyle()
        ps.minimumLineHeight = lineHeight
        ps.maximumLineHeight = lineHeight
        
        mutable.addAttributes([
            .font: UXFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular),
            .paragraphStyle: ps
        ])
        
        return mutable
    }

    // MARK: JSONTextViewDelegate
    
    func toggleExpandedState(for node: JSONContainerNode, range: NSRange) {
        node.isExpanded.toggle()
        let replacement = format(json: node, isFree: false)
        textModel.replace(text: replacement, at: range)
    }
    
    func toggleExpandedAll(_ isExpanded: Bool) {
        toggleExpandedAll(for: json, isExpanded: isExpanded)
        render()
    }

    private func toggleExpandedAll(for node: JSONNode, isExpanded: Bool) {
        switch node {
        case let object as JSONObjectNode:
            object.isExpanded = isExpanded
            object.children.forEach { toggleExpandedAll(for: $0.1, isExpanded: isExpanded) }
        case let array as JSONArrayNode:
            array.isExpanded = isExpanded
            array.children.forEach { toggleExpandedAll(for: $0, isExpanded: isExpanded) }
        default:
            break
        }
    }
    
    func focus(on node: JSONContainerNode) {
        self.json = node.element.toNode()
        textModel.isResetFocusButtonHidden = false
        render()
    }
    
    func resetFocus() {
        self.json = originalJSON
        textModel.isResetFocusButtonHidden = true
        render()
    }
    
    func expandedString(for node: JSONContainerNode) -> NSAttributedString {
        let expandedNode = node.element.toNode()
        return printer.render(node: expandedNode, isFree: true)
    }
    
    // MARK: JQ
    
    private func makeJQEmptyString() -> NSAttributedString {
        let str = NSMutableAttributedString()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: CGFloat(AppSettings.shared.viewerFontSize)),
            .foregroundColor: UXColor.label,
            .paragraphStyle: NSParagraphStyle.make(lineHeight: Constants.ResponseViewer.lineHeight(for: AppSettings.shared.viewerFontSize))
        ]
        str.append("""
        jq is a tool for processing JSON, applying the given filter. The simplest filter is ., which copies jq's input to its output unmodified. For more advanced filters see the jq(1) manpage ("man jq") and/or
        """, attrs)
        
        var linkAttrs = attrs
        linkAttrs[.foregroundColor] = NSColor.systemBlue
        linkAttrs[.link] = URL(string: "https://stedolan.github.io/jq")
        
        str.append(" ", attrs)
        str.append("https://stedolan.github.io/jq", linkAttrs)
        str.append(".", attrs)

        return str
    }
    
    private func process(expression: String) {
        guard !jqProcessing else {
            return
        }
        jqProcessing = true
        
        guard !expression.isEmpty else {
            jqOutput.display(text: makeJQEmptyString())
            jqProcessing = false
            return
        }
                        
        DispatchQueue.global().async {
            let process = Process()
            
            // TODO: use in-memory pipe
            process.standardInput = try? FileHandle(forReadingFrom: self.getInputFileURL())
            process.executableURL = Bundle.main.url(forResource: "jq-osx-amd64", withExtension: nil)
            process.arguments = [expression]
            
            self.task = process
        
            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            let errorPipe = Pipe()
            process.standardError = errorPipe
            
            do {
                try process.run()
            } catch {
                self.didFinishProcessingExpression(expression: expression, result: .failure(JQError(message: error.localizedDescription)))
                return
            }
                    
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: outputData, encoding: .utf8) else {
                self.didFinishProcessingExpression(expression: expression, result: .failure(JQError(message: "Something went wrong")))
                return
            }
            
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            guard let errorOutput = String(data: errorData, encoding: .utf8) else {
                self.didFinishProcessingExpression(expression: expression, result: .failure(JQError(message: "Something went wrong")))
                return
            }
            
            process.waitUntilExit()
            let status = Int(process.terminationStatus)
            
            if status == 0, errorOutput.isEmpty {
                self.didFinishProcessingExpression(expression: expression, result: .success(output))
            } else {
                self.didFinishProcessingExpression(expression: expression, result: .failure(JQError(message: errorOutput)))
            }
        }
    }
    
    private struct JQError: Error {
        let message: String
    }
    
    private func didFinishProcessingExpression(expression: String, result: Result<String, JQError>) {
        let jqOutput: NSAttributedString
        switch result {
        case .success(let output):
            if let data = output.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                jqOutput = format(json: json)
            } else {
                jqOutput = NSAttributedString(string: output, attributes: [.font: NSFont.systemFont(ofSize: CGFloat(AppSettings.shared.viewerFontSize)), .foregroundColor: NSColor.labelColor])
            }
        case .failure(let error):
            jqOutput = NSAttributedString(string: error.message, attributes: [.font: NSFont.systemFont(ofSize: CGFloat(AppSettings.shared.viewerFontSize)), .foregroundColor: NSColor.labelColor])
        }
        
        DispatchQueue.main.async {
            self._didFinishProcessingExpression(expression: expression, output: jqOutput)
        }
    }
    
    private func _didFinishProcessingExpression(expression: String, output: NSAttributedString) {
        jqProcessing = false
        jqOutput.display(text: output)
        
        guard !isJQHidden else { return }
                
        if expression != jqExpression {
            process(expression: jqExpression)
        }
    }
}
