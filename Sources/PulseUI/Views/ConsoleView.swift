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

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(title: "Search", text: $model.searchText)
                    .padding()
                List(model.messages, id: \.objectID) { messsage -> ConsoleMessageView in
                    ConsoleMessageView(model: .init(message: messsage))
                }
            }
            .navigationBarTitle(Text("Console"))
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
            List(model.messages, id: \.objectID) { messsage -> ConsoleMessageView in
                ConsoleMessageView(model: .init(message: messsage))
            }
        }
    }
}
#endif

struct ConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        let store = mockMessagesStore
        return Group {
            ConsoleView(model: ConsoleMessagesListViewModel(context: store.viewContext))
            ConsoleView(model: ConsoleMessagesListViewModel(context: store.viewContext))
                .environment(\.colorScheme, .dark)
        }
    }
}
