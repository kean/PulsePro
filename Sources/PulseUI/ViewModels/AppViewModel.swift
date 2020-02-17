import Foundation
import SwiftUI
import Pulse

final class AppViewModel: ObservableObject {
    #if os(macOS)
    @Published var state: AppState = .empty

    func openDatabase(url: URL) {
        let container = NSPersistentContainer(name: "LoggerStore", managedObjectModel: LoggerStorage.coreDataModel)

        let store = NSPersistentStoreDescription(url: url)
        store.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [store]

        #warning("TODO: handle errors")
        container.loadPersistentStores { _, error in
            guard error == nil else { return }
            self.state = .console(model: ConsoleViewModel(container: container))
        }
    }
    #endif
}

enum AppState {
    case empty
    case console(model: ConsoleViewModel)
}
