// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(macOS)
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
typealias PlatformTextView = NSTextView
#else
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
typealias PlatformTextView = UITextView
#endif
