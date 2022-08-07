// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import CoreData
import PulseCore
import Combine
import SwiftUI

final class ConsoleDetailsPanelViewModel: ObservableObject {
    @Published var selectedEntity: LoggerMessageEntity?

    func makeDetailsRouter(for message: LoggerMessageEntity, onClose: (() -> Void)?) -> ConsoleMessageDetailsRouterPro {
        ConsoleMessageDetailsRouterPro(message: message, onClose: onClose)
    }
}

struct ConsoleMessageDetailsRouterPro: View {
    let message: LoggerMessageEntity
    let onClose: (() -> Void)?

    var body: some View {
        if let request = message.request {
            NetworkInspectorViewPro(viewModel: .init(message: message, request: request), onClose: onClose)
                .id(message.objectID)
        } else {
            MessageDetailsViewPro(viewModel: .init(message: message), onClose: onClose)
                .id(message.objectID)
        }
    }
}
