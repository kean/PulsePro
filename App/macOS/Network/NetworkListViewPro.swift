// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).


import SwiftUI
import PulseCore
import CoreData
import Combine
import AppKit

struct NetworkListViewPro: NSViewRepresentable {
    @ObservedObject var list: ManagedObjectsList<LoggerNetworkRequestEntity>
    let main: NetworkMainViewModel
    
    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        private let list: ManagedObjectsList<LoggerNetworkRequestEntity>
        private let main: NetworkMainViewModel
        
        var cancellables: [AnyCancellable] = []
        
        private var colorPrimary = NSColor.labelColor
        private var colorSecondary = NSColor.secondaryLabelColor
        private var colorOrange = NSColor.systemOrange
        private var colorRed = Palette.red
        
        // TODO: make sure it adjust dynamically when scheme changes
        func color(for isSuccess: Bool) -> NSColor {
            switch isSuccess {
            case true: return colorPrimary
            case false: return colorRed
            }
        }

        init(main: NetworkMainViewModel) {
            self.main = main
            self.list = main.list
        }
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            list.count
        }
    
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let request = list[row]
            
            func makePlainCell(text: String) -> PlainTableCell {
                let cell = PlainTableCell.make(in: tableView)
                cell.display(text, color: color(for: request.isSuccess))
                return cell
            }
            
            guard let column = tableColumn, let item = NetworkListColumn(rawValue: column.identifier.rawValue) else {
                return nil
            }
            
            switch item {
            case .index:
                let cell = IndexTableCell.make(in: tableView)
                cell.text = "\(row + 1)"
                cell.isPinned = main.pins.pinnedRequestIds.contains(request.objectID)
                return cell
            case .dateAndTime: return makePlainCell(text: dateAndTimeFormatter.string(from: request.createdAt))
            case .date: return makePlainCell(text: dateFormatter.string(from: request.createdAt))
            case .time: return makePlainCell(text: timeFormatter.string(from: request.createdAt))
            case .interval:
                let first = main.earliestMessage ?? list[0]
                var interval = request.createdAt.timeIntervalSince1970 - first.createdAt.timeIntervalSince1970
                if interval > (3600 * 24) {
                    return makePlainCell(text: "—")
                } else {
                    interval = list.isCreatedAtAscending ? interval : (interval >= 0.001 ? -interval : interval)
                    return makePlainCell(text: "\(stringPrecise(from: interval))")
                }
            case .url: return makePlainCell(text: request.url ?? "–")
            case .host: return makePlainCell(text: request.host ?? "–")
            case .method: return makePlainCell(text: request.httpMethod ?? "–")
            case .statusCode: return makePlainCell(text: request.statusCode == 0 ? "–" : "\(request.statusCode)")
            case .duration: return makePlainCell(text: DurationFormatter.string(from: request.duration))
            case .uncompressedRequestSize: return makePlainCell(text: ByteCountFormatter.string(fromByteCount: request.details.requestBodySize, countStyle: .file))
            case .uncompressedResponseSize: return makePlainCell(text: ByteCountFormatter.string(fromByteCount: request.details.responseBodySize, countStyle: .file))
            case .error: return makePlainCell(text: request.errorCode != 0 ? "\(request.errorCode) (\(descriptionForURLErrorCode(Int(request.errorCode))))" : "–")
            case .statusIcon:
                let cell = BadgeTableCell.make(in: tableView)
                cell.color = request.isSuccess ? NSColor.systemGreen : NSColor.systemRed
                return cell
            }
        }
        
        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            26
        }
        
        func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
            main.setSortDescriptor(tableView.sortDescriptors)
            if let descriptor = tableView.sortDescriptors.first(where: { $0.key == "createdAt" }) {
                list.isCreatedAtAscending = descriptor.ascending
            }
        }

        func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
            if tableView.view(atColumn: tableView.clickedColumn, row: row, makeIfNecessary: false) is IndexTableCell {
                return false
            } else {
                return true
            }
        }
        
        @objc func tableViewClicked(_ tableView: NSTableView) {
            let (row, column) = (tableView.clickedRow, tableView.clickedColumn)
            guard row >= 0 && column >= 0 else { return }
            if let indexCell = tableView.view(atColumn: column, row: row, makeIfNecessary: false) as? IndexTableCell {
                main.pins.togglePin(for: list[row])
                indexCell.isPinned.toggle()
            }
        }

        @objc func tableViewDoubleClick(_ tableView: NSTableView) {
            guard tableView.clickedRow >= 0 else { return }
            guard let message = list[tableView.clickedRow].message else { return }
            openMessage(message)
        }

        private func openMessage(_ message: LoggerMessageEntity) {
            AppRouter.shared.openDetails(view: AnyView(
                main.details.makeDetailsRouter(for: message, onClose: nil)
                    .frame(minWidth: 500, idealWidth: 700, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 500, idealHeight: 800, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            ))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(main: main)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let tableView = NetworkTableView()
        tableView.main = main

        tableView.headerView = NSTableHeaderView()

        let visibleColumns = AppSettings.shared.mappedNetworkListVisibleColumns
        
        let menu = NSMenu()
        menu.delegate = tableView

        for item in NetworkListColumn.allCases {
            let column = NSTableColumn(identifier: item.identifier)
            column.headerCell = NSTableHeaderCell(textCell: item.title)
            column.width = item.preferredWidth
            if let minWidth = item.minWidth {
                column.minWidth = minWidth
            }
            column.isHidden = !visibleColumns.contains(item)
            if let sortDescriptor = item.sortDescriptorProtot {
                column.sortDescriptorPrototype = sortDescriptor
            }
            tableView.addTableColumn(column)
            
            let menuItemTitle: String
            switch item {
            case .statusIcon: menuItemTitle = "State"
            case .index: menuItemTitle = "Index"
            default: menuItemTitle = column.title
            }
            let menuItem = NSMenuItem(title: menuItemTitle, action: #selector(NetworkTableView.toggleColumn(_:)), keyEquivalent: "")
            menuItem.target = tableView
            menuItem.state = visibleColumns.contains(item) ? .on : .off
            menuItem.representedObject = column
            menu.addItem(menuItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let resetMenuItem = NSMenuItem(title: "Reset", action: #selector(NetworkTableView.resetColumns(_:)), keyEquivalent: "")
        resetMenuItem.target = tableView
        menu.addItem(resetMenuItem)
        
        tableView.headerView?.menu = menu

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        
        tableView.target = context.coordinator
        tableView.doubleAction = #selector(Coordinator.tableViewDoubleClick(_:))
        tableView.action = #selector(Coordinator.tableViewClicked(_:))

        tableView.style = .sourceList
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.backgroundColor = .clear
        
        let scroller = TableScroller()
        scroller.tableView = tableView
        
        let scrollView = NSScrollView()
        scrollView.verticalScroller = scroller
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .clear
        scrollView.documentView = tableView
        
        Publishers.CombineLatest(main.pins.$pinnedRequestIds, main.toolbar.$isOnlyPins)
            .sink { [weak tableView, weak scroller, weak main] in
                guard let main = main else { return }
                scroller?.refreshPinViews($0, main.list, isOnlyPins: $1)
                DispatchQueue.main.async {
                    tableView?.reloadColumn(withIdentifier: ConsoleColumn.index.identifier)
                }
            }.store(in: &context.coordinator.cancellables)
        
        main.toolbar.$isNowEnabled.dropFirst().sink { [weak tableView] in
            if $0 {
                tableView?.scrollToBottom()
            }
        }.store(in: &context.coordinator.cancellables)
        
        main.list.updates.sink { [weak tableView] in
            tableView?.process(update: $0)
        }.store(in: &context.coordinator.cancellables)
        
        main.list.scrollToIndex.sink { [weak tableView] in
            tableView?.scroll(to: $0)
        }.store(in: &context.coordinator.cancellables)
         
        NotificationCenter.default.publisher(for: NSScrollView.didLiveScrollNotification, object: scrollView).sink { [weak main] _ in
            main?.toolbar.isNowEnabled = false
        }.store(in: &context.coordinator.cancellables)
        
        NotificationCenter.default.publisher(for: NSTableView.selectionDidChangeNotification, object: tableView).sink { [weak main] in
            guard let table = $0.object as? NSTableView else { return }
            let row = table.selectedRow
            main?.selectEntityAt(row)
        }.store(in: &context.coordinator.cancellables)

        if main.toolbar.isNowEnabled {
            tableView.scrollToBottom()
        }
        
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Do nothing
    }
}

// All these tricks ensure dynamic context menu work.
private final class NetworkTableView: NSTableView, NSMenuDelegate {
    var main: NetworkMainViewModel!
    var model: ManagedObjectsList<LoggerNetworkRequestEntity> { main.list }
    
    @objc func toggleColumn(_ menu: NSMenuItem) {
        let column = menu.representedObject as! NSTableColumn

        column.isHidden = !column.isHidden
        menu.state = isHidden ? .off : .on
        
        var columns = AppSettings.shared.mappedNetworkListVisibleColumns
        let item = NetworkListColumn(rawValue: column.identifier.rawValue)!
        if column.isHidden { columns.remove(item) } else { columns.insert(item) }
        AppSettings.shared.mappedNetworkListVisibleColumns = columns
        
        isHidden ? sizeLastColumnToFit() : sizeToFit()
    }
    
    @objc func resetColumns(_ menu: NSMenuItem) {
        let defaults = Set(NetworkListColumn.defaultSelection)
        AppSettings.shared.mappedNetworkListVisibleColumns = defaults
        
        let defaultsIds = Set(defaults.map { $0.identifier })
        for column in tableColumns {
            column.isHidden = !defaultsIds.contains(column.identifier)
        }
        
        isHidden ? sizeLastColumnToFit() : sizeToFit()
    }
    
    // MARK: Reload
    
    func process(update: FetchedObjectsUpdate) {
        let selectedMessageID = (selectedRow == -1 || model.count <= selectedRow) ? nil : model[selectedRow].objectID
        
        switch update {
        case .append(let range):
            insertRows(at: IndexSet(integersIn: range), withAnimation: [])
            if !model.isCreatedAtAscending {
                let index = column(withIdentifier: NetworkListColumn.index.identifier)
                if index >= 0 {
                    let rows = rows(in: visibleRect)
                    reloadData(forRowIndexes: IndexSet(integersIn: rows.lowerBound..<rows.upperBound), columnIndexes: IndexSet(integer: index))
                }
            }
        case .reload:
            reloadData()
            (enclosingScrollView?.verticalScroller as? TableScroller)?.refreshPinViews(main.pins.pinnedRequestIds, main.list, isOnlyPins: main.toolbar.isOnlyPins)
        }
        
        if main.toolbar.isNowEnabled {
            scrollToBottom()
        }
        
        // Restore selection
        if let selectedObjectID = selectedMessageID {
            let range = rows(in: visibleRect)
            for index in range.lowerBound..<range.upperBound {
                if model[index].objectID == selectedObjectID {
                    selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                    break
                }
            }
        }
    }
    
    func scroll(to index: Int) {
        main.toolbar.isNowEnabled = false
        scrollRowToVisible(index)
        selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
    }
    
    // MARK: Context Menus
    
    var currentMenuView: NSView? {
        get {
            return nil
        }
        set {
            // Important!
            currentMenuView?.removeFromSuperview()
            if let view = newValue { addSubview(view) }
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        for item in menu.items {
            if let column = item.representedObject as? NSTableColumn {
                item.state = column.isHidden ? .off : .on
            }
        }
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        guard let main = self.main else { return nil }
        
        let row = row(at: convert(event.locationInWindow, from: nil))
        let column = column(at: convert(event.locationInWindow, from: nil))
        guard row >= 0 && column >= 0 else { return nil }
        
        let request = model[row]
        guard let message = request.message else {
            assertionFailure() // Should never happen
            return nil
        }
        
        let cellView = view(atColumn: column, row: row, makeIfNecessary: false)
        let stringValue = (cellView as? PlainTableCell)?.stringValue
        
        let menuModel = ConsoleNetworkRequestContextMenuViewModelPro(message: message, request: request, store: main.store, pins: main.pins)
        let view = ConsoleNetworkRequestContextMenuViewPro(model: menuModel)
        let menu = view.menu(for: event)
        
        if let stringValue = stringValue {
            let copyValueItem = NSMenuItem(title: "Copy Cell Value", action: #selector(copyCellValuePressed), keyEquivalent: "c")
            copyValueItem.target = self
            copyValueItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
            copyValueItem.representedObject = stringValue
            
            menu?.insertItem(copyValueItem, at: 0)
            menu?.insertItem(NSMenuItem.separator(), at: 1)
        }

        self.menu = menu
        currentMenuView = view
        return super.menu(for: event)
    }
    
    @objc private func copyCellValuePressed(_ item: NSMenuItem) {
        let value = item.representedObject as! String
        UXPasteboard.general.string = value
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()

private let dateAndTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()

// MARK: Columns

enum NetworkListColumn: String, Hashable, CaseIterable {
    case statusIcon = "statusIcon"
    case index = "index"
    case dateAndTime = "dateAndTime"
    case date = "date"
    case time = "time"
    case interval = "interval"
    case method = "method"
    case url = "url"
    case host = "host"
    case statusCode = "statusCode"
    case duration = "duration"
    case uncompressedRequestSize = "uncompressedRequestSize"
    case uncompressedResponseSize = "uncompressedResponseSize"
    case error = "error"
    
    static let defaultSelection: [NetworkListColumn] = [
        .statusIcon, .index, .time, .method, .url, .statusCode, .duration
    ]

    var title: String {
        switch self {
        case .statusIcon: return ""
        case .index: return ""
        case .dateAndTime: return "Date & Time"
        case .date: return "Date"
        case .time: return "Time"
        case .interval: return "Interval"
        case .method: return "Method"
        case .url: return "URL"
        case .host: return "Host"
        case .statusCode: return "Code"
        case .duration: return "Duration"
        case .uncompressedRequestSize: return "Request Size"
        case .uncompressedResponseSize: return "Response Size"
        case .error: return "Error"
        }
    }

    var preferredWidth: CGFloat {
        switch self {
        case .statusIcon: return 10
        case .index: return 34
        case .dateAndTime: return 152
        case .date: return 81
        case .time: return 81
        case .interval: return 64
        case .method: return 34
        case .url: return 230
        case .host: return 100
        case .statusCode: return 30
        case .duration: return 60
        case .uncompressedRequestSize: return 70
        case .uncompressedResponseSize: return 70
        case .error: return 70
        }
    }

    var minWidth: CGFloat? {
        switch self {
        case .statusIcon: return preferredWidth
        case .index: return 10
        case .dateAndTime: return preferredWidth
        case .date: return preferredWidth
        case .time: return preferredWidth
        case .interval: return preferredWidth - 10
        case .method: return 40
        case .url: return 40
        case .host: return 40
        case .statusCode: return preferredWidth
        case .duration: return preferredWidth
        case .uncompressedRequestSize: return 40
        case .uncompressedResponseSize: return 40
        case .error: return 40
        }
    }

    var sortDescriptorProtot: NSSortDescriptor? {
        switch self {
        case .dateAndTime, .date, .time, .interval:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.createdAt, ascending: false)
        case .url:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.url, ascending: false)
        case .host:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.host, ascending: false)
        case .method:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.httpMethod, ascending: false)
        case .statusCode:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.statusCode, ascending: false)
        case .duration:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.duration, ascending: false)
        case .uncompressedRequestSize:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.details.requestBodySize, ascending: false)
        case .uncompressedResponseSize:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.details.responseBodySize, ascending: false)
        case .error:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.errorCode, ascending: false)
        case .statusIcon:
            return NSSortDescriptor(keyPath: \LoggerNetworkRequestEntity.requestState, ascending: false)
        case .index:
            return nil
        }
    }

    var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(rawValue: rawValue)
    }
}
