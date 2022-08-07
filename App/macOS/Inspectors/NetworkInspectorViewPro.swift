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
    @ObservedObject var viewModel: NetworkInspectorViewModelPro
    @AppStorage("networkInspectorSelectedTab") private var selectedTab: NetworkInspectorTabPro = .response
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
            NetworkInspectorSummaryView(viewModel: viewModel.makeSummaryModel())
        case .headers:
            NetworkInspectorHeadersViewPro(viewModel: viewModel.makeHeadersModel())
        case .request:
            if let viewModel = viewModel.makeRequestBodyViewModel() {
                FileViewerPro(viewModel: viewModel)
            } else {
                makePlaceholder
            }
        case .response:
            if let viewModel = viewModel.makeResponseBodyViewModel() {
                FileViewerPro(viewModel: viewModel)
            } else {
                makePlaceholder
            }
        case .metrics:
            if let viewModel = viewModel.makeMetricsModel() {
                NetworkInspectorMetricsView(viewModel: viewModel)
            } else {
                makePlaceholder
            }
        case .curl:
            RichTextViewPro(viewModel: .init(string: viewModel.makecURLRepresentation()), content: .curl)
        }
    }

    @ViewBuilder
    private var makePlaceholder: some View {
        PlaceholderView(imageName: "exclamationmark.circle", title: "Not Available")
    }
}

private enum NetworkInspectorTabPro: String, Identifiable {
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

final class NetworkInspectorViewModelPro: ObservableObject {
    private(set) var title: String = ""
    let message: LoggerMessageEntity
    private let objectId: NSManagedObjectID
    let request: LoggerNetworkRequestEntity

    init(message: LoggerMessageEntity, request: LoggerNetworkRequestEntity) {
        self.objectId = message.objectID
        self.message = message
        self.request = request

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
        NetworkInspectorSummaryViewModel(request: request)
    }

    func makeHeadersModel() -> NetworkInspectorHeaderViewModel {
        NetworkInspectorHeaderViewModel(request: request)
    }

    func makeRequestBodyViewModel() -> FileViewModelPro? {
        guard let requestBody = request.requestBody?.data, !requestBody.isEmpty else { return nil }
        return FileViewModelPro(data: requestBody)
    }

    func makeResponseBodyViewModel() -> FileViewModelPro? {
        guard let responseBody = request.responseBody?.data, !responseBody.isEmpty else { return nil }
        return FileViewModelPro(data: responseBody)
    }

    func makeMetricsModel() -> NetworkInspectorMetricsViewModel? {
        request.details?.metrics.map(NetworkInspectorMetricsViewModel.init)
    }
    
    func makecURLRepresentation() -> NSAttributedString {
        let string = request.cURLDescription()
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
        return NetworkInspectorViewPro(viewModel: .init(message: messsage, request: messsage.request!))
                .previewLayout(.fixed(width: 600, height: 400))
    }
}
#endif
