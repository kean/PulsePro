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

    var body: some View {
        #if os(iOS)
        universalBody
            .navigationBarTitle(Text("Network Inspector"))
        #else
        universalBody
        #endif
    }

    private var universalBody: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("Summary").tag(NetworkInspectorTab.summary)
                Text("Headers").tag(NetworkInspectorTab.headers)
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
            case .response:
                NetworkInspectorResponseView(model: model.makeResponseModel())
            case .metrics:
                if let model = model.makeMetricsModel() {
                    NetworkInspectorMetricsView(model: model)
                } else {
                    Text("Not Available")
                        .font(.title)
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                }
            }

            Spacer()
        }
    }
}

private enum NetworkInspectorTab {
    case summary
    case headers
    case response
    case metrics
}

// MARK: - ViewModel

final class NetworkInspectorViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private let store: LoggerMessageStore
    private let taskId: String
    @Published private(set) var messages: [MessageEntity] = []
    private var summary: NetworkLoggerSummary

    private let controller: NSFetchedResultsController<MessageEntity>

    init(store: LoggerMessageStore, taskId: String) {
        self.store = store
        self.taskId = taskId

        let request = NSFetchRequest<MessageEntity>(entityName: "\(MessageEntity.self)")
        request.predicate = NSPredicate(format: "SUBQUERY(metadata, $entry, $entry.key == %@ AND $entry.value == %@).@count > 0", NetworkLoggerMetadataKey.taskId.rawValue, taskId)
        request.relationshipKeyPathsForPrefetching = ["\(\MessageEntity.metadata.self)"]
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.createdAt, ascending: false)]

        self.controller = NSFetchedResultsController<MessageEntity>(fetchRequest: request, managedObjectContext: store.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.summary = NetworkLoggerSummary(messages: [])

        super.init()

        controller.delegate = self
        try? controller.performFetch()
        self.didUpdateMessages(self.controller.fetchedObjects ?? [])
    }

    private func didUpdateMessages(_ messages: [MessageEntity]) {
        self.messages = messages
        self.summary = NetworkLoggerSummary(messages: messages)
    }

    // MARK: - Tabs

    func makeSummaryModel() -> NetworkInspectorSummaryViewModel {
        NetworkInspectorSummaryViewModel(
            request: summary.request,
            response: summary.response,
            responseBody: summary.responseBody,
            error: summary.error,
            metrics: summary.metrics
        )
    }

    func makeHeadersModel() -> NetworkInspectorHeaderViewModel {
        NetworkInspectorHeaderViewModel(
            request: summary.request,
            response: summary.response
        )
    }

    func makeResponseModel() -> NetworkInspectorResponseViewModel {
        NetworkInspectorResponseViewModel(
            data: summary.responseBody
        )
    }

    func makeMetricsModel() -> NetworkInspectorMetricsViewModel? {
        summary.metrics.map(NetworkInspectorMetricsViewModel.init)
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
                NetworkInspectorView(model: .init(store: .mock, taskId: LoggerMessageStore.mock.taskIdWithURL(MockDataTask.login.request.url!) ?? "–"))
            }
            .previewDisplayName("Light")
            .environment(\.colorScheme, .light)

            NavigationView {
                NetworkInspectorView(model: .init(store: .mock, taskId: LoggerMessageStore.mock.taskIdWithURL(MockDataTask.login.request.url!) ?? "–"))
            }
            .previewDisplayName("Dark")
            .environment(\.colorScheme, .dark)
        }
    }
}
#endif
