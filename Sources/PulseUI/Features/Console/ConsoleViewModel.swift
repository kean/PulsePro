// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import CoreData
import Pulse
import Logging
import Combine
import SwiftUI

public final class ConsoleViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private let store: LoggerMessageStore
    private var controller: NSFetchedResultsController<MessageEntity>

    @Published public private(set) var messages: ConsoleMessages

    @Published public var searchText: String = ""
    @Published public var searchCriteria: ConsoleSearchCriteria = .init()
    @Published public var filter: FilterType = .debug

    public enum FilterType {
        case trace
        case debug
        case errors
    }

    private var bag = [AnyCancellable]()

    public init(store: LoggerMessageStore) {
        self.store = store

        let request = NSFetchRequest<MessageEntity>(entityName: "\(MessageEntity.self)")
        request.fetchBatchSize = 40
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.createdAt, ascending: false)]

        self.controller = NSFetchedResultsController<MessageEntity>(fetchRequest: request, managedObjectContext: store.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])

        super.init()

        controller.delegate = self
        try? controller.performFetch()

        Publishers.CombineLatest($searchText, $searchCriteria).sink { [unowned self] searchText, criteria in
            self.refresh(searchText: searchText, criteria: criteria)
        }.store(in: &bag)

        $filter.sink { [unowned self] in
            self.setFilter($0)
        }.store(in: &bag)
    }

    private func refresh(searchText: String, criteria: ConsoleSearchCriteria) {
        // TODO: the latest session ID should come from the store
        update(request: controller.fetchRequest, searchText: searchText, criteria: criteria, sessionId: PersistentLogHandler.logSessionId.uuidString)
        try? controller.performFetch()
        self.messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])
    }

    private func setFilter(_ filter: FilterType) {
        var filters = searchCriteria.filters
        filters.removeAll(where: { $0.kind == .level })
        switch filter {
        case .trace:
            break // Show all
        case .debug:
            filters.append(ConsoleSearchFilter(text: Logger.Level.trace.rawValue, kind: .level, relation: .doesNotEqual))
        case .errors:
            filters.append(ConsoleSearchFilter(text: Logger.Level.error.rawValue, kind: .level, relation: .equals))
            filters.append(ConsoleSearchFilter(text: Logger.Level.critical.rawValue, kind: .level, relation: .equals))
        }
        searchCriteria.filters = filters
    }

    func prepareForSharing() throws -> URL {
        try ConsoleShareService(store: store).prepareForSharing()
    }

    func buttonRemoveAllMessagesTapped() {
        store.removeAllMessages()
    }

    // MARK: - DetailsViewModel

    func makeDetailsRouter(for message: MessageEntity) -> ConsoleMessageDetailsRouter {
        ConsoleMessageDetailsRouter(store: store, message: message)
    }

    // MARK: - NSFetchedResultsControllerDelegate

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])
    }
}
