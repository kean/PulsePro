// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import CoreData

final class NetworkLoggerSummary {
    let isCompleted: Bool
    private(set) var request: NetworkLoggerRequest?
    private(set) var response: NetworkLoggerResponse?
    private(set) var error: NetworkLoggerError?
    private(set) var requestBody: Data?
    private(set) var responseBody: Data?
    private(set) var metrics: NetworkLoggerMetrics?

    /// Decodes the given messages to create a summary of the request.
    init(messages: [MessageEntity], blobs: BlobStoring) {
        let messages = NetworkLoggerMessages(messages: messages)

        guard let didCompleteEvent = messages.didCompleteEvent else {
            self.isCompleted = false

            // TODO: populate with intermediate responses
            return
        }

        self.isCompleted = true
        self.request = didCompleteEvent.request
        self.response = didCompleteEvent.response
        self.error = didCompleteEvent.error
        self.requestBody = didCompleteEvent.requestBodyKey.flatMap(blobs.getData)
        self.responseBody = didCompleteEvent.responseBodyKey.flatMap(blobs.getData)
        self.metrics = didCompleteEvent.metrics
    }

    convenience init(store: LoggerMessageStore, blobs: BlobStoring, taskId: String) {
        let metrics = NSFetchRequest<MessageEntity>(entityName: "\(MessageEntity.self)")
        metrics.predicate = NSPredicate(format: "SUBQUERY(metadata, $entry, $entry.key == %@ AND $entry.value == %@).@count > 0", NetworkLoggerMetadataKey.taskId.rawValue, taskId)
        metrics.relationshipKeyPathsForPrefetching = ["\(\MessageEntity.metadata.self)"]

        let messages = (try? store.container.viewContext.fetch(metrics)) ?? []
        self.init(messages: messages, blobs: blobs)
    }
}

private final class NetworkLoggerMessages {
    private let messages: [MessageEntity]

    init(messages: [MessageEntity]) {
        self.messages = messages
    }

    var didCompleteEvent: NetworkLoggerEvent.TaskDidComplete? {
        guard let message = first(key: .eventType, value: NetworkLoggerEventType.taskDidComplete.rawValue) else {
            return nil
        }
        return payload(NetworkLoggerEvent.TaskDidComplete.self, for: message)
    }

    private func filter(key: NetworkLoggerMetadataKey, value: String) -> [MessageEntity] {
        messages.filter {
            $0.metadata.contains {
                $0.key == key.rawValue && $0.value == value
            }
        }
    }

    private func first(key: NetworkLoggerMetadataKey, value: String) -> MessageEntity? {
        messages.first {
            $0.metadata.contains {
                $0.key == key.rawValue && $0.value == value
            }
        }
    }

    private func payload<T: Decodable>(_ object: T.Type, for message: MessageEntity) -> T? {
        guard let payload = message.metadata.first(where: { $0.key == NetworkLoggerMetadataKey.payload.rawValue })?.value else {
            return nil
        }
        guard let data = payload.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

#if DEBUG
extension NetworkLoggerSummary {
    static func mock(url: URL) -> NetworkLoggerSummary {
        guard let taskId = LoggerMessageStore.mock.taskIdWithURL(url) else {
            return NetworkLoggerSummary(messages: [], blobs: BlobStore.mock)
        }
        return NetworkLoggerSummary.mock(taskId: taskId)
    }

    static func mock(taskId: String) -> NetworkLoggerSummary {
        NetworkLoggerSummary(store: .mock, blobs: BlobStore.mock, taskId: taskId)
    }
}
#endif
