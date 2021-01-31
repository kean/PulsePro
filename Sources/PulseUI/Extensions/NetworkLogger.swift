// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import Logging

// MARK: - NetworkLogger

public enum NetworkLoggerMetadataKey: String {
    case taskId = "networkTaskId"
    case eventType = "networkEventType"
    case taskType = "networkEventTaskType"
    case payload = "networkEventPayload"
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
        public let response: NetworkLoggerResponse?
        public let error: NetworkLoggerError?
        public let requestBody: Data?
        public let responseBody: Data?
        public let metrics: NetworkLoggerMetrics?
    }
}

public struct NetworkLoggerRequest: Codable {
    public let url: URL?
    public let httpMethod: String?
    public let headers: [String: String]
    /// `URLRequest.CachePolicy` raw value
    public let cachePolicy: UInt
    public let timeoutInterval: TimeInterval
    public let allowsCellularAccess: Bool
    public let allowsExpensiveNetworkAccess: Bool
    public let allowsConstrainedNetworkAccess: Bool
    public let httpShouldHandleCookies: Bool
    public let httpShouldUsePipelining: Bool

    init(urlRequest: URLRequest) {
        self.url = urlRequest.url
        self.httpMethod = urlRequest.httpMethod
        self.headers = urlRequest.allHTTPHeaderFields ?? [:]
        self.cachePolicy = urlRequest.cachePolicy.rawValue
        self.timeoutInterval = urlRequest.timeoutInterval
        self.allowsCellularAccess = urlRequest.allowsCellularAccess
        self.allowsExpensiveNetworkAccess = urlRequest.allowsExpensiveNetworkAccess
        self.allowsConstrainedNetworkAccess = urlRequest.allowsConstrainedNetworkAccess
        self.httpShouldHandleCookies = urlRequest.httpShouldHandleCookies
        self.httpShouldUsePipelining = urlRequest.httpShouldUsePipelining
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
    public let redirectCount: Int
    public let transactions: [NetworkLoggerTransactionMetrics]

    init(metrics: URLSessionTaskMetrics) {
        self.taskInterval = metrics.taskInterval
        self.redirectCount = metrics.redirectCount
        self.transactions = metrics.transactionMetrics.map(NetworkLoggerTransactionMetrics.init)
    }
}

public final class NetworkLoggerTransactionMetrics: Codable {
    public let request: NetworkLoggerRequest?
    public let response: NetworkLoggerResponse?
    public let fetchStartDate: Date?
    public let domainLookupStartDate: Date?
    public let domainLookupEndDate: Date?
    public let connectStartDate: Date?
    public let secureConnectionStartDate: Date?
    public let secureConnectionEndDate: Date?
    public let connectEndDate: Date?
    public let requestStartDate: Date?
    public let requestEndDate: Date?
    public let responseStartDate: Date?
    public let responseEndDate: Date?
    public let networkProtocolName: String?
    public let isProxyConnection: Bool
    public let isReusedConnection: Bool
    /// `URLSessionTaskMetrics.ResourceFetchType` enum raw value
    public let resourceFetchType: Int
    public let countOfRequestHeaderBytesSent: Int64
    public let countOfRequestBodyBytesSent: Int64
    public let countOfRequestBodyBytesBeforeEncoding: Int64
    public let countOfResponseHeaderBytesReceived: Int64
    public let countOfResponseBodyBytesReceived: Int64
    public let countOfResponseBodyBytesAfterDecoding: Int64
    public let localAddress: String?
    public let remoteAddress: String?
    public let isCellular: Bool
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let isMultipath: Bool
    public let localPort: Int?
    public let remotePort: Int?
    /// `tls_protocol_version_t` enum raw value
    public let negotiatedTLSProtocolVersion: UInt16?
    /// `tls_ciphersuite_t`  enum raw value
    public let negotiatedTLSCipherSuite: UInt16?

    init(metrics: URLSessionTaskTransactionMetrics) {
        self.request = NetworkLoggerRequest(urlRequest: metrics.request)
        self.response = metrics.response.map(NetworkLoggerResponse.init)
        self.fetchStartDate = metrics.fetchStartDate
        self.domainLookupStartDate = metrics.domainLookupStartDate
        self.domainLookupEndDate = metrics.domainLookupEndDate
        self.connectStartDate = metrics.connectStartDate
        self.secureConnectionStartDate = metrics.secureConnectionStartDate
        self.secureConnectionEndDate = metrics.secureConnectionEndDate
        self.connectEndDate = metrics.connectEndDate
        self.requestStartDate = metrics.requestStartDate
        self.requestEndDate = metrics.requestEndDate
        self.responseStartDate = metrics.responseStartDate
        self.responseEndDate = metrics.responseEndDate
        self.networkProtocolName = metrics.networkProtocolName
        self.isProxyConnection = metrics.isProxyConnection
        self.isReusedConnection = metrics.isReusedConnection
        self.resourceFetchType = metrics.resourceFetchType.rawValue
        self.countOfRequestHeaderBytesSent = metrics.countOfRequestHeaderBytesSent
        self.countOfRequestBodyBytesSent = metrics.countOfRequestBodyBytesSent
        self.countOfRequestBodyBytesBeforeEncoding = metrics.countOfRequestBodyBytesBeforeEncoding
        self.countOfResponseHeaderBytesReceived = metrics.countOfResponseHeaderBytesReceived
        self.countOfResponseBodyBytesReceived = metrics.countOfResponseBodyBytesReceived
        self.countOfResponseBodyBytesAfterDecoding = metrics.countOfResponseBodyBytesAfterDecoding
        self.localAddress = metrics.localAddress
        self.remoteAddress = metrics.remoteAddress
        self.isCellular = metrics.isCellular
        self.isExpensive = metrics.isExpensive
        self.isConstrained = metrics.isConstrained
        self.isMultipath = metrics.isMultipath
        self.localPort = metrics.localPort
        self.remotePort = metrics.remotePort
        self.negotiatedTLSProtocolVersion = metrics.negotiatedTLSProtocolVersion?.rawValue
        self.negotiatedTLSCipherSuite = metrics.negotiatedTLSCipherSuite?.rawValue
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
        let metrics = context.metrics
        let event = NetworkLoggerEvent.TaskDidComplete(request: request, response: response, error: error, requestBody: urlRequest.httpBody, responseBody: context.data, metrics: metrics)

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
                level = .debug
            }
            message = "🌐 \(statusCode.map(descriptionForStatusCode) ?? "–") \(urlRequest.httpMethod ?? "–") \(task.url ?? "–")"
        }

        logger.log(level: level, .init(stringLiteral: message), metadata: makeMetadata(context, task, .taskDidComplete, event))

        tasks[task] = nil
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let context = tasks[task] else { return }
        context.metrics = NetworkLoggerMetrics(metrics: metrics)
    }

    // MARK: - Private

    private var tasks: [URLSessionTask: TaskContext] = [:]

    private final class TaskContext {
        let uuid = UUID()
        var response: URLResponse?
        var metrics: NetworkLoggerMetrics?
        lazy var data = Data()
    }

    private func makeMetadata<T: Encodable>(_ context: TaskContext, _ task: URLSessionTask, _ eventType: NetworkLoggerEventType, _ payload: T) -> Logger.Metadata {
        [
            NetworkLoggerMetadataKey.taskId.rawValue: .string(context.uuid.uuidString),
            NetworkLoggerMetadataKey.eventType.rawValue: .string(eventType.rawValue),
            NetworkLoggerMetadataKey.taskType.rawValue: .string(NetworkTaskType(task: task).rawValue),
            NetworkLoggerMetadataKey.payload.rawValue: .string(encode(payload) ?? "")
        ]
    }

    func testInjectMetrics(_ metrics: NetworkLoggerMetrics, for task: URLSessionTask) {
        tasks[task]?.metrics = metrics
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
