// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import CoreData
import Logging

public extension LoggerMessageStore {
    static let mock: LoggerMessageStore = {
        let store = makeMockStore()
        populateStore(store)

        //        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
        //            logger.log("Hello, world")
        //        }

        return store
    }()
}

private func makeMockStore() -> LoggerMessageStore {
    let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent("com.github.kean.pulse-ui-demo")
    try? FileManager.default.removeItem(at: rootURL)
    try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)

    let storeURL = rootURL.appendingPathComponent("demo-store")
    return LoggerMessageStore(storeURL: storeURL)
}

private extension LoggerMessageStore {
    /// - storeURL: The storeURL.
    ///
    /// - warning: Make sure the directory used in storeURL exists.
    convenience init(storeURL: URL) {
        let container = NSPersistentContainer(name: storeURL.lastPathComponent, managedObjectModel: Self.model)
        let store = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [store]
        self.init(container: container)
    }
}

private extension NSManagedObject {
    convenience init(using usedContext: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: usedContext)!
        self.init(entity: entity, insertInto: usedContext)
    }
}

private func populateStore(_ store: LoggerMessageStore) {
    precondition(Thread.isMainThread)

    let moc = store.container.viewContext

    func addMessage(_ closure: (LoggerMessage) -> Void) {
        let message = LoggerMessage(using: moc)
        closure(message)
        moc.insert(message)
    }

    addMessage {
        $0.createdAt = Date() - 0.11
        $0.level = Logger.Level.info.rawValue
        $0.label = "application"
        $0.session = PersistentLogHandler.logSessionId.uuidString
        $0.text = "UIApplication.didFinishLaunching"
    }

    addMessage {
        $0.createdAt = Date() - 0.1
        $0.level = Logger.Level.info.rawValue
        $0.label = "application"
        $0.session = PersistentLogHandler.logSessionId.uuidString
        $0.text = "UIApplication.willEnterForeground"
    }

    addMessage {
        $0.createdAt = Date() - 0.095
        $0.level = Logger.Level.trace.rawValue
        $0.label = "auth"
        $0.session = PersistentLogHandler.logSessionId.uuidString
        $0.text = "Instantiated Session"
    }

    addMessage {
        $0.createdAt = Date() - 0.092
        $0.level = Logger.Level.trace.rawValue
        $0.label = "auth"
        $0.session = PersistentLogHandler.logSessionId.uuidString
        $0.text = "Instantiated the new login request"
    }

    addMessage {
        $0.createdAt = Date() - 0.07
        $0.level = Logger.Level.debug.rawValue
        $0.label = "auth"
        $0.session = PersistentLogHandler.logSessionId.uuidString
        $0.text = "🌐 Will authorize user with name \"kean@github.com\""
    }

    addMessage {
        $0.createdAt = Date() - 0.05
        $0.level = Logger.Level.warning.rawValue
        $0.label = "auth"
        $0.session = PersistentLogHandler.logSessionId.uuidString
        $0.text = "🌐 Authorization request failed with error 500"
    }

    addMessage {
        $0.createdAt = Date() - 0.04
        $0.level = Logger.Level.debug.rawValue
        $0.label = "auth"
        $0.session = PersistentLogHandler.logSessionId.uuidString
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
        $0.level = Logger.Level.critical.rawValue
        $0.label = "default"
        $0.session = PersistentLogHandler.logSessionId.uuidString
        $0.text = "💥 0xDEADBEEF"
    }

//    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
//        populateStore(logger)
//    }

    try! moc.save()
}
