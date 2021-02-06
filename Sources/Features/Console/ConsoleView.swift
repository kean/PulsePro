// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

public struct ConsoleView: View {
    @ObservedObject var model: ConsoleViewModel

    public init(messageStore: LoggerMessageStore, blobStore: BlobStore) {
        self.model = ConsoleViewModel(messageStore: messageStore, blobStore: blobStore)
    }

    public init(model: ConsoleViewModel) {
        self.model = model
    }

    #if os(iOS)

    @State private var isShowingShareSheet = false
    @State private var isShowingSettings = false

    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    public var body: some View {
        NavigationView {
            List {
                quickFiltersView
                messagesListView
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(Text("Console"))
            .navigationBarItems(trailing: shareButton)
        }
    }

    private var quickFiltersView: some View {
        VStack {
            SearchBar(title: "Search \(model.messages.count) messages", text: $model.searchText)
            Spacer(minLength: 8)
            ConsoleQuickFiltersView(filter: $model.filter, isShowingSettings: $isShowingSettings)
        }
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .sheet(isPresented: $isShowingSettings) {
            ConsoleSettingsView(model: self.model, isPresented:  self.$isShowingSettings)
        }
    }

    private var messagesListView: some View {
        ForEach(model.messages, id: \.objectID) { message in
            NavigationLink(destination: model.makeDetailsRouter(for: message)) {
                ConsoleMessageViewListItem(store: model.tempGetStore(), blobs: model.tempGetBlobs(), message: message, searchCriteria: self.$model.searchCriteria)
            }
            .padding(.trailing, -30)
            .listRowBackground(ConsoleMessageStyle.backgroundColor(for: message, colorScheme: self.colorScheme)) // The only way I made background color work with ForEach
        }
    }

    private var shareButton: some View {
        ShareButton {
            self.isShowingShareSheet = true
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareView(activityItems: [try! self.model.prepareForSharing()])
        }
    }

    #endif

    #if os(macOS)

    public var body: some View {
        NavigationView {
            List {
                quickFiltersView
                ForEach(model.messages, id: \.objectID) { message in
                    NavigationLink(destination: self.detailsView(message: message)) {
                        ConsoleMessageViewListItemContentView(message: message)
                    }
                }
            }
            .frame(minWidth: 280, idealWidth: 400)//, maxWidth: 480)
        }
        .frame(minWidth: 770, minHeight: 480)
    }

    private var quickFiltersView: some View {
        VStack {
            searchBar
            Spacer(minLength: 8)
            ConsoleQuickFiltersView(filter: $model.filter)
        }
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }

    private var searchBar: some View {
        Wrapped<ConsoleSearchView> {
            $0.searchCriteria = $model.searchCriteria
        }
    }

    private func detailsView(message: MessageEntity) -> some View {
        model.makeDetailsRouter(for: message)
            .frame(minWidth: 480)
    }

    #endif
}

#if DEBUG
struct ConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            ConsoleView(model: ConsoleViewModel(messageStore: .mock, blobStore: .mock))
            ConsoleView(model: ConsoleViewModel(messageStore: .mock, blobStore: .mock))
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif
