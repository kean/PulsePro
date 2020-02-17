// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import Pulse
import Combine

#if os(macOS)
struct AppWelcomeView: View {
    let buttonOpenDocumentTapped: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Text("Pulse")
                .font(.largeTitle)

            VStack {
                Text("Please select a Pulse database (.sqlite file)")
                Button(action: buttonOpenDocumentTapped) {
                    Text("Open document")
                }
            }
        }
    }
}
#endif
