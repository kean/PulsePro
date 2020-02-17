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
        do {
            let container = try NSPersistentContainer.load(loggerDatabaseUrl: url)
            let model = ConsoleViewModel(container: container)
            self.delegate?.showConsole(model: model)
        } catch {
            #warning("TODO: handle errors")
            debugPrint("Failed to open database with url: \(url) with error: \(error)")
        }
    }

    func buttonOpenDocumentTapped() {
        delegate?.openDocument()
    }
}
#endif
