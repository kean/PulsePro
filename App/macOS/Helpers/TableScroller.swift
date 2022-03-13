//
//  TableScroller.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/1/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import Combine
import CoreData
import AppKit
import PulseCore
import SwiftUI

final class TableScroller: NSScroller {
    weak var tableView: NSTableView?
    
    private var pinScrollerButtons: [NSManagedObjectID: PinScrollerButton] = [:]
    private var errorButtons: [NSManagedObjectID: PinScrollerButton] = [:]
    
    // MARK: Button Reuse
    
    private var reusableButtons: [PinScrollerButton] = []
    
    private func reuse(button: PinScrollerButton) {
        button.removeFromSuperview()
        reusableButtons.append(button)
    }
    
    private func makeButton(style: PinScrollerButton.Style) -> PinScrollerButton {
        if let reused = reusableButtons.popLast() {
            reused.style = style
            addSubview(reused)
            return reused
        }
        let button = PinScrollerButton()
        button.action = #selector(pinViewTapped(_:))
        button.target = self
        button.style = style
        addSubview(button)
        return button
    }
    
    override func layout() {
        super.layout()
        
        layoutPinViews()
    }
    
    // MARK: Pins
    
    func layoutPinViews() {
        let totalCount = (tableView?.numberOfRows ?? 0)
        guard totalCount > 0 else {
            return // Not reloaded yet
        }
        let height = bounds.height - 10
        func layout(button: PinScrollerButton) {
            let y = height * (CGFloat(button.index) / CGFloat(totalCount))
            let frame = CGRect(x: 0, y: y, width: bounds.width, height: PinScrollerButton.preferreHeight)
            if button.frame != frame {
                button.frame = frame
            }
        }
        for button in pinScrollerButtons.values {
            layout(button: button)
        }
        for button in errorButtons.values {
            layout(button: button)
        }
    }
    
    func refreshErrorsAndWarningsPins(_ messages: [LoggerMessageEntity], isShowingErrors: Bool) {
        for button in errorButtons.values {
            reuse(button: button)
        }
        errorButtons.removeAll()
        
        guard isShowingErrors else { return }
        
        struct Item {
            let index: Int
            let objectID: NSManagedObjectID
        }
        
        var items: [Item] = []
        
        for index in messages.indices {
            let message = messages[index]
            let level = LoggerStore.Level(rawValue: message.level) ?? .debug
            if level == .error || level == .critical {
                items.append(.init(index: index, objectID: message.objectID))
            }
        }
        
        guard items.count < 20 else {
            return // that's too many
        }
        
        for item in items {
            let button = makeButton(style: .error)
            errorButtons[item.objectID] = button
            button.index = item.index
        }
        if items.count > 0 {
            layoutPinViews()
        }
    }

    func refreshPinViews<C: Collection>(_ pins: Set<NSManagedObjectID>, _ objects: C, isOnlyPins: Bool) where C.Element: NSManagedObject {
        guard !isOnlyPins else {
            for button in pinScrollerButtons.values {
                reuse(button: button)
            }
            pinScrollerButtons = [:]
            return
        }
        
        if pins.isEmpty && pinScrollerButtons.isEmpty {
            return
        }

        // Update indices
        var visiblePinnedMessageIDs: Set<NSManagedObjectID> = []
        var index = 0
        var foundPins = 0
        for object in objects {
            let objectID = object.objectID
            if pins.contains(objectID) {
                visiblePinnedMessageIDs.insert(objectID)
                if let button = pinScrollerButtons[objectID] {
                    button.index = index
                } else {
                    let button = makeButton(style: .pin)
                    pinScrollerButtons[objectID] = button
                    button.index = index
                }
                foundPins += 1
                if foundPins == pins.count {
                    break // OK, nothing else to do
                }
            }
            index += 1
        }
        
        // Remove no longer visible pins
        pinScrollerButtons.keys.filter { !pins.contains($0) }.forEach {
            if let view = pinScrollerButtons.removeValue(forKey: $0) {
                reuse(button: view)
            }
        }
        
        // And finally layout. Technically we could skip existing keys
        layoutPinViews()
    }
    
    @objc func pinViewTapped(_ button: PinScrollerButton) {
        guard let tableView = self.tableView, let scrollView = tableView.enclosingScrollView else {
            return assertionFailure()
        }
        
        let headerHeight = tableView.headerView?.bounds.height ?? 0
        let offsetY = tableView.bounds.height * (CGFloat(button.index) / CGFloat(tableView.numberOfRows))
        tableView.scrollToVisible(CGRect(x: 0, y: offsetY - (scrollView.bounds.height - headerHeight) / 2, width: scrollView.bounds.width, height: scrollView.bounds.height))
    }
}
