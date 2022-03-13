// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine

struct NetworkInspectorResponseViewPro: View {
    @ObservedObject var model: NetworkInspectorResponseViewModelPro
    @State private var isSpinnerHidden = true

    var body: some View {
        content
            .onReceive(model.$isLoading.debounce(for: 0.33, scheduler: RunLoop.main, options: nil).removeDuplicates()) {
            self.isSpinnerHidden = !$0
        }
    }
    
    @ViewBuilder var content: some View {
        if let data = model.displayedData {
            switch data {
            case .json(let model):
                makeJSONViewer(model: model)
            case .image(let image):
                makeImageViewer(image: image)
            case .text(let text):
                makePlainTextView(text: text)
            }
        } else {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .opacity(isSpinnerHidden ? 0 : 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func makeJSONViewer(model: JSONViewModel) -> some View {
        JSONView(model: model)
    }
    
    @ViewBuilder
    private func makeImageViewer(image: NSImage) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    KeyValueSectionView(model: KeyValueSectionViewModel(title: "Image", color: .pink, items: [
                        ("Width", "\(image.cgImage?.width ?? 0) px"),
                        ("Height", "\(image.cgImage?.height ?? 0) px")
                    ]))
                }
                
                Divider()

                Image(uxImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                Spacer()
            }.padding()
        }
    }
    
    @ViewBuilder
    private func makePlainTextView(text: NSAttributedString) -> some View {
        RichTextViewPro(model: .init(string: text), content: .response)
    }
}

final class NetworkInspectorResponseViewModelPro: ObservableObject {
    @Published private(set) var displayedData: DisplayedData?
    @Published private(set) var isLoading = false
    
    enum DisplayedData {
        case json(JSONViewModel)
        case text(NSAttributedString)
        case image(UXImage)
    }
        
    init(data: Data) {
        if data.count < 1000 {
            // Fast path
            displayedData = process(data: data)
        } else {
            isLoading = true
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                let result = self.process(data: data)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.displayedData = result
                }
            }
        }
    }
    
    private func process(data: Data) -> DisplayedData {
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            return .json(JSONViewModel(json: json, isExpanded: data.count < (1 * 1024 * 1024)))
        } else if let image = UXImage(data: data) {
            return .image(image)
        } else {
            let string = String(data: data, encoding: .utf8) ?? ""
            let text = NSAttributedString(string: string, attributes: [
                .font: NSFont.systemFont(ofSize: CGFloat(AppSettings.shared.viewerFontSize)), .foregroundColor: UXColor.label,
                .paragraphStyle: NSParagraphStyle.make(lineHeight: Constants.ResponseViewer.lineHeight(for: AppSettings.shared.viewerFontSize))
            ])
            return .text(text)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct NetworkInspectorResponseViewPro_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorResponseViewPro(model: mockModel)
                .previewDisplayName("Light")
                .environment(\.colorScheme, .light)

            NetworkInspectorResponseViewPro(model: .init(data: mockImage))
                .previewDisplayName("Image")
                .environment(\.colorScheme, .light)

            NetworkInspectorResponseViewPro(model: .init(data: mockHTML))
                .previewDisplayName("HTML")
                .environment(\.colorScheme, .light)

            NetworkInspectorResponseViewPro(model: mockModel)
                .previewDisplayName("Dark")
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)


        }
    }
}

private let mockModel = NetworkInspectorResponseViewModelPro(data: MockJSON.allPossibleValues)

private let mockHTML = """
<!DOCTYPE html>
<html>
<body>

<h1>My First Heading</h1>
<p>My first paragraph.</p>

</body>
</html>
""".data(using: .utf8)!
#endif


private extension Data {
    var localizedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }
}
