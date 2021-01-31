// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorView: View {
    // Make sure all tabs are updated live
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
            .padding()

            switch selectedTab {
            case .summary:
                NetworkInspectorSummaryView(model: model.makeSummaryModel())
            case .headers:
                NetworkInspectorHeadersView(model: model.makeHeadersModel())
            case .response:
                NetworkInspectorResponseView(model: model.makeResponseModel())
            case .request:
                Text("Request")
            }

            Spacer()
        }
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
            .previewDisplayName("Light")
            .environment(\.colorScheme, .light)

            NavigationView {
                NetworkInspectorView(model: .init(store: .mock, taskId: LoggerMessageStore.mock.taskIdWithURL(MockDataTask.login.request.url!) ?? "–"))
            }
            .previewDisplayName("Dark")
            .environment(\.colorScheme, .dark)
        }
    }
}
#endif
