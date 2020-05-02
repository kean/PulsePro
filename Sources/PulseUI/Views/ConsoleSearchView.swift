// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

#if os(macOS)
import SwiftUI
import Pulse
import AppKit
import Combine

// I'm too lazy to create ViewModels for each of these components and menus,
// this should do.
final class ConsoleSearchView: NSView, NSTokenFieldDelegate {
    private let tokenField = NSTokenField()
    private var searchCriteria: Binding<ConsoleSearchCriteria>
    private var observer: Any?
    private var cancellable: AnyCancellable?

    init(searchCriteria: Binding<ConsoleSearchCriteria>) {
        self.searchCriteria = searchCriteria

        super.init(frame: .zero)

        tokenField.placeholderString = "Search"
        tokenField.delegate = self
        tokenField.tokenStyle = .rounded

        addSubview(tokenField)
        tokenField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tokenField.topAnchor.constraint(equalTo: topAnchor),
            tokenField.bottomAnchor.constraint(equalTo: bottomAnchor),
            tokenField.leadingAnchor.constraint(equalTo: leadingAnchor),
            tokenField.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        observer = NotificationCenter.default
            .addObserver(forName: NSControl.textDidChangeNotification, object: tokenField, queue: nil) { [weak self] _ in
                self?.tokensUpdated()
            }
    }

    func searchCriteriaUpdatedProgramatically() {
        tokenField.objectValue = searchCriteria.filters.wrappedValue
    }

    private func tokensUpdated() {
        searchCriteria.filters.wrappedValue = tokenField.objectValue as! [ConsoleSearchFilter]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        let filter = representedObject as! ConsoleSearchFilter
        return "\(title(for: filter.kind)): \(filter.text)"
    }

    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        for token in tokens.reversed() {
            searchCriteria.wrappedValue.filters.insert(token as! ConsoleSearchFilter, at: index)
        }
        return tokens
    }

    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any? {
        ConsoleSearchFilter(text: editingString, kind: .text, relation: .contains)
    }

    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        return true
    }

    func tokenField(_ tokenField: NSTokenField, menuForRepresentedObject representedObject: Any) -> NSMenu? {
        let filter = representedObject as! ConsoleSearchFilter

        let menu = NSMenu(title: title(for: filter.kind))

        let allKinds = ConsoleSearchFilter.Kind.allCases
        let kindItems: [NSMenuItem] = zip(allKinds.indices, allKinds).map { index, kind in
            let item = NSMenuItem(title: title(for: kind), action: #selector(didSelectKind), keyEquivalent: "")
            if kind == filter.kind {
                item.state = .on
            }
            item.representedObject = filter
            item.target = self
            item.tag = index
            return item
        }

        let allRelations = ConsoleSearchFilter.Relation.allCases
        let relationItems: [NSMenuItem] = zip(allRelations.indices, allRelations).map { index, relation in
            let item = NSMenuItem(title: title(for: relation), action: #selector(didSelectRelation), keyEquivalent: "")
            if relation == filter.relation {
                item.state = .on
            }
            item.representedObject = filter
            item.target = self
            item.tag = index
            return item
        }

        menu.items = kindItems + [.separator()] + relationItems

        return menu
    }

    @objc func didSelectKind(_ item: NSMenuItem) {
        let filter = item.representedObject as! ConsoleSearchFilter

        let allKinds = ConsoleSearchFilter.Kind.allCases
        let newKind = allKinds[item.tag]

        let newFilter = ConsoleSearchFilter(text: filter.text, kind: newKind, relation: filter.relation)

        let index = searchCriteria.wrappedValue.filters.firstIndex(of: filter)!
        searchCriteria.wrappedValue.filters[index] = newFilter
        tokenField.objectValue = searchCriteria.wrappedValue.filters
    }

    @objc func didSelectRelation(_ item: NSMenuItem) {
        let filter = item.representedObject as! ConsoleSearchFilter

        let allRelations = ConsoleSearchFilter.Relation.allCases
        let newRelation = allRelations[item.tag]

        let newFilter = ConsoleSearchFilter(text: filter.text, kind: filter.kind, relation: newRelation)

        let index = searchCriteria.wrappedValue.filters.firstIndex(of: filter)!
        searchCriteria.wrappedValue.filters[index] = newFilter
        tokenField.objectValue = searchCriteria.wrappedValue.filters
    }
}

#endif

private func title(for kind: ConsoleSearchFilter.Kind) -> String {
    switch kind {
    case .any: return "Any"
    case .category: return "Category"
    case .system: return "System"
    case .level: return "Level"
    case .text: return "Text"
    }
}

private func title(for relation: ConsoleSearchFilter.Relation) -> String {
    switch relation {
    case .contains: return "Contains"
    case .doesNotContain: return "Does Not Contain"
    case .equals: return "Equals"
    case .doesNotEqual: return "Does Not Equal"
    }
}
