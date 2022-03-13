//
//  NewJSONPrinter.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/5/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import AppKit

// MARK: JSONNodes (Keep track of what expanded basically)

protocol JSONNode: AnyObject {
    var element: JSON.Element { get }
}

protocol JSONContainerNode: JSONNode {
    var openingCharacter: String { get }
    var closingCharacter: String { get }
    
    var isExpanded: Bool { get set }
}

final class JSONObjectNode: JSONNode, JSONContainerNode {
    var element: JSON.Element { .object(object) }
    let object: JSON.Object
    var isExpanded = true
    let children: [(String, JSONNode)]
    let level: Int
    
    var openingCharacter: String { "{" }
    var closingCharacter: String { "}" }
        
    init(object: JSON.Object, children: [(String, JSONNode)], level: Int) {
        self.object = object
        self.children = children
        self.level = level
    }
}

final class JSONArrayNode: JSONNode, JSONContainerNode {
    var element: JSON.Element { .array(array) }
    let array: JSON.Array
    var isExpanded = true
    let children: [JSONNode]
    let level: Int
    
    var openingCharacter: String { "[" }
    var closingCharacter: String { "]" }
    
    init(array: JSON.Array, children: [JSONNode], level: Int) {
        self.array = array
        self.children = children
        self.level = level
    }
}

final class JSONPrimitiveValueNode: JSONNode {
    let element: JSON.Element
    
    init(element: JSON.Element) {
        self.element = element
    }
}

private func makeNode(for json: JSON.Element, level: Int = 0) -> JSONNode {
    switch json {
    case .object(let object):
        let values = object.values
        var children: [(String, JSONNode)] = []
        for key in values.keys.sorted() {
            children.append((key, makeNode(for: values[key]!, level: level + 1)))
        }
        return JSONObjectNode(object: object, children: children, level: level)
    case .array(let array):
        let values = array.values.map { makeNode(for: $0, level: level + 1)}
        return JSONArrayNode(array: array, children: values, level: level)
    case .string, .number, .boolean, .null:
        return JSONPrimitiveValueNode(element: json)
    }
}

extension JSON.Element {
    func toNode() -> JSONNode {
        makeNode(for: self)
    }
}

// MARK: JSONRenderer

protocol NewJSONRenderer: AnyObject {
    func append(_ string: String, element: JSONElement)
    func indent(count: Int)
    func newline()
}

final class NewJSONPrinter {
    private enum StringStyle {
        case punctuation, key, string, number, boolean, null
    }

    private var attributes: [StringStyle: [NSAttributedString.Key: Any]] = [
        .punctuation: [.foregroundColor: JSONColors.punctuation],
        .key: [.foregroundColor: JSONColors.key],
        .string: [.foregroundColor: JSONColors.valueString],
        .number: [.foregroundColor: JSONColors.valueOther],
        .boolean: [.foregroundColor: JSONColors.valueOther],
        .null: [.foregroundColor: JSONColors.null]
    ]
    
    private var moreAttributesProto: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.textColor,
        .underlineStyle: 13,
        .cursor: NSCursor.pointingHand
    ]
    
    private func makeMoreAttributes(for node: JSONContainerNode) -> [NSAttributedString.Key: Any] {
        var attributes = moreAttributesProto
        attributes[.node] = node
        return attributes
    }

    private var cache: [ObjectIdentifier: NSAttributedString] = [:]
    
    private func makeAttributes(for style: StringStyle, node: JSONNode) -> [NSAttributedString.Key: Any] {
        var attributes = self.attributes[style]!
        attributes[.node] = node
        return attributes
    }

    func render(node: JSONNode, isFree: Bool) -> NSAttributedString {
        return makeAttributedString(for: node, isFree: isFree)
    }

    private func makeAttributedString(for node: JSONNode, isFree: Bool) -> NSAttributedString {
        switch node {
        case let object as JSONObjectNode:
            let string = NSMutableAttributedString()
            if isFree {
                indent(string, level: object.level)
            }
            if object.isExpanded {
                string.append(makeAttributedString(for: object))
            } else {
                string.append(makePreview(for: object))
            }
            return string
        case let array as JSONArrayNode:
            if array.isExpanded {
                return makeAttributedString(for: array)
            } else {
                return makePreview(for: array)
            }
        case let primitive as JSONPrimitiveValueNode:
            return makeAttributedString(for: primitive)
        default:
            fatalError()
        }
    }
    
    private func makeAttributedString(for node: JSONObjectNode) -> NSAttributedString {
        let string = NSMutableAttributedString()

        var bracesAttributes = attributes[.punctuation]!
        bracesAttributes[.node] = node
        bracesAttributes[.cursor] = NSCursor.pointingHand
        bracesAttributes[.toolTip] = "\(node.children.count) values"
        
        string.append("{", bracesAttributes)
        string.append("\n")
        
        for (key, value) in node.children {
            // Append key
            indent(string, level: node.level)
            string.append("  \"\(key)\"", attributes[.key]!)
            string.append(": ", attributes[.punctuation]!)
            
            // Append value (with identation in case it's not primitive)
            string.append(makeAttributedString(for: value, isFree: false))
            
            if key != node.children.last!.0 {
                string.append(",", attributes[.punctuation]!)
            }
            string.append("\n")
        }
        indent(string, level: node.level)
        string.append("}", bracesAttributes)

        return string
    }
    
    private func makeAttributedString(for node: JSONArrayNode) -> NSAttributedString {
        let string = NSMutableAttributedString()
        
        var bracesAttributes = attributes[.punctuation]!
        bracesAttributes[.node] = node
        bracesAttributes[.cursor] = NSCursor.pointingHand
        bracesAttributes[.toolTip] = "\(node.children.count) elements"
        
        string.append("[", bracesAttributes)
        string.append("\n")
        for index in node.children.indices {
            let child = node.children[index]
            let isPrimitive = !(child is JSONContainerNode)
            if isPrimitive {
                indent(string, level: node.level + 1)
            }
            string.append(makeAttributedString(for: node.children[index], isFree: true))
            if index < node.children.endIndex - 1 {
                string.append(",", attributes[.punctuation]!)
            }
            string.append("\n")
        }

        indent(string, level: node.level)
        string.append("]", bracesAttributes)
        
        return string
    }
    
    private func makeAttributedString(for node: JSONPrimitiveValueNode) -> NSAttributedString {
        if let cache = cache[ObjectIdentifier(node)] {
            return cache
        }
        let string = _makeAttributedString(for: node)
        cache[ObjectIdentifier(node)] = string
        return string
    }
    
    private func _makeAttributedString(for node: JSONPrimitiveValueNode) -> NSAttributedString {
        switch node.element {
        case .string(let string):
            return NSAttributedString(string: "\"\(string)\"", attributes: attributes[.string]!)
        case .number(let number):
            return NSAttributedString(string: "\(number)", attributes: attributes[.number]!)
        case .boolean(let boolean):
            return NSAttributedString(string: boolean ? "true" : "false", attributes: attributes[.boolean]!)
        case .null:
            return NSAttributedString(string: "null", attributes: attributes[.null]!)
        default:
            fatalError()
        }
    }
    
    private var maxPreviewLength = 60
    private var maxPreviewCount = 5

    private func makePreview(for node: JSONNode) -> NSAttributedString {
        switch node {
        case let object as JSONObjectNode:
            var bracesAttributes = attributes[.punctuation]!
            bracesAttributes[.node] = node
            bracesAttributes[.cursor] = NSCursor.pointingHand
            
            let string = NSMutableAttributedString()
            string.append("{", bracesAttributes)
            
            var added = 0
            for (key, child) in object.children {
                let preview = NSMutableAttributedString()
                preview.append("\"\(key)\"", attributes[.key]!)
                preview.append(": ", attributes[.punctuation]!)
                preview.append(makeCollapsedPreview(for: child))

                if preview.string.count + string.length < maxPreviewLength, added < maxPreviewCount {
                    if added > 0 {
                        string.append(", ", attributes[.punctuation]!)
                    } else {
                        string.append(" ", attributes[.punctuation]!)
                    }
                    string.append(preview)
                    added += 1
                }
            }
            if added != object.children.count {
                string.append(", ", attributes[.punctuation]!)
                string.append("···", makeMoreAttributes(for: object))
                string.append(" ", attributes[.punctuation]!)
            } else {
                string.append(" ", attributes[.punctuation]!)
            }
            string.append("}", bracesAttributes)
            
            return string
        case let array as JSONArrayNode:
            var bracesAttributes = attributes[.punctuation]!
            bracesAttributes[.node] = node
            bracesAttributes[.cursor] = NSCursor.pointingHand
            
            let string = NSMutableAttributedString()
            string.append("[", bracesAttributes)
            
            var added = 0
            for child in array.children {
                let preview = makeCollapsedPreview(for: child)
                if preview.string.count + string.length < maxPreviewLength, added < maxPreviewCount {
                    if added > 0 {
                        string.append(", ", attributes[.punctuation]!)
                    }
                    string.append(preview)
                    added += 1
                }
            }
            if added != array.children.count {
                string.append(", ", attributes[.punctuation]!)
                string.append("···", makeMoreAttributes(for: array))
                string.append(" ", attributes[.punctuation]!)
            }
            string.append("]", bracesAttributes)
            
            return string
        case let primitive as JSONPrimitiveValueNode:
            return makeAttributedString(for: primitive)
        default:
            fatalError()
        }
    }
    
    // And even smaller preview than a preview.
    private func makeCollapsedPreview(for node: JSONNode) -> NSAttributedString {
        switch node {
        case is JSONObjectNode:
            return NSAttributedString(string: "{…}", attributes: attributes[.punctuation]!)
        case is JSONArrayNode:
            return NSAttributedString(string: "[…]", attributes: attributes[.punctuation]!)
        case let primitive as JSONPrimitiveValueNode:
            return makeAttributedString(for: primitive)
        default:
            fatalError()
        }
    }
    
    private func indent(_ string: NSMutableAttributedString, level: Int) {
        string.append(String(repeating: " ", count: level * 2), attributes[.punctuation]!)
    }
}

extension NSAttributedString.Key {
    static let node = NSAttributedString.Key(rawValue: "pulse_jsonNode")
}

final class NewAttributedStringJSONRenderer: NewJSONRenderer {
    private let output = NSMutableAttributedString()
    private let fontSize: CGFloat
    private let lineHeight: CGFloat
    
    private var attributes: [JSONElement: [NSAttributedString.Key: Any]] = [
        .punctuation: [.foregroundColor: JSONColors.punctuation],
        .key: [.foregroundColor: JSONColors.key],
        .valueString: [.foregroundColor: JSONColors.valueString],
        .valueOther: [.foregroundColor: JSONColors.valueOther],
        .null: [.foregroundColor: JSONColors.null]
    ]
    
    init(fontSize: CGFloat, lineHeight: CGFloat) {
        self.fontSize = fontSize
        self.lineHeight = lineHeight
    }
    
    func append(_ string: String, element: JSONElement) {
        output.append(string, attributes[element]!)
    }

    func indent(count: Int) {
        append(String(repeating: " ", count: count), element: .punctuation)
    }

    func newline() {
        output.append("\n")
    }

    func make() -> NSAttributedString {
        let ps = NSMutableParagraphStyle()
        ps.minimumLineHeight = lineHeight
        ps.maximumLineHeight = lineHeight
        
        output.addAttributes([
            .font: UXFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular),
            .paragraphStyle: ps
        ])
        return output
    }
}
