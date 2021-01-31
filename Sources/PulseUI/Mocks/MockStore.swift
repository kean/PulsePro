// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import CoreData
import Logging

#if DEBUG
public extension LoggerMessageStore {
    static let mock: LoggerMessageStore = {
        let store = makeMockStore()
        populateStore(store)

        //        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
        //            logger.log("Hello, world")
        //        }

        return store
    }()
}

private func makeMockStore() -> LoggerMessageStore {
    let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent("com.github.kean.pulse-ui-demo")
    try? FileManager.default.removeItem(at: rootURL)
    try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)

    let storeURL = rootURL.appendingPathComponent("demo-store")
    return LoggerMessageStore(storeURL: storeURL)
}

private extension NSManagedObject {
    convenience init(using usedContext: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: usedContext)!
        self.init(entity: entity, insertInto: usedContext)
    }
}

private func populateStore(_ store: LoggerMessageStore) {
    precondition(Thread.isMainThread)

    func logger(named: String) -> Logger {
        var logger = Logger(label: named, factory: { PersistentLogHandler(label: $0, store: store) })
        logger.logLevel = .trace
        return logger
    }

    logger(named: "application")
        .log(level: .info, "UIApplication.didFinishLaunching")

    logger(named: "application")
        .log(level: .info, "UIApplication.willEnterForeground")

    logger(named: "auth")
        .log(level: .trace, "Instantiated Session")

    logger(named: "auth")
        .log(level: .trace, "Instantiated the new login request")

    let networkLogger = NetworkLogger(logger(named: "network"))

    let urlSession = URLSession(configuration: .default)
    let dataTask = urlSession.dataTask(with: MockDataTask.login.request)

    networkLogger.urlSession(urlSession, didStartTask: dataTask)
    Thread.sleep(forTimeInterval: 0.01)
    networkLogger.urlSession(urlSession, dataTask: dataTask, didReceive: MockDataTask.login.response)
    Thread.sleep(forTimeInterval: 0.01)
    networkLogger.urlSession(urlSession, dataTask: dataTask, didReceive: MockDataTask.login.responseBody)
    networkLogger.testInjectMetrics(mockMetrics, for: dataTask)
    networkLogger.urlSession(urlSession, task: dataTask, didCompleteWithError: nil)

    logger(named: "application")
        .log(level: .info, "Will navigate to Dashboard")

    let stackTrace = """
        Replace this implementation with code to handle the error appropriately. fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

        2015-12-08 15:04:03.888 Conversion[76776:4410388] call stack:
        (
            0   Conversion                          0x000694b5 -[ViewController viewDidLoad] + 128
            1   UIKit                               0x27259f55 <redacted> + 1028
            ...
            9   UIKit                               0x274f67a7 <redacted> + 134
            10  FrontBoardServices                  0x2b358ca5 <redacted> + 232
            11  FrontBoardServices                  0x2b358f91 <redacted> + 44
            12  CoreFoundation                      0x230e87c7 <redacted> + 14
            ...
            16  CoreFoundation                      0x23038ecd CFRunLoopRunInMode + 108
            17  UIKit                               0x272c7607 <redacted> + 526
            18  UIKit                               0x272c22dd UIApplicationMain + 144
            19  Conversion                          0x000767b5 main + 108
            20  libdyld.dylib                       0x34f34873 <redacted> + 2
        )
        """

    logger(named: "auth")
        .log(level: .debug, .init(stringLiteral: stackTrace))

    logger(named: "default")
        .log(level: .critical, "💥 0xDEADBEEF")

    // Wait until everything is stored
    store.container.viewContext.performAndWait {}
}

private let mockMetrics = try! JSONDecoder().decode(NetworkLoggerMetrics.self, from: """
{
  "transactions": [
    {
      "isExpensive": false,
      "requestStartDate": 633758068.85251,
      "fetchStartDate": 633758068.852414,
      "countOfResponseBodyBytesAfterDecoding": 0,
      "countOfRequestBodyBytesSent": 0,
      "request": {
        "allowsCellularAccess": true,
        "httpMethod": "GET",
        "url": "https://www.flickr.com/services/rest/?method=flickr.photos.getExif&api_key=028205e598d52ef77ec2d7664cc7aafc&photo_id=50720070118&secret=9b27875a4804a5f8&format=json&nojsoncallback=1",
        "cachePolicy": 0,
        "allowsExpensiveNetworkAccess": true,
        "allowsConstrainedNetworkAccess": true,
        "httpShouldHandleCookies": true,
        "headers": {
          "Accept-Language": "en-us",
          "Accept": "*/*",
          "Accept-Encoding": "gzip, deflate, br"
        },
        "httpShouldUsePipelining": false,
        "timeoutInterval": 60
      },
      "countOfRequestBodyBytesBeforeEncoding": 0,
      "resourceFetchType": 3,
      "countOfResponseHeaderBytesReceived": 0,
      "isConstrained": false,
      "countOfResponseBodyBytesReceived": 0,
      "isMultipath": false,
      "requestEndDate": 633758068.85251,
      "isCellular": false,
      "response": {
        "headers": {
          "x-content-type-options": "nosniff",
          "x-cache": "Miss from cloudfront",
          "Server": "Apache/2.4.46 (Ubuntu)",
          "Content-Type": "application/json",
          "x-amz-cf-pop": "EWR52-C1",
          "Date": "Sun, 31 Jan 2021 03:43:40 GMT",
          "x-frame-options": "SAMEORIGIN",
          "Via": "1.1 b78bfeca7339074512b7289497872df2.cloudfront.net (CloudFront)",
          "x-amz-cf-id": "t7IHJ1r598_OU6FHB4hVrUPqLMY3igJhzs-olVk4kDGcd_RdGIudCQ=="
        },
        "statusCode": 200
      },
      "isProxyConnection": false,
      "isReusedConnection": false,
      "countOfRequestHeaderBytesSent": 0,
      "responseStartDate": 633758068.852557,
      "responseEndDate": 633758068.852557
    },
    {
      "isExpensive": false,
      "requestStartDate": 633758068.949125,
      "negotiatedTLSCipherSuite": 4865,
      "negotiatedTLSProtocolVersion": 772,
      "fetchStartDate": 633758068.852414,
      "countOfResponseBodyBytesAfterDecoding": 9012,
      "remotePort": 443,
      "networkProtocolName": "h2",
      "countOfRequestBodyBytesSent": 0,
      "localAddress": "192.168.0.13",
      "countOfRequestHeaderBytesSent": 132,
      "countOfRequestBodyBytesBeforeEncoding": 0,
      "resourceFetchType": 1,
      "countOfResponseHeaderBytesReceived": 275,
      "request": {
        "allowsCellularAccess": true,
        "httpMethod": "GET",
        "url": "https://www.flickr.com/services/rest/?method=flickr.photos.getExif&api_key=028205e598d52ef77ec2d7664cc7aafc&photo_id=50720070118&secret=9b27875a4804a5f8&format=json&nojsoncallback=1",
        "cachePolicy": 0,
        "allowsExpensiveNetworkAccess": true,
        "allowsConstrainedNetworkAccess": true,
        "httpShouldHandleCookies": true,
        "headers": {
          "User-Agent": "Pulse%20iOS/1 CFNetwork/1220.1 Darwin/20.2.0",
          "Host": "www.flickr.com",
          "Accept-Encoding": "gzip, deflate, br",
          "Accept-Language": "en-us",
          "Connection": "keep-alive",
          "Accept": "*/*"
        },
        "httpShouldUsePipelining": false,
        "timeoutInterval": 60
      },
      "countOfResponseBodyBytesReceived": 9039,
      "remoteAddress": "13.226.26.231",
      "requestEndDate": 633758068.949534,
      "isCellular": false,
      "response": {
        "headers": {
          "Server": "Apache/2.4.46 (Ubuntu)",
          "x-cache": "Miss from cloudfront",
          "x-content-type-options": "nosniff",
          "Content-Type": "application/json",
          "x-amz-cf-pop": "EWR53-C2",
          "Date": "Sun, 31 Jan 2021 03:54:33 GMT",
          "x-frame-options": "SAMEORIGIN",
          "x-amz-cf-id": "VETdJJweD92p88iksTtFQvod_uYdls6RzP3bUqruh6ht9KkwMqKpPw==",
          "Via": "1.1 17a3c2535aa705a7b5a80b78b876c79b.cloudfront.net (CloudFront)"
        },
        "statusCode": 200
      },
      "isProxyConnection": false,
      "isReusedConnection": true,
      "responseEndDate": 633758069.067999,
      "responseStartDate": 633758069.06693,
      "isConstrained": false,
      "isMultipath": false,
      "localPort": 65254
    }
  ],
  "taskInterval": {
    "start": 633758068.85186,
    "duration": 0.21628201007843018
  },
  "redirectCount": 0
}
""".data(using: .utf8)!)


#endif
