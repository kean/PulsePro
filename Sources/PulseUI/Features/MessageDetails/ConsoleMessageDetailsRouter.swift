// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import Pulse

// Shortcut, should've been some sort of a ViewModel, but not sure how to do that
// given the current SwiftUI navigation state
struct ConsoleMessageDetailsRouter: View {
    let store: LoggerMessageStore
    let message: MessageEntity

    var body: some View {
        if let taskId = message.metadata.first(where: { $0.key == NetworkLoggerMetadataKey.taskId })?.value {
            NetworkInspectorView(model: .init(store: store, taskId: taskId))
        } else {
            ConsoleMessageDetailsView(model: .init(message: message))
        }
    }
}
