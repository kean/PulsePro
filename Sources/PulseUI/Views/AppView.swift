// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import Pulse
import Combine

#if os(macOS)
struct AppView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        switch model.state {
        case .empty:
            return AnyView(Text("Please select a database"))
        case let .console(model):
            return AnyView(ConsoleView(model: model))
        }
    }
}
#endif
