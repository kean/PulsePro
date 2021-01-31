// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation

#if DEBUG
struct MockDataTask {
    let request: URLRequest
    let response: URLResponse
    let responseBody: Data
    let metrics: NetworkLoggerMetrics

    static let login = MockDataTask(
        request: mockRequest,
        response: mockResponse,
        responseBody: MockJSON.githubLoginResponse,
        metrics: mockMetrics
    )
}

private let mockRequest: URLRequest = {
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

private let mockResponse = HTTPURLResponse(url: URL(string: "https://github.com/login")!, statusCode: 200, httpVersion: "2.0", headerFields: [
    "Content-Length": "12400",
    "Content-Type": "text/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Content-Encoding": "gzip",
    "Set-Cookie": "_device_id=11111111111; path=/; expires=Sun, 30 Jan 2022 21:49:04 GMT; secure; HttpOnly; SameSite=Lax"
])!

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

private let mockResponseBody = """
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

#endif
