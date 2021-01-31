// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import CoreData

public struct ConsoleShareService {
    public let store: LoggerMessageStore
    private var context: NSManagedObjectContext { store.container.viewContext }

    public init(store: LoggerMessageStore) {
        self.store = store
    }

    /// Creates a directory with contents of the logger and some additional
    /// information like device DNA.
    ///
    /// - WARNING: Removes the previous share contents!
    func prepareForSharing() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("share", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)

        let allLogs = format(messages: try store.allMessages())
        let allLogsUrl = tempDir.appendingPathComponent("logs-all.txt")
        try allLogs?.write(to: allLogsUrl)

        let coreDataUrl = tempDir.appendingPathComponent("debug-data.sqlite")
        try store.container.persistentStoreCoordinator.createCopyOfStore(at: coreDataUrl)

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
        "\(dateFormatter.string(from: message.createdAt)) [\(message.level)]-[\(message.label)] \(message.text)"
    }

    func prepareMessageForSharing(_ message: MessageEntity) -> String {
        if let taskId = message.metadata.first(where: { $0.key == NetworkLoggerMetadataKey.taskId.rawValue })?.value {
            return prepareNetworkMessageForSharing(taskId: taskId)
        } else {
            return message.text
        }
    }

    private func prepareNetworkMessageForSharing(taskId: String) -> String {
        let info = NetworkLoggerSummary(store: store, taskId: taskId)

        var output = ""

        func add(title: String) {
            output.append("# \(title)\n\n")
        }

        func add(data: Data) {
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            output.append("```\(json != nil ? "json" : "")\n")
            output.append(prettifyJSON(data))
            output.append("```")
            output.append("\n\n")
        }

        func add(_ keyValueViewModel: KeyValueSectionViewModel?) {
            guard let model = keyValueViewModel else { return }
            add(title: model.title)
            if model.items.isEmpty {
                output.append("Empty")
            } else {
                for item in model.items {
                    output.append("\(item.0): \(item.1 ?? "–")")
                }
            }
            output.append("\n\n")
        }

        let summary = NetworkInspectorSummaryViewModel(summary: info)
        add(summary.summaryModel)
        add(summary.errorModel)
        add(summary.timingDetailsModel)
        if let transferModel = summary.transferModel {
            add(KeyValueSectionViewModel(title: "Sent data", color: .gray, items: [
                ("Total Bytes Sent", transferModel.totalBytesSent),
                ("Headers Sent", transferModel.headersBytesSent),
                ("Body Sent", transferModel.bodyBytesSent),
                ("Total Bytes Recieved", transferModel.totalBytesRecieved),
                ("Headers Recieved", transferModel.headersBytesRecieved),
                ("Body Recieved", transferModel.bodyBytesRecieved),
            ]))
        }
        add(summary.parametersModel)

        let headers = NetworkInspectorHeaderViewModel(request: info.request, response: info.response)

        add(title: "Request Headers")
        add(headers.requestHeaders)

        if let body = info.requestBody {
            add(title: "Request Body")
            add(data: body)
        }

        add(title: "Response Headers")
        add(headers.responseHeaders)

        if let body = info.responseBody {
            add(title: "Response Body")
            add(data: body)
        }

        return output
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    return formatter
}()

private extension NSPersistentStoreCoordinator {
    func createCopyOfStore(at url: URL) throws {
        assert(persistentStores.count == 1, "There is more than one persistent stores registered with the coordator")

        let sourceStore = persistentStores[0]
        let backupCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        let intermediateStoreOptions = (sourceStore.options ?? [:])
            .merging([NSReadOnlyPersistentStoreOption: true],
                     uniquingKeysWith: { $1 })
        let intermediateStore = try backupCoordinator.addPersistentStore(
            ofType: sourceStore.type,
            configurationName: sourceStore.configurationName,
            at: sourceStore.url,
            options: intermediateStoreOptions
        )

        let backupStoreOptions: [AnyHashable: Any] = [
            NSReadOnlyPersistentStoreOption: true,
            // Disable write-ahead logging. Benefit: the entire store will be
            // contained in a single file. No need to handle -wal/-shm files.
            // https://developer.apple.com/library/content/qa/qa1809/_index.html
            NSSQLitePragmasOption: ["journal_mode": "DELETE"],
            // Minimize file size
            NSSQLiteManualVacuumOption: true,
        ]

        try backupCoordinator.migratePersistentStore(intermediateStore, to: url, options: backupStoreOptions, withType: NSSQLiteStoreType)
    }
}
