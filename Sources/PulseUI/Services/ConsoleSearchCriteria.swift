// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse

struct ConsoleSearchCriteria {
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

