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
            .background(ConsoleWindowAccessors(viewModel: viewModel.toolbar))
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    ConsoleToolbarModePickerView(viewModel: viewModel.mode)
                }
                ToolbarItemGroup(placement: .principal) {
                    if let client = viewModel.remote.client {
                        RemoteLoggerClientStatusView(client: client)
                        RemoteLoggerTooglePlayButton(client: client)
                        ConsoleNowView(viewModel: viewModel.toolbar)
                        Button(action: client.clear, label: {
                            Label("Clear", systemImage: "trash")
                        }).help("Remove All Messages (⌘K)")
                    }
                }
                ToolbarItem {
                    Spacer()
                }
                ToolbarItemGroup(placement: .automatic) {
                    ConsoleToolbarSearchBar(viewModel: viewModel)
                    ConsoleToolbarToggleOnlyErrorsButton(viewModel: viewModel.toolbar)
                    ConsoleToolbarToggleFiltersButton(viewModel: viewModel.toolbar)
                    ConsoleToolbarToggleVerticalView(viewModel: viewModel.toolbar)
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
            ConsoleContainerMainPanel(viewModel: viewModel)
                .frame(minWidth: 400, idealWidth: 800, maxWidth: .infinity, minHeight: 120, idealHeight: 480, maxHeight: .infinity, alignment: .center),
            ConsoleContainerDetailsPanel(viewModel: viewModel.details)
                .frame(minWidth: 430, idealWidth: 800, maxWidth: .infinity, minHeight: 120, idealHeight: 480, maxHeight: .infinity, alignment: .center),
            isPanelTwoCollaped: details.selectedEntity == nil,
            isVertical: toolbar.isVertical
        )
    }
}

private struct ConsoleContainerFiltersPanel: View {
    let viewModel: ConsoleContainerViewModel
    @ObservedObject var mode: ConsoleModePickerViewModelPro
    
    init(viewModel: ConsoleContainerViewModel) {
        self.viewModel = viewModel
        self.mode = viewModel.mode
    }
    
    var body: some View {
        switch mode.mode {
        case .list, .text:
            ConsoleFiltersView(viewModel: viewModel.console.filters)
                .frame(width: Filters.preferredWidth)
        case .network:
            NetworkFiltersView(viewModel: viewModel.network.filters)
                .frame(width: Filters.preferredWidth)
        }
    }
}

private struct ConsoleContainerMainPanel: View {
    let viewModel: ConsoleContainerViewModel
    @ObservedObject var mode: ConsoleModePickerViewModelPro
    
    init(viewModel: ConsoleContainerViewModel) {
        self.viewModel = viewModel
        self.mode = viewModel.mode
    }
    
    var body: some View {
        switch mode.mode {
        case .list:
            VStack(spacing: 0) {
                ConsoleTableViewPro(viewModel: viewModel.console)
                if mode.mode == .list {
                    TextSearchToolbarWrapper(toolbar: viewModel.toolbar, search: viewModel.console.search)
                }
            }
            .onAppear(perform: viewModel.console.onAppear)
            .background(NavigationTitleUpdater(list: viewModel.console.list))
        case .text:
            ConsoleStoryView(viewModel: viewModel.console)
                .background(NavigationTitleUpdater(list: viewModel.console.list))
        case .network:
            VStack(spacing: 0) {
                NetworkListViewPro(list: viewModel.network.list, main: viewModel.network)
                TextSearchToolbarWrapper(toolbar: viewModel.toolbar, search: viewModel.network.search)
            }
            .onAppear(perform: viewModel.network.onAppear)
            .background(NetworkNavigationTitleUpdater(list: viewModel.network.list))
        }
    }
}

private struct TextSearchToolbarWrapper: View {
    @ObservedObject var toolbar: ConsoleToolbarViewModel
    @ObservedObject var search: TextSearchViewModel
    
    var body: some View {
        if toolbar.isSearchBarActive || !search.matches.isEmpty {
            Divider()
            TextSearchToolbar(viewModel: search)
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
    @ObservedObject var viewModel: ConsoleDetailsPanelViewModel

    var body: some View {
        if let selectedEntity = viewModel.selectedEntity {
            viewModel.makeDetailsRouter(for: selectedEntity, onClose: { viewModel.selectedEntity = nil })
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
    let viewModel: ConsoleToolbarViewModel
    @State private var window: NSWindow?
    
    #warning("TODO: rework how shortcuts are triggered")
    var body: some View {
        EmptyView()
            .background(WindowAccessor(window: $window))
            .onReceive(CommandsRegistry.shared.onToggleFilters) {
                if window?.isKeyWindow ?? false { viewModel.isFiltersPaneHidden.toggle() }
            }
    }
}

private struct ConsoleToolbarSearchBar: View {
    let viewModel: ConsoleMainViewModel
    @ObservedObject var toolbar: ConsoleToolbarViewModel
    @ObservedObject var mode: ConsoleModePickerViewModelPro
    @ObservedObject var searchBar: ConsoleSearchBarViewModel

    init(viewModel: ConsoleContainerViewModel) {
        self.viewModel = viewModel.console
        self.toolbar = viewModel.toolbar
        self.mode = viewModel.mode
        self.searchBar = viewModel.searchBar
    }

    var body: some View {
        SearchBar(title: mode.mode == .list ? "Search" : "Filter", text: $searchBar.text, onFind: CommandsRegistry.shared.onFind, onEditingChanged: { isEditing in
            toolbar.isSearchBarActive = isEditing
        }, onReturn: viewModel.search.nextMatch)
            .frame(width: toolbar.isSearchBarActive ? 200 : 95)
            .help("Search (⌘F)")
    }
}

private struct ConsoleToolbarModePickerView: View {
    @ObservedObject var viewModel: ConsoleModePickerViewModelPro

    var body: some View {
        Picker("Mode", selection: $viewModel.mode) {
            Label("as List", systemImage: "list.dash").tag(ConsoleViewMode.list)
            Label("as Text", systemImage: "doc.plaintext").tag(ConsoleViewMode.text)
            Label("as Network", systemImage: "network").tag(ConsoleViewMode.network)
        }.pickerStyle(InlinePickerStyle())
    }
}

// MARK: - ViewModel

final class ConsoleContainerViewModel: ObservableObject {
    let console: ConsoleMainViewModel
    let network: NetworkMainViewModel
    let remote: RemoteLoggerClientViewModel
    
    let mode = ConsoleModePickerViewModelPro()
    let toolbar = ConsoleToolbarViewModel()
    let searchBar = ConsoleSearchBarViewModel()
    let details: ConsoleDetailsPanelViewModel
    
    let name: String?
    
    private let store: LoggerStore
    
    private var cancellables: [AnyCancellable] = []
    
    init(store: LoggerStore, name: String? = nil, client: RemoteLoggerClient?) {
        self.store = store
        self.name = name

        self.details = ConsoleDetailsPanelViewModel()
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
