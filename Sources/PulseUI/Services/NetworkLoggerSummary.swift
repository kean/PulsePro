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
        let messages = messages.compactMap(NetworkLoggerMessage.init)

        guard let didCompleteMessage = messages.first(where: { $0.eventType == .taskDidComplete }),
              case let .taskDidComplete(didCompleteEvent) = didCompleteMessage.event else {
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

/// Simplifies parsing networkg logger messages.
final class NetworkLoggerMessage {
    let message: MessageEntity

    let taskId: String
    let taskType: NetworkLoggerTaskType
    let eventType: NetworkLoggerEventType
    let event: NetworkLoggerEvent

    init?(message: MessageEntity) {
        let metadata = message.metadata
        guard !metadata.isEmpty else {
            return nil
        }
        func value(for key: NetworkLoggerMetadataKey) -> String? {
            metadata.first(where: { $0.key == key.rawValue })?.value
        }
        guard let taskId = value(for: .taskId),
              let taskType = value(for: .taskType).flatMap(NetworkLoggerTaskType.init),
              let eventType = value(for: .eventType).flatMap(NetworkLoggerEventType.init) else {
            return nil
        }
        func decodeEvent() -> NetworkLoggerEvent? {
            func decode<T: Decodable>(_ object: T.Type) -> T? {
                guard let payload = value(for: .payload),
                      let data = payload.data(using: .utf8) else {
                    return nil
                }
                return try? JSONDecoder().decode(T.self, from: data)
            }
            switch eventType {
            case .taskDidStart:
                return decode(NetworkLoggerEvent.TaskDidStart.self).map(NetworkLoggerEvent.taskDidStart)
            case .taskDidComplete:
                return decode(NetworkLoggerEvent.TaskDidComplete.self).map(NetworkLoggerEvent.taskDidComplete)
            case .dataTaskDidReceieveResponse:
                return decode(NetworkLoggerEvent.DataTaskDidReceieveResponse.self).map(NetworkLoggerEvent.dataTaskDidReceieveResponse)
            case .dataTaskDidReceiveData:
                return decode(NetworkLoggerEvent.DataTaskDidReceiveData.self).map(NetworkLoggerEvent.dataTaskDidReceiveData)
            }
        }
        guard let event = decodeEvent() else {
            return nil
        }
        self.message = message
        self.taskId = taskId
        self.taskType = taskType
        self.eventType = eventType
        self.event = event
    }

    var taskDidCompleteEvent: NetworkLoggerEvent.TaskDidComplete? {
        switch event {
        case let .taskDidComplete(event): return event
        default: return nil
        }
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
