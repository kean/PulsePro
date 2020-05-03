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
            let logger = Logger(container: container)
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
#endif
