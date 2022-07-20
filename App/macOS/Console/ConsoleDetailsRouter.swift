// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import CoreData
import PulseCore
import Combine
import SwiftUI

final class ConsoleDetailsPanelViewModel: ObservableObject {
    @Published var selectedEntity: LoggerMessageEntity?
    private let store: LoggerStore

    init(store: LoggerStore) {
        self.store = store
    }

    func makeDetailsRouter(for message: LoggerMessageEntity, onClose: (() -> Void)?) -> ConsoleMessageDetailsRouterPro {
        ConsoleMessageDetailsRouterPro(store: store, message: message, onClose: onClose)
    }
}

struct ConsoleMessageDetailsRouterPro: View {
    let store: LoggerStore
    let message: LoggerMessageEntity
    let onClose: (() -> Void)?

    var body: some View {
        if let request = message.request {
            NetworkInspectorViewPro(viewModel: .init(message: message, request: request, store: store), onClose: onClose)
                .id(message.objectID)
        } else {
            MessageDetailsViewPro(viewModel: .init(store: store, message: message), onClose: onClose)
                .id(message.objectID)
        }
    }
}
