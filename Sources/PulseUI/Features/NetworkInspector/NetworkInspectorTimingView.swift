// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI

struct NetworkInspectorTimingView: View {
    var body: some View {
        Text("Timing View")
    }
}

#if DEBUG
struct NetworkInspectorTimingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkInspectorTimingView()
        }
    }
}
#endif
