//
//  JSON.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/5/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation

final class JSON {
    enum Element {
        case object(Object)
        case array(Array)
        case string(String)
        case number(NSNumber)
        case boolean(Bool)
        case null
        
        static func make(json: Any) -> Element {
            switch json {
            case let object as [String: Any]:
                return .object(.init(object.mapValues(Element.make)))
            case let object as String:
                return .string(object)
            case let object as [Any]:
                return .array(.init(object.map(Element.make)))
            case let number as NSNumber:
                if number === kCFBooleanTrue {
                    return .boolean(true)
                } else if number === kCFBooleanFalse {
                    return .boolean(false)
                } else {
                    return .number(number)
                }
            default:
                if json is NSNull {
                    return .null
                } else {
                    assertionFailure("This should never happen")
                    return .null
                }
            }
        }
        
        var isObject: Bool {
            switch self {
            case .object: return true
            default: return false
            }
        }
        
        var children: [JSON.Element] {
            switch self {
            case .object(let object): return Swift.Array(object.values.values)
            case .array(let array): return array.values
            case .string, .number, .boolean, .null: return []
            }
        }
    }
    
    final class Object {
        let values: [String: Element]
        init(_ values: [String: Element]) {
            self.values = values
        }
    }
    
    final class Array {
        let values: [Element]
        init(_ values: [Element]) {
            self.values = values
        }
    }
}
