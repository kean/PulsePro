// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import CoreData
import Pulse
import Combine
import SwiftUI

final class NetworkMainViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {

    let list = ManagedObjectsList<NetworkTaskEntity>()
    let details: ConsoleDetailsPanelViewModel
    let filters: NetworkSearchCriteriaViewModel
    let search: TextSearchViewModel
    let toolbar: ConsoleToolbarViewModel
    #warning("TODO: reimplement what text is used and don't pull related message")
    private let textSearch = ManagedObjectTextSearch<NetworkTaskEntity> { $0.message?.text ?? "" }
    
    let pins: PinsService

    // Text search (not the same as filter)
    @Published var searchTerm: String = ""

    private(set) var store: LoggerStore
    private let controller: NSFetchedResultsController<NetworkTaskEntity>
    private var latestSessionId: UUID?
    private var isFirstRefresh = true
    private var cancellables = [AnyCancellable]()
    private var appliedProgrammaticFilters: [NetworkSearchFilter] = []

    init(store: LoggerStore, toolbar: ConsoleToolbarViewModel, details: ConsoleDetailsPanelViewModel) {
        self.store = store
        self.toolbar = toolbar
        self.details = details
        self.filters = NetworkSearchCriteriaViewModel(store: store)

        let request = NSFetchRequest<NetworkTaskEntity>(entityName: "\(NetworkTaskEntity.self)")
        request.fetchBatchSize = 250
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NetworkTaskEntity.createdAt, ascending: true)]

        self.controller = NSFetchedResultsController<NetworkTaskEntity>(fetchRequest: request, managedObjectContext: store.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)

        self.pins = PinsService.service(for: store)
        self.search = TextSearchViewModel(textSearch: textSearch)
        
        super.init()
        
        search.onSelectMatchIndex = { [weak self] in
            self?.didUpdateCurrentSelectedMatch(newMatch: $0)
        }

        controller.delegate = self
        
        toolbar.$isOnlyErrors.removeDuplicates().dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.refreshNow() }
        }.store(in: &cancellables)
        
        toolbar.$isOnlyPins.removeDuplicates().dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.refreshNow() }
        }.store(in: &cancellables)
        
        filters.dataNeedsReload.throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true).sink {
            self.refreshNow()
        }.store(in: &cancellables)

        Publishers.CombineLatest($searchTerm.throttle(for: 0.33, scheduler: RunLoop.main, latest: true), search.$searchOptions).dropFirst().sink { [weak self] searchTerm, searchOptions in
            self?.search.refresh(searchTerm: searchTerm, searchOptions: searchOptions)
        }.store(in: &cancellables)
    }
    
    func onAppear() {
        if isFirstRefresh {
            isFirstRefresh = false
            refreshNow()
        }
        
        var isSelectionFound = false
        if let task = details.selectedEntity?.task {
            let objects = FetchedObjects(controller: controller)
            if let index = objects.firstIndex(where: { $0.objectID == task.objectID }) {
                isSelectionFound = true
                selectAndScroll(to: index)
            }
        }
        if !isSelectionFound {
            details.selectedEntity = nil
        }
    }

    func setSortDescriptor(_ sortDescriptors: [NSSortDescriptor]) {
        controller.fetchRequest.sortDescriptors = sortDescriptors
        refreshNow()
    }
    
    // MARK: Refresh

    private func refreshNow() {
        // Get sessionId
        let sessionId = store === LoggerStore.shared ? LoggerStore.Session.current.id : latestSessionId
        
        // Search messages
        NetworkSearchCriteria.update(request: controller.fetchRequest, filterTerm: "", criteria: filters.criteria, filters: filters.filters, isOnlyErrors: toolbar.isOnlyErrors, sessionId: sessionId)
        try? controller.performFetch()
        self.didRefreshTasks()
        
        if latestSessionId == nil {
            latestSessionId = list.first?.session
        }
        
        self.search.refresh(searchTerm: searchTerm, searchOptions: search.searchOptions)
    }

    // MARK: Selection

    func selectEntityAt(_ index: Int) {
        details.selectedEntity = list[index].message
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
        let requests = FetchedObjects(controller: self.controller)
        if isChangeContainsOnlyAppends, let appendRange = appendRange {
            if toolbar.isOnlyPins {
                // This is a new message, it can't possibly be pinned
            } else if !appliedProgrammaticFilters.isEmpty {
                var appendedTasks: [NetworkTaskEntity] = []
                for index in appendRange {
                    appendedTasks.append(self.controller.object(at: IndexPath(item: index, section: 0)))
                }
                let filteredTasks = appendedTasks.filter { evaluateProgrammaticFilters(appliedProgrammaticFilters, entity: $0, store: store) }
                if !filteredTasks.isEmpty {
                    let currentCount = list.count
                    let shiftedRange = (appendRange.lowerBound - currentCount)..<(appendRange.upperBound - currentCount)
                    let allRequests = Array(list) + filteredTasks
                    list.update(.append(range: shiftedRange), AnyCollection(allRequests))
                }
            } else {
                list.update(.append(range: appendRange), AnyCollection(requests))
            }
        } else {
            didRefreshTasks()
        }
        #warning("TODO: insert instead of refresh + update searched?")
        textSearch.replace(requests)
    }
        
    // MARK: Helpers

    private func didRefreshTasks() {
        var tasks: AnyCollection<NetworkTaskEntity>
        
        // Apply filters that couldn't be done programatically
        if let filters = filters.programmaticFilters {
            self.appliedProgrammaticFilters = filters
            let objects = controller.fetchedObjects ?? []
            tasks = AnyCollection(objects.filter { evaluateProgrammaticFilters(filters, entity: $0, store: store) })
        } else {
            tasks = AnyCollection(FetchedObjects(controller: controller))
        }
        
        if toolbar.isOnlyPins {
            tasks = AnyCollection(tasks.filter(pins.isPinned))
        }
        
        list.update(.reload, tasks)
        textSearch.replace(tasks)
    }
}
