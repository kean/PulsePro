// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import CoreData
import Pulse
import Combine

struct NetworkInspectorResponseView: View {
    let model: NetworkInspectorResponseViewModel

    var body: some View {
        if let json = try? JSONSerialization.jsonObject(with: model.data, options: []) {
            JSONViewer(json: json)
                .padding([.leading, .trailing], 6)
        } else {
            Text(String(bytes: model.data, encoding: .utf8) ?? "Data: \(model.data.localizedSize)")
                .padding()
        }
    }
}

struct NetworkInspectorResponseViewModel {
    let data: Data
}

private extension Data {
    var localizedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }
}

#if DEBUG
struct NetworkInspectorResponseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorResponseView(model: mockModel)
                .previewDisplayName("Light")
                .environment(\.colorScheme, .light)

            NetworkInspectorResponseView(model: mockModel)
                .previewDisplayName("Dark")
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
        }
    }
}

private let mockModel = NetworkInspectorResponseViewModel(data: MockJSON.allPossibleValues)
#endif
