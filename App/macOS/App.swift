// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Cocoa
import PulseCore
import SwiftUI
import Combine

@main
struct PulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainViewPro()
                .environmentObject(commands)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
            FindCommands()
            ViewCommands()
            MessagesCommands()
        }

        WindowGroup {
            FileRouterView()
        }
        .handlesExternalEvents(matching: ["file"])
        
        WindowGroup {
            RouterView()
        }
        .handlesExternalEvents(matching: [AppRouter.scheme])
        
        Settings {
            SettingsViewPro()
        }
    }
}

// MARK: Helpers

func openDocument() {
    let dialog = NSOpenPanel()

    dialog.title = "Select a Pulse document (has .pulse extension)"
    dialog.showsResizeIndicator = true
    dialog.showsHiddenFiles = false
    dialog.canChooseDirectories = false
    dialog.canCreateDirectories = false
    dialog.allowsMultipleSelection = false
    dialog.canChooseDirectories = true
    dialog.allowedFileTypes = ["pulse"]

    guard dialog.runModal() == NSApplication.ModalResponse.OK else {
        return // User cancelled the action
    }

    if let selectedUrl = dialog.url {
        NSWorkspace.shared.open(selectedUrl)
    }
}

// MARK: - AppViewModel

struct AlertViewModel: Hashable, Identifiable {
    var id: String = UUID().uuidString
    let title: String
    let message: String
}

enum AppViewModelError: Error, LocalizedError {
    case failedToFindLogsStore(url: URL)

    var errorDescription: String? {
        switch self {
        case .failedToFindLogsStore(let url):
            return "Failed to find a Pulse store at the given URL \(url)"
        }
    }
}
