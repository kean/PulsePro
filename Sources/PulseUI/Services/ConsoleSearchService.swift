// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import CoreData

public struct ConsoleSearchCriteria {
    public var filters = [ConsoleSearchFilter]()
    #if os(iOS)
    public var timePeriod = TimePeriod.currentSession
    #else
    public var timePeriod = TimePeriod.all
    #endif
}

public final class ConsoleSearchFilter: Hashable {
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

public enum TimePeriod: CaseIterable {
    case currentSession
    case lastTwentyMinutes
    case today
    case all

    var description: String {
        switch self {
        case .currentSession: return "Current Session"
        case .lastTwentyMinutes: return "Last 20 Minutes"
        case .today: return "Today"
        case .all: return "All"
        }
    }
}

private struct FilterParameters: Hashable {
    let kind: ConsoleSearchFilter.Kind
    let relation: ConsoleSearchFilter.Relation

    init(filter: ConsoleSearchFilter) {
        self.kind = filter.kind
        self.relation = filter.relation
    }
}

func update(request: NSFetchRequest<LoggerMessage>, searchText: String, criteria: ConsoleSearchCriteria, logger: Logger) {
    var predicates = [NSPredicate]()

    switch criteria.timePeriod {
    case .all:
        break // No filters needed
    case .currentSession:
        predicates.append(NSPredicate(format: "session == %@", logger.logSessionId.uuidString))
    case .today:
        let calendar = Calendar.current
        let dateFrom = calendar.startOfDay(for: Date())
        predicates.append(NSPredicate(format: "createdAt >= %@", dateFrom as NSDate))
    case .lastTwentyMinutes:
        let dateFrom = Date().addingTimeInterval(-20*60)
        predicates.append(NSPredicate(format: "createdAt >= %@", dateFrom as NSDate))
    }

    let groups = Dictionary(grouping: criteria.filters, by: { FilterParameters(filter: $0) })

    for group in groups {
        let searchTerms = group.value.map { $0.text }
        predicates.append(predicate(parameters: group.key, searchTerms: searchTerms))
    }

    if searchText.count > 1 {
        predicates.append(NSPredicate(format: "text CONTAINS %@", searchText))
    }

    request.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
}

private func predicate(parameters: FilterParameters, searchTerms: [String]) -> NSPredicate {
    let fields: [String]
    switch parameters.kind {
    case .category: fields = ["category"]
    case .system: fields = ["system"]
    case .text: fields = ["text"]
    case .level: fields = ["level"]
    case .any: fields = ["category", "system", "text", "level"]
    }

    let relation = parameters.relation.isExactMatch ? "==" : "CONTAINS"
    let prefix = parameters.relation.isNegated ? "NOT " : ""

    let predicates = fields.map { field in
        searchTerms.map { text in
            NSPredicate(format: "\(prefix)\(field) \(relation) %@", text)
        }
    }.flatMap { $0 }
    return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
}
