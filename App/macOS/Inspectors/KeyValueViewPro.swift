// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import PulseCore

enum KeyValuePro {
    static func makeString(for model: KeyValueSectionViewModel, fontSize: CGFloat) -> NSAttributedString {
        let output = NSMutableAttributedString()
        
        let attrTitle: [NSAttributedString.Key: Any] = [
            .font: UXFont.monospacedSystemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: UXColor.label,
            .paragraphStyle: NSParagraphStyle.make(fontSize: Int(fontSize))
        ]
        
        let attrKey: [NSAttributedString.Key: Any] = [
            .font: UXFont.monospacedSystemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: NSColor(.secondary),
            .paragraphStyle: NSParagraphStyle.make(fontSize: Int(fontSize))
        ]
        
        let attrLabel: [NSAttributedString.Key: Any] = [
            .font: UXFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: UXColor.label,
            .paragraphStyle: NSParagraphStyle.make(fontSize: Int(fontSize))
        ]
    
        output.append(model.title + "\n\n", attrTitle)

        for item in model.items {
            output.append(item.0 + ":", attrKey)
            output.append(" \(item.1 ?? "–")\n", attrLabel)
        }
                
        return output
    }
    
    static func makeNewline(fontSize: CGFloat) -> NSAttributedString {
        NSAttributedString(string: "\n", attributes: [
            .font:  UXFont.monospacedSystemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: UXColor.label,
            .paragraphStyle: NSParagraphStyle.make(fontSize: Int(fontSize))
        ])
    }
}
