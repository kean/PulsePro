// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import CoreData
import Pulse
import PulseUI
import Logging

final class MockNetworkLogger {
    let logger: NetworkLogger
    let dataLoader: MockDataLoader

    static let shared = MockNetworkLogger()

    init() {
        var logger = Logger(label: "network-logger")
        logger.logLevel = .trace

        self.logger = NetworkLogger(logger: logger)
        self.dataLoader = MockDataLoader(logger: self.logger)

        logger.log(level: .info, "MockNetworkLogger initialized")
    }

    func sendRequest() {
        // TODO: remove this
        let url = URL(string: "https://developer.apple.com/tutorials/js/analytics.js")!
        _ = dataLoader.loadData(with: URLRequest(url: url), didReceiveData: { _, _ in
            // Do nothing
        }, completion: { _ in
            // Do nothign
        })
    }
}

final class MockDataLoader {
    let session: URLSession
    private let impl: _DataLoader

    /// Initializes `DataLoader` with the given configuration.
    /// - parameter configuration: `URLSessionConfiguration.default` with
    /// `URLCache` with 0 MB memory capacity and 150 MB disk capacity.
    init(logger: NetworkLogger) {
        self.impl = _DataLoader(logger: logger)

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        self.session = URLSession(configuration: .default, delegate: impl, delegateQueue: queue)
    }

    func loadData(with request: URLRequest,
                         didReceiveData: @escaping (Data, URLResponse) -> Void,
                         completion: @escaping (Swift.Error?) -> Void) -> URLSessionDataTask {
        return impl.loadData(with: request, session: session, didReceiveData: didReceiveData, completion: completion)
    }
}

// Actual data loader implementation. Hide NSObject inheritance, hide
// URLSessionDataDelegate conformance, and break retain cycle between URLSession
// and URLSessionDataDelegate.
private final class _DataLoader: NSObject, URLSessionDataDelegate {
    private let logger: NetworkLogger
    private var handlers = [URLSessionTask: _Handler]()

    init(logger: NetworkLogger) {
        self.logger = logger
    }

    /// Loads data with the given request.
    func loadData(with request: URLRequest,
                  session: URLSession,
                  didReceiveData: @escaping (Data, URLResponse) -> Void,
                  completion: @escaping (Error?) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: request)
        let handler = _Handler(didReceiveData: didReceiveData, completion: completion)
        session.delegateQueue.addOperation { // `URLSession` is configured to use this same queue
            self.handlers[task] = handler
        }
        task.resume()
        logger.urlSession(session, didStartTask: task)
        return task
    }

    // MARK: URLSessionDelegate

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        logger.urlSession(session, dataTask: dataTask, didReceive: response)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        assert(task is URLSessionDataTask)
        logger.urlSession(session, task: task, didCompleteWithError: error)
        guard let handler = handlers[task] else {
            return
        }
        handlers[task] = nil
        handler.completion(error)
    }

    // MARK: URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        logger.urlSession(session, dataTask: dataTask, didReceive: data)

        guard let handler = handlers[dataTask], let response = dataTask.response else {
            return
        }
        // Don't store data anywhere, just send it to the pipeline.
        handler.didReceiveData(data, response)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        logger.urlSession(session, task: task, didFinishCollecting: metrics)
    }

    // MARK: Internal

    private final class _Handler {
        let didReceiveData: (Data, URLResponse) -> Void
        let completion: (Error?) -> Void

        init(didReceiveData: @escaping (Data, URLResponse) -> Void, completion: @escaping (Error?) -> Void) {
            self.didReceiveData = didReceiveData
            self.completion = completion
        }
    }
}
