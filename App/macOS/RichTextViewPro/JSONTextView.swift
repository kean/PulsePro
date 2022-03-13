//
//  IntelliTextView.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/6/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import AppKit

protocol JSONTextViewDelegate: AnyObject {
    func toggleExpandedState(for node: JSONContainerNode, range: NSRange)
    func toggleExpandedAll(_ isExpanded: Bool)
    func focus(on node: JSONContainerNode)
    func resetFocus()
    func expandedString(for node: JSONContainerNode) -> NSAttributedString
}

final class JSONTextView: NSTextView {
    private struct HighlightedNode {
        var node: JSONContainerNode
        var items: [HighlightedItem]
    }
    
    private struct HighlightedItem {
        let index: Int
        let originalAttributes: [NSAttributedString.Key: Any]
        
        init(index: Int, string: NSAttributedString) {
            self.index = index
            self.originalAttributes = string.attributes(at: 0, effectiveRange: nil)
        }
    }
    
    private var highlightedNode: HighlightedNode?
    
    weak var textDelegate: JSONTextViewDelegate?
    private var isJSON: Bool { textDelegate != nil}
    var isShowingFilteredResults = false

    // MARK: Managing Highlight

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        guard isJSON && !isShowingFilteredResults else { return }
        updateCurrentHighlight(at: convert(event.locationInWindow, from: nil))
    }
    
    private func updateCurrentHighlight(at point: NSPoint) {
        guard let (openingIndex, openingSubstring) = substring(at: point) else {
            removeCurrentHighlight()
            return
        }

        if let node = openingSubstring.attribute(.node, at: 0, effectiveRange: nil) as? JSONContainerNode, (openingSubstring.string == node.openingCharacter || openingSubstring.string == node.closingCharacter) {
            if highlightedNode?.node !== node {
                removeCurrentHighlight()
                
                let (closingIndex, closingSubstring) = findMatchingSubstring(in: textStorage!, for: node, substring: openingSubstring, index: openingIndex)
                
                let highlightedNode = HighlightedNode(node: node, items: [
                    .init(index: openingIndex, string: openingSubstring),
                    .init(index: closingIndex, string: closingSubstring)
                ])
                highlightedNode.items.forEach(addHighlight)
                
                self.highlightedNode = highlightedNode
            }
        } else {
            removeCurrentHighlight()
        }
    }
    
    private func substring(at event: NSEvent) -> (Int, NSAttributedString)? {
        substring(at: convert(event.locationInWindow, from: nil))
    }
    
    private func substring(at point: NSPoint) -> (Int, NSAttributedString)? {
        var point = point
        point.x -= textContainerInset.width
        point.y -= textContainerInset.height
        
        var fraction: CGFloat! = 0
        let index = layoutManager!.characterIndex(for: point, in: textContainer!, fractionOfDistanceBetweenInsertionPoints: &fraction)
        guard fraction < 1 else {
            return nil
        }
        let substring = textStorage!.attributedSubstring(from: NSRange(location: index, length: 1))
        return (index, substring)
    }
        
    private func removeCurrentHighlight() {
        if let highlightedNode = highlightedNode {
            highlightedNode.items.forEach(removeHighlight)
            self.highlightedNode = nil
        }
    }
    
    // MARK: Highlight (Visuals)
    
    private func addHighlight(_ item: HighlightedItem) {
        let font = item.originalAttributes[.font]! as! NSFont
        let newFont = NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .bold)
        textStorage!.addAttributes([.foregroundColor: NSColor.systemBlue, .font: newFont], range: NSRange(location: item.index, length: 1))
    }
    
    private func removeHighlight(_ item: HighlightedItem) {
        guard item.index < textStorage!.length else { return assertionFailure() }
        textStorage!.addAttributes(item.originalAttributes, range: NSRange(location: item.index, length: 1))
    }
    
    // MARK: Clicks
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        guard isJSON else { return }

        guard let (index, substring) = substring(at: event) else {
            return
        }

        guard let node = substring.attribute(.node, at: 0, effectiveRange: nil) as? JSONContainerNode else {
            return
        }

        if event.clickCount == 1 {
            if event.modifierFlags.contains(.command) {
                let context = MenuContext(node: node, index: index, substring: substring)
                showMenu(for: context, event: event)
            } else {
                guard !isShowingFilteredResults else { return }
                removeCurrentHighlight()
                let range = findRange(for: node, in: textStorage!, index: index, substring: substring)
                textDelegate?.toggleExpandedState(for: node, range: range)
            }
        }
    }
        
    // MARK: Menu
    
    func makeMenu(_ menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        return menu
    }
    
    private func showMenu(for context: MenuContext, event: NSEvent) {
        let menu = NSMenu()
        
        let isObject = context.node is JSONObjectNode
    
        let copyObjectItem = NSMenuItem(title: "Copy \(isObject ? "Object" : "Array")", action: #selector(buttonCopyNodeClicked(_:)), keyEquivalent: "")
        copyObjectItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        copyObjectItem.representedObject = context
        copyObjectItem.target = self
        menu.addItem(copyObjectItem)
        
        if !isShowingFilteredResults {
            let selectItem = NSMenuItem(title: "Select \(isObject ? "Object" : "Array")", action: #selector(buttonSelectNodeClicked(_:)), keyEquivalent: "")
            selectItem.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: nil)
            selectItem.representedObject = context
            selectItem.target = self
            menu.addItem(selectItem)
            
            let isExpanded = context.node.isExpanded
            let foldItem = NSMenuItem(title: isExpanded ? "Fold" : "Expand", action: #selector(buttonToggleExpandClicked(_:)), keyEquivalent: "")
            foldItem.image = NSImage(systemSymbolName: isExpanded ? "arrow.down.forward.and.arrow.up.backward" : "arrow.up.backward.and.arrow.down.forward", accessibilityDescription: nil)
            foldItem.representedObject = context
            foldItem.target = self
            menu.addItem(foldItem)
            
            let focusItem = NSMenuItem(title: "Focus", action: #selector(buttonFocusClicked(_:)), keyEquivalent: "")
            focusItem.image = NSImage(systemSymbolName: "target", accessibilityDescription: nil)
            focusItem.representedObject = context
            focusItem.target = self
            menu.addItem(focusItem)
        }
    
        let point = convert(event.locationInWindow, from: nil)
        menu.popUp(positioning: nil, at: point, in: superview)
    }
    
    private struct MenuContext {
        let node: JSONContainerNode
        let index: Int
        let substring: NSAttributedString
    }
    
    @objc private func buttonCopyNodeClicked(_ item: NSMenuItem) {
        let context = item.representedObject as! MenuContext
        if let textDelegate = textDelegate {
            NSPasteboard.general.string = textDelegate.expandedString(for: context.node).string
        } else {
            let range = range(for: context) // This should never happen
            NSPasteboard.general.string = textStorage!.attributedSubstring(from: range).string
        }
    }
    
    @objc private func buttonSelectNodeClicked(_ item: NSMenuItem) {
        let context = item.representedObject as! MenuContext
        let range = range(for: context)
        setSelectedRange(range)
    }
    
    @objc private func buttonToggleExpandClicked(_ item: NSMenuItem) {
        removeCurrentHighlight() // Important!
        let context = item.representedObject as! MenuContext
        let range = range(for: context)
        textDelegate?.toggleExpandedState(for: context.node, range: range)
    }
    
    @objc private func buttonFocusClicked(_ item: NSMenuItem) {
        removeCurrentHighlight() // Important!
        let context = item.representedObject as! MenuContext
        textDelegate?.focus(on: context.node)
    }

    private func range(for context: MenuContext) -> NSRange {
        findRange(for: context.node, in: textStorage!, index: context.index, substring: context.substring)
    }
    
    // MARK: Ranges
    
    private func findRange(for node: JSONContainerNode, in string: NSAttributedString, index: Int, substring: NSAttributedString) -> NSRange {
        switch substring.string {
        case "·":
            let (openingIndex, _) = findCharater(node.openingCharacter, in: string, for: node, startingIndex: index, isForward: false)
            let (closingIndex, _) = findCharater(node.closingCharacter, in: string, for: node, startingIndex: index, isForward: true)
            return NSRange(location: openingIndex, length: closingIndex - openingIndex + 1)
        case node.openingCharacter:
            let (closingIndex, _) = findCharater(node.closingCharacter, in: string, for: node, startingIndex: index, isForward: true)
            return NSRange(location: index, length: closingIndex - index + 1)
        case node.closingCharacter:
            let (openingIndex, _) = findCharater(node.openingCharacter, in: string, for: node, startingIndex: index, isForward: false)
            return NSRange(location: openingIndex, length: index - openingIndex + 1)
        default:
            assertionFailure()
            return NSRange(location: 0, length: 0)
        }
    }
    
    private func findMatchingSubstring(in string: NSAttributedString, for node: JSONContainerNode, substring: NSAttributedString, index: Int) -> (Int, NSAttributedString) {
        let isForward = substring.string == node.openingCharacter
        let matchingCharacter = isForward ? node.closingCharacter : node.openingCharacter
        
        return findCharater(matchingCharacter, in: string, for: node, startingIndex: index, isForward: isForward)
    }
    
    private func findCharater(_ character: String, in string: NSAttributedString, for node: JSONContainerNode, startingIndex: Int, isForward: Bool) -> (Int, NSAttributedString) {
        var index = startingIndex
        
        var s: [Character]
        if let cache = jsonTextCachedCharacterArray, cache.1 == string, cache.2 == string.length {
            s = cache.0
        } else {
            s = Array(string.string)
            jsonTextCachedCharacterArray = (s, string, string.length)
        }
        
        let ch = Character(character)
        while true {
            index += (isForward ? 1 : -1)
            guard s[index] == ch else {
                continue
            }
            let substring = string.attributedSubstring(from: NSRange(location: index, length: 1))
            if substring.string == character,
               let matchingNode = substring.attribute(.node, at: 0, effectiveRange: nil) as? JSONContainerNode,
               matchingNode === node {
                return (index, substring)
            }
        }
    }
}

var jsonTextCachedCharacterArray: ([Character], NSAttributedString, Int)?

final class JSONLayoutManager: NSLayoutManager {
    override func drawUnderline(forGlyphRange glyphRange: NSRange,
        underlineType underlineVal: NSUnderlineStyle,
        baselineOffset: CGFloat,
        lineFragmentRect lineRect: CGRect,
        lineFragmentGlyphRange lineGlyphRange: NSRange,
        containerOrigin: CGPoint
    ) {
        guard underlineVal.rawValue == 11 || underlineVal.rawValue == 12 || underlineVal.rawValue == 13 else {
            super.drawUnderline(forGlyphRange: glyphRange, underlineType: underlineVal, baselineOffset: baselineOffset, lineFragmentRect: lineRect, lineFragmentGlyphRange: lineGlyphRange, containerOrigin: containerOrigin)
            return
        }
        
        let firstPosition  = location(forGlyphAt: glyphRange.location).x

        let lastPosition: CGFloat

        if NSMaxRange(glyphRange) < NSMaxRange(lineGlyphRange) {
            lastPosition = location(forGlyphAt: NSMaxRange(glyphRange)).x
        } else {
            lastPosition = lineFragmentUsedRect(
                forGlyphAt: NSMaxRange(glyphRange) - 1,
                effectiveRange: nil).size.width
        }

        var lineRect = lineRect
        let height = lineRect.size.height * 3.5 / 4.0 // replace your under line height
        lineRect.origin.x += firstPosition
        lineRect.size.width = lastPosition - firstPosition
        lineRect.size.height = height

        lineRect.origin.x += containerOrigin.x
        lineRect.origin.y += (containerOrigin.y + 1.5)

        lineRect = lineRect.integral.insetBy(dx: -0.5, dy: -0.5)
        
        if underlineVal.rawValue == 13 {
            lineRect = lineRect.insetBy(dx: -0.5, dy: 3)
            lineRect.origin.y += 1
        }

        let path = NSBezierPath(roundedRect: lineRect, xRadius: 4, yRadius: 4)
        let color: NSColor
        switch underlineVal.rawValue {
        case 11: color = Palette.searchBackground
        case 12: color = Palette.yellow
        case 13: color = Palette.searchBackground
        default: fatalError()
        }
        color.setFill()
        path.fill()
    }
}

private let focusedColor = Palette.yellow
private let highlightColor = Palette.yellow

private extension Palette {
    @available(iOS 13.0, tvOS 13.0, *)
    static var yellow: UXColor {
        UXColor.dynamic(light: Palette.darkYellow, dark: Palette.darkYellow)
    }
    private static let lightYellow = UXColor(red: 254.0/255.0, green: 248.0/255.0, blue: 106.0/255.0, alpha: 1.0)
    private static let darkYellow = UXColor(red: 254.0/255.0, green: 249.0/255.0, blue: 57.0/255.0, alpha: 1.0)
    
    @available(iOS 13.0, tvOS 13.0, *)
    static var searchBackground: UXColor {
        UXColor.dynamic(light: NSColor.textColor.withAlphaComponent(0.15), dark: NSColor.textColor.withAlphaComponent(0.25))
    }
}
