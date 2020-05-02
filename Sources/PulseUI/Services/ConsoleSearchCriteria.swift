// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse

struct ConsoleSearchCriteria {
    var filters = [ConsoleSearchFilter]()
    var levels = ConsoleFilter<Logger.Level>.allItems
}

struct ConsoleFilter<T: Hashable>: Hashable {
    let items: Set<T>
    let isWhitelist: Bool

    /// An "empty" filter which blacklists no items.
    static var allItems: ConsoleFilter { .blacklist(items: []) }

    static func whitelist(items: Set<T>) -> ConsoleFilter {
        ConsoleFilter(items: items, isWhitelist: true)
    }

    static func blacklist(items: Set<T>) -> ConsoleFilter {
        ConsoleFilter(items: items, isWhitelist: false)
    }

    func map<U>(_ transform: (T) -> U) -> ConsoleFilter<U> {
        ConsoleFilter<U>(items: Set(items.map(transform)), isWhitelist: isWhitelist)
    }
}

final class ConsoleSearchFilter: Hashable {
    let text: String
    let kind: Kind
    let relation: Relation

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    public static func == (lhs: ConsoleSearchFilter, rhs: ConsoleSearchFilter) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    init(text: String, kind: ConsoleSearchFilter.Kind, relation: ConsoleSearchFilter.Relation) {
        self.text = text
        self.kind = kind
        self.relation = relation
    }

    enum Kind: CaseIterable {
        case text
        case system
        case category
        case created
        case any
    }

    enum Relation: CaseIterable {
        case contains
        case doesNotContain
        case equals
        case doesNotEqual

        var isNegated: Bool {
            switch self {
            case .doesNotEqual, .doesNotContain: return true
            case .equals, .contains: return false
            }
        }

        var isExactMatch: Bool {
            switch self {
            case .equals, .doesNotEqual: return true
            case .contains, .doesNotContain: return false
            }
        }
    }
}
