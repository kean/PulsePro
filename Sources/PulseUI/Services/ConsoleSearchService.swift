//
//  ConsoleSearchService.swift
//  PulseUI
//
//  Created by Alexander Grebenyuk on 02.05.2020.
//  Copyright © 2020 kean. All rights reserved.
//

import Foundation
import Pulse
import CoreData

struct ConsoleSearchCriteria {
    var filters = [ConsoleSearchFilter]()
    #if os(iOS)
    var timePeriod = TimePeriod.currentSession
    #else
    var timePeriod = TimePeriod.all
    #endif
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

enum TimePeriod: CaseIterable {
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

func update(request: NSFetchRequest<MessageEntity>, searchText: String, criteria: ConsoleSearchCriteria, logger: Logger) {
    var predicates = [NSPredicate]()

    if searchText.count > 1 {
        predicates.append(NSPredicate(format: "text CONTAINS %@", searchText))
    }

    let groups = Dictionary(grouping: criteria.filters, by: { FilterParameters(filter: $0) })

    for group in groups {
        let searchTerms = group.value.map { $0.text }
        predicates.append(predicate(parameters: group.key, searchTerms: searchTerms))
    }

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


    request.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.createdAt, ascending: false)]
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
