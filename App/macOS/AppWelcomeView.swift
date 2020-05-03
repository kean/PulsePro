// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Pulse
import PulseUI
import SwiftUI
import CoreData
import Combine

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

struct AppWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        AppWelcomeView(buttonOpenDocumentTapped: {})
    }
}
