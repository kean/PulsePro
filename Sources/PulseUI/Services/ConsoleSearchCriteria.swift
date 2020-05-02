// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse

struct ConsoleSearchCriteria {
    var filters = [ConsoleSearchFilter]()
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
        case level
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
