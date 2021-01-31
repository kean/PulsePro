// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

struct NetworkInspectorMetricsView: View {
    var body: some View {
        Text("Timing View")

        GeometryReader { geo in
//            TimingRowView(width: geo.size.width)
            Text("123")
        }.padding()
    }
}

#if DEBUG
struct NetworkInspectorMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorMetricsView()
                .previewLayout(.fixed(width: 320, height: 500))
                .previewDisplayName("Light")
                .environment(\.colorScheme, .light)
            
            NetworkInspectorMetricsView()
                .previewLayout(.fixed(width: 320, height: 500))
                .previewDisplayName("Dark")
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif
