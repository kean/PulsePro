// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import Pulse
import Combine

public struct ConsoleView: View {
    @ObservedObject var model: ConsoleViewModel

    public init(logger: Logger) {
        self.model = ConsoleViewModel(logger: logger)
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
            .navigationBarTitle(Text("Console"))
            .navigationBarItems(trailing: shareButton)
        }
    }

    private var quickFiltersView: some View {
        VStack {
            SearchBar(title: "Search \(model.messages.count) messages", text: $model.searchText)
            Spacer(minLength: 8)
            ConsoleQuickFiltersView(onlyErrors: $model.onlyErrors, isShowingSettings: $isShowingSettings)
        }
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .sheet(isPresented: $isShowingSettings) {
            ConsoleSettingsView(model: self.model, isPresented:  self.$isShowingSettings)
        }
    }

    private var messagesListView: some View {
        ForEach(model.messages, id: \.objectID) { message in
            NavigationLink(destination: ConsoleMessageDetailsView(model: .init(message: message))) {
                ConsoleMessageViewListItem(message: message, searchCriteria: self.$model.searchCriteria)
            }.listRowBackground(ConsoleMessageStyle.backgroundColor(for: message, colorScheme: self.colorScheme)) // The only way I made background color work with ForEach
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
        VStack {
            HSplitView {
                NavigationView {
                    List(model.messages, id: \.objectID) { message in
                        NavigationLink(destination: self.detailsView(message: message)) {
                            ConsoleMessageView(model: .init(message: message))
                        }
                    }
                    .frame(minWidth: 320, minHeight: 480)
                }
            }
        }
    }

    private func detailsView(message: MessageEntity) -> some View {
        ConsoleMessageDetailsView(model: .init(message: message))
            .frame(minWidth: 320, minHeight: 480)
    }

    #endif
}

struct ConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            ConsoleView(model: ConsoleViewModel(logger: mockLogger))
            ConsoleView(model: ConsoleViewModel(logger: mockLogger))
                .environment(\.colorScheme, .dark)
        }
    }
}
