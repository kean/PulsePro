// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import CoreData

public extension Logger {
    /// A mock logger.
    static let mock: Logger = {
        let container = makeMockMessagesStore()
        let logger = Logger(store: Store(container: container))
        populateStore(logger)

//        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
//            logger.log("Hello, world")
//        }

        return logger
    }()
}

private func makeMockMessagesStore() -> NSPersistentContainer {
    let container = NSPersistentContainer(name: "MockMessagesStore", managedObjectModel: Logger.Store.model)

    let store = NSPersistentStoreDescription(url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))

    container.persistentStoreDescriptions = [store]

    var isCompleted = false
    container.loadPersistentStores { _, error in
        assert(error == nil, "Failed to load persistent store: \(String(describing: error))")
        isCompleted = true
    }

    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

    precondition(isCompleted)

    return container
}

private extension NSManagedObject {
    convenience init(using usedContext: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: usedContext)!
        self.init(entity: entity, insertInto: usedContext)
    }
}

private func populateStore(_ logger: Logger) {
    precondition(Thread.isMainThread)

    let moc = logger.store.container.viewContext

    func addMessage(_ closure: (LoggerMessage) -> Void) {
        let message = LoggerMessage(using: moc)
        closure(message)
        moc.insert(message)
    }

    addMessage {
        $0.createdAt = Date() - 0.11
        $0.level = "info"
        $0.system = "application"
        $0.category = "default"
        $0.session = logger.logSessionId.uuidString
        $0.text = "UIApplication.didFinishLaunching"
    }

    addMessage {
        $0.createdAt = Date() - 0.1
        $0.level = "info"
        $0.system = "application"
        $0.category = "default"
        $0.session = logger.logSessionId.uuidString
        $0.text = "UIApplication.willEnterForeground"
    }

    addMessage {
        $0.createdAt = Date() - 0.07
        $0.level = "debug"
        $0.system = "auth"
        $0.category = "default"
        $0.session = logger.logSessionId.uuidString
        $0.text = "🌐 Will authorize user with name \"kean@github.com\""
    }

    addMessage {
        $0.createdAt = Date() - 0.05
        $0.level = "error"
        $0.system = "auth"
        $0.category = "default"
        $0.session = logger.logSessionId.uuidString
        $0.text = "🌐 Authorization request failed with error 500"
    }

    addMessage {
        $0.createdAt = Date() - 0.04
        $0.level = "debug"
        $0.system = "auth"
        $0.category = "default"
        $0.session = logger.logSessionId.uuidString
        $0.text = """
        Replace this implementation with code to handle the error appropriately. fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

        2015-12-08 15:04:03.888 Conversion[76776:4410388] call stack:
        (
            0   Conversion                          0x000694b5 -[ViewController viewDidLoad] + 128
            1   UIKit                               0x27259f55 <redacted> + 1028
            ...
            9   UIKit                               0x274f67a7 <redacted> + 134
            10  FrontBoardServices                  0x2b358ca5 <redacted> + 232
            11  FrontBoardServices                  0x2b358f91 <redacted> + 44
            12  CoreFoundation                      0x230e87c7 <redacted> + 14
            ...
            16  CoreFoundation                      0x23038ecd CFRunLoopRunInMode + 108
            17  UIKit                               0x272c7607 <redacted> + 526
            18  UIKit                               0x272c22dd UIApplicationMain + 144
            19  Conversion                          0x000767b5 main + 108
            20  libdyld.dylib                       0x34f34873 <redacted> + 2
        )
        """
    }

    addMessage {
        $0.createdAt = Date() - 0.03
        $0.level = "fatal"
        $0.system = "default"
        $0.category = "default"
        $0.session = logger.logSessionId.uuidString
        $0.text = "💥 0xDEADBEAF"
    }

//    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
//        populateStore(container)
//    }

    try! moc.save()
}
