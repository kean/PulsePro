// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import CoreData
import Pulse
import Combine

struct ConsoleSearchCriteria {
    let levels: ConsoleFilter<String> = .hide(items: [])
}

enum ConsoleFilter<T: Hashable> {
    case focus(item: T)
    case hide(items: Set<T>)
}

final class ConsoleViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private var container: NSPersistentContainer
    private var controller: NSFetchedResultsController<MessageEntity>

    @Published var searchText: String = ""
    @Published var searchCriteria: ConsoleSearchCriteria = .init()
    @Published private(set) var messages: ConsoleMessages

    init(container: NSPersistentContainer) {
        self.container = container

        let request = NSFetchRequest<MessageEntity>(entityName: "\(MessageEntity.self)")
        request.fetchBatchSize = 40

        self.controller = NSFetchedResultsController<MessageEntity>(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])

        super.init()

        controller.delegate = self
        try? controller.performFetch()

        Publishers.CombineLatest($searchText, $searchCriteria).sink { [unowned self] _ in
            self.refresh()
        }.store(in: &bag)
    }

    private func refresh() {
        update(request: controller.fetchRequest, searchText: searchText, criteria: searchCriteria)
        try? controller.performFetch()
        self.messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])
    }

    func prepareForSharing() throws -> URL {
        try ConsoleShareService(container: container).prepareForSharing()
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])
    }
}

#if os(macOS)
import AppKit

private extension NSToolbarItem.Identifier {
    static let searchField: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "console.search_field")
}

/// This isn't great, but hey, I want this macOS thing to work and I don't have time to think.
extension ConsoleViewModel: NSToolbarDelegate, NSSearchFieldDelegate {
    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        switch itemIdentifier {
        case .searchField:
            let searchField = NSSearchField(string: searchText)
            searchField.placeholderString = "Search"
            searchField.delegate = self
            let item = NSToolbarItem(itemIdentifier: .searchField)
            item.view = searchField
            return item
        default:
            return nil
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .searchField]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.searchField, .space, .flexibleSpace, .print]
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarAllowedItemIdentifiers(toolbar)
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ notification: Notification) {
        let textField = notification.object as! NSTextField
        searchText = textField.stringValue
    }
}
#endif

struct ConsoleMessages: RandomAccessCollection {
    private let messages: [MessageEntity]

    init(messages: [MessageEntity]) {
        self.messages = messages
    }

    typealias Index = Int

    var startIndex: Index { return messages.startIndex }
    var endIndex: Index { return messages.endIndex }
    func index(after i: Index) -> Index { i + 1 }

    subscript(index: Index) -> MessageEntity {
        return messages[index]
    }
}

private func update(request: NSFetchRequest<MessageEntity>, searchText: String, criteria: ConsoleSearchCriteria) {
    var predicates = [NSPredicate]()
    if searchText.count > 1 {
        predicates.append(NSPredicate(format: "text CONTAINS %@", searchText))
    }
    func apply<T: CVarArg>(filter: ConsoleFilter<T>, field: String) {
        switch filter {
        case let .focus(item):
            predicates.append(NSPredicate(format: "\(field) == %@", item))
        case let .hide(items):
            guard !items.isEmpty else { return }
            predicates.append(NSPredicate(format: "\(field) IN %@", items))
        }
    }
    apply(filter: criteria.levels, field: "level")

    request.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.created, ascending: false)]
}
