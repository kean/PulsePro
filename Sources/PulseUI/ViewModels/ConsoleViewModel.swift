// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import CoreData
import Pulse
import Combine

struct ConsoleSearchCriteria {
    var levels: ConsoleFilter<Logger.Level> = .hide([])
}

enum ConsoleFilter<T: Hashable> {
    case focus(_ item: T)
    case hide(_ items: Set<T>)

    func map<U>(_ transform: (T) -> U) -> ConsoleFilter<U> {
        switch self {
        case let .focus(item): return .focus(transform(item))
        case let .hide(items): return .hide(Set(items.map(transform)))
        }
    }
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
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.created, ascending: false)]

        self.controller = NSFetchedResultsController<MessageEntity>(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])

        super.init()

        controller.delegate = self
        try? controller.performFetch()

        Publishers.CombineLatest($searchText, $searchCriteria).sink { [unowned self] searchText, criteria in
            self.refresh(searchText: searchText, criteria: criteria)
        }.store(in: &bag)
    }

    private func refresh(searchText: String, criteria: ConsoleSearchCriteria) {
        update(request: controller.fetchRequest, searchText: searchText, criteria: criteria)
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
    static let levelSegmentedControl: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "console.levels_segmented_control")
}

/// This isn't great, but hey, I want this macOS thing to work and I don't have time to think.
extension ConsoleViewModel: NSToolbarDelegate, NSSearchFieldDelegate {
    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        switch itemIdentifier {
        case .levelSegmentedControl:
            let segmentedControl = NSSegmentedControl(labels: ["All Messages", "Only Errors"], trackingMode: .selectOne, target: self, action: #selector(segmentedControlValueChanges(_:)))
            segmentedControl.selectedSegment = 0

            let item = NSToolbarItem(itemIdentifier: .searchField)
            item.view = segmentedControl
            return item
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
        [.levelSegmentedControl, .flexibleSpace, .searchField]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.levelSegmentedControl, .searchField, .space, .flexibleSpace, .print]
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarAllowedItemIdentifiers(toolbar)
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ notification: Notification) {
        let textField = notification.object as! NSTextField
        searchText = textField.stringValue
    }

    // MARK: - NSSegmentedControl

    @objc private func segmentedControlValueChanges(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0: searchCriteria.levels = .hide([])
        case 1: searchCriteria.levels = .hide([.debug, .info])
        default: fatalError("Invalid selected segment: \(sender.selectedSegment)")
        }
    }
}
#endif
