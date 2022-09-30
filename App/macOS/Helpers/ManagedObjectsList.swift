// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Foundation
import CoreData
import Pulse
import Combine

/// Controlling and reloading the table view (list). Can also be used to observe
/// currently displayed messages in the other parts of the app.
final class ManagedObjectsList<Element: NSManagedObject>: ObservableObject, Collection {
    private var messages: AnyCollection<Element> = AnyCollection([])
    
    let updates = PassthroughSubject<FetchedObjectsUpdate, Never>()
    let scrollToIndex = PassthroughSubject<Int, Never>()
        
    func update(_ update: FetchedObjectsUpdate, _ messages: AnyCollection<Element>) {
        self.messages = messages
        updates.send(update)
        objectWillChange.send()
    }

    func scroll(to index: Int) {
        scrollToIndex.send(index)
    }

    var isCreatedAtAscending = true
    
    // MARK: Collection
    
    typealias Index = Int
    
    var startIndex: Int { 0 }
    var endIndex: Int { messages.count }
    
    var indices: Range<Int> {
        startIndex..<endIndex
    }
    
    subscript(position: Int) -> Element {
        messages[AnyIndex(position)]
    }
    
    func index(after i: Int) -> Int {
        i + 1
    }
}
