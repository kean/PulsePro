// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse
import CoreData

public struct ConsoleShareService {
    public let logger: Logger
    private var context: NSManagedObjectContext { logger.container.viewContext }

    public init(logger: Logger) {
        self.logger = logger
    }

    /// Creates a directory with contents of the logger and some additional
    /// information like device DNA.
    ///
    /// - WARNING: Removes the previous share contents!
    func prepareForSharing() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("share", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)

        let allLogs = format(messages: try logger.store.allMessage())
        let allLogsUrl = tempDir.appendingPathComponent("logs-all.txt")
        try allLogs?.write(to: allLogsUrl)

        let coreDataUrl = tempDir.appendingPathComponent("debug-data.sqlite")
        try logger.container.persistentStoreCoordinator.createCopyOfStore(at: coreDataUrl)

        let userDefaultsContents = UserDefaults.standard.dictionaryRepresentation()
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
            .data(using: .utf8) ??
            "<failed to generate user defaults>".data(using: .utf8)!
        let userDefaultsContentsUrl = tempDir.appendingPathComponent("user-defaults.txt")
        try userDefaultsContents.write(to: userDefaultsContentsUrl)

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

    private func format(messages: [MessageEntity]) -> Data? {
        var output = ""
        for message in messages {
            output.append(format(message: message))
            output.append("\n")
        }
        return output.data(using: .utf8)
    }

    private func format(message: MessageEntity) -> String {
        "\(dateFormatter.string(from: message.createdAt)) [\(message.level)]-[\(message.system):\(message.category)] \(message.text)"
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    return formatter
}()
