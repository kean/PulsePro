// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation

#if DEBUG
struct MockDataTask {
    let request: URLRequest
    let response: URLResponse
    let responseBody: Data

    static let login = MockDataTask(
        request: mockRequest,
        response: mockResponse,
        responseBody: MockJSON.githubLoginResponse
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
