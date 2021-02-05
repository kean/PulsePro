// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import Logging

#if DEBUG
extension LoggerMessageStore {
    func taskIdWithURL(_ url: URL) -> String? {
        return (try? allMessages())?
            .lazy
            .compactMap(NetworkLoggerMessage.init)
            .first(where: {
                guard case let .taskDidComplete(event) = $0.event else {
                    return false
                }
                return event.request.url == url
            })?.taskId
    }
}
#endif
