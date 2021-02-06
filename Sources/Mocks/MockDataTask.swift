// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse

struct MockDataTask {
    let request: URLRequest
    let response: URLResponse
    let responseBody: Data
    let metrics: NetworkLoggerMetrics
}

// MARK: - GitHub Login (Success)

extension MockDataTask {
    static let login = MockDataTask(
        request: mockLoginRequest,
        response: mockLoginResponse,
        responseBody: MockJSON.githubLoginResponse,
        metrics: mockMetrics
    )
}

private let mockLoginRequest: URLRequest = {
    var request = URLRequest(url: URL(string: "https://github.com/login")!)

    request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
    request.setValue("github.com", forHTTPHeaderField: "Host")
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
    request.setValue("text/json", forHTTPHeaderField: "Content-Type")
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    request.setValue("en-us", forHTTPHeaderField: "Accept-Language")
    request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")

    return request
}()

private let mockLoginResponse = HTTPURLResponse(url: URL(string: "https://github.com/login")!, statusCode: 200, httpVersion: "2.0", headerFields: [
    "Content-Length": "22988",
    "Content-Type": "text/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Content-Encoding": "gzip",
    "Set-Cookie": "_device_id=11111111111; path=/; expires=Sun, 30 Jan 2022 21:49:04 GMT; secure; HttpOnly; SameSite=Lax"
])!

private let mockMetrics = try! JSONDecoder().decode(NetworkLoggerMetrics.self, from: """
{
  "transactions": [
    {
      "resourceFetchType": 1,
      "responseStartDate": 633801585.020091,
      "secureConnectionStartDate": 633801584.903459,
      "response": {
        "headers": {
          "Server": "ATS/8.1.1",
          "Connection": "keep-alive",
          "Content-Encoding": "gzip",
          "Vary": "Accept-Encoding",
          "Content-Type": "application/javascript",
          "X-Frame-Options": "sameorigin",
          "Expires": "Sun, 31 Jan 2021 15:59:12 GMT",
          "Strict-Transport-Security": "max-age=31536000",
          "Cache-Control": "max-age=300, public",
          "X-Cache": "hit-fresh, hit-stale",
          "CDNUUID": "7bacabb5-d210-42a2-94bb-a5a6a03e6e36-20658596809",
          "X-B3-TraceId": "033cc1f07abf7ac2",
          "Content-Security-Policy": "frame-ancestors 'self'",
          "Date": "Sun, 31 Jan 2021 15:59:02 GMT",
          "Age": "43",
          "Via": "https/1.1 usewr1-edge-lx-007.ts.apple.com (ApacheTrafficServer/8.1.1), http/1.1 usewr1-edge-bx-016.ts.apple.com (ApacheTrafficServer/8.1.1)",
          "Content-Length": "22988"
        },
        "statusCode": 200
      },
      "fetchStartDate": 633801584.8037,
      "requestEndDate": 633801585.004759,
      "request": {
        "allowsCellularAccess": true,
        "httpMethod": "GET",
        "url": "https://developer.apple.com/tutorials/js/analytics.js",
        "cachePolicy": 0,
        "allowsExpensiveNetworkAccess": true,
        "allowsConstrainedNetworkAccess": true,
        "httpShouldHandleCookies": true,
        "headers": {
          "User-Agent": "Pulse%20iOS/1 CFNetwork/1220.1 Darwin/20.2.0",
          "Accept-Encoding": "gzip, deflate, br",
          "Host": "developer.apple.com",
          "Accept-Language": "en-us",
          "Connection": "keep-alive",
          "Accept": "*/*"
        },
        "httpShouldUsePipelining": false,
        "timeoutInterval": 60
      },
      "domainLookupStartDate": 633801584.861459,
      "secureConnectionEndDate": 633801585.0024589,
      "isProxyConnection": false,
      "connectEndDate": 633801585.0024589,
      "networkProtocolName": "http/1.1",
      "responseEndDate": 633801585.03594,
      "isReusedConnection": false,
      "domainLookupEndDate": 633801584.883459,
      "connectStartDate": 633801584.885459,
      "requestStartDate": 633801585.004591,
      "details": {
        "countOfResponseHeaderBytesReceived": 683,
        "countOfRequestBodyBytesBeforeEncoding": 0,
        "countOfResponseBodyBytesReceived": 22988,
        "countOfRequestBodyBytesSent": 0,
        "countOfResponseBodyBytesAfterDecoding": 64979,
        "countOfRequestHeaderBytesSent": 225,
        "localAddress": "192.168.0.13",
        "remoteAddress": "17.253.97.204",
        "localPort": 58622,
        "remotePort": 443,
        "isMultipath": false,
        "isExpensive": false,
        "isConstrained": false,
        "isCellular": false,
        "negotiatedTLSProtocolVersion": 772,
        "negotiatedTLSCipherSuite": 4865
      }
    }
  ],
  "taskInterval": {
    "start": 633801584.802039,
    "duration": 0.23401391506195068
  },
  "redirectCount": 0
}
""".data(using: .utf8)!)

// MARK: - GitHub Profile (Failure, 404)

extension MockDataTask {
    static let profileFailure = MockDataTask(
        request: mockProfileFailureRequest,
        response: mockProfileFailureResponse,
        responseBody: """
        <h1>Error 404</h1>
        """.data(using: .utf8)!,
        metrics: mockMetrics
    )
}

private let mockProfileFailureRequest: URLRequest = {
    var request = URLRequest(url: URL(string: "https://github.com/profile/valdo")!)

    request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
    request.setValue("github.com", forHTTPHeaderField: "Host")
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
    request.setValue("text/json", forHTTPHeaderField: "Content-Type")
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    request.setValue("en-us", forHTTPHeaderField: "Accept-Language")
    request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")

    return request
}()

private let mockProfileFailureResponse = HTTPURLResponse(url: URL(string: "https://github.com/profile/valdo")!, statusCode: 404, httpVersion: "2.0", headerFields: [
    "Content-Length": "18",
    "Content-Type": "text/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Content-Encoding": "gzip"
])!

// MARK: - GitHub Stats (Network Error)

let mockStatsFailureRequest: URLRequest = {
    var request = URLRequest(url: URL(string: "https://github.com/stats")!)

    request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
    request.setValue("github.com", forHTTPHeaderField: "Host")
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
    request.setValue("text/json", forHTTPHeaderField: "Content-Type")
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    request.setValue("en-us", forHTTPHeaderField: "Accept-Language")
    request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")

    return request
}()

// MARK: - JSON (Mocks)

struct MockJSON {
    static let githubLoginResponse = """
    {
        "access-token": "a1",
        "refresh-token": "m1",
        "profile": {
            "id": 1,
            "name": "kean",
            "repos": ["Nuke", "Pulse", "Align"],
            "hireable": false,
            "email": null
        }
    }
    """.data(using: .utf8)!

    static let allPossibleValues = """
    {
      "actors": [
        {
          "name": "Tom Cruise",
          "age": 56,
          "Born At": "Syracuse, NY",
          "Birthdate": "July 3, 1962",
          "photo": "https://jsonformatter.org/img/tom-cruise.jpg",
          "wife": null,
          "weight": 67.5,
          "hasChildren": true,
          "hasGreyHair": false,
          "children": [
            "Suri",
            "Isabella Jane",
            "Connor"
          ]
        },
        {
          "name": "Robert Downey Jr.",
          "age": 53,
          "born At": "New York City, NY",
          "birthdate": "April 4, 1965",
          "photo": "https://jsonformatter.org/img/Robert-Downey-Jr.jpg",
          "wife": "Susan Downey",
          "weight": 77.1,
          "hasChildren": true,
          "hasGreyHair": false,
          "children": [
            "Indio Falconer",
            "Avri Roel",
            "Exton Elias"
          ]
        }
      ]
    }
    """.data(using: .utf8)!
}
