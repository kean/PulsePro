// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import SwiftUI
import Pulse
import PulseUI
import CoreData

protocol AppViewModelDelegate: class {
    func openDocument()
    func showConsole(model: ConsoleViewModel)
}

final class AppViewModel: ObservableObject {
    weak var delegate: AppViewModelDelegate?

    func openDatabase(url: URL) throws {
        let storeURL: URL
        let blobsURL: URL
        if url.pathExtension == "sqlite" {
            storeURL = url
            blobsURL = makeBlobsURL(forStoreURL: storeURL)
        } else { // Assuming the extension is .pulse
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            guard let firstStoreURL = contents.first(where: { $0.pathExtension == "sqlite" }) else {
                throw AppViewModelError.failedToFindLogsStore(url: url)
            }
            storeURL = firstStoreURL
            blobsURL = contents.first(where: { $0.pathExtension == "blobs" }) ??
                makeBlobsURL(forStoreURL: storeURL)
        }

        let store = LoggerMessageStore(storeURL: storeURL)
        let blobs = BlobStore(path: blobsURL, isViewing: true)
        let model = ConsoleViewModel(store: store, blobs: blobs)
        self.delegate?.showConsole(model: model)
    }

    func buttonOpenDocumentTapped() {
        delegate?.openDocument()
    }
}

private func makeBlobsURL(forStoreURL storeURL: URL) -> URL {
    storeURL
        .deletingLastPathComponent()
        .appendingPathComponent(storeURL.deletingPathExtension().lastPathComponent)
        .appendingPathExtension("blobs")
}

enum AppViewModelError: Error, LocalizedError {
    case failedToFindLogsStore(url: URL)

    var errorDescription: String? {
        switch self {
        case .failedToFindLogsStore(let url):
            return "Failed to find a Pulse store at the given URL \(url)"
        }
    }
}
