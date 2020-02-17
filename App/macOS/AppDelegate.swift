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
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    let model = AppViewModel()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
//        let store = mockMessagesStore
//        let model = ConsoleViewModel(container: store)

        let contentView = AppView(model: model)
            .frame(minWidth: 320, minHeight: 480)

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - App Menu

    @IBAction func openDocument(_ sender: Any) {
        let dialog = NSOpenPanel()

        dialog.title = "Choose a .sqlite file with logs"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = false
        dialog.canCreateDirectories = false
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes = ["sqlite"];

        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let selectedUrl = dialog.url {
                model.openDatabase(url: selectedUrl)
            }
        } else {
            print("cancelled")
            // User clicked on "Cancel"
            return
        }

    }
}
