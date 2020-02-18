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

func update(request: NSFetchRequest<MessageEntity>, searchText: String, criteria: ConsoleSearchCriteria) {
    var predicates = [NSPredicate]()

    if searchText.count > 1 {
        predicates.append(NSPredicate(format: "text CONTAINS %@", searchText))
    }

    func apply<T: CVarArg>(filter: ConsoleFilter<T>, field: String) {
        if filter.isWhitelist {
            predicates.append(NSPredicate(format: "\(field) IN %@", filter.items))
        } else if !filter.items.isEmpty {
            predicates.append(NSPredicate(format: "NOT (\(field) IN %@)", filter.items))
        }
    }

    apply(filter: criteria.levels.map { $0.rawValue }, field: "level")

    request.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.created, ascending: false)]
}
