//
//  AppDelegate.swift
//  macOS
//
//  Created by Alexander Grebenyuk on 16.02.2020.
//  Copyright © 2020 kean. All rights reserved.
//

import Cocoa
import Pulse
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, AppViewModelDelegate {
    let model = AppViewModel()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        model.delegate = self

        showWelcomeView()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - App Menu

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
        dialog.allowedFileTypes = ["sqlite"];

        #warning("TODO: open recent is not working")

        guard dialog.runModal() == NSApplication.ModalResponse.OK else {
            return // User cancelled the action
        }

        if let selectedUrl = dialog.url {
            model.openDatabase(url: selectedUrl)
        }
    }

    func showConsole(model: ConsoleViewModel) {
        #warning("TODO: improve preferred window/panels size")
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName(consoleWindowAutosaveName)

        let contentView = ConsoleView(model: model)
        window.contentView = NSHostingView(rootView: contentView)

        let toolbar = NSToolbar(identifier: "console.toolbar")
        toolbar.delegate = model
        window.toolbar = toolbar

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
                        #warning("TODO: implement error handling?")
                        return
                }
                DispatchQueue.main.async {
                    self.model.openDatabase(url: url)
                }
            }
        }
    }

    func showWelcomeView() {
        #warning("TODO: open window not on top of the existing one")
        #warning("TODO: show a welcome when closing all of the windows")
        #warning("TODO: add title to each window")
        #warning("TODO: add support for tabs instead of windows")
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
