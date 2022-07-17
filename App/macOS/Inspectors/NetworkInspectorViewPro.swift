// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine

// MARK: - View

private struct NetworkTabView: View {
    @Binding var selectedTab: NetworkInspectorTabPro
    
    var body: some View {
        HStack(spacing: 0) {
            HStack {
                makeItem("Response", tab: .response)
                Divider()
                makeItem("Request", tab: .request)
                Divider()
                makeItem("Headers", tab: .headers)
                Divider()
            }
            HStack {
                Spacer().frame(width: 8)
                makeItem("Summary", tab: .summary)
                Divider()
                makeItem("Metrics", tab: .metrics)
                Divider()
                makeItem("cURL", tab: .curl)
            }
        }.fixedSize()
    }
    
    private func makeItem(_ title: String, tab: NetworkInspectorTabPro) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundColor(tab == selectedTab ? .accentColor : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 13.0, tvOS 14.0, watchOS 7.0, *)
struct NetworkInspectorViewPro: View {
    // Make sure all tabs are updated live
    @ObservedObject var model: NetworkInspectorViewModelPro
    @State private var selectedTab: NetworkInspectorTabPro = .response
    @Environment(\.colorScheme) private var colorScheme
    var onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            selectedTabView
                .background(colorScheme == .dark ? Color(NSColor(red: 30/255.0, green: 30/255.0, blue: 30/255.0, alpha: 1)) : .clear)
        }
        .background(colorScheme == .light ? Color(UXColor.controlBackgroundColor) : Color(UXColor.clear))
    }

    @ViewBuilder
    private var toolbar: some View {
        HStack {
            NetworkTabView(selectedTab: $selectedTab)
            Spacer()
            if let onClose = onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark").foregroundColor(.secondary)
                }.buttonStyle(PlainButtonStyle())
            }
        }.padding(EdgeInsets(top: 7, leading: 10, bottom: 6, trailing: 10))
    }
    
    @ViewBuilder
    private var selectedTabView: some View {
        switch selectedTab {
        case .summary:
            NetworkInspectorSummaryView(viewModel: model.makeSummaryModel())
        case .headers:
            NetworkInspectorHeadersViewPro(viewModel: model.makeHeadersModel())
        case .request:
            if let model = model.makeRequestBodyViewModel() {
                NetworkInspectorResponseViewPro(model: model)
            } else {
                makePlaceholder
            }
        case .response:
            if let model = model.makeResponseBodyViewModel() {
                NetworkInspectorResponseViewPro(model: model)
            } else {
                makePlaceholder
            }
        case .metrics:
            if let model = model.makeMetricsModel() {
                NetworkInspectorMetricsView(viewModel: model)
            } else {
                makePlaceholder
            }
        case .curl:
            RichTextViewPro(model: .init(string: model.makecURLRepresentation()), content: .curl)
        }
    }

    @ViewBuilder
    private var makePlaceholder: some View {
        PlaceholderView(imageName: "exclamationmark.circle", title: "Not Available")
    }
}

private enum NetworkInspectorTabPro: Identifiable {
    case summary
    case headers
    case request
    case response
    case metrics
    case curl

    var id: NetworkInspectorTabPro { self }

    var text: String {
        switch self {
        case .summary: return "Summary"
        case .headers: return "Headers"
        case .request: return "Request"
        case .response: return "Response"
        case .metrics: return "Metrics"
        case .curl: return "cURL"
        }
    }
}

// MARK: - ViewModel

@available(iOS 13.0, tvOS 14.0, watchOS 7.0, *)
final class NetworkInspectorViewModelPro: ObservableObject {
    private(set) var title: String = ""
    let message: LoggerMessageEntity
    let request: LoggerNetworkRequestEntity
    private let objectId: NSManagedObjectID
    let store: LoggerStore // TODO: make it private
    private let summary: NetworkLoggerSummary

    init(message: LoggerMessageEntity, request: LoggerNetworkRequestEntity, store: LoggerStore) {
        self.objectId = message.objectID
        self.message = message
        self.request = request
        self.store = store
        self.summary = NetworkLoggerSummary(request: request, store: store)

        if let url = request.url.flatMap(URL.init(string:)) {
            if let httpMethod = request.httpMethod {
                self.title = "\(httpMethod) /\(url.lastPathComponent)"
            } else {
                self.title = "/" + url.lastPathComponent
            }
        }
    }

    // MARK: - Tabs

    func makeSummaryModel() -> NetworkInspectorSummaryViewModel {
        NetworkInspectorSummaryViewModel(summary: summary)
    }

    func makeHeadersModel() -> NetworkInspectorHeaderViewModel {
        NetworkInspectorHeaderViewModel(summary: summary)
    }

    func makeRequestBodyViewModel() -> NetworkInspectorResponseViewModelPro? {
        guard let requestBody = summary.requestBody, !requestBody.isEmpty else { return nil }
        return NetworkInspectorResponseViewModelPro(data: requestBody)
    }

    func makeResponseBodyViewModel() -> NetworkInspectorResponseViewModelPro? {
        guard let responseBody = summary.responseBody, !responseBody.isEmpty else { return nil }
        return NetworkInspectorResponseViewModelPro(data: responseBody)
    }

    func makeMetricsModel() -> NetworkInspectorMetricsViewModel? {
        summary.metrics.map(NetworkInspectorMetricsViewModel.init)
    }
    
    func makecURLRepresentation() -> NSAttributedString {
        let string = NetworkLoggerSummary(request: request, store: store).cURLDescription()
        let fontSize = AppSettings.shared.cURLFontSize
        return NSAttributedString(string: string, attributes: [
            .font:  UXFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular),
            .foregroundColor: UXColor.label,
            .paragraphStyle: NSParagraphStyle.make(fontSize: fontSize)
        ])
    }
}

#if DEBUG
struct NetworkInspectorViewPro_Previews: PreviewProvider {
    static var previews: some View {
            let messsage = try! LoggerStore.mock.allMessages()[7]
        return NetworkInspectorViewPro(model: .init(message: messsage, request: messsage.request!, store: .mock))
                .previewLayout(.fixed(width: 600, height: 400))
    }
}
#endif
