// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import CoreData
import PulseCore
import Combine
import SwiftUI

final class ConsoleDetailsPanelViewModel: ObservableObject {
    @Published var selectedEntity: LoggerMessageEntity?
    private let context: AppContext

    init(context: AppContext) {
        self.context = context
    }

    func makeDetailsRouter(for message: LoggerMessageEntity, onClose: (() -> Void)?) -> ConsoleMessageDetailsRouterPro {
        ConsoleMessageDetailsRouterPro(context: context, message: message, onClose: onClose)
    }
}

struct ConsoleMessageDetailsRouterPro: View {
    let context: AppContext
    let message: LoggerMessageEntity
    let onClose: (() -> Void)?

    var body: some View {
        if let request = message.request {
            NetworkInspectorViewPro(model: .init(message: message, request: request, context: context), onClose: onClose)
                .id(message.objectID)
        } else {
            MessageDetailsViewPro(model: .init(context: context, message: message), onClose: onClose)
                .id(message.objectID)
        }
    }
}
