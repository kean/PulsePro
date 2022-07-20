// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import Cocoa
import PulseCore
import SwiftUI
import Combine

struct FileRouterView: View {
    @StateObject var viewModel = FileRouterViewModel()

    var body: some View {
        contents
            .onOpenURL(perform: viewModel.open)
    }

    @ViewBuilder
    private var contents: some View {
        if let store = viewModel.selectedStore {
            MainViewPro(store: store)
        } else if let (data, url) = viewModel.selectedJsonData {
            StandaloneJSONViewer(viewModel: .init(data: data, url: url))
        } else if let alert = viewModel.alert {
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
