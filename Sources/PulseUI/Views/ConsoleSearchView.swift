// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse
import AppKit

// TOOD: add code completion, suggest systems
// TODO: finish menu
struct ConsoleSearchView: NSViewRepresentable {
    @Binding var searchCriteria: ConsoleSearchCriteria

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSTokenField {
        let tokenField = NSTokenField()
        tokenField.delegate = context.coordinator
        tokenField.tokenStyle = .rounded
        return tokenField
    }

    func updateNSView(_ textView: NSTokenField, context: Context) {
//        guard textView.string != text else { return }
//        textView.string = text
    }

    class Coordinator: NSObject, NSTokenFieldDelegate {
        func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
            return "System: \(representedObject)"
        }

        func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
            return true
        }

        func tokenField(_ tokenField: NSTokenField, menuForRepresentedObject representedObject: Any) -> NSMenu? {
            let menu = NSMenu(title: "Any")

            let item1 = NSMenuItem(title: "test", action: #selector(doSomething), keyEquivalent: "")
            item1.target = self

            item1.state = .on

            let item2 = NSMenuItem(title: "test 2", action: #selector(doSomething), keyEquivalent: "")

            let item3 = NSMenuItem(title: "test 3", action: #selector(doSomething), keyEquivalent: "")
            item3.target = self

//            menu.autoenablesItems = true
//            menu.showsStateColumn = true

            menu.items = [item1, item2, .separator(), item3]

            return menu
        }

        @objc func doSomething() {

        }
    }
}

struct ConsoleSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleSearchView(searchCriteria: .constant(.init()))
            .previewLayout(.fixed(width: 320, height: 50))
//        ConsoleSearchOptionsView(searchCriteria: .constant(.init()))
    }
}

