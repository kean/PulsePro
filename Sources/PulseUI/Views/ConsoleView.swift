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
    @State private var isShowingSettings = false

    var body: some View {
        NavigationView {
            List {
                VStack {
                    SearchBar(title: "Search", text: $model.searchText)
                    Spacer(minLength: 12)
                    ConsoleQuickFiltersView(onlyErrors: $model.onlyErrors, isShowingSettings: $isShowingSettings)
                }.padding(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                ForEach(model.messages, id: \.objectID) { message in
                    NavigationLink(destination: ConsoleMessageDetailsView(model: .init(message: message))) {
                        ConsoleMessageViewListItem(searchCriteria: self.$model.searchCriteria, message: message)
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
            .sheet(isPresented: $isShowingSettings) {
                ConsoleSettingsView(model: self.model, isPresented:  self.$isShowingSettings)
            }
        }
    }
}

struct ConsoleMessageViewListItem: View {
    @Binding var searchCriteria: ConsoleSearchCriteria
    let message: MessageEntity
    @State private var isShowingShareSheet = false

    var body: some View {
        ConsoleMessageView(model: .init(message: message))
            // TODO: create a ViewModel for a share sheet
            .contextMenu {
                Button(action: {
                    self.isShowingShareSheet = true
                }) {
                    Text("Share")
                    Image(systemName: "square.and.arrow.up")
                }
                Button(action: {
                    let filter = ConsoleSearchFilter(text: self.message.system, kind: .system, relation: .equals)
                    self.searchCriteria.filters.append(filter)
                }) {
                    Text("Show system \"\(message.system)\"")
                    Image(systemName: "eye")
                }
                Button(action: {
                    let filter = ConsoleSearchFilter(text: self.message.system, kind: .system, relation: .doesNotEqual)
                    self.searchCriteria.filters.append(filter)
                }) {
                    Text("Hide system \"\(message.system)\"")
                    Image(systemName: "eye.slash")
                }.foregroundColor(.red)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareView(activityItems: [self.message.text])
        }
    }
}
#endif

#if os(macOS)
struct ConsoleView: View {
    @ObservedObject var model: ConsoleViewModel

    var body: some View {
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
}
#endif

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
