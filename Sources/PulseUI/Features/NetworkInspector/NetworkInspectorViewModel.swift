// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse

final class NetworkInspectorViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private let store: LoggerMessageStore
    private let taskId: String
    @Published private(set) var messages: [MessageEntity] = []
    private var summary: NetworkLoggerSummary

    private let controller: NSFetchedResultsController<MessageEntity>

    init(store: LoggerMessageStore, taskId: String) {
        self.store = store
        self.taskId = taskId

        let request = NSFetchRequest<MessageEntity>(entityName: "\(MessageEntity.self)")
        request.predicate = NSPredicate(format: "SUBQUERY(metadata, $entry, $entry.key == %@ AND $entry.value == %@).@count > 0", NetworkLoggerMetadataKey.taskId.rawValue, taskId)
        request.relationshipKeyPathsForPrefetching = ["\(\MessageEntity.metadata.self)"]
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.createdAt, ascending: false)]

        self.controller = NSFetchedResultsController<MessageEntity>(fetchRequest: request, managedObjectContext: store.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.summary = NetworkLoggerSummary(messages: [])

        super.init()

        controller.delegate = self
        try? controller.performFetch()
        self.didUpdateMessages(self.controller.fetchedObjects ?? [])
    }

    private func didUpdateMessages(_ messages: [MessageEntity]) {
        self.messages = messages
        self.summary = NetworkLoggerSummary(messages: messages)
    }

    // MARK: - Tabs

    func makeSummaryModel() -> NetworkInspectorSummaryViewModel {
        NetworkInspectorSummaryViewModel(
            request: summary.request,
            response: summary.response,
            responseBody: summary.responseBody,
            error: summary.error,
            metrics: summary.metrics
        )
    }

    func makeHeadersModel() -> NetworkInspectorHeaderViewModel {
        NetworkInspectorHeaderViewModel(
            request: summary.request,
            response: summary.response
        )
    }

    func makeResponseModel() -> NetworkInspectorResponseViewModel {
        NetworkInspectorResponseViewModel(
            data: summary.responseBody
        )
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.didUpdateMessages(self.controller.fetchedObjects ?? [])
    }
}
