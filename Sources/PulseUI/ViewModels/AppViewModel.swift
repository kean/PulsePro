import Foundation
import SwiftUI
import Pulse

#if os(macOS)
protocol AppViewModelDelegate: class {
    func openDocument()
    func showConsole(model: ConsoleViewModel)
}

final class AppViewModel: ObservableObject {
    weak var delegate: AppViewModelDelegate?

    func openDatabase(url: URL) {
        let container = NSPersistentContainer(name: "LoggerStore", managedObjectModel: LoggerStorage.coreDataModel)

        let store = NSPersistentStoreDescription(url: url)
        store.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [store]

        #warning("TODO: handle errors")
        container.loadPersistentStores { _, error in
            guard error == nil else { return }
            let model = ConsoleViewModel(container: container)
            self.delegate?.showConsole(model: model)
        }
    }

    func buttonOpenDocumentTapped() {
        delegate?.openDocument()
    }
}
#endif
