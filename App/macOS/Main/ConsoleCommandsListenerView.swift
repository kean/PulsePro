//
//  ConsoleCommandsListenerView.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 11/7/21.
//  Copyright © 2021 kean. All rights reserved.
//

import SwiftUI
import Combine

struct ConsoleCommandsListenerView: View {
    let model: ConsoleContainerViewModel
    @EnvironmentObject private var wrapper: CommandsRegistryWrapper
    private var commands: CommandsRegistry2 { wrapper.commands }
    @State private var id = UUID()
        
    @StateObject private var commandsModel = CommandsListenerViewModel()
    
    var body: some View {
        Text("").opacity(0)
            .onAppear {
                commands.setConsoleView(id, visible: true)
                commands.removeAllMessages.isVisible = model.remote.client != nil
                commands.toggleStreaming.isVisible = model.remote.client != nil
                commands.nowMode.isVisible = model.remote.client != nil
            }
            .onDisappear {
                commands.setConsoleView(id, visible: false)
            }
        // only errors
            .onReceive(commands.onlyErrors.value) {
                guard model.console.toolbar.isOnlyErrors != $0 else { return }
                model.console.toolbar.isOnlyErrors = $0
            }
            .onReceive(model.console.toolbar.$isOnlyErrors) { commands.onlyErrors.update($0) }
        // only pins
            .onReceive(commands.onlyPins.value) {
                guard model.console.toolbar.isOnlyPins != $0 else { return }
                model.console.toolbar.isOnlyPins = $0
            }
            .onReceive(model.console.toolbar.$isOnlyPins) { commands.onlyPins.update($0) }
        // toggle pin
            .onReceive(commands.togglePin.action) {
                guard let message = model.details.selectedEntity else { return }
                model.console.pins.togglePin(for: message)
            }
            .onReceive(model.details.$selectedEntity) { commands.togglePin.setEnabled($0 != nil) }
        // removeAllPins
            .onReceive(commands.removeAllPins.action) { model.console.pins.removeAllPins() }
            .onReceive(model.console.pins.$pinnedMessageIds) { commands.removeAllPins.setEnabled(!$0.isEmpty) }
        // remove all messages
            .onReceive(commands.removeAllMessages.action) { model.console.buttonRemoveAllMessagesTapped() }
        
        // viewers
            .onReceive(commands.showConsole.action) { model.mode.mode = .list }
            .onReceive(commands.showStory.action) { model.mode.mode = .text }
            .onReceive(commands.showNetwork.action) { model.mode.mode = .network }
        
        // filters
            .onReceive(commands.resetFilters.action) {
                model.console.filters.resetAll()
                model.network.filters.resetAll()
            }
        
        // streaming
            .onReceive(commands.toggleStreaming.action) { model.remote.client?.togglePlay() }
            .onReceive(model.remote.client?.$isPaused ?? commandsModel.$mockBoolean) { commands.isStreaming = !$0 }
        // now mode
            .onReceive(commands.nowMode.value.dropFirst()) {
                guard model.toolbar.isNowEnabled != $0 else { return }
                model.toolbar.isNowEnabled = $0
            }
            .onReceive(model.toolbar.$isNowEnabled) { commands.nowMode.update($0) }
    }
}

private final class CommandsListenerViewModel: ObservableObject {
    @Published var mockBoolean = false
}
