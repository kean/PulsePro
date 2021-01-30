// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation

#if DEBUG
struct MockDataTask {
    let request: URLRequest
    let response: URLResponse
    let responseBody: Data

    static let first = MockDataTask(
        request: mockRequest,
        response: mockResponse,
        responseBody: mockResponseBody
    )
}

private let mockRequest: URLRequest = {
    var request = URLRequest(url: URL(string: "https://example.com")!)

    request.setValue("text/json", forHTTPHeaderField: "Content-Type")
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    request.setValue("en-us", forHTTPHeaderField: "Accept-Language")

    return request
}()

private let mockResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: "2.0", headerFields: [
    "Content-Length": "12400",
    "Content-Type": "text/json"
])!

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
