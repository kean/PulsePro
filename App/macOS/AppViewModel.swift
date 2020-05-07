// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import SwiftUI
import Pulse
import PulseUI
import CoreData

protocol AppViewModelDelegate: class {
    func openDocument()
    func showConsole(model: ConsoleViewModel)
}

final class AppViewModel: ObservableObject {
    weak var delegate: AppViewModelDelegate?

    func openDatabase(url: URL) {
        let store = LoggerMessageStore(storeURL: url)
        let model = ConsoleViewModel(store: store)
        self.delegate?.showConsole(model: model)
    }

    func buttonOpenDocumentTapped() {
        delegate?.openDocument()
    }
}

private extension LoggerMessageStore {
    /// - storeURL: The storeURL.
    ///
    /// - warning: Make sure the directory used in storeURL exists.
    convenience init(storeURL: URL) {
        let container = NSPersistentContainer(name: storeURL.lastPathComponent, managedObjectModel: Self.model)
        let store = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [store]
        self.init(container: container)
    }
}
