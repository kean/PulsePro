//
//  TableViewExtensions.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/19/21.
//  Copyright © 2021 kean. All rights reserved.
//

import AppKit

extension NSTableView {
    func scrollToBottom() {
        if numberOfRows > 0 {
            scrollRowToVisible(numberOfRows - 1)
        }
    }
    
    func reloadColumn(withIdentifier identifier: NSUserInterfaceItemIdentifier) {
        let index = column(withIdentifier: identifier)
        guard index >= 0 else { return }

        let rows = rows(in: visibleRect)
        reloadData(forRowIndexes: IndexSet(integersIn: rows.lowerBound..<rows.upperBound), columnIndexes: IndexSet(integer: index))
    }
}
