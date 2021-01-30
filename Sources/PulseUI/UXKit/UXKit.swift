// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// A set of typealias and APIs to make AppKit and UIKit more
// compatible with each other

#if os(macOS)
typealias UXColor = NSColor
typealias UXFont = NSFont
typealias UXTextView = NSTextView
typealias UXAutoTextView = NSIntrinsicTextView

extension NSColor {
    static var label: NSColor { labelColor }
}
#else
typealias UXColor = UIColor
typealias UXFont = UIFont
typealias UXTextView = UITextView
typealias UXAutoTextView = UITextView
#endif

// MARK: - NSTextView

#if os(iOS)
extension UITextView {
    var isAutomaticLinkDetectionEnabled: Bool {
        get { dataDetectorTypes.contains(.link) }
        set { dataDetectorTypes.insert(.link) }
    }
}
#endif

#if os(macOS)
extension NSTextView {
    var attributedText: NSAttributedString? {
        get { nil }
        set { textStorage?.setAttributedString(newValue ?? NSAttributedString()) }
    }
}
#endif
