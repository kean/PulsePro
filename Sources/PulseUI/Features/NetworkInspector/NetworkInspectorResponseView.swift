// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorResponseView: View {
    let response: Data

    init(response: Data) {
        self.response = response
    }

    var body: some View {
        Wrapped<PlatformTextView> {
            $0.isSelectable = true
            $0.isEditable = false
            #if os(iOS)
            $0.dataDetectorTypes = [.link]
            #elseif os(macOS)
            $0.isAutomaticLinkDetectionEnabled = true
            #endif
            $0.linkTextAttributes = [
                .foregroundColor: JSONColors.valueString,
                .underlineStyle: 1
            ]

            if let text = JSONPrinter.print(data: response) {
                #if os(iOS)
                $0.attributedText = text
                #elseif os(macOS)
                $0.textStorage?.setAttributedString(text)
                #endif
            }
        }
    }
}

struct NetworkInspectorResponseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorResponseView(response: sampleJSON.data(using: .utf8)!)
                .environment(\.colorScheme, .light)

            NetworkInspectorResponseView(response: sampleJSON.data(using: .utf8)!)
            .previewDisplayName("Dark")
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
        }
    }
}

private let sampleJSON = """
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
"""
