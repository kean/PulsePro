// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

struct ConsoleMessageDetailsView: View {
    let model: ConsoleMessageDetailsViewModel
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        contents
            .navigationBarTitle("Message")
    }

    private var contents: some View {
        VStack {
            tags
            TextView(text: .constant(model.text), isEditing: .constant(false), isEditable: false, isScrollingEnabled: true)
            .padding(8)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var tags: some View {
        VStack(alignment: .leading) {
            ForEach(model.tags, id: \.title) { tag in
                HStack {
                    Text(tag.title)
                        .font(.caption)
                        .foregroundColor(self.model.style.titleColor)
                    Text(tag.value)
                        .font(.caption)
                        .bold()
                        .foregroundColor(self.model.style.titleColor)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.15))
    }
}

struct ConsoleMessageDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConsoleMessageDetailsView(model:
                ConsoleMessageDetailsViewModel(tags: [.init(title: "Date", value: "2019 Feb 10"), .init(title: "System", value: "-")], text: "UIApplication.willEnterForeground", style: .fatal)
            ).previewDisplayName("Fatal Dark")

            ConsoleMessageDetailsView(model:
                ConsoleMessageDetailsViewModel(tags: [.init(title: "Date", value: "2019 Feb 10"), .init(title: "System", value: "-")], text: "Aenean vel ullamcorper ipsum. Pellentesque viverra fringilla accumsan. Vestibulum blandit accumsan tortor, viverra laoreet augue rutrum et. Praesent quis libero est. Duis imperdiet, eros sit amet commodo tincidunt, risus est interdum mi, sit amet sagittis nunc sapien et orci. Phasellus lectus ante, rutrum vel lorem vitae, interdum elementum erat. ", style: .debug)
            )
        }
    }
}
