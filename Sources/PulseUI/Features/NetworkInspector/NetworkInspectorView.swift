// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorView: View {
    @ObservedObject var model: NetworkInspectorViewModel

    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: .constant(0)) {
                    Text("Summary").tag(0)
                    Text("Headers").tag(1)
                    Text("Response").tag(2)
                    Text("Request").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))

                Text(model.messageCount.description)

                messagesListView
            }
            .navigationBarTitle(Text("Network Inspector"))
        }
    }

    private var messagesListView: some View {
        List((0...5).map { $0 }, id: \.self) {
            Text("\($0)")
        }.listStyle(PlainListStyle())
    }
}

struct NetworkInspectorView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkInspectorView(model: .init(store: .default, taskId: "A409ED79-91B2-490D-B364-607A2B565557"))
    }
}
