// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Cocoa
import Pulse
import PulseUI
import SwiftUI
import Combine

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, AppViewModelDelegate {
    let model = AppViewModel()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        model.delegate = self

        if ProcessInfo.processInfo.environment["PULSE_MOCK_STORE_ENABLED"] != nil {
            showConsole(model: ConsoleViewModel(store: .mock, blobs: BlobStore.mock))
        } else {
            showWelcomeView()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func openDocument(_ sender: Any) {
        self.openDocument()
    }

    func openDocument() {
        let dialog = NSOpenPanel()

        dialog.title = "Choose a .sqlite file with logs"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = false
        dialog.canCreateDirectories = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true
        dialog.allowedFileTypes = ["sqlite", "pulse"]

        guard dialog.runModal() == NSApplication.ModalResponse.OK else {
            return // User cancelled the action
        }

        if let selectedUrl = dialog.url {
            openDatabase(at: selectedUrl)
        }
    }

    func showConsole(model: ConsoleViewModel) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName(consoleWindowAutosaveName)

        let contentView = ConsoleView(model: model)
        window.contentView = NSHostingView(rootView: contentView)

        // TODO: Add toolbar late
//        let toolbar = NSToolbar(identifier: "console.toolbar")
//        let toolbarController = ConsoleToolbarController(model: model)
//        toolbar.delegate = toolbarController
//        window.toolbar = toolbar
//        window.bag.append(AnyCancellable { _ = toolbarController })

        model.$messages
            .map { "Console (\($0.count) messages)" }
            .assign(to: \.title, on: window)
            .store(in: &bag)

        window.makeKeyAndOrderFront(nil)

        NSApplication.shared.windows
            .filter { $0.frameAutosaveName == welcomeWindowAutosaveName }
            .forEach {
                $0.orderOut(nil)
            }
    }

    private func onDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: [:]) { result, error in
                guard let data = result as? Data,
                    let path = String(data: data, encoding: .utf8),
                    let url = URL(string: path) else {
                        return
                }
                DispatchQueue.main.async {
                    self.openDatabase(at: url)
                }
            }
        }
    }

    private func openDatabase(at url: URL) {
        do {
            try self.model.openDatabase(url: url)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to open Pulse store"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    func showWelcomeView() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName(welcomeWindowAutosaveName)

        let contentView = AppWelcomeView(buttonOpenDocumentTapped: { [weak self] in
            self?.openDocument()
        })
            .frame(minWidth: 320, minHeight: 320)
            .onDrop(of: [(kUTTypeFileURL as String)], isTargeted: nil) { [weak self] in
                self?.onDrop(providers: $0)
                return true
            }

        window.contentView = NSHostingView(rootView: contentView)

        window.makeKeyAndOrderFront(nil)
    }
}

private let consoleWindowAutosaveName = "Console Window"
private let welcomeWindowAutosaveName = "Welcome Window"
