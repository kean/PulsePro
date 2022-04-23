// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine

final class MainViewModelPro: ObservableObject {
    let details = MainViewDetailsViewModel()
    
    private var connections: [RemoteLoggerClient.ID: RemoteClientRAAI] = [:]

    init(client: RemoteLoggerClient) {
        let name = client.info.deviceInfo.name + (client.preferredSuffix ?? "")
        self.details.model = ConsoleContainerViewModel(store: client.store, name: name, client: client)
        self.connect(to: client)
    }
    
    init(store: LoggerStore) {
        self.details.model = ConsoleContainerViewModel(store: store, name:  store.storeURL.lastPathComponent, client: nil)
    }
    
    init() {
        // Do nothing
    }
    
    func open(client: RemoteLoggerClient) {
        self.details.model = ConsoleContainerViewModel(store: .mock, client: client)
        self.connect(to: client)
    }

    func didCloseWindow() {
        disconnect()
    }

    // MARK: Managing Connection (Auto Disconnect)
    
    private func disconnect() {
        for connection in connections.values {
            connection.decrement()
        }
        connections = [:]
    }
    
    private func connect(to client: RemoteLoggerClient) {
        guard connections[client.id] == nil else { return }
        let connection = RemoteClientRAAI.aquite(for: client)
        connection.increment()
        client.resume()
        connections[client.id] = connection
    }
}

final class MainViewDetailsViewModel: ObservableObject {
    @Published var model: ConsoleContainerViewModel?
    
    func open(url: URL) {
        do {
            let store = try LoggerStore(storeURL: url)
            self.model = ConsoleContainerViewModel(store: store, name: url.lastPathComponent, client: nil)
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        } catch {
            #warning("TODO: add error handling")
//            alert = AlertViewModel(title: "Failed to open Pulse document", message: error.localizedDescription)
        }
    }
}

private final class RemoteClientRAAI {
    private weak var client: RemoteLoggerClient?
    private var counter = 0
    
    init(client: RemoteLoggerClient) {
        self.client = client
    }
    
    func increment() {
        pulseLog("\(counter + 1) inc for \(client?.deviceInfo.name ?? "-")")
        counter += 1
    }
    
    func decrement() {
        pulseLog("\(counter - 1) dec for \(client?.deviceInfo.name ?? "-")")
        if counter == 1 {
            client?.pause()
        }
        counter -= 1
        counter = max(0, counter) // Just in case
    }
    
    private static var connections: [RemoteLoggerClient.ID: RemoteClientRAAI] = [:]
    
    static func aquite(for client: RemoteLoggerClient) -> RemoteClientRAAI {
        if let connection = connections[client.id] {
            return connection
        }
        let connection = RemoteClientRAAI(client: client)
        connections[client.id] = connection
        return connection
    }
}
