// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import Logging

#if DEBUG
extension LoggerMessageStore {
    func taskIdWithURL(_ url: URL) -> String? {
        let messages = ((try? allMessages()) ?? []).filter {
            $0.metadata.contains {
                $0.key == NetworkLoggerMetadataKey.eventType.rawValue && $0.value == NetworkLoggerEventType.taskDidComplete.rawValue
            }
        }

        func event(for message: MessageEntity) -> NetworkLoggerEvent.TaskDidComplete? {
            guard let payload = message.metadata.first(where: { $0.key == NetworkLoggerMetadataKey.payload.rawValue })?.value else {
                return nil
            }
            guard let responseBody = payload.data(using: .utf8) else {
                return nil
            }
            return try? JSONDecoder().decode(NetworkLoggerEvent.TaskDidComplete.self, from: responseBody)
        }

        let message = messages.first(where: {
            event(for: $0)?.request.url == url
        })

        return message?.metadata.first(where: { $0.key == NetworkLoggerMetadataKey.taskId.rawValue })?.value
    }
}
#endif
