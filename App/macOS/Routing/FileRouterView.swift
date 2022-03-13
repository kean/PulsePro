// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Cocoa
import PulseCore
import SwiftUI
import Combine

struct FileRouterView: View {
    @StateObject var model = FileRouterViewModel()

    var body: some View {
        contents
            .onOpenURL(perform: model.open)
    }

    @ViewBuilder
    private var contents: some View {
        if let store = model.selectedStore {
            MainViewPro(store: store)
        } else if let (data, url) = model.selectedJsonData {
            StandaloneJSONViewer(model: .init(data: data, url: url))
        } else if let alert = model.alert {
            PlaceholderView(imageName: "exclamationmark.circle.fill", title: alert.title, subtitle: alert.message)
        } else {
            PlaceholderView(imageName: "exclamationmark.circle.fill", title: "Failed to open store", subtitle: nil)
        }
    }
}

final class FileRouterViewModel: ObservableObject {
    @Published var selectedStore: LoggerStore?
    @Published var selectedJsonData: (Data, URL)?
    @Published var alert: AlertViewModel?

    init() {}

    func open(url: URL) {
        do {
            if url.pathExtension == "json" {
                let data = try Data(contentsOf: url)
                selectedJsonData = (data, url)
            } else {
                self.selectedStore = try LoggerStore(storeURL: url)
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
            }
        } catch {
            alert = AlertViewModel(title: "Failed to open Pulse document", message: error.localizedDescription)
        }
    }
}
