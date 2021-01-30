// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

struct KeyValueSectionView: View {
    let title: String
    let items: [(String, String)]
    let tintColor: UXColor

    private var actualTintColor: UXColor {
        items.isEmpty ? .systemGray : tintColor
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title)

            Wrapped<UXAutoTextView> {
                $0.isSelectable = true
                $0.isEditable = false
                #if os(iOS)
                $0.isScrollEnabled = false
                #elseif os(macOS)
                $0.backgroundColor = .clear
                #endif
                $0.isAutomaticLinkDetectionEnabled = true
                $0.linkTextAttributes = [
//                    .foregroundColor: tintColor,
                    .underlineStyle: 1
                ]
                $0.attributedText = makeAttributedText()
            }
            .padding(EdgeInsets(top: 0, leading: 5, bottom: 2, trailing: 0))
            .border(width: 2, edges: [.leading], color: Color(actualTintColor))
            .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
        }
    }

    private func makeAttributedText() -> NSAttributedString {
        guard !items.isEmpty else {
            return NSAttributedString(string: "Empty", attributes: [
                .foregroundColor: actualTintColor, .font: UXFont.systemFont(ofSize: 15, weight: .medium)
            ])
        }
        let output = NSMutableAttributedString()
        for (key, value) in items {
            let string = NSMutableAttributedString()
            string.append("" + key + ": ", [
                .foregroundColor: actualTintColor,
                .font: UXFont.systemFont(ofSize: 15, weight: .medium)
            ])
            string.append(value, [
                .foregroundColor: UXColor.label,
                .font: UXFont.systemFont(ofSize: 15, weight: .regular)
            ])
            if key != items.last?.0 {
                string.append("\n")
            }
            output.append(string)
        }

        return output
    }
}
