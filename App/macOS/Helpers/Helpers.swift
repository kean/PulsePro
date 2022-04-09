// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Foundation
import PulseCore
import CoreData

extension URL {
    static var library: URL {
        let url = Files.urls(for: .libraryDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/dev/null")
        Files.createDirectoryIfNeeded(at: url)
        return url
    }
}

func stringPrecise(from timeInterval: TimeInterval) -> String {
    let ti = Int(timeInterval)
    let ms = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 1000)
    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    
    if hours >= 1 {
        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    } else {
        return String(format: "%0.2d:%0.2d.%0.3d",minutes,seconds,ms)
    }
}

extension LoggerNetworkRequestEntity {
    var isSuccess: Bool {
        guard let state = State(rawValue: requestState) else {
            if errorCode != 0 {
                return false
            } else if statusCode != 0, !(200..<400).contains(statusCode) {
                return false
            } else {
                return true
            }
        }
        return state == .success
    }
}

func descriptionForStatusCode(_ statusCode: Int) -> String {
    switch statusCode {
    case 200: return "200 (OK)"
    default: return "\(statusCode) (\( HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized))"
    }
}

var Files: FileManager { FileManager.default }

extension FileManager {
    @discardableResult
    func createDirectoryIfNeeded(at url: URL) -> Bool {
        guard !fileExists(atPath: url.path) else { return false }
        try? createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
        return true
    }
}

extension URL {
    static var temp: URL {
        let url = Files.temporaryDirectory
            .appendingDirectory("com.github.kean.logger")
        Files.createDirectoryIfNeeded(at: url)
        return url
    }

    static var logs: URL {
        var url = Files.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingDirectory("Logs")
            .appendingDirectory("com.github.kean.logger")  ?? URL(fileURLWithPath: "/dev/null")
        if !Files.createDirectoryIfNeeded(at: url) {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? url.setResourceValues(resourceValues)
        }
        return url
    }

    func appendingFilename(_ filename: String) -> URL {
        appendingPathComponent(filename, isDirectory: false)
    }

    func appendingDirectory(_ directory: String) -> URL {
        appendingPathComponent(directory, isDirectory: true)
    }
}

// MARK: - CoreData

extension NSPersistentStoreCoordinator {
    func createCopyOfStore(at url: URL) throws {
        guard let sourceStore = persistentStores.first else {
            throw LoggerStoreError.unknownError // Should never happen
        }

        let backupCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        var intermediateStoreOptions = sourceStore.options ?? [:]
        intermediateStoreOptions[NSReadOnlyPersistentStoreOption] = true

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

        try backupCoordinator.migratePersistentStore(
            intermediateStore,
            to: url,
            options: backupStoreOptions,
            withType: NSSQLiteStoreType
        )
    }
}

extension NSManagedObjectContext {
    func tryPerform<T>(_ closure: () throws -> T) throws -> T {
        var result: Result<T, Error>?
        performAndWait {
            result = Result { try closure() }
        }
        guard let unwrappedResult = result else { throw LoggerStoreError.unknownError }
        return try unwrappedResult.get()
    }
}

