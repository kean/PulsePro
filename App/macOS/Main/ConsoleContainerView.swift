// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine

struct ConsoleContainerView: View {
    let viewModel: ConsoleContainerViewModel
    
    var body: some View {
        InnerConsoleContainerView(viewModel: viewModel, toolbar: viewModel.toolbar, details: viewModel.details)
            .navigationTitle(viewModel.name ?? "Console")
            .background(ConsoleWindowAccessors(model: viewModel.toolbar))
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    ConsoleToolbarModePickerView(model: viewModel.mode)
                }
                ToolbarItemGroup(placement: .principal) {
                    if let client = viewModel.remote.client {
                        RemoteLoggerClientStatusView(client: client)
                        RemoteLoggerTooglePlayButton(client: client)
                        ConsoleNowView(model: viewModel.toolbar)
                        Button(action: client.clear, label: {
                            Label("Clear", systemImage: "trash")
                        }).help("Remove All Messages (⌘K)")
                    }
                }
                ToolbarItem {
                    Spacer()
                }
                ToolbarItemGroup(placement: .automatic) {
                    ConsoleToolbarSearchBar(model: viewModel)
                    ConsoleToolbarToggleOnlyErrorsButton(model: viewModel.toolbar)
                    ConsoleToolbarToggleFiltersButton(model: viewModel.toolbar)
                    ConsoleToolbarToggleVerticalView(model: viewModel.toolbar)
                }
            }
    }
}

private struct InnerConsoleContainerView: View {
    let viewModel: ConsoleContainerViewModel
    @ObservedObject var toolbar: ConsoleToolbarViewModel
    @ObservedObject var details: ConsoleDetailsPanelViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                mainPanel
                filterPanel
            }
        }
        .background(ConsoleCommandsListenerView(model: viewModel))
    }
    
    @ViewBuilder
    private var filterPanel: some View {
        if !toolbar.isFiltersPaneHidden {
            HStack(spacing: 0) {
                ExDivider()
                ConsoleContainerFiltersPanel(viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    private var mainPanel: some View {
        NotSplitView(
            ConsoleContainerMainPanel(model: viewModel)
                .frame(minWidth: 400, idealWidth: 800, maxWidth: .infinity, minHeight: 120, idealHeight: 480, maxHeight: .infinity, alignment: .center),
            ConsoleContainerDetailsPanel(model: viewModel.details)
                .frame(minWidth: 430, idealWidth: 800, maxWidth: .infinity, minHeight: 120, idealHeight: 480, maxHeight: .infinity, alignment: .center),
            isPanelTwoCollaped: details.selectedEntity == nil,
            isVertical: toolbar.isVertical
        )
    }
}

private struct ConsoleContainerFiltersPanel: View {
    let viewModel: ConsoleContainerViewModel
    @ObservedObject var mode: ConsoleModePickerViewModel
    
    init(viewModel: ConsoleContainerViewModel) {
        self.viewModel = viewModel
        self.mode = viewModel.mode
    }
    
    var body: some View {
        switch mode.mode {
        case .list, .text:
            ConsoleFiltersView(viewModel: viewModel.console.filters)
                .frame(width: 200)
        case .network:
            NetworkFiltersView(viewModel: viewModel.network.filters)
                .frame(width: 200)
        }
    }
}

private struct ConsoleContainerMainPanel: View {
    let model: ConsoleContainerViewModel
    @ObservedObject var mode: ConsoleModePickerViewModel
    
    init(model: ConsoleContainerViewModel) {
        self.model = model
        self.mode = model.mode
    }
    
    var body: some View {
        switch mode.mode {
        case .list:
            VStack(spacing: 0) {
                ConsoleTableViewPro(model: model.console)
                if mode.mode == .list {
                    TextSearchToolbarWrapper(toolbar: model.toolbar, search: model.console.search)
                }
            }
            .onAppear(perform: model.console.onAppear)
            .background(NavigationTitleUpdater(list: model.console.list))
        case .text:
            ConsoleStoryView(model: model.console)
                .background(NavigationTitleUpdater(list: model.console.list))
        case .network:
            VStack(spacing: 0) {
                NetworkListViewPro(list: model.network.list, main: model.network)
                TextSearchToolbarWrapper(toolbar: model.toolbar, search: model.network.search)
            }
            .onAppear(perform: model.network.onAppear)
            .background(NetworkNavigationTitleUpdater(list: model.network.list))
        }
    }
}

private struct TextSearchToolbarWrapper: View {
    @ObservedObject var toolbar: ConsoleToolbarViewModel
    @ObservedObject var search: TextSearchViewModel
    
    var body: some View {
        if toolbar.isSearchBarActive || !search.matches.isEmpty {
            Divider()
            TextSearchToolbar(model: search)
        }
    }
}

private struct NavigationTitleUpdater: View {
    @ObservedObject var list: ManagedObjectsList<LoggerMessageEntity>
    
    var body: some View {
        EmptyView()
            .navigationSubtitle("\(list.count) Messages")
    }
}

private struct NetworkNavigationTitleUpdater: View {
    @ObservedObject var list: ManagedObjectsList<LoggerNetworkRequestEntity>
    
    var body: some View {
        EmptyView()
            .navigationSubtitle("\(list.count) Requests")
    }
}

struct ConsoleContainerDetailsPanel: View {
    @ObservedObject var model: ConsoleDetailsPanelViewModel

    var body: some View {
        if let selectedEntity = model.selectedEntity {
            model.makeDetailsRouter(for: selectedEntity, onClose: { model.selectedEntity = nil })
        } else {
            Text("No Selection")
                .font(.title)
                .foregroundColor(.secondary)
                .toolbar(content: {
                    Spacer()
                })
        }
    }
}

enum ConsoleViewMode {
    case list
    case text
    case network
}

// MARK: - Helpers

private struct ConsoleWindowAccessors: View {
    let model: ConsoleToolbarViewModel
    @State private var window: NSWindow?
    
    #warning("TODO: rework how sohrtcuts are triggered")
    var body: some View {
        EmptyView()
            .background(WindowAccessor(window: $window))
            .onReceive(CommandsRegistry.shared.onToggleFilters) {
                if window?.isKeyWindow ?? false { model.isFiltersPaneHidden.toggle() }
            }
    }
}

private struct ConsoleToolbarSearchBar: View {
    let model: ConsoleMainViewModel
    @ObservedObject var toolbar: ConsoleToolbarViewModel
    @ObservedObject var mode: ConsoleModePickerViewModel
    @ObservedObject var searchBar: ConsoleSearchBarViewModel
    
    init(model: ConsoleContainerViewModel) {
        self.model = model.console
        self.toolbar = model.toolbar
        self.mode = model.mode
        self.searchBar = model.searchBar
    }
    
    var body: some View {
        SearchBar(title: mode.mode == .list ? "Search" : "Filter", text: $searchBar.text, onFind: CommandsRegistry.shared.onFind, onEditingChanged: { isEditing in
            toolbar.isSearchBarActive = isEditing
        }, onReturn: model.search.nextMatch)
            .frame(width: toolbar.isSearchBarActive ? 200 : 95)
            .help("Search (⌘F)")
    }
}

private struct ExDivider: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var color: Color {
        colorScheme == .dark ? .black : .separator
    }
    var width: CGFloat = 1
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width)
            .edgesIgnoringSafeArea(.vertical)
    }
}

// MARK: - Toolbar

private struct ConsoleNowView: View {
    @ObservedObject var model: ConsoleToolbarViewModel
    
    var body: some View {
        Button(action: { model.isNowEnabled.toggle() }) {
            Image(systemName: model.isNowEnabled ? "clock.fill" : "clock")
                .foregroundColor(model.isNowEnabled ? Color.accentColor : Color.secondary)
        }.help("Automatically Scroll to Recent Messages (⇧⌘N)")
    }
}

private struct ConsoleToolbarToggleFiltersButton: View {
    @ObservedObject var model: ConsoleToolbarViewModel
    
    var body: some View {
        Button(action: { model.isFiltersPaneHidden.toggle() }, label: {
            Image(systemName: model.isFiltersPaneHidden ? "line.horizontal.3.decrease.circle" : "line.horizontal.3.decrease.circle.fill")
        }).foregroundColor(model.isFiltersPaneHidden ? .secondary : .accentColor)
            .help("Toggle Filters Panel (⌥⌘F)")
    }
}

private struct ConsoleToolbarToggleOnlyErrorsButton: View {
    @ObservedObject var model: ConsoleToolbarViewModel
    
    var body: some View {
        Button(action: { model.isOnlyErrors.toggle() }) {
            Image(systemName: model.isOnlyErrors ? "exclamationmark.octagon.fill" : "exclamationmark.octagon")
        }.foregroundColor(model.isOnlyErrors ? .accentColor : .secondary)
            .help("Toggle Show Only Errors (⇧⌘E)")
    }
}

private struct ConsoleToolbarModePickerView: View {
    @ObservedObject var model: ConsoleModePickerViewModel
    
    var body: some View {
        Picker("Mode", selection: $model.mode) {
            Label("as List", systemImage: "list.dash").tag(ConsoleViewMode.list)
            Label("as Text", systemImage: "doc.plaintext").tag(ConsoleViewMode.text)
            Label("as Network", systemImage: "network").tag(ConsoleViewMode.network)
        }.pickerStyle(InlinePickerStyle())
    }
}

private struct ConsoleToolbarToggleVerticalView: View {
    @ObservedObject var model: ConsoleToolbarViewModel
    
    var body: some View {
        Button(action: { model.isVertical.toggle() }, label: {
            Image(systemName: model.isVertical ? "square.split.2x1" : "square.split.1x2")
        }).help(model.isVertical ? "Switch to Horizontal Layout" : "Switch to Vertical Layout")
    }
}

// MARK: - ViewModel

final class ConsoleContainerViewModel: ObservableObject {
    let console: ConsoleMainViewModel
    let network: NetworkMainViewModel
    let remote: RemoteLoggerClientViewModel
    
    let mode = ConsoleModePickerViewModel()
    let toolbar = ConsoleToolbarViewModel()
    let searchBar = ConsoleSearchBarViewModel()
    let details: ConsoleDetailsPanelViewModel
    
    let name: String?
    
    private let store: LoggerStore
    
    private var cancellables: [AnyCancellable] = []
    
    init(store: LoggerStore, name: String? = nil, client: RemoteLoggerClient?) {
        self.store = store
        self.name = name

        self.details = ConsoleDetailsPanelViewModel(store: store)
        self.console = ConsoleMainViewModel(store: store, toolbar: toolbar, details: details, mode: mode)
        self.network = NetworkMainViewModel(store: store, toolbar: toolbar, details: details)
        self.remote = RemoteLoggerClientViewModel(client: client)
        
        self.toolbar.isNowEnabled = client != nil
        
        mode.$mode.sink { [weak self] _ in
            self?.resetSearchBar()
        }.store(in: &cancellables)
        
        searchBar.$text.sink { [weak self] in
            self?.didChangeSearchText($0)
        }.store(in: &cancellables)
    }
        
    private func resetSearchBar() {
        if searchBar.text != "" { searchBar.text = "" }
        if console.filterTerm != "" { console.filterTerm = "" }
        if console.searchTerm != "" { console.searchTerm = "" }
        if network.searchTerm != "" { network.searchTerm = "" }
    }
    
    private func didChangeSearchText(_ text: String) {
        switch mode.mode {
        case .list: console.searchTerm = text
        case .network: network.searchTerm = text
        case .text: console.filterTerm = text
        }
    }
}
