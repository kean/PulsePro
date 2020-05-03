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
        do {
            let container = try NSPersistentContainer.load(loggerDatabaseUrl: url)
            let logger = Logger(store: .init(container: container))
            let model = ConsoleViewModel(logger: logger)
            self.delegate?.showConsole(model: model)
        } catch {
            debugPrint("Failed to open database with url: \(url) with error: \(error)")
        }
    }

    func buttonOpenDocumentTapped() {
        delegate?.openDocument()
    }
}

extension NSPersistentContainer {
    static func load(loggerDatabaseUrl url: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "LoggerStore", managedObjectModel: Logger.Store.model)

        let store = NSPersistentStoreDescription(url: url)
        store.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [store]

        var error: Error?
        var isLoaded = false
        container.loadPersistentStores {
            isLoaded = true
            error = $1
        }
        assert(isLoaded, "Expected persistent stores to be loaded synchronously")
        if let error = error {
            throw error
        }

        return container
    }
}
