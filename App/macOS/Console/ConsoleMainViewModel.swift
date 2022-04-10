// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import CoreData
import PulseCore
import Combine
import SwiftUI

final class ConsoleMainViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    let list = ManagedObjectsList<LoggerMessageEntity>()
    let details: ConsoleDetailsPanelViewModel
    let filters = ConsoleSearchCriteriaViewModel()
    let search: TextSearchViewModel
    let toolbar: ConsoleToolbarViewModel
    let mode: ConsoleModePickerViewModel
    
    private let textSearch = ManagedObjectTextSearch<LoggerMessageEntity> { $0.text }
    
    let pins: PinsService
        
    // Search criteria
    @Published var filterTerm: String = ""

    // Text search (not the same as filter)
    @Published var searchTerm: String = ""
        
    @AppStorage("consoleTableShowErrorsInScroller") var isShowingErrorsInScroller = false

    private(set) var earliestMessage: LoggerMessageEntity?
    
    // TODO: get DI right, this is a quick workaround to fix @EnvironmentObject crashes
    var context: AppContext { .init(store: store) }

    private let store: LoggerStore
    private let controller: NSFetchedResultsController<LoggerMessageEntity>
    private var latestSessionId: String?
    private var cancellables = [AnyCancellable]()
    
    init(store: LoggerStore, toolbar: ConsoleToolbarViewModel, details: ConsoleDetailsPanelViewModel, mode: ConsoleModePickerViewModel) {
        self.store = store
        self.toolbar = toolbar
        self.details = details
        self.mode = mode

        self.pins = PinsService.service(for: store)
        
        let request = NSFetchRequest<LoggerMessageEntity>(entityName: "\(LoggerMessageEntity.self)")
        request.fetchBatchSize = 250
        request.relationshipKeyPathsForPrefetching = ["request"]
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LoggerMessageEntity.createdAt, ascending: true)]

        self.controller = NSFetchedResultsController<LoggerMessageEntity>(fetchRequest: request, managedObjectContext: store.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)

        self.search = TextSearchViewModel(textSearch: textSearch)
        
        super.init()

        search.onSelectMatchIndex = { [weak self] in
            self?.didUpdateCurrentSelectedMatch(newMatch: $0)
        }
        
        controller.delegate = self
                
        $filterTerm.throttle(for: 0.33, scheduler: RunLoop.main, latest: true).dropFirst().sink { [weak self] filterTerm in
            self?.refresh(filterTerm: filterTerm)
        }.store(in: &cancellables)
        
        toolbar.$isOnlyErrors.removeDuplicates().dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.refreshNow() }
        }.store(in: &cancellables)
        
        toolbar.$isOnlyPins.removeDuplicates().dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.refreshNow() }
        }.store(in: &cancellables)
        
        filters.dataNeedsReload.throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true).sink { [weak self] in
            self?.refreshNow()
        }.store(in: &cancellables)

        refreshNow()

        Publishers.CombineLatest($searchTerm.throttle(for: 0.33, scheduler: RunLoop.main, latest: true), search.$searchOptions).dropFirst().sink { [weak self] searchTerm, searchOptions in
            self?.search.refresh(searchTerm: searchTerm, searchOptions: searchOptions)
        }.store(in: &cancellables)

        store.backgroundContext.perform {
            self.getAllLabels()
        }
    }

    func setSortDescriptor(_ sortDescriptors: [NSSortDescriptor]) {
        controller.fetchRequest.sortDescriptors = sortDescriptors
        refreshNow()
    }
    
    private func refreshNow() {
        refresh(filterTerm: filterTerm)
    }
    
    func onAppear() {
        var isSelectionFound = false
        if let entity = details.selectedEntity {
            let objects = FetchedObjects(controller: controller)
            if let index = objects.firstIndex(where: { $0.objectID == entity.objectID }) {
                isSelectionFound = true
                selectAndScroll(to: index)
            }
        }
        if !isSelectionFound {
            details.selectedEntity = nil
        }
    }
    
    private func getAllLabels() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "\(LoggerMessageEntity.self)")

        // Required! Unless you set the resultType to NSDictionaryResultType, distinct can't work.
        // All objects in the backing store are implicitly distinct, but two dictionaries can be duplicates.
        // Since you only want distinct names, only ask for the 'name' property.
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["label"]
        fetchRequest.returnsDistinctResults = true

        // Now it should yield an NSArray of distinct values in dictionaries.
        let map = (try? store.backgroundContext.fetch(fetchRequest)) ?? []
        let values = (map as? [[String: String]])?.compactMap { $0["label"] }
        let set = Set(values ?? [])

        DispatchQueue.main.async {
            self.filters.setInitialLabels(set)
        }
    }

    // MARK: Refresh

    private func refresh(filterTerm: String) {
        // Get sessionId
        let sessionId = store === LoggerStore.default ? LoggerSession.current.id.uuidString : latestSessionId

        // Search messages
        ConsoleSearchCriteria.update(request: controller.fetchRequest, filterTerm: filterTerm, criteria: filters.criteria, filters: filters.filters, sessionId: sessionId, isOnlyErrors: toolbar.isOnlyErrors)
        try? controller.performFetch()
        
        if latestSessionId == nil {
            latestSessionId = list.first?.session
        }

        didRefreshMessages()
        search.refresh(searchTerm: searchTerm, searchOptions: search.searchOptions)
    }

    // MARK: Selection

    func selectEntityAt(_ index: Int) {
        details.selectedEntity = list[index]
        if let index = search.matches.firstIndex(where: { $0.index == index }) {
            search.selectedMatchIndex = index
        }
    }

    // MARK: Search (Matches)

    private func didUpdateCurrentSelectedMatch(newMatch: Int) {
        guard !search.matches.isEmpty else { return }
        selectAndScroll(to: search.matches[search.selectedMatchIndex].index)
    }
    
    private func selectAndScroll(to index: Int) {
        list.scroll(to: index)
        selectEntityAt(index)
    }

    func buttonRemoveAllMessagesTapped() {
        store.removeAll()
        pins.removeAllPins()
    }

    // MARK: - NSFetchedResultsControllerDelegate

    private var isChangeContainsOnlyAppends = true
    private var appendRange: Range<Int>?
    private var countBeforeChange = 0
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        isChangeContainsOnlyAppends = true
        countBeforeChange = list.count
        appendRange = nil
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let entity = anObject as? LoggerMessageEntity {
                filters.didInsertEntity(entity)
            }
            if let newIndexPath = newIndexPath, newIndexPath.item >= countBeforeChange {
                if let appendRange = appendRange {
                    self.appendRange = min(appendRange.lowerBound, newIndexPath.item)..<max(appendRange.upperBound, (newIndexPath.item + 1))
                } else {
                    self.appendRange = newIndexPath.item..<(newIndexPath.item + 1)
                }
            } else {
                isChangeContainsOnlyAppends = false
            }
        default:
            isChangeContainsOnlyAppends = false
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if isChangeContainsOnlyAppends, let appendRange = appendRange {
            if toolbar.isOnlyPins {
                // This is a new message, it can't possibly be pinned
            } else {
                list.update(.append(range: appendRange), AnyCollection(FetchedObjects(controller: self.controller)))
            }
        } else {
            didRefreshMessages()
        }
        if list.isEmpty {
            earliestMessage = nil
            filters.setInitialLabels([])
        }
        #warning("TODO: insert instead of refresh + update searched?")
        textSearch.replace(list)
    }
    
    // MARK: Helpers
    
    private func didRefreshMessages() {
        let messages: AnyCollection<LoggerMessageEntity>
        if toolbar.isOnlyPins {
            let objects = controller.fetchedObjects ?? []
            messages = AnyCollection(objects.filter(pins.isPinned))
        } else {
            messages = AnyCollection(FetchedObjects(controller: controller))
        }
        
        if earliestMessage == nil {
            earliestMessage = list.first
        }
        list.update(.reload, messages)
        textSearch.replace(list)
    }
}

final class ConsoleToolbarViewModel: ObservableObject {
    @Published var isFiltersPaneHidden = true
    @AppStorage("console-view-is-vertical") var isVertical = true {
        didSet { objectWillChange.send() }
    }
    @Published var isOnlyErrors = false
    @Published var isOnlyPins = false
    @Published var isSearchBarActive = false
    @Published var isNowEnabled = true
}

final class ConsoleSearchBarViewModel: ObservableObject {
    @Published var text: String = ""
}

final class ConsoleModePickerViewModel: ObservableObject {
    @Published var mode: ConsoleViewMode = .list
}
