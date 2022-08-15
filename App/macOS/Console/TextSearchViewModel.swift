//
//  TextSearchViewModel.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 10/13/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData
import Pulse

final class TextSearchViewModel: ObservableObject {
    @Published var searchOptions = StringSearchOptions()
    @Published var selectedMatchIndex = 0
    @Published private(set) var matches: [ConsoleMatch] = []
    private(set) var matchesSet: Set<NSManagedObjectID> = []
    private let textSearch: TextSearchProtocol
    
    var onSelectMatchIndex: ((Int) -> Void)?
    
    init(textSearch: TextSearchProtocol) {
        self.textSearch = textSearch
    }
    
    var previousMatchObjectId: NSManagedObjectID? {
        !matches.isEmpty ? matches[selectedMatchIndex].objectID : nil
    }
        
    func refresh(searchTerm: String, searchOptions: StringSearchOptions) {
        if !textSearch.isEmpty, searchTerm.count > 1 {
            let previousMatchObjectID = previousMatchObjectId
            matches = textSearch.search(term: searchTerm, options: searchOptions)
            matchesSet = Set(matches.map { $0.objectID })
            if previousMatchObjectID == nil || !matchesSet.contains(previousMatchObjectID!) {
               updateMatchIndex(0)
            } else {
                if let newIndexOfPreviousMatch = matches.firstIndex(where: { $0.objectID == previousMatchObjectID }) {
                    selectedMatchIndex = newIndexOfPreviousMatch
                }
            }
        } else {
            selectedMatchIndex = 0
            matches = []
            matchesSet = []
        }
    }
    
    func isMatch(_ message: NSManagedObject) -> Bool {
        matchesSet.contains(message.objectID)
    }

    func nextMatch() {
        guard !matches.isEmpty else { return }
        updateMatchIndex(selectedMatchIndex + 1 < matches.count ? selectedMatchIndex + 1 : 0)
    }

    func previousMatch() {
        guard !matches.isEmpty else { return }
        updateMatchIndex(selectedMatchIndex - 1 < 0 ? matches.count - 1 : selectedMatchIndex - 1)
    }
    
    private func updateMatchIndex(_ newIndex: Int) {
        selectedMatchIndex = newIndex
        onSelectMatchIndex?(newIndex)
    }
}

protocol TextSearchProtocol {
    var isEmpty: Bool { get }
    func search(term: String, options: StringSearchOptions) -> [ConsoleMatch]
}

extension ManagedObjectTextSearch: TextSearchProtocol {
    var isEmpty: Bool { objects.isEmpty }
}
