// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

struct KeyValueSectionView: View {
    let model: KeyValueSectionViewModel

    private var actualTintColor: UXColor {
        model.items.isEmpty ? .systemGray : model.color
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(model.title)
                .font(.headline)

            if model.items.isEmpty {
                Text("Empty")
                    .foregroundColor(Color(actualTintColor))
                    .font(.system(size: fontSize, weight: .medium))
            } else {
                VStack(spacing: 2) {
                    let rows = model.items.enumerated().map(Row.init)
                    ForEach(rows, id: \.index) { row in
                        HStack {
                            let title = Text(row.item.0 + ": ")
                                .foregroundColor(Color(actualTintColor))
                                .font(.system(size: fontSize, weight: .medium))
                            let value = Text(row.item.1 ?? "–")
                                .foregroundColor(.primary)
                                .font(.system(size: fontSize, weight: .regular))
                            (title + value).lineLimit(nil)
                            Spacer()
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                .border(width: 2, edges: [.leading], color: Color(actualTintColor))
                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 0))
            }

            Spacer()
        }
    }
}

// TODO: Switch to UITextView-based approach, need to figure out how implementat
// auto-growable field. This doesn't work.
//            Wrapped<UXAutoTextView> {
//                $0.isSelectable = true
//                $0.isEditable = false
//                $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//                #if os(iOS)
//                $0.isScrollEnabled = false
//                $0.textContainer.lineBreakMode = .byCharWrapping
//                #elseif os(macOS)
//                $0.backgroundColor = .clear
//                $0.textContainer?.lineBreakMode = .byCharWrapping
//                #endif
//                $0.isAutomaticLinkDetectionEnabled = true
//                $0.linkTextAttributes = [
//                    .underlineStyle: 1
//                ]
//                $0.attributedText = makeAttributedText()
//            }
//            .padding(EdgeInsets(top: 0, leading: 5, bottom: 2, trailing: 0))
//            .border(width: 2, edges: [.leading], color: Color(actualTintColor))
//            .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
//        }
//    }
//
//    private func makeAttributedText() -> NSAttributedString {
//        guard !model.items.isEmpty else {
//            return NSAttributedString(string: "Empty", attributes: [
//                .foregroundColor: actualTintColor, .font: UXFont.systemFont(ofSize: fontSize, weight: .medium)
//            ])
//        }
//        let output = NSMutableAttributedString()
//        for index in model.items.indices {
//            let (key, value) = model.items[index]
//            let string = NSMutableAttributedString()
//            string.append("" + key + ": ", [
//                .foregroundColor: actualTintColor,
//                .font: UXFont.systemFont(ofSize: fontSize, weight: .medium)
//            ])
//            string.append(value ?? "–", [
//                .foregroundColor: UXColor.label,
//                .font: UXFont.systemFont(ofSize: fontSize, weight: .regular)
//            ])
//            if index < model.items.endIndex - 1 {
//                string.append("\n")
//            }
//            output.append(string)
//        }
//
//        return output
//    }
//}

private var fontSize: CGFloat {
    #if os(iOS)
    return 15
    #else
    return 12
    #endif
}

struct KeyValueSectionViewModel {
    let title: String
    let color: UXColor
    let items: [(String, String?)]
}

private struct Row {
    let index: Int
    let item: (String, String?)
}
