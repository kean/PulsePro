// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorView: View {
    @ObservedObject var model: NetworkInspectorViewModel
    @State private var selectedTab: NetworkInspectorTab = .summary

    var body: some View {
        #if os(iOS)
        universalBody
            .navigationBarTitle(Text("Network Inspector"))
        #else
        universalBody
        #endif
    }

    private var universalBody: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("Summary").tag(NetworkInspectorTab.summary)
                Text("Headers").tag(NetworkInspectorTab.headers)
                Text("Response").tag(NetworkInspectorTab.response)
                Text("Request").tag(NetworkInspectorTab.request)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))

            switch selectedTab {
            case .summary:
                NetworkInspectorSummaryView(model: model.makeSummaryModel())
            case .headers:
                Text("Headers")
            case .response:
                Text("Response")
            case .request:
                Text("Request")
            }
        }
    }

    private var messagesListView: some View {
        List((0...5).map { $0 }, id: \.self) {
            Text("\($0)")
        }.listStyle(PlainListStyle())
    }
}

private enum NetworkInspectorTab {
    case summary
    case headers
    case response
    case request
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
