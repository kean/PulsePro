// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse
import CoreData

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
