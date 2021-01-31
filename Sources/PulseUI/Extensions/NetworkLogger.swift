// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import Logging

// MARK: - NetworkLogger

public struct NetworkLoggerMetadataKey {
    static let taskId = "networkTaskId"
    static let eventType = "networkEventType"
    static let taskType = "networkEventTaskType"
    static let payload = "networkEventPayload"
}

public enum NetworkLoggerEventType: String, Codable {
    case dataTaskDidReceieveResponse
    case dataTaskDidReceiveData

    case taskDidStart
    case taskDidComplete
}

public enum NetworkLoggerEvent {
    public struct TaskDidStart: Codable {
        public let request: NetworkLoggerRequest
    }

    public struct DataTaskDidReceieveResponse: Codable {
        public let response: NetworkLoggerResponse
    }

    public struct DataTaskDidReceiveData: Codable {
        public let dataCount: Int
    }

    public struct TaskDidComplete: Codable {
        public let request: NetworkLoggerRequest
        public let reponse: NetworkLoggerResponse?
        public let error: NetworkLoggerError?
        public let data: Data?
        public let metrics: NetworkLoggerMetrics?
    }
}

public struct NetworkLoggerRequest: Codable {
    public let url: URL?
    public let httpMethod: String?
    public let headers: [String: String]

    init(urlRequest: URLRequest) {
        self.url = urlRequest.url
        self.httpMethod = urlRequest.httpMethod
        self.headers = urlRequest.allHTTPHeaderFields ?? [:]
    }
}

public struct NetworkLoggerResponse: Codable {
    public let statusCode: Int?
    public let headers: [String: String]

    init(urlResponse: URLResponse) {
        let httpResponse = urlResponse as? HTTPURLResponse
        self.statusCode = httpResponse?.statusCode
        self.headers = httpResponse?.allHeaderFields as? [String: String] ?? [:]
    }
}

public struct NetworkLoggerError: Codable {
    public let code: Int
    public let domain: String
    public let localizedDescription: String

    init(error: Error) {
        let error = error as NSError
        self.code = error.code
        self.domain = error.domain
        self.localizedDescription = error.localizedDescription
    }
}

public struct NetworkLoggerMetrics: Codable {
    public let taskInterval: DateInterval

    init(metrics: URLSessionTaskMetrics) {
        self.taskInterval = metrics.taskInterval
    }
}

public enum NetworkTaskType: String, Codable {
    case dataTask
    case downloadTask
    case uploadTask
    case streamTask
    case webSocketTask

    init(task: URLSessionTask) {
        switch task {
        case task as URLSessionDataTask: self = .dataTask
        case task as URLSessionDownloadTask: self = .downloadTask
        case task as URLSessionWebSocketTask: self = .webSocketTask
        case task as URLSessionStreamTask: self = .streamTask
        case task as URLSessionUploadTask: self = .uploadTask
        default:
            assertionFailure("Unknown task type: \(task)")
            self = .dataTask
        }
    }
}

public final class NetworkLogger: NSObject {
    let logger: Logger

    public init(_ logger: Logger) {
        self.logger = logger
    }

    // MARK: Logging

    public func urlSession(_ session: URLSession, didStartTask task: URLSessionTask) {
        guard let urlRequest = task.originalRequest else { return }

        let context = TaskContext()
        tasks[task] = context

        let request = NetworkLoggerRequest(urlRequest: urlRequest)
        let event = NetworkLoggerEvent.TaskDidStart(request: request)

        logger.log(
            level: .debug,
            "Did start request \(task.originalRequest?.url?.absoluteString ?? "null")",
            metadata: makeMetadata(context, task, .taskDidStart, event)
        )
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) {
        guard let context = tasks[dataTask] else { return }
        context.response = response

        let response = NetworkLoggerResponse(urlResponse: response)
        let event = NetworkLoggerEvent.DataTaskDidReceieveResponse(response: response)
        let statusCode = response.statusCode

        logger.log(
            level: .trace,
            "Did receive response with status code: \(statusCode.map(descriptionForStatusCode) ?? "–") for \(dataTask.url ?? "null")",
            metadata: makeMetadata(context, dataTask, .dataTaskDidReceieveResponse, event)
        )
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let context = tasks[dataTask] else { return }
        context.data.append(data)

        let event = NetworkLoggerEvent.DataTaskDidReceiveData(dataCount: data.count)

        logger.log(
            level: .trace,
            "Did receive data: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)) for \(dataTask.url ?? "null")",
            metadata: makeMetadata(context, dataTask, .dataTaskDidReceiveData, event)
        )
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let context = tasks[task], let urlRequest = task.originalRequest else { return }

        let error = error.map(NetworkLoggerError.init)
        let request = NetworkLoggerRequest(urlRequest: urlRequest)
        let response = context.response.map(NetworkLoggerResponse.init)
        let metrics = context.metrics.map(NetworkLoggerMetrics.init)
        let event = NetworkLoggerEvent.TaskDidComplete(request: request, reponse: response, error: error, data: context.data, metrics: metrics)

        let level: Logger.Level
        let message: String
        if let error = error {
            level = .error
            message = "🌐 \(urlRequest.httpMethod ?? "–") \(task.url ?? "–") failed. \(error.localizedDescription)"
        } else {
            let statusCode = (context.response as? HTTPURLResponse)?.statusCode
            if let statusCode = statusCode, !(200..<400).contains(statusCode) {
                level = .error
            } else {
                level = .info
            }
            message = "🌐 \(statusCode.map(descriptionForStatusCode) ?? "–") \(urlRequest.httpMethod ?? "–") \(task.url ?? "–")"
        }

        logger.log(level: level, .init(stringLiteral: message), metadata: makeMetadata(context, task, .taskDidComplete, event))

        tasks[task] = nil
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let context = tasks[task] else { return }
        context.metrics = metrics
    }

    // MARK: - Private

    private var tasks: [URLSessionTask: TaskContext] = [:]

    private final class TaskContext {
        let uuid = UUID()
        var response: URLResponse?
        var metrics: URLSessionTaskMetrics?
        lazy var data = Data()
    }

    private func makeMetadata<T: Encodable>(_ context: TaskContext, _ task: URLSessionTask, _ eventType: NetworkLoggerEventType, _ payload: T) -> Logger.Metadata {
        [
            NetworkLoggerMetadataKey.taskId: .string(context.uuid.uuidString),
            NetworkLoggerMetadataKey.eventType: .string(eventType.rawValue),
            NetworkLoggerMetadataKey.taskType: .string(NetworkTaskType(task: task).rawValue),
            NetworkLoggerMetadataKey.payload: .string(encode(payload) ?? "")
        ]
    }
}

private extension URLSessionTask {
    var url: String? {
        originalRequest?.url?.absoluteString
    }
}

private func encode<T: Encodable>(_ value: T) -> String? {
    guard let data = try? JSONEncoder().encode(value) else { return nil }
    return String(data: data, encoding: .utf8)
}

private func descriptionForStatusCode(_ statusCode: Int) -> String {
    switch statusCode {
    case 200: return "200 (OK)"
    default: return "\(statusCode) (\( HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized))"
    }
}
