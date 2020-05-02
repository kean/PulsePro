// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse
import CoreData

extension NSPersistentContainer {
    static func load(loggerDatabaseUrl url: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "LoggerStore", managedObjectModel: LoggerStorage.coreDataModel)

        let store = NSPersistentStoreDescription(url: url)
        store.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [store]

        var error: Error?
        var isLoaded = false
        container.loadPersistentStores {
            isLoaded = true
            error = $1
        }
        assert(isLoaded, "Expected persistent stores to be loaded synchronously")
        if let error = error {
            throw error
        }

        return container
    }
}

extension NSPersistentStoreCoordinator {
    func createCopyOfStore(at url: URL) throws {
        assert(persistentStores.count == 1, "There is more than one persistent stores registered with the coordator")

        let sourceStore = persistentStores[0]
        let backupCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        let intermediateStoreOptions = (sourceStore.options ?? [:])
            .merging([NSReadOnlyPersistentStoreOption: true],
                     uniquingKeysWith: { $1 })
        let intermediateStore = try backupCoordinator.addPersistentStore(
            ofType: sourceStore.type,
            configurationName: sourceStore.configurationName,
            at: sourceStore.url,
            options: intermediateStoreOptions
        )

        let backupStoreOptions: [AnyHashable: Any] = [
            NSReadOnlyPersistentStoreOption: true,
            // Disable write-ahead logging. Benefit: the entire store will be
            // contained in a single file. No need to handle -wal/-shm files.
            // https://developer.apple.com/library/content/qa/qa1809/_index.html
            NSSQLitePragmasOption: ["journal_mode": "DELETE"],
            // Minimize file size
            NSSQLiteManualVacuumOption: true,
        ]

        try backupCoordinator.migratePersistentStore(intermediateStore, to: url, options: backupStoreOptions, withType: NSSQLiteStoreType)
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

func update(request: NSFetchRequest<MessageEntity>, searchText: String, criteria: ConsoleSearchCriteria) {
    var predicates = [NSPredicate]()

    if searchText.count > 1 {
        predicates.append(NSPredicate(format: "text CONTAINS %@", searchText))
    }

    let groups = Dictionary(grouping: criteria.filters, by: { FilterParameters(filter: $0) })

    for group in groups {
        let searchTerms = group.value.map { $0.text }
        predicates.append(predicate(parameters: group.key, searchTerms: searchTerms))
    }

    request.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.created, ascending: false)]
}

extension Logger.Level {
    init?(description: String) {
        switch description {
        case "debug": self = .debug
        case "info": self = .info
        case "error": self = .error
        case "fatal": self = .fatal
        default: return nil
        }
    }
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
