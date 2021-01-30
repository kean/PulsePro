// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorView: View {
    @ObservedObject var model: NetworkInspectorViewModel

    var body: some View {
        #if os(iOS)
        content
            .navigationBarTitle(Text("Network Inspector"))
        #else
        content
        #endif
    }

    private var content: some View {
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
    }

    private var messagesListView: some View {
        List((0...5).map { $0 }, id: \.self) {
            Text("\($0)")
        }.listStyle(PlainListStyle())
    }
}

#if DEBUG
struct NetworkInspectorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                NetworkInspectorView(model: .init(store: .mock, taskId: LoggerMessageStore.mock.taskIdWithURL(MockDataTask.login.request.url!) ?? "–"))
            }

            NavigationView {
                NetworkInspectorView(model: .init(store: .mock, taskId: LoggerMessageStore.mock.taskIdWithURL(MockDataTask.login.request.url!) ?? "–"))
            }
            .previewDisplayName("Dark")
            .environment(\.colorScheme, .dark)
        }
    }
}
#endif
