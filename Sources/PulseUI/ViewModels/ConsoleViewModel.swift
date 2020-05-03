// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import CoreData
import Pulse
import Combine
import SwiftUI

final class ConsoleViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private let logger: Logger
    private let container: NSPersistentContainer
    private var controller: NSFetchedResultsController<MessageEntity>

    @Published var searchText: String = ""
    @Published var searchCriteria: ConsoleSearchCriteria = .init()
    @Published var onlyErrors: Bool = false
    #warning("TODO: remove")
    @Published private(set) var isShowingFilters = false
    @Published private(set) var messages: ConsoleMessages

    #if os(macOS)
    // TEMP:
    private var searchView: ConsoleSearchView?
    #endif

    init(logger: Logger) {
        self.logger = logger
        self.container = logger.container

        let request = NSFetchRequest<MessageEntity>(entityName: "\(MessageEntity.self)")
        request.fetchBatchSize = 40
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.createdAt, ascending: false)]

        self.controller = NSFetchedResultsController<MessageEntity>(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])

        super.init()

        controller.delegate = self
        try? controller.performFetch()

        Publishers.CombineLatest($searchText, $searchCriteria).sink { [unowned self] searchText, criteria in
            self.refresh(searchText: searchText, criteria: criteria)
        }.store(in: &bag)

        $onlyErrors.sink { [unowned self] in
            self.setOnlyErrorsEnabled($0)
        }.store(in: &bag)
    }

    private func refresh(searchText: String, criteria: ConsoleSearchCriteria) {
        update(request: controller.fetchRequest, searchText: searchText, criteria: criteria, logger: logger)
        try? controller.performFetch()
        self.messages = ConsoleMessages(messages: self.controller.fetchedObjects ?? [])
    }

    private func setOnlyErrorsEnabled(_ onlyErrors: Bool) {
        var filters = searchCriteria.filters
        filters.removeAll(where: { $0.kind == .level })
        if onlyErrors {
            filters.append(ConsoleSearchFilter(text: "error", kind: .level, relation: .equals))
            filters.append(ConsoleSearchFilter(text: "fatal", kind: .level, relation: .equals))
        }
        searchCriteria.filters = filters
    }

    func prepareForSharing() throws -> URL {
        try ConsoleShareService(container: container).prepareForSharing()
    }

    func buttonRemoveAllMessagesTapped() {
        try? logger.store.removeAllMessages()
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
            #warning("TODO: there must be a clearer way to do that without @ObservedObject")
            let binding = Binding(get: { [unowned self] in
                return self.searchCriteria
            }, set: { [unowned self] in
                self.searchCriteria = $0
            })
            let searchField = ConsoleSearchView(searchCriteria: binding)
            searchField.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
            searchField.heightAnchor.constraint(equalToConstant: 22).isActive = true
            self.searchView = searchField
            let width = searchField.widthAnchor.constraint(equalToConstant: 320)
            width.priority = .init(759)
            width.isActive = true
            let item = NSToolbarItem(itemIdentifier: .searchField)
            item.view = searchField
            return item
        default:
            return nil
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.searchField, .flexibleSpace, .levelSegmentedControl]
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
        onlyErrors = sender.selectedSegment == 1
        searchView?.searchCriteriaUpdatedProgramatically()
    }

    // MARK - Buttons

    @objc private func buttonShowFiltersTapped() {
        isShowingFilters.toggle()
    }
}
#endif
