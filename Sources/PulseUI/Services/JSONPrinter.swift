// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import CoreData

struct JSONColors {
    static let punctuation = PlatformColor.label.withAlphaComponent(0.7)
    static let key = PlatformColor.label
    static let valueString = PlatformColor.systemRed
    static let valueOther = PlatformColor.systemBlue
    static let null = PlatformColor.systemPurple
}

struct JSONPrinter {
    private let output = NSMutableAttributedString()
    private var indention = 0
    private let json: Any

    init(json: Any) {
        self.json = json
    }

    static func print(data: Data) -> NSAttributedString? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        var printer = JSONPrinter(json: json)
        return printer.print()
    }

    mutating func print() -> NSAttributedString {
        print(json: json, isFree: true)
        output.addAttributes([.font: PlatformFont.monospacedSystemFont(ofSize: 12, weight: .regular)])
        return output
    }

    mutating func print(json: Any, isFree: Bool) {
        switch json {
        case let object as [String: Any]:
            if isFree {
                indent()
            }
            append("{\n", [.foregroundColor: JSONColors.punctuation])
            let keys = object.keys.sorted()
            for key in keys {
                indent()
                append("  \"\(key)\"", [.foregroundColor: JSONColors.key])
                append(": ", [.foregroundColor: JSONColors.punctuation])
                indention += 2
                print(json: object[key]!, isFree: false)
                indention -= 2
                if key == keys.last {
                    append("\n", [.foregroundColor: JSONColors.punctuation])
                } else {
                    append(",\n", [.foregroundColor: JSONColors.punctuation])
                }
            }
            indent()
            append("}", [.foregroundColor: JSONColors.punctuation])
        case let object as String:
            append("\"\(object)\"", [.foregroundColor: JSONColors.valueString])
        case let array as Array<Any>:
            if array.contains(where: { $0 is [String: Any] }) {
                append("[\n", [.foregroundColor: JSONColors.punctuation])
                indention += 2
                for index in array.indices {
                    print(json: array[index], isFree: true)
                    if index < array.endIndex - 1 {
                        append(",\n", [.foregroundColor: JSONColors.punctuation])
                    } else {
                        append("\n", [.foregroundColor: JSONColors.punctuation])
                    }
                }
                indention -= 2
                indent()
                append("]", [.foregroundColor: JSONColors.punctuation])
            } else {
                append("[", [.foregroundColor: JSONColors.punctuation])
                for index in array.indices {
                    print(json: array[index], isFree: true)
                    if index < array.endIndex - 1 {
                        append(", ", [.foregroundColor: JSONColors.punctuation])
                    }
                }
                append("]", [.foregroundColor: JSONColors.punctuation])
            }
        case let object as Bool:
            append(object ? "true" : "false", [.foregroundColor: JSONColors.valueOther])
        default:
            if json is NSNull {
                append("null", [.foregroundColor: JSONColors.null])
            } else {
                append("\(json)", [.foregroundColor: JSONColors.valueOther])
            }
        }
    }

    func indent() {
        output.append(NSAttributedString(string: String(repeating: " ", count: indention), attributes: [:]))
    }

    func append(_ string: String, _ attributes: [NSAttributedString.Key: Any] = [:]) {
        output.append(string, attributes)
    }
}
