// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import Pulse
import Combine

#if os(iOS)
struct ConsoleView: View {
    @FetchRequest<MessageEntity>(sortDescriptors: [NSSortDescriptor(keyPath: \MessageEntity.created, ascending: false)], predicate: nil)
    var messages: FetchedResults<MessageEntity>

    @ObservedObject var model: ConsoleMessagesListViewModel

    @State private var isShowingShareSheet = false

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(title: "Search", text: $model.searchText)
                    .padding()
                ConsoleMessageList(messages: model.messages)
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
    @FetchRequest<MessageEntity>(sortDescriptors: [NSSortDescriptor(keyPath: \MessageEntity.created, ascending: false)], predicate: nil)
    var messages: FetchedResults<MessageEntity>

    @ObservedObject var model: ConsoleMessagesListViewModel

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
            ConsoleView(model: ConsoleMessagesListViewModel(container: store))
            ConsoleView(model: ConsoleMessagesListViewModel(container: store))
                .environment(\.colorScheme, .dark)
        }
    }
}
