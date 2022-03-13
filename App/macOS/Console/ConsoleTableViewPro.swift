// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).


import SwiftUI
import PulseCore
import CoreData
import Combine
import AppKit

struct ConsoleTableViewPro: NSViewRepresentable {
    @ObservedObject var list: ManagedObjectsList<LoggerMessageEntity>
    private let main: ConsoleMainViewModel
    
    init(model: ConsoleMainViewModel) {
        self.main = model
        self.list = model.list
    }
    
    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        private let main: ConsoleMainViewModel
        private let list: ManagedObjectsList<LoggerMessageEntity>
        
        private var colorPrimary = NSColor.labelColor
        private var colorSecondary = NSColor.secondaryLabelColor
        private var colorOrange = NSColor.systemOrange
        private var colorRed = Palette.red
        
        var cancellables: [AnyCancellable] = []
        
        // TODO: make sure it adjust dynamically when scheme changes
        func color(for level: LoggerStore.Level) -> NSColor {
            switch level {
            case .trace: return colorSecondary
            case .debug, .info: return colorPrimary
            case .notice, .warning: return colorOrange
            case .error, .critical: return colorRed
            }
        }

        init(main: ConsoleMainViewModel) {
            self.list = main.list
            self.main = main
        }
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            list.count
        }
    
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let message = list[row]
    
            func makePlainCell(text: String) -> PlainTableCell {
                let cell = PlainTableCell.make(in: tableView)
                let level = LoggerStore.Level(rawValue: message.level) ?? .debug
                cell.display(text, color: color(for: level))
                return cell
            }
            
            guard let column = tableColumn, let item = ConsoleColumn(rawValue: column.identifier.rawValue) else {
                return nil
            }
            
            switch item {
            case .index:
                let cell = IndexTableCell.make(in: tableView)
                cell.text = "\(row + 1)"
                cell.isPinned = main.pins.pinnedMessageIds.contains(message.objectID)
                return cell
            case .dateAndTime: return makePlainCell(text: dateAndTimeFormatter.string(from: message.createdAt))
            case .date: return makePlainCell(text: dateFormatter.string(from: message.createdAt))
            case .time: return makePlainCell(text: timeFormatter.string(from: message.createdAt))
            case .interval:
                let first = main.earliestMessage ?? list[0]
                var interval = message.createdAt.timeIntervalSince1970 - first.createdAt.timeIntervalSince1970
                if interval > (3600 * 24) {
                    return makePlainCell(text: "1+ day")
                } else {
                    interval = list.isCreatedAtAscending ? interval : (interval >= 0.001 ? -interval : interval)
                    return makePlainCell(text: "\(stringPrecise(from: interval))")
                }
            case .level: return makePlainCell(text: message.level)
            case .label: return makePlainCell(text: message.label)
            case .status:
                guard let request = message.request else {
                    return nil
                }
                let cell = BadgeTableCell.make(in: tableView)
                cell.color = request.isSuccess ? NSColor.systemGreen : NSColor.systemRed
                return cell
            case .message: return makePlainCell(text: message.text)
            case .file: return makePlainCell(text: message.file)
            case .filename: return makePlainCell(text: message.filename)
            case .function: return makePlainCell(text: message.function)
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
            openMessage(list[tableView.clickedRow])
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
        let tableView = ConsoleTableView()
        tableView.model = list
        tableView.main = main

        // Configure header view
        let headerView = NSTableHeaderView()
        tableView.headerView = headerView
        
        // Configure visible columns and associated header menu
        let visibleColumns = AppSettings.shared.mappedConsoleVisibleColumns
        
        let menu = NSMenu()
        menu.delegate = tableView

        for item in ConsoleColumn.allCases {
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
            case .status: menuItemTitle = "State"
            case .index: menuItemTitle = "Index"
            default: menuItemTitle = column.title
            }
            let menuItem = NSMenuItem(title: menuItemTitle, action: #selector(ConsoleTableView.toggleColumn(_:)), keyEquivalent: "")
            menuItem.target = tableView
            menuItem.state = visibleColumns.contains(item) ? .on : .off
            menuItem.representedObject = column
            menu.addItem(menuItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // TODO: reimplement when this is done
//        let showErrorsItem = NSMenuItem(title: "Errors Minimap", action: #selector(ConsoleTableView.buttonToggleErrorsPressed(_:)), keyEquivalent: "")
//        showErrorsItem.target = tableView
//        menu.addItem(showErrorsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let resetMenuItem = NSMenuItem(title: "Reset", action: #selector(ConsoleTableView.resetColumns(_:)), keyEquivalent: "")
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
        scrollView.hasHorizontalRuler = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .clear
        scrollView.documentView = tableView

        // Configure observables
        Publishers.CombineLatest(main.pins.$pinnedMessageIds, main.toolbar.$isOnlyPins)
            .sink { [weak tableView, weak scroller, weak main] in
                guard let main = main else { return }
                scroller?.refreshPinViews($0, main.list, isOnlyPins: $1)
                DispatchQueue.main.async {
                    tableView?.reloadColumn(withIdentifier: ConsoleColumn.index.identifier)
                }
            }.store(in: &context.coordinator.cancellables)
        
        // TODO: renable when a better solution is found
//        model.$messages.sink { [scroller] in
//            scroller.refreshErrorsAndWarningsPins($0, isShowingErrors: model.isShowingErrorsInScroller)
//        }.store(in: &context.coordinator.cancellables)
        
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
private final class ConsoleTableView: NSTableView, NSMenuDelegate {
    var main: ConsoleMainViewModel!
    var model: ManagedObjectsList<LoggerMessageEntity>!
    
    // MARK: Managing Columns
    
    @objc func toggleColumn(_ menu: NSMenuItem) {
        let column = menu.representedObject as! NSTableColumn

        column.isHidden = !column.isHidden
        menu.state = isHidden ? .off : .on
        
        var columns = AppSettings.shared.mappedConsoleVisibleColumns
        let item = ConsoleColumn(rawValue: column.identifier.rawValue)!
        if column.isHidden { columns.remove(item) } else { columns.insert(item) }
        AppSettings.shared.mappedConsoleVisibleColumns = columns
        
        isHidden ? sizeLastColumnToFit() : sizeToFit()
    }
    
    @objc func resetColumns(_ menu: NSMenuItem) {
        let defaults = Set(ConsoleColumn.defaultSelection)
        AppSettings.shared.mappedConsoleVisibleColumns = defaults
        
        let defaultsIds = Set(defaults.map { $0.identifier })
        for column in tableColumns {
            column.isHidden = !defaultsIds.contains(column.identifier)
        }
        
        isHidden ? sizeLastColumnToFit() : sizeToFit()
    }
    
    @objc func buttonToggleErrorsPressed(_ item: NSMenuItem) {
        main.isShowingErrorsInScroller.toggle()
        let isShowing = main.isShowingErrorsInScroller
        item.state = isShowing ? .on : .off
        #warning("TODO: reimplement")
        // (enclosingScrollView?.verticalScroller as? TableScroller)?.refreshErrorsAndWarningsPins(model.messages, isShowingErrors: isShowing)
    }
    
    // MARK: Reload
    
    func process(update: FetchedObjectsUpdate) {
        let selectedMessageID = (selectedRow == -1 || model.count <= selectedRow) ? nil : model[selectedRow].id
        
        switch update {
        case .append(let range):
            insertRows(at: IndexSet(integersIn: range), withAnimation: [])
            if !model.isCreatedAtAscending {
                reloadColumn(withIdentifier: ConsoleColumn.index.identifier)
            }
        case .reload:
            reloadData()
            (enclosingScrollView?.verticalScroller as? TableScroller)?.refreshPinViews(main.pins.pinnedMessageIds, main.list, isOnlyPins: main.toolbar.isOnlyPins)
        }
        
        if main.toolbar.isNowEnabled {
            scrollToBottom()
        }

        // Restore selection
        if let selectedObjectID = selectedMessageID {
            let range = rows(in: visibleRect)
            for index in range.lowerBound..<range.upperBound {
                if model[index].id == selectedObjectID {
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
        didSet {
            // Important!
            oldValue?.removeFromSuperview()
            if let view = currentMenuView { addSubview(view) }
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
        guard let model = self.model else { return nil }
        
        let row = row(at: convert(event.locationInWindow, from: nil))
        let column = column(at: convert(event.locationInWindow, from: nil))
        guard row >= 0 && column >= 0 else { return nil }
        
        let cellView = view(atColumn: column, row: row, makeIfNecessary: false)
        
        let message = model[row]
        
        var menu: NSMenu?
        if let request = message.request {
            let model = ConsoleNetworkRequestContextMenuViewModelPro(message: message, request: request, store: main.context.store, pins: main.pins)
            let view = ConsoleNetworkRequestContextMenuViewPro(model: model)
            menu = view.menu(for: event)
            
            currentMenuView = view
        } else {
            menu = makeMenu(for: message)
        }
        
        if let menuItem = makeCopyCellValueItem(with: cellView) {
            menu?.insertItem(menuItem, at: 0)
            menu?.insertItem(NSMenuItem.separator(), at: 1)
        }
        
        self.menu = menu
        return super.menu(for: event)
    }
    
    private func makeCopyCellValueItem(with cellView: NSView?) -> NSMenuItem? {
        guard let stringValue = (cellView as? PlainTableCell)?.stringValue else {
            return nil
        }
        let copyValueItem = NSMenuItem(title: "Copy Cell Value", action: #selector(copyCellValuePressed), keyEquivalent: "c")
        copyValueItem.target = self
        copyValueItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        copyValueItem.representedObject = stringValue
        return copyValueItem
    }
    
    // MARK: LoggerMessageEntity Menu
    
    private func makeMenu(for message: LoggerMessageEntity) -> NSMenu {
        let menu = NSMenu()
        
        let hideLabelItem = NSMenuItem(title: "Hide \'\(message.label)\'", action: #selector(buttonHideLabelTapped(_:)), keyEquivalent: "")
        hideLabelItem.target = self
        hideLabelItem.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: nil)
        hideLabelItem.representedObject = message.label
        
        let hideLevelItem = NSMenuItem(title: "Hide \'\(message.level)\'", action: #selector(buttonHideLevelTapped(_:)), keyEquivalent: "")
        hideLevelItem.target = self
        hideLevelItem.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: nil)
        hideLevelItem.representedObject = LoggerStore.Level(rawValue: message.level)
        
        let showLabelItem = NSMenuItem(title: "Show \'\(message.label)\'", action: #selector(buttonShowLabelTapped(_:)), keyEquivalent: "")
        showLabelItem.target = self
        showLabelItem.image = NSImage(systemSymbolName: "eye", accessibilityDescription: nil)
        showLabelItem.representedObject = message.label
        
        let showLevelItem = NSMenuItem(title: "Show \'\(message.level)\'", action: #selector(buttonShowLevelTapped(_:)), keyEquivalent: "")
        showLevelItem.target = self
        showLevelItem.image = NSImage(systemSymbolName: "eye", accessibilityDescription: nil)
        showLevelItem.representedObject = LoggerStore.Level(rawValue: message.level)
        
        let copyItem = NSMenuItem(title: "Copy Message", action: #selector(buttonCopyTapped(_:)), keyEquivalent: "")
        copyItem.target = self
        copyItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        copyItem.representedObject = message.text
        
        let isPinned = main.pins.isPinned(message)
        let pinItem = NSMenuItem(title: isPinned ? "Remove Pin" : "Pin", action: #selector(buttonPinTapped), keyEquivalent: "p")
        pinItem.target = self
        pinItem.image = NSImage(systemSymbolName: isPinned ? "pin.slash" : "pin", accessibilityDescription: nil)
        pinItem.representedObject = message

        menu.addItem(copyItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(hideLevelItem)
        menu.addItem(hideLabelItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(showLevelItem)
        menu.addItem(showLabelItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(pinItem)

        return menu
    }
                    
    @objc func buttonHideLabelTapped(_ item: NSMenuItem) {
        let label = item.representedObject as! String
        main!.filters.criteria.labels.hidden.insert(label)
    }
    
    @objc func buttonShowLabelTapped(_ item: NSMenuItem) {
        let label = item.representedObject as! String
        main!.filters.criteria.labels.focused = label
    }
    
    @objc func buttonHideLevelTapped(_ item: NSMenuItem) {
        let level = item.representedObject as! LoggerStore.Level
        main!.filters.criteria.logLevels.levels.remove(level)
    }
    
    @objc func buttonShowLevelTapped(_ item: NSMenuItem) {
        let level = item.representedObject as! LoggerStore.Level
        main!.filters.criteria.logLevels.levels = [level]
    }
    
    @objc func buttonCopyTapped(_ item: NSMenuItem) {
        let text = item.representedObject as! String
        UXPasteboard.general.string = text
    }
    
    @objc func buttonPinTapped(_ item: NSMenuItem) {
        let message = item.representedObject as! LoggerMessageEntity
        main!.pins.togglePin(for: message)
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

enum ConsoleColumn: String, Hashable, CaseIterable {
    case status = "status"
    case index = "index"
    case dateAndTime = "dateAndTime"
    case date = "date"
    case time = "time"
    case interval = "interval"
    case level = "level"
    case label = "label"
    case message = "message"
    case file = "file"
    case filename = "filename"
    case function = "function"
    
    static let defaultSelection: [ConsoleColumn] = [
        .status, .index, .time, .interval, .label, .message
    ]
    
    var title: String {
        switch self {
        case .status: return ""
        case .index: return ""
        case .dateAndTime: return "Date & Time"
        case .date: return "Date"
        case .time: return "Time"
        case .interval: return "Interval"
        case .level: return "Level"
        case .label: return "Label"
        case .message: return "Message"
        case .file: return "File"
        case .filename: return "Filename"
        case .function: return "Function"
        }
    }
    
    var preferredWidth: CGFloat {
        switch self {
        case .status: return 10
        case .index: return 34
        case .dateAndTime: return 152
        case .date: return 81
        case .time: return 81
        case .interval: return 64
        case .level: return 46
        case .label: return 68
        case .message: return 320
        case .file: return 136
        case .filename: return 136
        case .function: return 136
        }
    }
    
    var minWidth: CGFloat? {
        switch self {
        case .status: return preferredWidth
        case .index: return 10
        case .dateAndTime: return preferredWidth
        case .date: return preferredWidth
        case .time: return preferredWidth
        case .interval: return preferredWidth - 10
        case .level: return preferredWidth
        case .label: return 40
        case .message: return 100
        case .file: return 50
        case .filename: return 50
        case .function: return 50
        }
    }
    
    var sortDescriptorProtot: NSSortDescriptor? {
        switch self {
        case .dateAndTime, .date, .time, .interval:
            return NSSortDescriptor(keyPath: \LoggerMessageEntity.createdAt, ascending: false)
        case .level:
            return NSSortDescriptor(keyPath: \LoggerMessageEntity.levelOrder, ascending: false)
        case .label:
            return NSSortDescriptor(keyPath: \LoggerMessageEntity.label, ascending: true)
        case .message:
            return NSSortDescriptor(keyPath: \LoggerMessageEntity.text, ascending: true)
        case .file:
            return NSSortDescriptor(keyPath: \LoggerMessageEntity.file, ascending: true)
        case .filename:
            return NSSortDescriptor(keyPath: \LoggerMessageEntity.filename, ascending: true)
        case .function:
            return NSSortDescriptor(keyPath: \LoggerMessageEntity.function, ascending: true)
        case .status:
            return NSSortDescriptor(keyPath: \LoggerMessageEntity.requestState, ascending: true)
        case .index: return nil
        }
    }
    
    var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(rawValue: rawValue)
    }
}
