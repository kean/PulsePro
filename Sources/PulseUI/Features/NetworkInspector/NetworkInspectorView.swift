// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

// MARK: - View

struct NetworkInspectorView: View {
    // Make sure all tabs are updated live
    @ObservedObject var model: NetworkInspectorViewModel
    @State private var selectedTab: NetworkInspectorTab = .summary
    @State private var isShowingShareSheet = false

    var body: some View {
        #if os(iOS)
        universalBody
            .navigationBarTitle(Text("Network Inspector"))
            .navigationBarItems(trailing:
                ShareButton {
                    self.isShowingShareSheet = true
                }
            )
            .sheet(isPresented: $isShowingShareSheet) {
                ShareView(activityItems: [self.model.prepareForSharing()])
            }
        #else
        universalBody
        #endif
    }

    private var universalBody: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("Summary").tag(NetworkInspectorTab.summary)
                Text("Headers").tag(NetworkInspectorTab.headers)
                Text("Request").tag(NetworkInspectorTab.request)
                Text("Response").tag(NetworkInspectorTab.response)
                Text("Metrics").tag(NetworkInspectorTab.metrics)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            switch selectedTab {
            case .summary:
                NetworkInspectorSummaryView(model: model.makeSummaryModel())
            case .headers:
                NetworkInspectorHeadersView(model: model.makeHeadersModel())
            case .request:
                if let model = model.makeRequestModel() {
                    NetworkInspectorRequestView(model: model)
                } else {
                    PlaceholderView(title: "Empty")
                }
            case .response:
                if let model = model.makeResponseModel() {
                    NetworkInspectorResponseView(model: model)
                } else {
                    PlaceholderView(title: model.isCompleted ? "Request Pending" : "Empty")
                }
            case .metrics:
                if let model = model.makeMetricsModel() {
                    NetworkInspectorMetricsView(model: model)
                } else {
                    PlaceholderView(title: "Not Available")
                }
            }

            Spacer()
        }
    }
}

private struct PlaceholderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}

private enum NetworkInspectorTab {
    case summary
    case headers
    case request
    case response
    case metrics
}

// MARK: - ViewModel

final class NetworkInspectorViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private let store: LoggerMessageStore
    private let blobs: BlobStoring
    private let taskId: String
    @Published private(set) var messages: [MessageEntity] = []
    private var summary: NetworkLoggerSummary
    var isCompleted: Bool { summary.isCompleted }
    private let controller: NSFetchedResultsController<MessageEntity>

    init(store: LoggerMessageStore, blobs: BlobStoring, taskId: String) {
        self.store = store
        self.blobs = blobs
        self.taskId = taskId

        let request = NSFetchRequest<MessageEntity>(entityName: "\(MessageEntity.self)")
        request.predicate = NSPredicate(format: "SUBQUERY(metadata, $entry, $entry.key == %@ AND $entry.value == %@).@count > 0", NetworkLoggerMetadataKey.taskId.rawValue, taskId)
        request.relationshipKeyPathsForPrefetching = ["\(\MessageEntity.metadata.self)"]
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.createdAt, ascending: false)]

        self.controller = NSFetchedResultsController<MessageEntity>(fetchRequest: request, managedObjectContext: store.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.summary = NetworkLoggerSummary(messages: [], blobs: blobs)

        super.init()

        controller.delegate = self
        try? controller.performFetch()
        self.didUpdateMessages(self.controller.fetchedObjects ?? [])
    }

    private func didUpdateMessages(_ messages: [MessageEntity]) {
        self.messages = messages
        self.summary = NetworkLoggerSummary(messages: messages, blobs: blobs)
    }

    // MARK: - Tabs

    func makeSummaryModel() -> NetworkInspectorSummaryViewModel {
        NetworkInspectorSummaryViewModel(summary: summary)
    }

    func makeHeadersModel() -> NetworkInspectorHeaderViewModel {
        NetworkInspectorHeaderViewModel(
            request: summary.request,
            response: summary.response
        )
    }

    func makeRequestModel() -> NetworkInspectorRequestViewModel? {
        summary.requestBody.map(NetworkInspectorRequestViewModel.init)
    }

    func makeResponseModel() -> NetworkInspectorResponseViewModel? {
        summary.responseBody.map(NetworkInspectorResponseViewModel.init)
    }

    func makeMetricsModel() -> NetworkInspectorMetricsViewModel? {
        summary.metrics.map(NetworkInspectorMetricsViewModel.init)
    }

    // MARK: Sharing

    func prepareForSharing() -> String {
        ConsoleShareService(store: store, blobs: blobs).prepareForSharing(summary: summary)
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.didUpdateMessages(self.controller.fetchedObjects ?? [])
    }
}

// MARK: - Preview

#if DEBUG
struct NetworkInspectorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                NetworkInspectorView(model: .init(store: .mock, blobs: BlobStore.mock, taskId: LoggerMessageStore.mock.taskIdWithURL(MockDataTask.login.request.url!) ?? "–"))
            }
            .previewDisplayName("Light")
            .environment(\.colorScheme, .light)

            NavigationView {
                NetworkInspectorView(model: .init(store: .mock, blobs: BlobStore.mock, taskId: LoggerMessageStore.mock.taskIdWithURL(MockDataTask.login.request.url!) ?? "–"))
            }
            .previewDisplayName("Dark")
            .environment(\.colorScheme, .dark)
        }
    }
}
#endif
