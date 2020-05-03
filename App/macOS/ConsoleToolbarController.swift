// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Cocoa
import Pulse
import PulseUI
import SwiftUI
import AppKit

private extension NSToolbarItem.Identifier {
    static let searchField: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "console.search_field")
    static let levelSegmentedControl: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "console.levels_segmented_control")
}

final class ConsoleToolbarController: NSObject, NSToolbarDelegate, NSSearchFieldDelegate {
    private let model: ConsoleViewModel
    private var searchView: ConsoleSearchView?

    init(model: ConsoleViewModel) {
        self.model = model
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        switch itemIdentifier {
        case .levelSegmentedControl:
            let segmentedControl = NSSegmentedControl(labels: ["All Messages", "Only Errors"], trackingMode: .selectOne, target: self, action: #selector(segmentedControlValueChanges(_:)))
            segmentedControl.selectedSegment = 0

            let item = NSToolbarItem(itemIdentifier: .searchField)
            item.view = segmentedControl
            return item
        case .searchField:
            // TODO: there must be a clearer way to do that without @ObservedObject
            let binding = Binding(get: { [unowned self] in
                return self.model.searchCriteria
            }, set: { [unowned self] in
                self.model.searchCriteria = $0
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
        model.searchText = textField.stringValue
    }

    // MARK: - NSSegmentedControl

    @objc private func segmentedControlValueChanges(_ sender: NSSegmentedControl) {
        model.onlyErrors = sender.selectedSegment == 1
        searchView?.searchCriteriaUpdatedProgramatically()
    }
}
