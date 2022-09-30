//
//  SiderbarViewController.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/27/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import AppKit
import SwiftUI
import Combine

struct SiderbarViewPro: NSViewControllerRepresentable {
    let viewModel: MainViewModelPro
    var remote: RemoteLoggerViewModel
    
    func makeNSViewController(context: Context) -> SidebarViewController {
        let vc = SidebarViewController()
        vc.viewModel = viewModel
        vc.remote = remote
        return vc
    }
    
    func updateNSViewController(_ vc: SidebarViewController, context: Context) {
//        vc.reload()
    }
}

final class SidebarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, SidebarTableViewDelegate {
    var viewModel: MainViewModelPro!
    var remote: RemoteLoggerViewModel!
    
    private let tableView = SiderbarTableView()
    
    private var items: [Any] = []
    
    private var cancellables: [AnyCancellable] = []
    
    override func loadView() {
        view = NSView(frame: .zero)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sidebarDelegate = self
        
        tableView.headerView = nil
        
        let column = NSTableColumn(identifier: .init(rawValue: "a"))
        column.resizingMask = .autoresizingMask
        
        tableView.addTableColumn(column)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        tableView.target = self
        tableView.doubleAction = #selector(SidebarViewController.tableViewDoubleClick)
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = tableView
        
        view.addSubview(scrollView)
        scrollView.anchors.edges.pin()
        
        remote.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async { self?.reload() }
        }.store(in: &cancellables)
        
        self.reload()
    }
    
    func reload() {
        var items: [Any] = []
        items.append(SectionHeaderModel(text: "Devices"))
        for client in remote.clients {
            items.append(client)
        }
        self.items = items
        
        tableView.reloadData()
        
        if let selectedClient = viewModel.details.viewModel?.remote.client {
            if let index = items.firstIndex(where: { ($0 as? RemoteLoggerClient)?
                .id == selectedClient.id }) {
                tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            } else {
                if viewModel.details.viewModel?.remote.client != nil {
                    viewModel.details.viewModel = nil
                } else {
                    // Important! Existing store was open
                }
            }
        }
    }
    
    // MARK: DoubleClick
    
    @objc private func tableViewDoubleClick() {
        guard items.indices.contains(tableView.clickedRow) else { return }

        switch items[tableView.clickedRow] {
        case is SectionHeaderModel:
            return
        case let client as RemoteLoggerClient:
            AppRouter.shared.openMainView(client: client)
        default:
            fatalError()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0 else { return }
        switch items[row] {
        case is SectionHeaderModel:
            break
        case let client as RemoteLoggerClient:
            if viewModel.details.viewModel?.remote.client?.id != client.id {
                viewModel.open(client: client)
            }
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch items[row] {
        case let header as SectionHeaderModel:
            return NSHostingView(rootView: SiderbarSectionTitle2(text: header.text))
        case let client as RemoteLoggerClient:
            let cell = RemoteLoggerClientTableViewCell.make(in: tableView)
            cell.display(client: client)
            return cell
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch items[row] {
        case is SectionHeaderModel:
            return 20
        case is RemoteLoggerClient:
            return 27
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        switch items[row] {
        case is SectionHeaderModel:
            return false
        case is RemoteLoggerClient:
            return true
        default:
            fatalError()
        }
    }
    
    // MARK: - SiderbarTableViewDelegate
    
    func getClient(at index: Int) -> RemoteLoggerClient? {
        guard items.indices.contains(index) else { return nil }
        return items[index] as? RemoteLoggerClient
    }
}

private protocol SidebarTableViewDelegate: AnyObject {
    func getClient(at index: Int) -> RemoteLoggerClient?
}

private final class SiderbarTableView: NSTableView {
    weak var sidebarDelegate: SidebarTableViewDelegate?
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let row = row(at: convert(event.locationInWindow, from: nil))
        
        guard let client = sidebarDelegate?.getClient(at: row) else {
            return nil
        }
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        let openInWindowItem = NSMenuItem(title: "Open in Window", action: #selector(menuOpenInWindowButtonPressed), keyEquivalent: "")
        openInWindowItem.target = self
        openInWindowItem.representedObject = client
        menu.addItem(openInWindowItem)
        
        let showInFinderItem = NSMenuItem(title: "Show in Finder", action: #selector(menuShowInFinderButtonPressed), keyEquivalent: "")
        showInFinderItem.target = self
        showInFinderItem.representedObject = client
        menu.addItem(showInFinderItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let deleteItem = NSMenuItem(title: "Remove Device", action: #selector(menuDeleteButtonPressed), keyEquivalent: "")
        deleteItem.target = self
        deleteItem.representedObject = client
        deleteItem.isEnabled = !client.isConnected
        menu.addItem(deleteItem)
        
        self.menu = menu
        return super.menu(for: event)
    }
    
    @objc func menuOpenInWindowButtonPressed(_ item: NSMenuItem) {
        let client = item.representedObject as! RemoteLoggerClient
        AppRouter.shared.openMainView(client: client)
    }
    
    @objc func menuShowInFinderButtonPressed(_ item: NSMenuItem) {
        let client = item.representedObject as! RemoteLoggerClient
        NSWorkspace.shared.activateFileViewerSelecting([client.store.storeURL])
    }
    
    @objc func menuDeleteButtonPressed(_ item: NSMenuItem) {
        let client = item.representedObject as! RemoteLoggerClient
        deleteClient(client: client)
    }
    
    private func deleteClient(client: RemoteLoggerClient) {
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to remove this device?"
        alert.informativeText = "The device and the logs will be removed. If the device connects again later, it will appear in the list.";
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        var frame = alert.window.frame
        frame.size.height = 300
        frame.size.width = 200
        alert.window.setFrame(frame, display: true)
        
        alert.beginSheetModal(for: self.window!) { response -> Void in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                RemoteLoggerServer.shared.remove(client: client)
            } else{
                // Do nothing
            }
        }
    }
}

private struct SectionHeaderModel {
    let text: String
}
                                 
private struct SiderbarSectionTitle2: View {
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.secondary.opacity(0.8))
            Spacer()
        }
    }
}
