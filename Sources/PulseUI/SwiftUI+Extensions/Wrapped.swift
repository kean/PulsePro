// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

import SwiftUI

#if os(iOS)
struct Wrapped<T: UIView>: UIViewRepresentable {
    let configuration: (T) -> Void

    func makeUIView(context: UIViewRepresentableContext<Self>) -> T {
        UITextView()
    }

    func updateUIView(_ uiView: T, context: UIViewRepresentableContext<Self>) {
        configuration(uiView)
    }
}
#endif

#if os(macOS)
struct Wrapped<T: NSView>: NSViewRepresentable {
    let configuration: (T) -> Void

    func makeNSView(context: Context) -> T {
        T()
    }

    func updateNSView(_ nsView: T, context: Context) {
        configuration(nsView)
    }
}
#endif


