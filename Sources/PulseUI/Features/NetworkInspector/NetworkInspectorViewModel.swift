// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse

final class NetworkInspectorViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private let store: LoggerMessageStore
    private let taskId: String
    private var messages: [MessageEntity] = []

    private let controller: NSFetchedResultsController<MessageEntity>

    @Published var messageCount = 0

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
        self.didUpdateMessages(self.controller.fetchedObjects ?? [])
    }

    private func didUpdateMessages(_ messages: [MessageEntity]) {
        self.messages = messages
        self.messageCount = messages.count
    }

    // MARK: - NSFetchedResultsControllerDelegate

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.didUpdateMessages(self.controller.fetchedObjects ?? [])
    }
}
