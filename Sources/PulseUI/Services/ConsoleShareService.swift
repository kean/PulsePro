// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse
import CoreData

public struct ConsoleShareService {
    public let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }

    public init(container: NSPersistentContainer) {
        self.container = container
    }

    /// Creates a directory with contents of the logger and some additional
    /// information like device DNA.
    ///
    /// - WARNING: Removes the previous share contents!
    func prepareForSharing() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("share", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)

        let allLogs = format(messages: try fetchAllMessages())
        let allLogsUrl = tempDir.appendingPathComponent("logs-all.txt")
        try allLogs?.write(to: allLogsUrl)

        let coreDataUrl = tempDir.appendingPathComponent("debug-data.sqlite")
        try container.persistentStoreCoordinator.createCopyOfStore(at: coreDataUrl)

        let userDefaultsContents = UserDefaults.standard.dictionaryRepresentation()
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
            .data(using: .utf8) ??
            "<failed to generate user defaults>".data(using: .utf8)!
        let userDefaultsContentsUrl = tempDir.appendingPathComponent("user-defaults.txt")
        try userDefaultsContents.write(to: userDefaultsContentsUrl)

        #warning("TODO: this isn't going to work in Outlook")
        #warning("TODO: add filtered logs")
        #warning("TODO: add device DNA")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let date = dateFormatter.string(from: Date())
        let sharedDirUrl = tempDir.appendingPathComponent("logs-\(date)")
        try FileManager.default.createDirectory(at: sharedDirUrl, withIntermediateDirectories: true, attributes: nil)

        for url in [allLogsUrl, coreDataUrl, userDefaultsContentsUrl] {
            try FileManager.default.moveItem(at: url, to: sharedDirUrl.appendingPathComponent(url.lastPathComponent))
        }

        return sharedDirUrl
    }

    private func fetchAllMessages() throws -> [MessageEntity] {
        let request = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.created, ascending: true)]
        return try context.fetch(request)
    }

    private func format(messages: [MessageEntity]) -> Data? {
        #warning("TODO: split by sessions")
        var output = ""
        for message in messages {
            output.append(format(message: message))
            output.append("\n")
        }
        return output.data(using: .utf8)
    }

    private func format(message: MessageEntity) -> String {
        #warning("TODO: improve date format")
        #warning("TODO: add icon for criticals/errors")
        #warning("TODO: print type properly")
        #warning("TODO: print type properly")
        return "\(message.created) [\(message.system)][\(message.level)] \(message.text)"
    }
}
