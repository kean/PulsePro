// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import Pulse

// Shortcut, should've been some sort of a ViewModel, but not sure how to do that
// given the current SwiftUI navigation state
struct ConsoleMessageDetailsRouter: View {
    let store: LoggerMessageStore
    let blobs: BlobStore
    let message: MessageEntity

    var body: some View {
        if let taskId = NetworkLoggerMessage(message: message)?.taskId {
            NetworkInspectorView(model: .init(store: store, blobs: blobs, taskId: taskId))
        } else {
            ConsoleMessageDetailsView(model: .init(message: message))
        }
    }
}
