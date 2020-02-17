// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import Pulse
import Combine

#if os(iOS)
struct ConsoleView: View {
    @ObservedObject var model: ConsoleViewModel

    @State private var isShowingShareSheet = false

    #warning("TODO: add a context menu")
    #warning("TODO: add a more menu")
    #warning("TODO: add share/more options")
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(title: "Search", text: $model.searchText)
                    .padding()
                List(model.messages, id: \.objectID) { message in
                    NavigationLink(destination: ConsoleMessageDetailsView(model: .init(message: message))) {
                        ConsoleMessageView(model: .init(message: message))
                    }
                }
            }
            .navigationBarTitle(Text("Console"))
            .navigationBarItems(trailing:
                ShareButton {
                    self.isShowingShareSheet = true
                }
            )
            .sheet(isPresented: $isShowingShareSheet) {
                ShareView(activityItems: [try! self.model.prepareForSharing()])
            }
        }
    }
}
#else
struct ConsoleView: View {
    @ObservedObject var model: ConsoleViewModel

    var body: some View {
        VStack {
            SearchBar(title: "Search", text: $model.searchText)
                .padding()
            ConsoleMessageList(messages: model.messages)
        }
    }
}
#endif

struct ConsoleMessageList: View {
    var messages: ConsoleMessages

    #warning("TODO: add empty state")
    var body: some View {
        List(messages, id: \.objectID) {
            ConsoleMessageView(model: .init(message: $0))
        }
    }
}

struct ConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        let store = mockMessagesStore
        return Group {
            ConsoleView(model: ConsoleViewModel(container: store))
            ConsoleView(model: ConsoleViewModel(container: store))
                .environment(\.colorScheme, .dark)
        }
    }
}
