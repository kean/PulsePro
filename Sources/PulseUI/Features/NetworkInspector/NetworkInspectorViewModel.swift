// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse

final class NetworkInspectorViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private let store: LoggerMessageStore
    private let taskId: String

    private let controller: NSFetchedResultsController<MessageEntity>

    public init(store: LoggerMessageStore, taskId: String) {
        self.store = store
        self.taskId = taskId

        let request = NSFetchRequest<MessageEntity>(entityName: "\(MessageEntity.self)")
        request.predicate = NSPredicate(format: "SUBQUERY(metadata, $entry, $entry.key == %@ AND $entry.value == %@).@count > 0", NetworkLoggerMetadataKey.taskId, taskId)
        request.relationshipKeyPathsForPrefetching = ["\(\MessageEntity.metadata.self)"]
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.createdAt, ascending: false)]

        self.controller = NSFetchedResultsController<MessageEntity>(fetchRequest: request, managedObjectContext: store.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)

        super.init()

        controller.delegate = self
        try? controller.performFetch()
    }

    // MARK: - NSFetchedResultsControllerDelegate

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])
        print(messages)
    }
}
