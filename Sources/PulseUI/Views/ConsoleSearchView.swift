// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

#if os(macOS)
import SwiftUI
import Pulse
import AppKit
import Combine

// I'm too lazy to create ViewModels for each of these components and menus,
// this should do.
public final class ConsoleSearchView: NSView, NSTokenFieldDelegate {
    private let tokenField = NSTokenField()
    private var searchCriteria: Binding<ConsoleSearchCriteria>
    private var observer: Any?
    private var cancellable: AnyCancellable?

    public init(searchCriteria: Binding<ConsoleSearchCriteria>) {
        self.searchCriteria = searchCriteria

        super.init(frame: .zero)

        tokenField.placeholderAttributedString = makePlaceholderString()
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

    private func makePlaceholderString() -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = magnifiyingGlass

        let string = NSMutableAttributedString(attachment: attachment)

        let text = NSAttributedString(
            string: " Search",
            attributes: [
                NSAttributedString.Key.baselineOffset: 3.5,
                NSAttributedString.Key.foregroundColor: NSColor.secondaryLabelColor
            ]
        )

        string.append(text)
        return string
    }

    public func searchCriteriaUpdatedProgramatically() {
        tokenField.objectValue = searchCriteria.filters.wrappedValue
    }

    private func tokensUpdated() {
        searchCriteria.filters.wrappedValue = tokenField.objectValue as! [ConsoleSearchFilter]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - NSTokenFieldDelegate

    public func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        let filter = representedObject as! ConsoleSearchFilter
        return "\(title(for: filter.kind)): \(filter.text)"
    }

    public func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        for token in tokens.reversed() {
            searchCriteria.wrappedValue.filters.insert(token as! ConsoleSearchFilter, at: index)
        }
        return tokens
    }

    public func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any? {
        ConsoleSearchFilter(text: editingString, kind: .text, relation: .contains)
    }

    public func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        return true
    }

    public func tokenField(_ tokenField: NSTokenField, menuForRepresentedObject representedObject: Any) -> NSMenu? {
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

private var magnifiyingGlass: NSImage {
    let dataBase64 = "iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAYAAAA6/NlyAAAABmJLR0QA/wD/AP+gvaeTAAADbElEQVRoge2ZvU8UQRiHH8mJAYyKeBZAZUMjNnpiK/bSEGgsICFqSSg0ipZAYaeg/4AmGkPhRyyJrfEj0QZEE8OnIWgCJzlBDVjMgse7c8vtMLO7MfskU8ze5f29v5vbmXdmICUlJSUlueyxHK8COA20AieBJqAe2O99vgLMAxPAW2AMeA2sW87DOY3AEDADbIRsM8Ag0BB51gbUAXeBNcIblW0VGAEOR+ogBJ3AIrs3Ktsi0BGhjx3JoEa1VMJLwH2gB8gBWWCv17Lesx7gAbAcEGfY04qVKuAZ+gTHgS7vO2HidaMmMV3MpyHjWSWD3mwB6GV3o5EB+rxYMv6TXcY25p4mmVnglEWNHDCn0bljUaMsOjVJvEOtsbap92JLvXYHWlrq8M/Gs7gxu0kWmBSaC0CtQ80t5IxcwO7fuBTH8b/Tt12LNqIKgmLRXteiRfQL7Z+4/WcxJATHiXbGrME/iQ24EqvAXxt3uRIL4JLIYcrLzTpnhNAS8RQB1UBe5JIzDRb0S50V/eeodyhqCsAL8azVNFiQYTkTvzQVscCY6BuvEkGGm0T/vamIBaS2zM0K39n+3hxxIVImR0Uuiy5E5Ka+0oVImewTuayaBnIyvUeA8VlckOEV0T9gKmKBg6IvcyubIMNfRf+YqYgFpPasaaAgwx9F/4SpiAWk9mfTQEGG34i+LESi5Jzov3Ih0sL2mXGZeErLGuAHlkrLIHSbh24XQjtwWeQwjf0bky0GhdgE0W8P50UO110KNuA/AOhzKSi4KbTzwCHXoiNCtICjd0jQjP+I51YEutpDvDncH+J9EppT+AsQZ3QI8c1j2qwDrSzqKrVYax3/0uScYfymJ1Gni7Zoxj+yG8CoRY2yyaDuenRXLf2oGdWUGuAG+quWDeA36jIgcqpQdz26pOZQB27VIeJVo9ZZufQkynQGdddTKrE88BC4iKrWsqi9dCVqI9+C+mEe4a+git/ZUZTJRJgGddezwM4jE7ZN8W+C6iRhpmtR1x+yODFpedQ6K5eexJkGtSYPoEYnrNFp4BrBFVQiTYPacOSAq8Bj4APqMHAN+AV8Q51AjgJXvO+WuxFIrGmXtOM3/Qe4EGdSrklNk5r+fyk1kbXFmZRrdKanY80oAqTp+XjTiYY24AtqdM/HnEtKSkpKihF/AY392IKcUAttAAAAAElFTkSuQmCC"
    let data = Data(base64Encoded: dataBase64)!
    let image = NSImage(data: data) ?? NSImage()
    return image.tinted(NSColor.secondaryLabelColor).resize(to: NSSize(width: 16, height: 16))
}

private extension NSImage {
    func tinted(_ tintColor: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()

        tintColor.set()

        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceIn)

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    func resize(to targetSize: NSSize) -> NSImage {
        let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return self
        }
        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })

        return image
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
