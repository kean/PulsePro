// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Cocoa
import SwiftUI
import Combine

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(before: .newItem) {
            Button("Open", action: openDocument).keyboardShortcut("o")
            Menu("Open Recent") {
                ForEach(NSDocumentController.shared.recentDocumentURLs, id: \.self) { url in
                    Button(action: { NSWorkspace.shared.open(url) }, label: {
                        Text(url.lastPathComponent)
                    })
                }
            }
            #warning("TODO: move into a separate menu")
            Button("Start Remote Logging", action: RemoteLoggerViewModel.shared.buttonStartLoggerTapped)
                .keyboardShortcut("r", modifiers: [/*@START_MENU_TOKEN@*/.command/*@END_MENU_TOKEN@*/, .shift])
        }
    }
}

struct ViewCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .toolbar) {
            ViewCommandsView()
        }
    }
    
    private struct ViewCommandsView: View {
        @ObservedObject private var manager = WindowManager.shared
        @ObservedObject private var observer = CommandsObserver()
        private var commands: CommandsRegistry2? { manager.activeCommandsRegistry }
        
        var body: some View {
            Section {
                Menu("Viewers") {
                    makeButton("Show Messages", commands?.showConsole).keyboardShortcut("1")
                    makeButton("Show Text Log", commands?.showStory) .keyboardShortcut("2")
                    makeButton("Show Network Requests", commands?.showNetwork).keyboardShortcut("3")
                }
            }.disabled(!(commands?.isConsoleVisible ?? false))
            Section {
                Button("Toggle Line Numbers") { commandsWorkaround.onToggleLineNumbers.send() }
                .keyboardShortcut("l")
                Menu("Font Size") {
                    Button("Increase") { commandsWorkaround.onIncreaseFont.send() }
                    .keyboardShortcut("+")
                    Button("Decrease") { commandsWorkaround.onDecreaseFont.send() }
                    .keyboardShortcut("-")
                    Button("Reset") { commandsWorkaround.onResetFont.send() }
                    .keyboardShortcut("0")
                }
            }.disabled(!(commands?.isConsoleVisible ?? false))
        }
    }
}

struct FindCommands: Commands {
    var body: some Commands {
        CommandMenu("Find") {
            FindCommandsView()
        }
    }
    
    private struct FindCommandsView: View {
        @ObservedObject private var manager = WindowManager.shared
        @ObservedObject private var observer = CommandsObserver()
        private var commands: CommandsRegistry2? { manager.activeCommandsRegistry }
        
        var body: some View {
            Section {
                Button("Find", action: commandsWorkaround.sendOnFind).keyboardShortcut("f")
                Button("Toggle Filters", action: commandsWorkaround.onToggleFilters.send).keyboardShortcut("f", modifiers: [.command, .option])
                makeButton("Reset Filters", commands?.resetFilters).keyboardShortcut("0", modifiers: [.command, .shift])
            }.disabled(!(commands?.isConsoleVisible ?? false))
        }
    }
}

struct MessagesCommands: Commands {
    var body: some Commands {
        CommandMenu("Console") {
            MessagesCommandsView()
        }
    }
    
    private struct MessagesCommandsView: View {
        @ObservedObject private var manager = WindowManager.shared
        @ObservedObject private var observer = CommandsObserver()
        private var commands: CommandsRegistry2? { manager.activeCommandsRegistry }
        
        var body: some View {
            Section {
                if commands?.toggleStreaming.isVisible ?? false {
                    makeButton((commands?.isStreaming ?? false) ? "Pause Streaming" : "Start Streaming", commands?.toggleStreaming)
                        .keyboardShortcut("s", modifiers: [.command, .shift])
                }
                if commands?.nowMode.isVisible ?? false {
                    makeToggle("Now Mode", commands?.nowMode).keyboardShortcut("n", modifiers: [.command, .shift])
                }
            }
            Section {
                makeToggle("Only Errors", commands?.onlyErrors).keyboardShortcut("e", modifiers: [.command, .shift])
                makeToggle("Only Pins", commands?.onlyPins).keyboardShortcut("p", modifiers: [.command, .shift])
            }.disabled(!(commands?.isConsoleVisible ?? false))
            Section {
                makeButton("Toggle Pin", commands?.togglePin).keyboardShortcut("p", modifiers: [.command])
                makeButton("Remove All Pins", commands?.removeAllPins).keyboardShortcut("p", modifiers: [.command, .option, .control])
            }.disabled(!(commands?.isConsoleVisible ?? false))
            if commands?.removeAllMessages.isVisible ?? false {
                Section {
                    makeButton("Remove All Messages", commands?.removeAllMessages).keyboardShortcut("k", modifiers: [.command])
                }.disabled(!(commands?.isConsoleVisible ?? false))
            }
        }
    }
}

private func makeButton(_ title: String, _ command: Command?) -> some View {
    Button(title) { command?.send() }
        .disabled(!(command?.isEnabled ?? false))
}

private func makeToggle(_ title: String, _ command: ToggleCommand?) -> some View {
    Toggle(title, isOn: Binding(get: { command?.value.value ?? false }, set: { command?.value.value = $0 }))
        .disabled(command == nil)
}

// MARK: CommandsRegistry

var commands: CommandsRegistry { CommandsRegistry.shared }
private var commandsWorkaround: CommandsRegistry { commands }

// yeah this sucks
final class CommandsRegistry: ObservableObject {
    let onFindFirst = PassthroughSubject<Void, Never>()
    let onFind = PassthroughSubject<Void, Never>()
    let onToggleFilters = PassthroughSubject<Void, Never>()
    
    var isCommandHandled: Bool = false
    
    func sendOnFind() {
        onFindFirst.send()
        if isCommandHandled {
            isCommandHandled = false
            return
        }
        onFind.send()
    }
    
    let onToggleLineNumbers = PassthroughSubject<Void, Never>()
    
    // Font Size
    let onIncreaseFont = PassthroughSubject<Void, Never>()
    let onDecreaseFont = PassthroughSubject<Void, Never>()
    let onResetFont = PassthroughSubject<Void, Never>()
    
    static let shared = CommandsRegistry()
}

final class CommandsRegistry2: ObservableObject {
    @Published var onlyErrors = ToggleCommand()
    @Published var onlyPins = ToggleCommand()
    
    @Published var removeAllPins = Command(isEnabled: false)
    @Published var togglePin = Command(isEnabled: false)
    
    @Published var removeAllMessages = Command(isEnabled: true, isVisible: false)
    
    @Published var resetFilters = Command()
    
    @Published var showConsole = Command()
    @Published var showStory = Command()
    @Published var showNetwork = Command()
    
    @Published var nowMode = ToggleCommand(isVisible: false)
    @Published var toggleStreaming = Command(isEnabled: true, isVisible: false)
    @Published var isStreaming = false
    
    @Published var isConsoleVisible = false
    
    private var visibleConsoleViewId: UUID?
    
    // These are some crazy worakrounds yo
    func setConsoleView(_ id: UUID, visible: Bool) {
        guard let previousId = visibleConsoleViewId else {
            isConsoleVisible = visible
            visibleConsoleViewId = id
            return
        }
        if visible {
            isConsoleVisible = true
            visibleConsoleViewId = id
        } else {
            if previousId == id {
                visibleConsoleViewId = nil
                isConsoleVisible = false
            }
        }
    }
}

struct Command {
    let action = PassthroughSubject<Void, Never>()
    var isEnabled = true
    var isVisible = true
    
    func send() {
        action.send()
    }
    
    mutating func setEnabled(_ isEnabled: Bool) {
        guard self.isEnabled != isEnabled else { return }
        self.isEnabled = isEnabled
    }
}

// This is just a bunch of hacks
struct ToggleCommand {
    var value = CurrentValueSubject<Bool, Never>(false)
    var index = 0
    var isVisible = true
    
    mutating func update(_ value: Bool) {
        if self.value.value != value {
            self.value.value = value
        }
        index += 1
    }
}
    
private final class CommandsObserver: ObservableObject {
    private var cancellables: [AnyCancellable] = []
    private var commandsCancellables: [AnyCancellable] = []
    
    init(manager: WindowManager = .shared) {
        manager.$activeCommandsRegistry.sink { [weak self] in
            self?.commands = $0
        }.store(in: &cancellables)
    }
    
    var commands: CommandsRegistry2? {
        didSet {
            commandsCancellables = []
            guard let commands = commands else { return }
            commands.objectWillChange.sink { [weak self] in
                self?.objectWillChange.send()
            }.store(in: &commandsCancellables)
        }
    }
}

final class WindowManager: ObservableObject {
    @Published var activeCommandsRegistry: CommandsRegistry2?
    
    static let shared = WindowManager()
    
    private var cancellables: [AnyCancellable] = []
    
    func add(commands: CommandsRegistry2, for window: NSWindow) {
        self.activeCommandsRegistry = commands

        let notifications = NotificationCenter.default
        notifications.publisher(for: NSWindow.didBecomeKeyNotification, object: window).sink { [weak self] _ in
            self?.activeCommandsRegistry = commands
        }.store(in: &cancellables)
        notifications.publisher(for: NSWindow.willCloseNotification, object: window).sink { [weak self] _ in
            self?.activeCommandsRegistry = nil
        }.store(in: &cancellables)
    }
}
